import SwiftUI

struct HomeView: View {
    @Environment(PeopleViewModel.self) private var viewModel
    @State private var showingAddPerson = false

    // MARK: - Computed helpers

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Guten Morgen"
        case 12..<17: return "Guten Nachmittag"
        case 17..<21: return "Guten Abend"
        default:      return "Gute Nacht"
        }
    }

    private var dateString: String {
        Date().formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    private static let quotes: [(text: String, author: String)] = [
        ("Die kleinen Dinge sind es, die das Leben groß machen.", "Unbekannt"),
        ("Wer liebt, findet immer Zeit.", "Unbekannt"),
        ("Liebe ist keine Leistung – sie ist ein Geschenk.", "Unbekannt"),
        ("Große Liebe zeigt sich in kleinen Gesten.", "Unbekannt"),
        ("Freundschaft ist eine Seele in zwei Körpern.", "Aristoteles"),
        ("Ein Anruf kostet wenig und bedeutet viel.", "Unbekannt"),
        ("Das Schönste, was du tragen kannst, ist ein Lächeln.", "Audrey Hepburn"),
        ("Lieben heißt, das andere Gesicht anzuschauen.", "Marcel Proust"),
        ("Wahre Liebe beginnt, wenn nichts erwartet wird.", "Antoine de Saint-Exupéry"),
    ]

    private var dailyQuote: (text: String, author: String) {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return Self.quotes[day % Self.quotes.count]
    }

    private var upcoming: [PeopleViewModel.Upcoming] {
        viewModel.upcoming(limit: 4)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerView

                    if let next = upcoming.first {
                        featuredCard(for: next)
                    } else {
                        emptyCard
                    }

                    if upcoming.count > 1 {
                        upcomingList
                    }

                    statsRow

                    quoteCard

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddPerson) {
                PersonFormView()
            }
        }
    }

    // MARK: - Sub-views

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greeting)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Wem bist du heute nah?")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(dateString.capitalized)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
        .padding(.top, 16)
    }

    private func featuredCard(for next: PeopleViewModel.Upcoming) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                PersonAvatarView(person: next.person, size: 32)
                    .overlay(Circle().strokeBorder(.white.opacity(0.6), lineWidth: 1))
                Text("Als Nächstes für \(next.person.name)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .textCase(.uppercase)
                    .kerning(0.6)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "bell.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(next.reminder.emoji)
                    .font(.system(size: 54))
                Text(next.reminder.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption)
                Text(next.date, format: .relative(presentation: .named))
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.75))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.rosePrimary, .roseDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .rosePrimary.opacity(0.30), radius: 18, x: 0, y: 8)
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("👋")
                .font(.system(size: 48))
            Text(viewModel.people.isEmpty ? "Wer ist dir wichtig?" : "Keine anstehenden Erinnerungen")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text("Füge eine Person hinzu und lass dich daran erinnern, dich zu melden.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            Button {
                showingAddPerson = true
            } label: {
                Label("Person hinzufügen", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.white))
                    .foregroundStyle(Color.roseDeep)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.rosePrimary, .roseDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var upcomingList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Danach")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(upcoming.dropFirst()) { item in
                    HStack(spacing: 12) {
                        PersonAvatarView(person: item.person, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(item.reminder.emoji) \(item.reminder.title)")
                                .font(.subheadline)
                                .lineLimit(1)
                            Text(item.person.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(item.date, format: .relative(presentation: .named))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    private var statsRow: some View {
        HStack(spacing: 14) {
            StatCard(
                value: "\(viewModel.people.count)",
                label: viewModel.people.count == 1 ? "Person" : "Personen",
                systemImage: "person.2.fill",
                color: .purple
            )
            StatCard(
                value: "\(viewModel.activeReminderCount)",
                label: viewModel.activeReminderCount == 1 ? "Aktive Erinnerung" : "Aktive Erinnerungen",
                systemImage: "bell.fill",
                color: .rosePrimary
            )
        }
    }

    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "text.quote")
                .font(.title3)
                .foregroundStyle(.rosePrimary.opacity(0.5))

            Text(dailyQuote.text)
                .font(.body.italic())
                .foregroundStyle(.primary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(dailyQuote.author)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    HomeView()
        .environment(PeopleViewModel())
}
