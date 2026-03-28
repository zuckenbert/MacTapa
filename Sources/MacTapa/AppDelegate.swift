import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var slapDetector: SlapDetector!
    private var audioEngine: AudioEngine!
    private var lidDetector: LidDetector!
    private var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon — menu bar only
        NSApp.setActivationPolicy(.accessory)

        audioEngine = AudioEngine()
        slapDetector = SlapDetector { [weak self] intensity in
            DispatchQueue.main.async {
                self?.audioEngine.playSound(intensity: intensity)
            }
        }

        lidDetector = LidDetector(
            onLidOpen: { [weak self] in
                DispatchQueue.main.async {
                    self?.audioEngine.playDoorSound(type: .open)
                }
            },
            onLidClose: { [weak self] in
                DispatchQueue.main.async {
                    self?.audioEngine.playDoorSound(type: .close)
                }
            }
        )

        setupMenuBar()
        slapDetector.start()
        lidDetector.start()
        print("[MacTapa] App running. Look for the hand icon in the menu bar.")
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "hand.raised.fill", accessibilityDescription: "MacTapa")
            button.action = #selector(togglePopover)
            button.target = self
        }

        popover = NSPopover()
        popover.behavior = .transient

        let hostingController = NSHostingController(
            rootView: MenuBarView(
                audioEngine: audioEngine,
                slapDetector: slapDetector,
                lidDetector: lidDetector
            )
        )
        // Let SwiftUI calculate the ideal size
        hostingController.view.setFrameSize(hostingController.sizeThatFits(in: NSSize(width: 280, height: 600)))
        popover.contentViewController = hostingController
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

