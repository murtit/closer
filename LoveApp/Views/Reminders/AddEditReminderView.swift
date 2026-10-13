import SwiftUI

enum ReminderFormMode {
    case add
    case edit(Reminder)
}

struct AddEditReminderView: View {
    @Environment(RemindersViewModel.self) var viewModel
    @Environment(\.dismiss) private var dismiss

    let mode: ReminderFormMode

    @State private var title: String
    @State private var emoji: String
    @State private var isEnabled: Bool
    @State private var time: Date
    @State private var showingEmojiPicker = false

    // MARK: - Init

    init(mode: ReminderFormMode) {
        self.mode = mode
        switch mode {
        case .add:
            _title      = State(initialValue: "")
            _emoji      = State(initialValue: "💝")
            _isEnabled  = State(initialValue: false)
            _time       = State(initialValue: Calendar.current
                .date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
        case .edit(let reminder):
            _title      = State(initialValue: reminder.title)
            _emoji      = State(initialValue: reminder.emoji)
            _isEnabled  = State(initialValue: reminder.isEnabled)
            _time       = State(initialValue: reminder.time)
        }
    }

    // MARK: - Helpers

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                gestureSection
                notificationSection
            }
            .navigationTitle(isEditing ? "Geste bearbeiten" : "Neue Geste")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .tint(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Sichern" : "Hinzufügen", action: save)
                        .fontWeight(.semibold)
                        .tint(.rosePrimary)
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $emoji)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: - Form Sections

    private var gestureSection: some View {
        Section {
            HStack(spacing: 16) {
                Button {
                    showingEmojiPicker = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.roseBlush)
                            .frame(width: 58, height: 58)
                        Text(emoji)
                            .font(.system(size: 30))
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "pencil.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .rosePrimary)
                            .font(.system(size: 18))
                            .offset(x: 2, y: 2)
                    }
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 4) {
                    TextField("Was möchtest du tun?", text: $title, axis: .vertical)
                        .font(.body)
                        .lineLimit(1...3)
                    Text("Tippe auf das Emoji, um es zu ändern")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 6)
        } header: {
            Text("Deine Geste")
        }
    }

    private var notificationSection: some View {
        Section {
            Toggle("Tägliche Erinnerung", isOn: $isEnabled.animation(.spring(response: 0.3)))
                .tint(.rosePrimary)

            if isEnabled {
                DatePicker("Uhrzeit", selection: $time, displayedComponents: .hourAndMinute)
                    .tint(.rosePrimary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        } header: {
            Text("Benachrichtigung")
        } footer: {
            Group {
                if isEnabled {
                    Text("Du erhältst jeden Tag um \(time, format: .dateTime.hour().minute()) eine Erinnerung.")
                } else {
                    Text("Aktiviere die Erinnerung, damit du täglich daran erinnert wirst.")
                }
            }
        }
    }

    // MARK: - Actions

    private func save() {
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)

        switch mode {
        case .add:
            let reminder = Reminder(
                title: cleanTitle,
                emoji: emoji,
                isEnabled: isEnabled,
                time: time,
                isCustom: true
            )
            viewModel.add(reminder)

        case .edit(let original):
            var updated = original
            updated.title = cleanTitle
            updated.emoji = emoji
            updated.isEnabled = isEnabled
            updated.time = time
            viewModel.update(updated)
        }

        dismiss()
    }
}

#Preview {
    AddEditReminderView(mode: .add)
        .environment(RemindersViewModel())
}
