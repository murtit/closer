import SwiftUI

struct ReminderRowView: View {
    @Environment(RemindersViewModel.self) var viewModel
    let reminder: Reminder

    var body: some View {
        VStack(spacing: 0) {
            mainRow

            if reminder.isEnabled {
                Divider()
                    .padding(.top, 10)
                timePicker
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: reminder.isEnabled)
        .padding(.vertical, 4)
    }

    // MARK: - Sub-views

    private var mainRow: some View {
        HStack(spacing: 14) {
            emojiBubble

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title)
                    .font(.body)
                    .foregroundStyle(reminder.isEnabled ? .primary : Color(.secondaryLabel))

                if reminder.isEnabled {
                    Text("Täglich um \(reminder.time, format: .dateTime.hour().minute())")
                        .font(.caption)
                        .foregroundStyle(.rosePrimary)
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.3), value: reminder.isEnabled)

            Spacer()

            toggle
        }
    }

    private var emojiBubble: some View {
        ZStack {
            Circle()
                .fill(reminder.isEnabled ? Color.roseBlush : Color(.systemFill))
                .frame(width: 46, height: 46)
            Text(reminder.emoji)
                .font(.system(size: 24))
        }
        .animation(.spring(response: 0.3), value: reminder.isEnabled)
    }

    private var toggle: some View {
        Toggle(
            "",
            isOn: Binding(
                get: { reminder.isEnabled },
                set: { _ in viewModel.toggle(reminder) }
            )
        )
        .tint(.rosePrimary)
        .labelsHidden()
    }

    private var timePicker: some View {
        HStack {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundStyle(.rosePrimary.opacity(0.7))
            Text("Uhrzeit")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            DatePicker(
                "",
                selection: Binding(
                    get: { reminder.time },
                    set: { newTime in
                        var updated = reminder
                        updated.time = newTime
                        viewModel.update(updated)
                    }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .tint(.rosePrimary)
        }
        .padding(.top, 10)
        .padding(.bottom, 2)
    }
}
