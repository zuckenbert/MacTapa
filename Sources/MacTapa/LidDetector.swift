import Foundation
import IOKit
import IOKit.pwr_mgt

// IOKit power message constants (C macros not importable in Swift)
// iokit_common_msg(x) = (sys_iokit | sub_iokit_common | x) where sys_iokit = 0xE0000000
private let kIOMessageSystemWillSleepValue:    UInt32 = 0xE0000280
private let kIOMessageCanSystemSleepValue:     UInt32 = 0xE0000270
private let kIOMessageSystemHasPoweredOnValue: UInt32 = 0xE0000300

/// Detects lid open/close events via IOKit power notifications and plays door sounds.
final class LidDetector: ObservableObject {
    @Published var lidSoundEnabled: Bool = true

    private let onLidOpen: () -> Void
    private let onLidClose: () -> Void

    // IOKit power management
    private var rootPort: io_connect_t = 0
    private var notifyPortRef: IONotificationPortRef?
    private var notifierObject: io_object_t = 0

    init(onLidOpen: @escaping () -> Void, onLidClose: @escaping () -> Void) {
        self.onLidOpen = onLidOpen
        self.onLidClose = onLidClose
    }

    // MARK: - Start / Stop

    func start() {
        let context = Unmanaged.passUnretained(self).toOpaque()

        rootPort = IORegisterForSystemPower(
            context,
            &notifyPortRef,
            powerCallback,
            &notifierObject
        )

        guard rootPort != 0 else {
            print("[MacTapa] LidDetector: Failed to register for system power notifications")
            return
        }

        guard let notifyPort = notifyPortRef else {
            print("[MacTapa] LidDetector: notifyPortRef is nil")
            return
        }

        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            IONotificationPortGetRunLoopSource(notifyPort).takeUnretainedValue(),
            .commonModes
        )

        print("[MacTapa] LidDetector: Listening for lid open/close events")
    }

    func stop() {
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

    // MARK: - Clamshell State

    func isClamshellClosed() -> Bool {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceNameMatching("IOPMrootDomain"))
        guard service != 0 else {
            print("[MacTapa] LidDetector: Could not find IOPMrootDomain")
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

    // MARK: - Power Event Handling

    fileprivate func handlePowerEvent(messageType: UInt32, messageArgument: UnsafeMutableRawPointer?) {
        switch messageType {
        case kIOMessageSystemWillSleepValue:
            print("[MacTapa] LidDetector: System will sleep")
            if lidSoundEnabled && isClamshellClosed() {
                print("[MacTapa] LidDetector: Lid closed — playing door close sound")
                onLidClose()
                // Delay acknowledgement to allow sound playback (~2s)
                DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    guard let self = self else { return }
                    IOAllowPowerChange(self.rootPort, Int(bitPattern: messageArgument))
                    print("[MacTapa] LidDetector: Acknowledged sleep (after sound delay)")
                }
            } else {
                IOAllowPowerChange(rootPort, Int(bitPattern: messageArgument))
                print("[MacTapa] LidDetector: Acknowledged sleep (immediate)")
            }

        case kIOMessageCanSystemSleepValue:
            // Always allow idle sleep immediately
            IOAllowPowerChange(rootPort, Int(bitPattern: messageArgument))

        case kIOMessageSystemHasPoweredOnValue:
            print("[MacTapa] LidDetector: System has powered on")
            if lidSoundEnabled {
                // Small delay for audio subsystem to be ready
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    guard let self = self, self.lidSoundEnabled else { return }
                    print("[MacTapa] LidDetector: Playing door open sound")
                    self.onLidOpen()
                }
            }

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
