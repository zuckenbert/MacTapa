import AppKit
import AVFoundation
import Foundation

final class AudioEngine: ObservableObject {
    @Published var currentPack: String = "GemidaoClassic" {
        didSet {
            if oldValue != currentPack {
                loadSounds(pack: currentPack)
                selectedSoundIndex = -1 // Reset to random when switching packs
            }
        }
    }
    @Published var volume: Float = 0.8
    @Published var availablePacks: [String] = []

    // -1 = random, 0+ = index into soundList
    @Published var selectedSoundIndex: Int = -1

    // Exposed for UI: list of sounds in current pack
    @Published var soundNames: [String] = []
    private var soundURLs: [URL] = []

    private var sounds: [String: [URL]] = [:]
    private var players: [AVAudioPlayer] = []

    init() {
        loadAvailablePacks()
        loadSounds(pack: currentPack)
    }

    func playSound(intensity: Double) {
        let url: URL

        if selectedSoundIndex >= 0 && selectedSoundIndex < soundURLs.count {
            url = soundURLs[selectedSoundIndex]
        } else {
            guard !soundURLs.isEmpty else {
                print("[MacTapa] No sounds loaded for pack: \(currentPack)")
                NSSound.beep()
                return
            }
            url = soundURLs.randomElement()!
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume * Float(0.3 + intensity * 0.7)
            player.prepareToPlay()
            player.play()

            players.append(player)
            players.removeAll { !$0.isPlaying }
        } catch {
            print("[MacTapa] Error playing sound: \(error)")
        }
    }

    // MARK: - Sound Loading

    private func loadAvailablePacks() {
        if let resourcePath = Bundle.main.resourcePath {
            let soundsPath = (resourcePath as NSString).appendingPathComponent("Sounds")
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: soundsPath) {
                availablePacks = contents.filter { name in
                    var isDir: ObjCBool = false
                    let fullPath = (soundsPath as NSString).appendingPathComponent(name)
                    FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
                    return isDir.boolValue
                }.sorted()
            }
        }

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
            print("[MacTapa] No sound packs found.")
        }
    }

    private func loadSounds(pack: String) {
        var urls: [URL] = []

        if let resourcePath = Bundle.main.resourcePath {
            let packPath = (resourcePath as NSString)
                .appendingPathComponent("Sounds")
                .appending("/\(pack)")
            urls.append(contentsOf: audioFiles(in: packPath))
        }

        let userPackPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".mactapa/sounds/\(pack)")
        urls.append(contentsOf: audioFiles(in: userPackPath.path))

        urls.sort { $0.lastPathComponent < $1.lastPathComponent }
        sounds[pack] = urls
        soundURLs = urls

        // Build readable names for UI
        soundNames = urls.map { url in
            url.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }

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
