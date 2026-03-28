import AppKit
import AVFoundation
import Foundation
import IOKit
import IOKit.hid

/// Detects slaps via accelerometer (IOKit HID) with microphone fallback.
/// Based on taigrr/spank's approach: wake SPU drivers first, then register HID callbacks.
final class SlapDetector: ObservableObject {
    @Published var isActive = true
    @Published var sensitivity: Double = 0.5 // 0.0 = very sensitive, 1.0 = less sensitive
    @Published var slapCount: Int = 0
    @Published var detectionMode: String = "Starting..."
    @Published var cooldown: TimeInterval = 0.75 // 750ms default (matches spank), user-configurable
    @Published var fastMode: Bool = false { didSet { cooldown = fastMode ? 0.35 : 0.75 } }

    private var lastSlapTime: Date = .distantPast
    private let onSlap: (Double) -> Void

    // Accelerometer
    private var hidManager: IOHIDManager?
    private var hidDevice: IOHIDDevice?
    private var reportBuffer: UnsafeMutablePointer<UInt8>?
    private var sensorThread: Thread?

    // 2nd-order Butterworth HPF at 4Hz (fs=125Hz after decimation)
    // Coefficients computed via Audio EQ Cookbook (fc=4, fs=125, Q=0.7071)
    private let bw_b0: Double =  0.86744
    private let bw_b1: Double = -1.73488
    private let bw_b2: Double =  0.86744
    private let bw_a1: Double = -1.71710  // negated for y[n] = b*x + a*y convention
    private let bw_a2: Double =  0.75252

    // Butterworth filter state (x history and y history per axis)
    private var bwX: (x1: Double, x2: Double, y1: Double, y2: Double) = (0, 0, 0, 0)
    private var bwY: (x1: Double, x2: Double, y1: Double, y2: Double) = (0, 0, 0, 0)
    private var bwZ: (x1: Double, x2: Double, y1: Double, y2: Double) = (0, 0, 0, 0)

    // STA/LTA detection (from Spank)
    private var staFast: Double = 0, ltaFast: Double = 0
    private var staMed: Double = 0, ltaMed: Double = 0
    private var warmupSamples: Int = 0

    // CUSUM secondary confirmation
    private var cusumPos: Double = 0
    private var cusumNeg: Double = 0
    private var cusumBaseline: Double = 0

    // Runtime sample rate measurement
    private var sampleRateCount: Int = 0
    private var sampleRateStart: Date?
    private var measuredSampleRate: Double = 125.0 // default estimate

    // Microphone fallback
    private var audioRecorder: AVAudioRecorder?
    private var meteringTimer: Timer?
    private var ambientLevel: Float = -40.0

    init(onSlap: @escaping (Double) -> Void) {
        self.onSlap = onSlap
    }

    deinit {
        reportBuffer?.deallocate()
    }

    func start() {
        // Try accelerometer first (needs root for IOKit)
        if startAccelerometer() {
            return
        }

        // Fallback to microphone
        if startMicrophone() {
            return
        }

        // Last resort: keyboard
        detectionMode = "Teclado (Ctrl+Shift+T)"
        setupKeyboardFallback()
    }

    func stop() {
        meteringTimer?.invalidate()
        audioRecorder?.stop()
        if let device = hidDevice {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        if let manager = hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        }
    }

    // MARK: - Accelerometer (IOKit HID, based on taigrr/spank)

    private func startAccelerometer() -> Bool {
        // Step 1: Wake SPU drivers (CRITICAL - without this, sensor sends no data)
        let driversWoken = wakeSPUDrivers()
        print("[MacTapa] SPU drivers woken: \(driversWoken)")

        if driversWoken == 0 {
            print("[MacTapa] No SPU drivers found — this Mac may not have an accelerometer")
            return false
        }

        // Step 2: Find and open SPU HID devices
        guard let device = findSPUHIDDevice() else {
            print("[MacTapa] No accelerometer HID device found")
            return false
        }

        self.hidDevice = device

        let result = IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            print("[MacTapa] Failed to open device (result=\(result)). Run with sudo.")
            return false
        }

        // Allocate report buffer (4096 like spank)
        let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: 4096)
        buf.initialize(repeating: 0, count: 4096)
        self.reportBuffer = buf

        // Register callback
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device, buf, 4096, hidReportCallback, context)

        // Schedule on main run loop (NSApplication.run() drives it)
        IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue)

        print("[MacTapa] Accelerometer active! Listening for slaps...")
        detectionMode = "Acelerometro"
        setupKeyboardFallback()
        return true
    }

    /// Wake AppleSPUHIDDriver instances by setting reporting state, power state, and report interval.
    /// Without this, the sensor hardware stays asleep and produces no HID reports.
    private func wakeSPUDrivers() -> Int {
        var iterator: io_iterator_t = 0
        let matchDict = IOServiceMatching("AppleSPUHIDDriver")

        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matchDict, &iterator)
        guard kr == KERN_SUCCESS else {
            print("[MacTapa] IOServiceGetMatchingServices failed: \(kr)")
            return 0
        }

        var count = 0
        var service = IOIteratorNext(iterator)
        while service != 0 {
            // Set SensorPropertyReportingState = 1 (enable reporting)
            IORegistryEntrySetCFProperty(service, "SensorPropertyReportingState" as CFString, 1 as CFNumber)
            // Set SensorPropertyPowerState = 1 (power on)
            IORegistryEntrySetCFProperty(service, "SensorPropertyPowerState" as CFString, 1 as CFNumber)
            // Set ReportInterval = 1000 microseconds (1kHz)
            IORegistryEntrySetCFProperty(service, "ReportInterval" as CFString, 1000 as CFNumber)

            IOObjectRelease(service)
            count += 1
            service = IOIteratorNext(iterator)
        }
        IOObjectRelease(iterator)
        return count
    }

    /// Find the accelerometer AppleSPUHIDDevice (usage page 0xFF00, usage 3)
    private func findSPUHIDDevice() -> IOHIDDevice? {
        var iterator: io_iterator_t = 0
        let matchDict = IOServiceMatching("AppleSPUHIDDevice")

        let kr = IOServiceGetMatchingServices(kIOMainPortDefault, matchDict, &iterator)
        guard kr == KERN_SUCCESS else {
            print("[MacTapa] No AppleSPUHIDDevice services found")
            return nil
        }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            // Check if this is the accelerometer (usage page 0xFF00, usage 3)
            var usagePage: Int = 0
            var usage: Int = 0

            if let prop = IORegistryEntryCreateCFProperty(service, "PrimaryUsagePage" as CFString, kCFAllocatorDefault, 0) {
                CFNumberGetValue((prop.takeRetainedValue() as! CFNumber), .intType, &usagePage)
            }
            if let prop = IORegistryEntryCreateCFProperty(service, "PrimaryUsage" as CFString, kCFAllocatorDefault, 0) {
                CFNumberGetValue((prop.takeRetainedValue() as! CFNumber), .intType, &usage)
            }

            print("[MacTapa] SPU device: usagePage=0x\(String(usagePage, radix: 16)) usage=\(usage)")

            if usagePage == 0xFF00 && usage == 3 {
                // Found accelerometer — create HID device from service
                let createdDevice = IOHIDDeviceCreate(kCFAllocatorDefault, service)
                IOObjectRelease(service)
                IOObjectRelease(iterator)
                print("[MacTapa] Found accelerometer device!")
                return createdDevice
            }

            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }

        IOObjectRelease(iterator)
        return nil
    }

    // MARK: - HID Report Processing

    private var decimationCount: Int = 0

    fileprivate func processHIDReport(_ report: UnsafeMutablePointer<UInt8>, length: CFIndex) {
        guard length >= 18, isActive else { return }

        // Decimate: keep 1 in 8 (like spank, reduces from ~1kHz to ~125Hz)
        decimationCount += 1
        guard decimationCount % 8 == 0 else { return }

        // Parse x/y/z as int32 LE at offsets 6, 10, 14
        let rawX = readInt32LE(report, offset: 6)
        let rawY = readInt32LE(report, offset: 10)
        let rawZ = readInt32LE(report, offset: 14)

        let gx = Double(rawX) / 65536.0
        let gy = Double(rawY) / 65536.0
        let gz = Double(rawZ) / 65536.0

        // 2nd-order Butterworth HPF: removes gravity, keeps sudden movements
        let fX = butterworthHPF(input: gx, state: &bwX)
        let fY = butterworthHPF(input: gy, state: &bwY)
        let fZ = butterworthHPF(input: gz, state: &bwZ)

        let magnitude = sqrt(fX * fX + fY * fY + fZ * fZ)
        let energy = magnitude * magnitude

        // Sample rate measurement during warmup
        warmupSamples += 1
        if warmupSamples == 1 {
            sampleRateStart = Date()
            sampleRateCount = 0
        }
        sampleRateCount += 1
        if warmupSamples < 200 {
            // Just update LTAs and CUSUM baseline during warmup, don't trigger
            ltaFast += (energy - ltaFast) / 100.0
            ltaMed += (energy - ltaMed) / 500.0
            staFast = ltaFast
            staMed = ltaMed
            cusumBaseline += (energy - cusumBaseline) / 200.0
            return
        }
        if warmupSamples == 200, let start = sampleRateStart {
            let elapsed = Date().timeIntervalSince(start)
            if elapsed > 0 {
                measuredSampleRate = Double(sampleRateCount) / elapsed
                print(String(format: "[MacTapa] Measured sample rate: %.0f Hz (after decimation)", measuredSampleRate))
            }
        }

        // STA/LTA detection (fast: STA=3, LTA=100)
        staFast += (energy - staFast) / 3.0
        ltaFast += (energy - ltaFast) / 100.0

        // STA/LTA detection (medium: STA=15, LTA=500)
        staMed += (energy - staMed) / 15.0
        ltaMed += (energy - ltaMed) / 500.0

        let ratioFast = ltaFast > 1e-10 ? staFast / ltaFast : 0
        let ratioMed = ltaMed > 1e-10 ? staMed / ltaMed : 0

        // CUSUM change-point detection (secondary confirmation)
        let cusumDrift = energy - cusumBaseline
        cusumPos = max(0, cusumPos + cusumDrift - 0.001)
        cusumNeg = max(0, cusumNeg - cusumDrift - 0.001)
        let cusumTriggered = cusumPos > 0.05 || cusumNeg > 0.05
        // Slowly adapt baseline
        cusumBaseline += (energy - cusumBaseline) / 2000.0

        // Threshold based on sensitivity
        let thresholdOn = 3.0 + (1.0 - sensitivity) * 1.5  // 3.0 to 4.5
        let minAmplitude = 0.03 + sensitivity * 0.22  // 0.03g to 0.25g

        let staLtaTriggered = ratioFast > thresholdOn || ratioMed > thresholdOn * 0.85
        if staLtaTriggered && cusumTriggered && magnitude > minAmplitude {
            let intensity = min(magnitude / 0.8, 1.0)  // 0.8g reference for practical slap range
            handleSlap(intensity: max(0.3, intensity))
            // Reset CUSUM after detection
            cusumPos = 0
            cusumNeg = 0
        }
    }

    /// 2nd-order Butterworth high-pass filter (direct form I)
    private func butterworthHPF(input x: Double, state s: inout (x1: Double, x2: Double, y1: Double, y2: Double)) -> Double {
        let y = bw_b0 * x + bw_b1 * s.x1 + bw_b2 * s.x2 - bw_a1 * s.y1 - bw_a2 * s.y2
        s.x2 = s.x1; s.x1 = x
        s.y2 = s.y1; s.y1 = y
        return y
    }

    private func readInt32LE(_ buffer: UnsafeMutablePointer<UInt8>, offset: Int) -> Int32 {
        var value: Int32 = 0
        memcpy(&value, buffer.advanced(by: offset), 4)
        return Int32(littleEndian: value)
    }

    // MARK: - Microphone Fallback

    private func startMicrophone() -> Bool {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mactapa_mic.caf")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        } catch {
            print("[MacTapa] Microphone not available: \(error)")
            return false
        }

        guard let recorder = audioRecorder else { return false }

        recorder.isMeteringEnabled = true
        recorder.record()

        meteringTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.checkMicLevel()
        }

        print("[MacTapa] Microphone detection active")
        detectionMode = "Microfone"
        setupKeyboardFallback()
        return true
    }

    private func checkMicLevel() {
        guard let recorder = audioRecorder, isActive else { return }

        recorder.updateMeters()
        let peak = recorder.peakPower(forChannel: 0)
        let avg = recorder.averagePower(forChannel: 0)

        // Slow-moving ambient level
        ambientLevel = ambientLevel * 0.995 + avg * 0.005

        // Need to be significantly above ambient AND above absolute threshold
        let thresholdOffset: Float = 15.0 + Float(sensitivity) * 25.0
        let threshold = ambientLevel + thresholdOffset
        let absoluteMin: Float = -15.0

        if peak > threshold && peak > absoluteMin {
            let overshoot = peak - threshold
            let intensity = Double(min(overshoot / 15.0, 1.0))
            handleSlap(intensity: max(0.3, intensity))
        }
    }

    // MARK: - Keyboard Fallback

    private func setupKeyboardFallback() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.control, .shift]) && event.keyCode == 17 {
                self?.handleSlap(intensity: 0.7)
            }
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.control, .shift]) && event.keyCode == 17 {
                self?.handleSlap(intensity: 0.7)
            }
            return event
        }
    }

    // MARK: - Common

    private func handleSlap(intensity: Double) {
        let now = Date()
        guard now.timeIntervalSince(lastSlapTime) > cooldown else { return }
        lastSlapTime = now

        print(String(format: "[MacTapa] TAPA! intensity=%.2f mode=%@", intensity, detectionMode))

        DispatchQueue.main.async { [weak self] in
            self?.slapCount += 1
        }

        onSlap(intensity)
    }
}

// C-style callback for IOKit HID
private func hidReportCallback(
    context: UnsafeMutableRawPointer?,
    result: IOReturn,
    sender: UnsafeMutableRawPointer?,
    type: IOHIDReportType,
    reportID: UInt32,
    report: UnsafeMutablePointer<UInt8>,
    reportLength: CFIndex
) {
    guard let context = context else { return }
    let detector = Unmanaged<SlapDetector>.fromOpaque(context).takeUnretainedValue()
    detector.processHIDReport(report, length: reportLength)
}
