import SwiftUI

/// List row for a person: photo, name, relationship and the next reminder.
struct PersonRowView: View {
    let person: Person

    var body: some View {
        HStack(spacing: 14) {
            PersonAvatarView(person: person, size: 48)

            VStack(alignment: .leading, spacing: 3) {
                Text(person.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)

                if let next = person.nextReminder() {
                    Text("\(next.reminder.emoji) \(next.reminder.title) · \(next.date, format: .relative(presentation: .named))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("Keine anstehende Erinnerung")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        PersonRowView(person: Person(
            name: "Opa",
            relationship: .family,
            reminders: [Reminder(title: "Anrufen", emoji: "📞")]
        ))
    }
}
