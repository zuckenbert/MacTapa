import AppKit
import AVFoundation
import Foundation

final class AudioEngine: ObservableObject {
    @Published var currentPack: String = "GemidaoClassic"
    @Published var volume: Float = 0.8
    @Published var availablePacks: [String] = []

    private var sounds: [String: [URL]] = [:]
    private var players: [AVAudioPlayer] = []

    init() {
        loadAvailablePacks()
        loadSounds(pack: currentPack)
    }

    func playSound(intensity: Double) {
        guard let packSounds = sounds[currentPack], !packSounds.isEmpty else {
            print("[MacTapa] No sounds loaded for pack: \(currentPack)")
            // Play system sound as fallback
            NSSound.beep()
            return
        }

        let url = packSounds.randomElement()!
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            // Volume scales with impact intensity (min 0.3, max 1.0)
            player.volume = volume * Float(0.3 + intensity * 0.7)
            player.prepareToPlay()
            player.play()

            // Keep reference so it doesn't get deallocated mid-play
            players.append(player)

            // Cleanup finished players
            players.removeAll { !$0.isPlaying }
        } catch {
            print("[MacTapa] Error playing sound: \(error)")
        }
    }

    func switchPack(_ name: String) {
        currentPack = name
        loadSounds(pack: name)
    }

    // MARK: - Sound Loading

    private func loadAvailablePacks() {
        // Check bundled resources
        if let resourcePath = Bundle.main.resourcePath {
            let soundsPath = (resourcePath as NSString).appendingPathComponent("Sounds")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: soundsPath) {
                availablePacks = contents.filter { name in
                    var isDir: ObjCBool = false
                    let fullPath = (soundsPath as NSString).appendingPathComponent(name)
                    FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
                    return isDir.boolValue
                }
            }
        }

        // Also check user sounds directory
        let userSoundsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".mactapa/sounds")
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: userSoundsDir.path) {
            let userPacks = contents.filter { name in
                var isDir: ObjCBool = false
                let fullPath = userSoundsDir.appendingPathComponent(name).path
                FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
                return isDir.boolValue
            }
            availablePacks.append(contentsOf: userPacks)
        }

        if availablePacks.isEmpty {
            print("[MacTapa] No sound packs found. Add .mp3 files to Resources/Sounds/<PackName>/")
        }
    }

    private func loadSounds(pack: String) {
        var urls: [URL] = []

        // Try bundled resources first
        if let resourcePath = Bundle.main.resourcePath {
            let packPath = (resourcePath as NSString)
                .appendingPathComponent("Sounds")
                .appending("/\(pack)")
            urls.append(contentsOf: audioFiles(in: packPath))
        }

        // Then user directory
        let userPackPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".mactapa/sounds/\(pack)")
        urls.append(contentsOf: audioFiles(in: userPackPath.path))

        sounds[pack] = urls
        print("[MacTapa] Loaded \(urls.count) sounds for pack '\(pack)'")
    }

    private func audioFiles(in directory: String) -> [URL] {
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
            return []
        }
        return files
            .filter { $0.hasSuffix(".mp3") || $0.hasSuffix(".wav") || $0.hasSuffix(".m4a") }
            .map { URL(fileURLWithPath: (directory as NSString).appendingPathComponent($0)) }
    }
}
