import SwiftUI

/// List of notification sounds with a checkmark on the chosen one. Tapping a sound selects it and
/// plays it, like the sound settings of the iPhone.
struct NotificationSoundPicker: View {
    @Binding var sound: NotificationSound
    @State private var player = SoundPreviewPlayer()

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
        }
        .listStyle(.insetGrouped)
        .closerListBackground()
        .navigationTitle("Benachrichtigungston")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { player.stop() }
    }

    private func row(for choice: NotificationSound) -> some View {
        let isSelected = choice == sound
        return Button {
            sound = choice
            player.play(choice)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: choice == .standard ? "iphone" : "music.note")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.closerOnAccentSoft)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.closerAccentSoft))
                VStack(alignment: .leading, spacing: 2) {
                    Text(choice.title)
                        .foregroundStyle(.primary)
                    Text(choice.subtitle)
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
        .accessibilityIdentifier("sound.\(choice.rawValue)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var sound: NotificationSound = .naehe
    NavigationStack {
        NotificationSoundPicker(sound: $sound)
    }
}
