import SwiftUI

/// The partner on the home screen: a warm card with how long you are together and the countdown
/// to the next anniversary. Tapping it opens the partner.
struct PartnerCardView: View {
    @Environment(\.openURL) private var openURL
    let person: Person
    var now: Date = Date()
    let onAddAnniversary: () -> Void

    private var anniversary: Anniversary? { person.partnerAnniversary }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            NavigationLink(value: person.id) {
                header
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("partnerCard")

            HStack(spacing: 10) {
                if let anniversary {
                    countdown(for: anniversary)
                } else {
                    addAnniversaryButton
                }
                Spacer(minLength: 0)
                if let messageURL = person.messageURL {
                    Button {
                        openURL(messageURL)
                    } label: {
                        Image(systemName: "heart.text.square.fill")
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.closerOnPartner.opacity(0.1)))
                            .foregroundStyle(.closerPartnerAccent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(person.name) eine liebe Nachricht schreiben")
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Parts

    private var header: some View {
        HStack(spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                PersonAvatarView(person: person, size: 64)
                    // The avatar is coral like the card by day; the ring sets it apart.
                    .padding(3)
                    .background(Circle().fill(Color.closerBackground))
                Image(systemName: "heart.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.closerPartner)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.closerPartnerAccent))
                    .offset(x: 4, y: 4)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Dein Herzensmensch")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.closerPartnerAccent)
                    .textCase(.uppercase)
                    .kerning(0.6)
                Text(person.name)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(.closerOnPartner)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let anniversary {
                    Text(anniversary.togetherText(on: now))
                        .font(.subheadline)
                        .foregroundStyle(.closerOnPartner.opacity(0.85))
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.closerOnPartner.opacity(0.5))
        }
        .contentShape(Rectangle())
    }

    private func countdown(for anniversary: Anniversary) -> some View {
        let isToday = anniversary.isToday(now)
        return HStack(spacing: 8) {
            Text(isToday ? "🎉" : "💞")
            Text(anniversary.countdownText(from: now) ?? "")
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.closerOnPartner)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.closerOnPartner.opacity(0.1)))
    }

    private var addAnniversaryButton: some View {
        Button(action: onAddAnniversary) {
            Label("Jahrestag hinzufügen", systemImage: "calendar.badge.plus")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.closerOnPartner))
                .foregroundStyle(.closerPartner)
        }
        .buttonStyle(.plain)
    }

    private var background: some View {
        LinearGradient(
            colors: [.closerPartner, .closerPartnerEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "heart.fill")
                .font(.system(size: 120))
                .foregroundStyle(.closerOnPartner.opacity(0.05))
                .rotationEffect(.degrees(12))
                .offset(x: 30, y: -24)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    NavigationStack {
        PartnerCardView(
            person: Person(
                name: "Lea Brunner",
                relationship: .partner,
                phoneNumber: "+41 79 123 45 67",
                anniversary: Anniversary(date: Calendar.current.date(byAdding: .day, value: -1072, to: Date())!)
            ),
            onAddAnniversary: { }
        )
        .padding()
    }
}
