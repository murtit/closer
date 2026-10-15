import SwiftUI
import UniformTypeIdentifiers

/// List of notification sounds with a checkmark on the chosen one. Tapping a sound selects it and
/// plays it, like the sound settings of the iPhone. Own sounds can be added from the Files app.
struct NotificationSoundPicker: View {
    @Environment(PeopleViewModel.self) private var viewModel
    @Binding var sound: NotificationSound
    @State private var player = SoundPreviewPlayer()
    @State private var showingImporter = false
    @State private var isImporting = false
    @State private var importFailed = false

    var body: some View {
        List {
            Section {
                row(for: .standard)
            } footer: {
                Text("Der Ton, den du in den iPhone-Einstellungen unter *Töne & Haptik* gewählt hast.")
            }

            Section {
                ForEach(NotificationSound.bundled) { sound in
                    row(for: sound)
                }
            } header: {
                Text("Closer-Töne")
            } footer: {
                Text("Antippen zum Anhören. Auf stumm geschaltetem iPhone spielt die Benachrichtigung keinen Ton.")
            }

            customSection
        }
        .listStyle(.insetGrouped)
        .closerListBackground()
        .navigationTitle("Benachrichtigungston")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { player.stop() }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.audio], onCompletion: importSound)
        .alert("Ton konnte nicht hinzugefügt werden", isPresented: $importFailed) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Wähle eine Audiodatei, zum Beispiel MP3, M4A, WAV oder AIFF.")
        }
    }

    // MARK: - Custom sounds

    private var customSection: some View {
        Section {
            ForEach(viewModel.customSounds) { custom in
                row(for: custom.sound, title: custom.name, subtitle: Self.durationText(custom.duration))
                    .swipeActions {
                        Button("Löschen", systemImage: "trash", role: .destructive) {
                            delete(custom)
                        }
                    }
            }

            Button {
                showingImporter = true
            } label: {
                HStack {
                    Label("Eigenen Ton hinzufügen", systemImage: "plus.circle.fill")
                    Spacer()
                    if isImporting {
                        ProgressView()
                    }
                }
            }
            .disabled(isImporting)
            .listRowBackground(Color.closerSurface)
            .accessibilityIdentifier("addCustomSound")
        } header: {
            Text("Eigene Töne")
        } footer: {
            Text("Aus der Dateien-App, z. B. eine Sprachnachricht oder ein Lied. Längere Töne werden auf 30 Sekunden gekürzt. Eigene Töne stehen bei allen Personen zur Auswahl.")
        }
    }

    private func importSound(_ result: Result<URL, any Error>) {
        guard case .success(let url) = result else { return }
        isImporting = true
        Task {
            defer { isImporting = false }
            do {
                let custom = try await viewModel.importSound(from: url)
                sound = custom.sound
                player.play(viewModel.soundURL(for: custom.sound))
            } catch {
                importFailed = true
            }
        }
    }

    private func delete(_ custom: CustomSound) {
        if sound == custom.sound {
            player.stop()
            sound = .standard
        }
        viewModel.deleteSound(custom)
    }

    /// "0:04", "0:29"
    static func durationText(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    // MARK: - Row

    private func row(for choice: NotificationSound, title: String? = nil, subtitle: String? = nil) -> some View {
        let isSelected = choice == sound
        return Button {
            sound = choice
            player.play(viewModel.soundURL(for: choice))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon(for: choice))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.closerOnAccentSoft)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.closerAccentSoft))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title ?? choice.title)
                        .foregroundStyle(.primary)
                    Text(subtitle ?? choice.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.closerAccent)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.closerSurface)
        .accessibilityIdentifier("sound.\(choice.id)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func icon(for choice: NotificationSound) -> String {
        switch choice {
        case .standard: "iphone"
        case .custom: "waveform"
        default: "music.note"
        }
    }
}

#Preview {
    @Previewable @State var sound: NotificationSound = .naehe
    NavigationStack {
        NotificationSoundPicker(sound: $sound)
    }
    .environment(PeopleViewModel())
}
