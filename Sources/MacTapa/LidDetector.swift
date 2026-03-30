import Foundation
import IOKit
import IOKit.pwr_mgt

// IOKit power message constants (C macros not importable in Swift)
private let kIOMessageSystemWillSleepValue:    UInt32 = 0xE0000280
private let kIOMessageCanSystemSleepValue:     UInt32 = 0xE0000270
private let kIOMessageSystemHasPoweredOnValue: UInt32 = 0xE0000300

/// Detects lid open/close events via IOKit power notifications + clamshell state polling.
final class LidDetector: ObservableObject {
    @Published var lidSoundEnabled: Bool = true

    private let onLidOpen: () -> Void
    private let onLidClose: () -> Void

    // IOKit power management
    private var rootPort: io_connect_t = 0
    private var notifyPortRef: IONotificationPortRef?
    private var notifierObject: io_object_t = 0

    // Clamshell polling
    private var pollTimer: Timer?
    private var lastClamshellState: Bool? = nil

    init(onLidOpen: @escaping () -> Void, onLidClose: @escaping () -> Void) {
        self.onLidOpen = onLidOpen
        self.onLidClose = onLidClose
    }

    // MARK: - Start / Stop

    func start() {
        // Register for IOKit power notifications (sleep/wake)
        let context = Unmanaged.passUnretained(self).toOpaque()

        rootPort = IORegisterForSystemPower(
            context,
            &notifyPortRef,
            powerCallback,
            &notifierObject
        )

        if rootPort != 0, let notifyPort = notifyPortRef {
            CFRunLoopAddSource(
                CFRunLoopGetMain(),
                IONotificationPortGetRunLoopSource(notifyPort).takeUnretainedValue(),
                .commonModes
            )
            print("[MacTapa] LidDetector: IOKit power notifications registered")
        } else {
            print("[MacTapa] LidDetector: IOKit registration failed, using polling only")
        }

        // Also poll clamshell state for reliability
        lastClamshellState = isClamshellClosed()
        print("[MacTapa] LidDetector: Initial clamshell state: \(lastClamshellState == true ? "closed" : "open")")

        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClamshellChange()
        }

        print("[MacTapa] LidDetector: Listening for lid events (IOKit + polling)")
    }

    func stop() {
        pollTimer?.invalidate()
        pollTimer = nil

        if let notifyPort = notifyPortRef {
            CFRunLoopRemoveSource(
                CFRunLoopGetMain(),
                IONotificationPortGetRunLoopSource(notifyPort).takeUnretainedValue(),
                .commonModes
            )
            IODeregisterForSystemPower(&notifierObject)
            IOServiceClose(rootPort)
            IONotificationPortDestroy(notifyPort)
            notifyPortRef = nil
        }
        print("[MacTapa] LidDetector: Stopped")
    }

    // MARK: - Clamshell Polling

    private func checkClamshellChange() {
        let currentState = isClamshellClosed()
        guard let last = lastClamshellState, currentState != last else {
            if lastClamshellState == nil {
                lastClamshellState = currentState
            }
            return
        }

        lastClamshellState = currentState

        guard lidSoundEnabled else { return }

        if currentState {
            print("[MacTapa] LidDetector: Clamshell closed (poll) — playing door close")
            onLidClose()
        } else {
            print("[MacTapa] LidDetector: Clamshell opened (poll) — playing door open")
            onLidOpen()
        }
    }

    // MARK: - Clamshell State

    func isClamshellClosed() -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceNameMatching("IOPMrootDomain"))
        guard service != 0 else {
            return false
        }
        defer { IOObjectRelease(service) }

        guard let prop = IORegistryEntryCreateCFProperty(
            service,
            "AppleClamshellState" as CFString,
            kCFAllocatorDefault,
            0
        ) else {
            // Property not present — desktop Mac or no lid sensor
            return false
        }

        let value = prop.takeRetainedValue() as? Bool ?? false
        return value
    }

    // MARK: - Power Event Handling (backup)

    fileprivate func handlePowerEvent(messageType: UInt32, messageArgument: UnsafeMutableRawPointer?) {
        switch messageType {
        case kIOMessageSystemWillSleepValue:
            print("[MacTapa] LidDetector: System will sleep")
            // Polling already handles lid close sound, just acknowledge sleep
            if lidSoundEnabled && isClamshellClosed() {
                DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    guard let self = self else { return }
                    IOAllowPowerChange(self.rootPort, Int(bitPattern: messageArgument))
                }
            } else {
                IOAllowPowerChange(rootPort, Int(bitPattern: messageArgument))
            }

        case kIOMessageCanSystemSleepValue:
            IOAllowPowerChange(rootPort, Int(bitPattern: messageArgument))

        case kIOMessageSystemHasPoweredOnValue:
            print("[MacTapa] LidDetector: System powered on")
            // Polling handles lid open sound too

        default:
            break
        }
    }
}

// C-style callback for IOKit power notifications
private func powerCallback(
    refCon: UnsafeMutableRawPointer?,
    service: io_service_t,
    messageType: UInt32,
    messageArgument: UnsafeMutableRawPointer?
) {
    guard let refCon = refCon else { return }
    let detector = Unmanaged<LidDetector>.fromOpaque(refCon).takeUnretainedValue()
    detector.handlePowerEvent(messageType: messageType, messageArgument: messageArgument)
}
