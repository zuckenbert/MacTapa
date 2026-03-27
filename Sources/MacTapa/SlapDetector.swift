import AppKit
import Foundation
import IOKit
import IOKit.hid

/// Reads the Apple Silicon accelerometer via IOKit HID and detects slap impacts.
/// Requires root privileges (sudo) for IOKit HID device access.
final class SlapDetector: ObservableObject {
    @Published var isActive = true
    @Published var sensitivity: Double = 1.5 // g-force threshold
    @Published var slapCount: Int = 0

    private var device: IOHIDDevice?
    private var reportBuffer = [UInt8](repeating: 0, count: 22)
    private var lastSlapTime: Date = .distantPast
    private let cooldown: TimeInterval = 0.5
    private let onSlap: (Double) -> Void

    // Long-term average for baseline detection
    private var ltaMagnitude: Double = 1.0
    private let ltaAlpha: Double = 0.01

    init(onSlap: @escaping (Double) -> Void) {
        self.onSlap = onSlap
    }

    func start() {
        guard findAndOpenDevice() else {
            print("[MacTapa] Could not open accelerometer. Make sure you're running with sudo on Apple Silicon.")
            print("[MacTapa] Falling back to keyboard shortcut mode (Ctrl+Shift+T)")
            setupKeyboardFallback()
            return
        }
        print("[MacTapa] Accelerometer connected. Listening for slaps...")
    }

    func stop() {
        if let device = device {
            IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
        }
        device = nil
    }

    // MARK: - IOKit HID Device Discovery

    private func findAndOpenDevice() -> Bool {
        let matching: [String: Any] = [
            kIOHIDPrimaryUsagePageKey as String: 0xFF00,
            kIOHIDPrimaryUsageKey as String: 3 // Accelerometer
        ]

        guard let matchingDict = matching as CFDictionary? else { return false }

        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        IOHIDManagerSetDeviceMatching(manager, matchingDict)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))

        guard let deviceSet = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>,
              let foundDevice = deviceSet.first else {
            print("[MacTapa] No AppleSPUHIDDevice found. Is this Apple Silicon?")
            return false
        }

        self.device = foundDevice

        let result = IOHIDDeviceOpen(foundDevice, IOOptionBits(kIOHIDOptionsTypeNone))
        guard result == kIOReturnSuccess else {
            print("[MacTapa] Failed to open device. Run with sudo.")
            return false
        }

        // Register input report callback
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(
            foundDevice,
            &reportBuffer,
            reportBuffer.count,
            inputReportCallback,
            context
        )

        IOHIDDeviceScheduleWithRunLoop(
            foundDevice,
            CFRunLoopGetMain(),
            CFRunLoopMode.defaultMode.rawValue
        )

        return true
    }

    // MARK: - Keyboard Fallback

    private func setupKeyboardFallback() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Ctrl + Shift + T
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

    // MARK: - Data Processing

    fileprivate func processReport(_ report: UnsafeMutablePointer<UInt8>, length: CFIndex) {
        guard length >= 18, isActive else { return }

        // Parse x/y/z as int32 little-endian at byte offsets 6, 10, 14
        let x = readInt32LE(report, offset: 6)
        let y = readInt32LE(report, offset: 10)
        let z = readInt32LE(report, offset: 14)

        // Convert to g-force
        let gx = Double(x) / 65536.0
        let gy = Double(y) / 65536.0
        let gz = Double(z) / 65536.0

        let magnitude = sqrt(gx * gx + gy * gy + gz * gz)

        // Update long-term average
        ltaMagnitude = ltaMagnitude * (1.0 - ltaAlpha) + magnitude * ltaAlpha

        // Detect spike above threshold
        let delta = abs(magnitude - ltaMagnitude)
        if delta > sensitivity {
            // Normalize intensity to 0.0 - 1.0 range
            let intensity = min(delta / (sensitivity * 3.0), 1.0)
            handleSlap(intensity: intensity)
        }
    }

    private func handleSlap(intensity: Double) {
        let now = Date()
        guard now.timeIntervalSince(lastSlapTime) > cooldown else { return }
        lastSlapTime = now

        DispatchQueue.main.async { [weak self] in
            self?.slapCount += 1
        }

        onSlap(intensity)
    }

    private func readInt32LE(_ buffer: UnsafeMutablePointer<UInt8>, offset: Int) -> Int32 {
        var value: Int32 = 0
        memcpy(&value, buffer.advanced(by: offset), 4)
        return Int32(littleEndian: value)
    }
}

// C-style callback for IOKit HID
private func inputReportCallback(
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
    detector.processReport(report, length: reportLength)
}
