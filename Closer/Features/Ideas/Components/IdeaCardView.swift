import SwiftUI

/// One idea: emoji, title and description, with links to matching places and a reminder.
struct IdeaCardView: View {
    let idea: Idea
    var isSaved = false
    var onSave: () -> Void = { }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Text(idea.emoji)
                    .font(.system(size: 26))
                    .frame(width: 52, height: 52)
                    .background(Circle().fill(Color.closerAccentSoft))

                VStack(alignment: .leading, spacing: 4) {
                    Text(idea.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(idea.detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 8) {
                NavigationLink(value: idea) {
                    chip("Orte in der Nähe", systemImage: "map.fill")
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("ideaPlacesButton")

                Button(action: onSave) {
                    chip(isSaved ? "Erinnerung erstellt" : "Erinnern", systemImage: isSaved ? "checkmark" : "bell.badge")
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .disabled(isSaved)
                .accessibilityHint(isSaved ? "" : "Erinnert dich in einer Woche an diese Idee")
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.closerSurface)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func chip(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.footnote.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color.closerAccentSoft))
            .foregroundStyle(Color.closerOnAccentSoft)
    }
}

#Preview {
    NavigationStack {
        IdeaCardView(idea: Idea(
            emoji: "🍝",
            title: "Pasta-Abend wie in Rom",
            detail: "Kocht zusammen frische Pasta und deckt den Tisch mit Kerzen. Danach gibt es Tiramisu.",
            placeSearch: "Italienisches Feinkostgeschäft"
        ))
        .padding()
        .background(Color.closerBackground)
    }
}
