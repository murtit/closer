import SwiftUI

/// Three tiles to choose what the ideas are for: date (or get-together), gift, activity.
struct IdeaCategoryPicker: View {
    @Binding var selection: IdeaCategory
    let relationship: Relationship

    var body: some View {
        HStack(spacing: 10) {
            ForEach(IdeaCategory.allCases) { category in
                tile(for: category)
            }
        }
    }

    private func tile(for category: IdeaCategory) -> some View {
        let isSelected = category == selection
        return Button {
            withAnimation(.snappy) { selection = category }
        } label: {
            VStack(spacing: 6) {
                Text(category.emoji)
                    .font(.system(size: 28))
                    .scaleEffect(isSelected ? 1.1 : 1)
                Text(category.title(for: relationship))
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(isSelected ? Color.closerOnAccent : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? Color.closerAccent : Color.closerSurface)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("ideaCategory.\(category.rawValue)")
    }
}

#Preview {
    @Previewable @State var selection = IdeaCategory.date
    IdeaCategoryPicker(selection: $selection, relationship: .partner)
        .padding()
        .background(Color.closerBackground)
}
