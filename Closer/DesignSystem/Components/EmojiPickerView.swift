import SwiftUI

struct EmojiPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedEmoji: String

    private let emojis: [String] = [
        "💝", "💖", "💗", "💓", "💞", "💕", "❤️", "🧡", "💛", "💚", "💙", "💜",
        "🤍", "💌", "💋", "😍", "🥰", "😘", "🤗", "😊", "🙈",
        "🌸", "🌹", "🌺", "🌻", "🌼", "🌷", "🌿", "🍀",
        "🌙", "☀️", "⭐", "✨", "🌟", "💫", "🌈", "🌅",
        "🎁", "🎀", "🎊", "🎉", "🍫", "🍷", "🫖", "☕",
        "📸", "🎵", "🎶", "🔥", "💎", "🦋", "🐝",
        "💐", "🫶", "👫", "💏", "💑",
        "📞", "💬", "👋", "🤝", "🍻", "🍕", "🎂", "⚽", "🎮", "🏃",
        "🏡", "🤲", "✉️", "🗓️", "🎬", "🏔️", "🚗", "✈️",
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button {
                            selectedEmoji = emoji
                            dismiss()
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedEmoji == emoji
                                          ? Color.rosePrimary.opacity(0.18)
                                          : Color.clear)
                                Text(emoji)
                                    .font(.system(size: 32))
                                    .padding(8)
                            }
                            .frame(height: 56)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Emoji wählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}
