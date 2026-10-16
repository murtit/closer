import SwiftUI

/// Placeholder cards that gently pulse while the on-device model writes the ideas.
struct IdeaLoadingView: View {
    private static let placeholder = Idea(
        emoji: "✨",
        title: "Eine schöne Idee für euch",
        detail: "Hier steht gleich, was ihr zusammen erleben könnt und warum es Freude macht.",
        placeSearch: ""
    )

    var body: some View {
        VStack(spacing: 14) {
            ForEach(0..<3, id: \.self) { index in
                IdeaCardView(idea: Self.placeholder)
                    .redacted(reason: .placeholder)
                    .disabled(true)
                    .phaseAnimator([0.45, 1.0]) { content, opacity in
                        content.opacity(opacity)
                    } animation: { _ in
                        .easeInOut(duration: 0.9).delay(Double(index) * 0.15)
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ideen werden erdacht")
    }
}

#Preview {
    NavigationStack {
        IdeaLoadingView()
            .padding()
            .background(Color.closerBackground)
    }
}
