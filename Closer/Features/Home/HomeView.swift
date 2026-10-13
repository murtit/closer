import SwiftUI

struct HomeView: View {
    @Environment(RemindersViewModel.self) var viewModel

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
        ("Das Schönste, was du tragen kannst, ist ein Lächeln.", "Audrey Hepburn"),
        ("Lieben heißt, das andere Gesicht anzuschauen.", "Marcel Proust"),
        ("Wahre Liebe beginnt, wenn nichts erwartet wird.", "Antoine de Saint-Exupéry"),
    ]

    private var dailyQuote: (text: String, author: String) {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return Self.quotes[day % Self.quotes.count]
    }

    private var featuredReminder: Reminder? {
        let active = viewModel.reminders.filter { $0.isEnabled }
        return active.randomElement() ?? viewModel.reminders.first
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerView

                    if let reminder = featuredReminder {
                        featuredCard(for: reminder)
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
        }
    }

    // MARK: - Sub-views

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(greeting)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("Wie liebst du heute?")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(dateString.capitalized)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
        .padding(.top, 16)
    }

    private func featuredCard(for reminder: Reminder) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Inspiration für heute")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.75))
                    .textCase(.uppercase)
                    .kerning(0.6)
                Spacer()
                if reminder.isEnabled {
                    Image(systemName: "bell.fill")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(reminder.emoji)
                    .font(.system(size: 54))
                Text(reminder.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if reminder.isEnabled {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("Täglich um \(reminder.time, format: .dateTime.hour().minute())")
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.7))
            }
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

    private var statsRow: some View {
        HStack(spacing: 14) {
            StatCard(
                value: "\(viewModel.activeCount)",
                label: viewModel.activeCount == 1 ? "Aktive Erinnerung" : "Aktive Erinnerungen",
                systemImage: "bell.fill",
                color: .rosePrimary
            )
            StatCard(
                value: "\(viewModel.totalCount)",
                label: viewModel.totalCount == 1 ? "Liebesgeste" : "Liebesgesten",
                systemImage: "heart.fill",
                color: .purple
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
        .environment(RemindersViewModel())
}
