import SwiftUI

/// App settings, opened from the home screen.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(IdeaServices.self) private var ideaServices
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

                appleIntelligenceSection
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
        // Checks again while the model downloads, so the status changes by itself.
        .task { await ideaServices.waitWhileModelLoads() }
    }

    /// Whether this iPhone supports Apple Intelligence, whether it is on and whether the model is loaded.
    private var appleIntelligenceSection: some View {
        let availability = ideaServices.availability
        return Section {
            LabeledContent("Status") {
                Text(availability.statusTitle)
                    .foregroundStyle(availability == .available ? Color.green : .secondary)
            }
            .accessibilityIdentifier("appleIntelligenceStatus")
            AppleIntelligenceChecklist(availability: availability)
                .padding(.vertical, 4)
            if availability.offersSettings {
                AppleIntelligenceSettingsButton()
                    .padding(.vertical, 4)
            }
        } header: {
            Text("Apple Intelligence")
        } footer: {
            Text(availability.statusMessage)
        }
        .listRowBackground(Color.closerSurface)
    }
}

#Preview {
    SettingsView()
        .environment(DemoData.makeIdeaServices())
}
