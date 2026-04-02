import AppKit
import AVFoundation
import Foundation

enum DoorSoundType {
    case open
    case close
}

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

    // AVAudioEngine for low-latency playback (PCM buffers stay decoded in memory)
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let doorPlayerNode = AVAudioPlayerNode()
    private var pcmBuffers: [URL: AVAudioPCMBuffer] = [:]
    private var doorBuffers: [DoorSoundType: AVAudioPCMBuffer] = [:]

    // MARK: - Door Sounds

    func playDoorSound(type: DoorSoundType) {
        guard let buffer = doorBuffers[type] else {
            print("[MacTapa] No door buffer for: \(type)")
            NSSound.beep()
            return
        }

        doorPlayerNode.stop()
        engine.mainMixerNode.outputVolume = volume

        if !engine.isRunning {
            try? engine.start()
        }

        doorPlayerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        doorPlayerNode.play()
    }

    init() {
        // Wire up AVAudioEngine graph: playerNode + doorPlayerNode → mainMixer → output
        engine.attach(playerNode)
        engine.attach(doorPlayerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
        engine.connect(doorPlayerNode, to: engine.mainMixerNode, format: nil)
        do {
            try engine.start()
        } catch {
            print("[MacTapa] AVAudioEngine failed to start: \(error)")
        }

        loadAvailablePacks()
        loadSounds(pack: currentPack)
        loadDoorSounds()
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

        guard let buffer = pcmBuffers[url] else {
            print("[MacTapa] No PCM buffer for: \(url.lastPathComponent)")
            return
        }

        // Cut previous sound instantly, schedule new buffer — zero allocation
        playerNode.stop()
        engine.mainMixerNode.outputVolume = volume * Float(0.3 + intensity * 0.7)

        // Restart engine if it stopped (e.g. audio route change)
        if !engine.isRunning {
            try? engine.start()
        }

        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        playerNode.play()
    }

    // MARK: - Door Sound Loading

    private func loadDoorSounds() {
        for (type, filename) in [(DoorSoundType.open, "door_open"), (.close, "door_close")] {
            if let url = findDoorSound(filename: filename),
               let buffer = loadPCMBuffer(url: url) {
                doorBuffers[type] = buffer
                print("[MacTapa] Door sound loaded: \(filename)")
            } else {
                print("[MacTapa] Door sound not found: \(filename)")
            }
        }
    }

    private func findDoorSound(filename: String) -> URL? {
        let extensions = ["mp3", "m4a", "wav"]

        // Try bundle first
        if let resourcePath = Bundle.main.resourcePath {
            for ext in extensions {
                let path = (resourcePath as NSString)
                    .appendingPathComponent("Sounds")
                    .appending("/DoorSounds/\(filename).\(ext)")
                if FileManager.default.fileExists(atPath: path) {
                    return URL(fileURLWithPath: path)
                }
            }
        }

        // Try user directory
        for ext in extensions {
            let userPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent(".mactapa/sounds/DoorSounds/\(filename).\(ext)")
            if FileManager.default.fileExists(atPath: userPath.path) {
                return userPath
            }
        }

        return nil
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
                    return isDir.boolValue && name != "DoorSounds"
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

        // Pre-decode all sounds to PCM buffers (instant playback, zero I/O on tap)
        pcmBuffers.removeAll()
        for url in urls {
            if let buffer = loadPCMBuffer(url: url) {
                pcmBuffers[url] = buffer
            }
        }

        // Build readable names for UI
        soundNames = urls.map { url in
            url.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }

        print("[MacTapa] Loaded \(urls.count) sounds for pack '\(pack)'")
    }

    /// Decode audio file to PCM buffer for instant playback via AVAudioEngine
    private func loadPCMBuffer(url: URL) -> AVAudioPCMBuffer? {
        guard let file = try? AVAudioFile(forReading: url) else { return nil }
        let format = file.processingFormat
        let frameCount = AVAudioFrameCount(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        do {
            try file.read(into: buffer)
            return buffer
        } catch {
            print("[MacTapa] Failed to decode \(url.lastPathComponent): \(error)")
            return nil
        }
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
