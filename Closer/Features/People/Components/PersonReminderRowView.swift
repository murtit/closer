import SwiftUI

/// A reminder of a person with its schedule and an on/off switch.
struct PersonReminderRowView: View {
    let reminder: Reminder
    @Binding var isEnabled: Bool

    private var subtitle: String {
        guard reminder.isEnabled else { return "Pausiert" }
        guard reminder.nextOccurrence() != nil else { return "Erledigt" }
        return reminder.schedule.summary()
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(reminder.emoji)
                .font(.system(size: 22))
                .frame(width: 42, height: 42)
                .background(Circle().fill(reminder.isEnabled ? Color.closerAccentSoft : Color(.systemFill)))

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.title)
                    .foregroundStyle(reminder.isEnabled ? Color.primary : Color.secondary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(reminder.isEnabled ? Color.closerAccent : Color.secondary)
            }

            Spacer()

            Toggle(reminder.title, isOn: $isEnabled)
                .labelsHidden()
                .tint(.closerAccent)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    @Previewable @State var isEnabled = true
    List {
        PersonReminderRowView(
            reminder: Reminder(title: "Anrufen und fragen, wie es geht", emoji: "📞", isEnabled: isEnabled),
            isEnabled: $isEnabled
        )
    }
}
