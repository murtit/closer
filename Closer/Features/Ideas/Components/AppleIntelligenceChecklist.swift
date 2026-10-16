import SwiftUI

/// The Apple Intelligence checks as rows with a mark each: supported, turned on, model loaded.
struct AppleIntelligenceChecklist: View {
    let availability: IdeaAvailability

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(availability.checks) { check in
                HStack(spacing: 10) {
                    mark(for: check.state)
                        .frame(width: 22)
                    Text(check.title)
                        .foregroundStyle(check.state == .skipped ? .secondary : .primary)
                    Spacer(minLength: 0)
                }
                .font(.subheadline)
                .accessibilityElement(children: .combine)
                .accessibilityValue(accessibilityValue(for: check.state))
            }
        }
    }

    @ViewBuilder
    private func mark(for state: AppleIntelligenceCheck.State) -> some View {
        switch state {
        case .passed:
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed:
            Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        case .inProgress:
            ProgressView().controlSize(.small)
        case .skipped:
            Image(systemName: "minus.circle").foregroundStyle(.secondary)
        }
    }

    private func accessibilityValue(for state: AppleIntelligenceCheck.State) -> String {
        switch state {
        case .passed: "Ja"
        case .failed: "Nein"
        case .inProgress: "Läuft"
        case .skipped: "Nicht geprüft"
        }
    }
}

/// Opens the Settings app. iOS has no public link straight to „Apple Intelligence & Siri“, so this
/// opens Closer's own page there; the footnote says how to get from there to the right page.
struct AppleIntelligenceSettingsButton: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Button("Einstellungen öffnen") { openURL(url) }
                    .font(.subheadline.weight(.semibold))
                    .accessibilityIdentifier("appleIntelligenceSettingsButton")
            }
            Text("Öffnet die Einstellungen bei Closer. Tippe oben links auf „Zurück“, bis du in der Übersicht bist, und wähle dort „Apple Intelligence & Siri“.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 32) {
        ForEach([IdeaAvailability.available, .notEnabled, .notReady, .unsupported], id: \.self) { availability in
            AppleIntelligenceChecklist(availability: availability)
        }
    }
    .padding()
}
