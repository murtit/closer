import SwiftUI

/// App settings, opened from the home screen.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppearancePreference.storageKey) private var appearance: AppearancePreference = .system

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Erscheinungsbild", selection: $appearance) {
                        ForEach(AppearancePreference.allCases) { preference in
                            Label(preference.title, systemImage: preference.systemImage)
                                .tag(preference)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Erscheinungsbild")
                } footer: {
                    Text("„Automatisch“ folgt der iPhone-Einstellung unter Anzeige & Helligkeit.")
                }
                .listRowBackground(Color.closerSurface)
            }
            .closerListBackground()
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
        .tint(.closerAccent)
    }
}

#Preview {
    SettingsView()
}
