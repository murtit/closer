import SwiftUI

/// Chips for the built-in relationships plus "Andere" with a free-text label.
struct RelationshipPicker: View {
    @Binding var relationship: Relationship
    /// `false` when someone else already is the partner; the chip is then disabled.
    let isPartnerAvailable: Bool
    @State private var otherLabel: String

    init(relationship: Binding<Relationship>, isPartnerAvailable: Bool = true) {
        _relationship = relationship
        self.isPartnerAvailable = isPartnerAvailable
        if case .other(let label) = relationship.wrappedValue {
            _otherLabel = State(initialValue: label)
        } else {
            _otherLabel = State(initialValue: "")
        }
    }

    private var choices: [Relationship] { Relationship.builtIn + [.other(otherLabel)] }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(choices, id: \.sortIndex) { choice in
                    chip(for: choice)
                }
            }

            if !isPartnerAvailable && relationship != .partner {
                Text("Du hast bereits eine:n Partner:in erfasst.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if relationship.isOther {
                TextField("z. B. Arbeitskollege, Nachbarin", text: $otherLabel)
                    .textInputAutocapitalization(.words)
                    .onChange(of: otherLabel) { _, newValue in
                        relationship = .other(newValue)
                    }
            }
        }
        .padding(.vertical, 4)
    }

    private func chip(for choice: Relationship) -> some View {
        let isSelected = choice.sortIndex == relationship.sortIndex
        let isDisabled = choice == .partner && !isPartnerAvailable && !isSelected
        return Button {
            withAnimation(.spring(response: 0.3)) {
                relationship = choice
            }
        } label: {
            VStack(spacing: 4) {
                Text(choice.emoji)
                    .font(.title2)
                Text(choice.isOther ? "Andere" : choice.title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.closerAccentSoft : Color(.tertiarySystemFill))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.closerAccent : .clear, lineWidth: 1.5)
            )
            .foregroundStyle(isSelected ? Color.closerOnAccentSoft : Color.primary)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var relationship: Relationship = .family
    Form {
        RelationshipPicker(relationship: $relationship)
    }
}
