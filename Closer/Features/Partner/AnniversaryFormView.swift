import SwiftUI

/// Enter or change the partner's anniversary and when Closer reminds of it.
struct AnniversaryFormView: View {
    @Environment(PeopleViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let personID: Person.ID
    private let original: Anniversary?

    @State private var anniversary: Anniversary
    @State private var confirmingRemove = false

    /// `anniversary == nil` adds one, with reminders on the day and 2 weeks and 3 days before.
    init(personID: Person.ID, anniversary: Anniversary? = nil) {
        self.personID = personID
        self.original = anniversary
        _anniversary = State(initialValue: anniversary ?? Anniversary(date: Date()))
    }

    private var partnerName: String {
        viewModel.person(withID: personID)?.name ?? "deine:n Partner:in"
    }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    dateSection
                    remindersSection
                    if anniversary.isEnabled {
                        headsUpSection
                    }
                    if original != nil {
                        removeSection
                    }
                }
                .listRowBackground(Color.closerSurface)
            }
            .closerListBackground()
            .navigationTitle("Jahrestag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(original == nil ? "Hinzufügen" : "Sichern", action: save)
                        .fontWeight(.semibold)
                }
            }
            .tint(.closerAccent)
            .confirmationDialog("Jahrestag entfernen?", isPresented: $confirmingRemove, titleVisibility: .visible) {
                Button("Entfernen", role: .destructive, action: remove)
            }
        }
    }

    // MARK: - Sections

    private var dateSection: some View {
        Section {
            DatePicker("Zusammen seit", selection: $anniversary.date, in: ...Date(), displayedComponents: .date)
        } header: {
            Text("Euer Tag")
        } footer: {
            VStack(alignment: .leading, spacing: 2) {
                Text(anniversary.togetherText())
                if let countdown = anniversary.countdownText() {
                    Text(countdown)
                }
            }
        }
    }

    private var remindersSection: some View {
        Section {
            Toggle("Am Jahrestag erinnern", isOn: $anniversary.isEnabled)
            if anniversary.isEnabled {
                DatePicker("Uhrzeit", selection: timeBinding, displayedComponents: .hourAndMinute)
            }
        } header: {
            Text("Erinnerung")
        } footer: {
            Text(anniversary.isEnabled
                 ? "Jedes Jahr am Jahrestag eine Nachricht, damit ihr ihn gemeinsam feiern könnt."
                 : "Closer erinnert dich nicht an euren Jahrestag.")
        }
    }

    private var headsUpSection: some View {
        Section {
            ForEach(Anniversary.headsUpChoices, id: \.self) { days in
                Toggle(isOn: headsUpBinding(days)) {
                    HStack(spacing: 12) {
                        Text(Anniversary.headsUpEmoji(daysBefore: days))
                        Text(Anniversary.headsUpLabel(daysBefore: days))
                    }
                }
            }
        } header: {
            Text("Schon vorher erinnern")
        } footer: {
            Text("Genug Zeit, um für \(partnerName) ein Date zu planen oder ein Geschenk zu besorgen.")
        }
    }

    private var removeSection: some View {
        Section {
            Button("Jahrestag entfernen", role: .destructive) {
                confirmingRemove = true
            }
        }
    }

    // MARK: - Helpers

    private func headsUpBinding(_ days: Int) -> Binding<Bool> {
        Binding(
            get: { anniversary.headsUpDays.contains(days) },
            set: { anniversary.setHeadsUp(days, enabled: $0) }
        )
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: anniversary.hour, minute: anniversary.minute, second: 0, of: Date()) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                anniversary.hour = components.hour ?? anniversary.hour
                anniversary.minute = components.minute ?? anniversary.minute
            }
        )
    }

    private func save() {
        viewModel.setAnniversary(anniversary, for: personID)
        dismiss()
    }

    private func remove() {
        viewModel.setAnniversary(nil, for: personID)
        dismiss()
    }
}

#Preview {
    AnniversaryFormView(personID: UUID())
        .environment(PeopleViewModel())
}
