import SwiftUI

/// Create or edit a single reminder of a person.
struct ReminderFormView: View {
    @Environment(PeopleViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let personID: Person.ID
    private let original: Reminder?

    @State private var title: String
    @State private var emoji: String
    @State private var isEnabled: Bool
    @State private var schedule: ReminderSchedule
    @State private var showingEmojiPicker = false

    /// `reminder == nil` creates a new one.
    init(personID: Person.ID, reminder: Reminder? = nil) {
        self.personID = personID
        self.original = reminder
        let base = reminder ?? Reminder(title: "", emoji: "💝", schedule: .once(in: 7))
        _title = State(initialValue: base.title)
        _emoji = State(initialValue: base.emoji)
        _isEnabled = State(initialValue: base.isEnabled)
        _schedule = State(initialValue: base.schedule)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                whatSection
                whenSection
                if original != nil {
                    deleteSection
                }
            }
            .navigationTitle(original == nil ? "Neue Erinnerung" : "Erinnerung")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(original == nil ? "Hinzufügen" : "Sichern", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .tint(.rosePrimary)
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Sections

    private var whatSection: some View {
        Section("Was") {
            HStack(spacing: 14) {
                Button {
                    showingEmojiPicker = true
                } label: {
                    Text(emoji)
                        .font(.system(size: 28))
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(Color.roseBlush))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Emoji ändern")

                TextField("z. B. Anrufen", text: $title, axis: .vertical)
                    .lineLimit(1...3)
            }
            .padding(.vertical, 4)
        }
    }

    private var whenSection: some View {
        Section {
            Toggle("Erinnerung aktiv", isOn: $isEnabled)

            Picker("Wiederholen", selection: $schedule.frequency) {
                ForEach(ReminderSchedule.Frequency.allCases) { frequency in
                    Text(frequency.title).tag(frequency)
                }
            }

            switch schedule.frequency {
            case .once:
                DatePicker("Datum", selection: $schedule.date, in: Date()..., displayedComponents: .date)
            case .daily:
                EmptyView()
            case .weekly:
                Picker("Wochentag", selection: $schedule.weekday) {
                    ForEach(Self.weekdayOrder, id: \.self) { weekday in
                        Text(ReminderSchedule.weekdayName(weekday)).tag(weekday)
                    }
                }
            case .monthly:
                Picker("Tag im Monat", selection: $schedule.dayOfMonth) {
                    ForEach(1...28, id: \.self) { day in
                        Text("\(day).").tag(day)
                    }
                }
            }

            DatePicker("Uhrzeit", selection: timeBinding, displayedComponents: .hourAndMinute)
        } header: {
            Text("Wann")
        } footer: {
            Text(footerText)
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Erinnerung löschen", role: .destructive) {
                if let original {
                    viewModel.deleteReminder(original.id, for: personID)
                }
                dismiss()
            }
        }
    }

    // MARK: - Helpers

    private var footerText: String {
        guard isEnabled else { return "Die Erinnerung ist pausiert." }
        guard schedule.nextOccurrence() != nil else { return "Dieser Zeitpunkt liegt in der Vergangenheit." }
        return schedule.summary()
    }

    /// Monday first, as used in Switzerland.
    private static let weekdayOrder = [2, 3, 4, 5, 6, 7, 1]

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: schedule.hour, minute: schedule.minute, second: 0, of: Date()) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                schedule.hour = components.hour ?? schedule.hour
                schedule.minute = components.minute ?? schedule.minute
            }
        )
    }

    private func save() {
        var reminder = original ?? Reminder(title: "", emoji: emoji)
        reminder.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        reminder.emoji = emoji
        reminder.isEnabled = isEnabled
        reminder.schedule = schedule
        viewModel.save(reminder, for: personID)
        dismiss()
    }
}

#Preview {
    ReminderFormView(personID: UUID())
        .environment(PeopleViewModel())
}
