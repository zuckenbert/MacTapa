import SwiftUI

struct MenuBarView: View {
    @ObservedObject var audioEngine: AudioEngine
    @ObservedObject var slapDetector: SlapDetector

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                Text("MacTapa")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("\(slapDetector.slapCount) tapas")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // On/Off Toggle
            Toggle(isOn: $slapDetector.isActive) {
                HStack {
                    Image(systemName: slapDetector.isActive ? "hand.raised.fill" : "hand.raised.slash")
                    Text(slapDetector.isActive ? "Ativo" : "Desativado")
                }
            }
            .toggleStyle(.switch)

            // Detection mode
            HStack {
                Image(systemName: "waveform")
                Text("Modo: \(slapDetector.detectionMode)")
                    .font(.caption)
            }
            .foregroundColor(.secondary)

            // Pack Selector
            if !audioEngine.availablePacks.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pack")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Pack", selection: $audioEngine.currentPack) {
                        ForEach(audioEngine.availablePacks, id: \.self) { pack in
                            Text(formatPackName(pack)).tag(pack)
                        }
                    }
                    .labelsHidden()
                }
            }

            // Sound Selector (within pack)
            if !audioEngine.soundNames.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Som")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Som", selection: $audioEngine.selectedSoundIndex) {
                        Text("Aleatorio").tag(-1)
                        ForEach(0..<audioEngine.soundNames.count, id: \.self) { i in
                            Text(audioEngine.soundNames[i]).tag(i)
                        }
                    }
                    .labelsHidden()
                }
            }

            // Sensitivity
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Sensibilidade")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", (1.0 - slapDetector.sensitivity) * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: $slapDetector.sensitivity, in: 0.0...1.0, step: 0.05)
            }

            // Volume
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Volume")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(audioEngine.volume * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: $audioEngine.volume, in: 0...1)
            }

            // Test Button
            Button(action: {
                audioEngine.playSound(intensity: 0.7)
                slapDetector.slapCount += 1
            }) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                    Text("Testar Som")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Divider()

            // Footer
            HStack {
                Button("Sair") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Spacer()

                Text("v1.0")
                    .font(.caption2)
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
        .padding()
        .frame(width: 280)
    }

    private func formatPackName(_ name: String) -> String {
        name.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
    }
}
