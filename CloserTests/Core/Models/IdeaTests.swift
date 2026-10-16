import Foundation
import Testing
@testable import Closer

@MainActor
struct IdeaTests {
    // MARK: - Cleaning model output

    @Test func cleanedTrimsWhitespaceAndQuotes() throws {
        let idea = try #require(Idea.cleaned(
            emoji: " 🍝 ",
            title: "  „Pasta-Abend“ \n",
            detail: " Kocht zusammen. ",
            placeSearch: " \"Italienisches Restaurant\" ",
            category: .date
        ))
        #expect(idea.emoji == "🍝")
        #expect(idea.title == "Pasta-Abend")
        #expect(idea.detail == "Kocht zusammen.")
        #expect(idea.placeSearch == "Italienisches Restaurant")
    }

    @Test func cleanedKeepsOnlyTheFirstEmoji() throws {
        let idea = try #require(Idea.cleaned(emoji: "🎁✨ Geschenk", title: "Buch", detail: "", placeSearch: "Buchhandlung", category: .gift))
        #expect(idea.emoji == "🎁")
    }

    @Test func cleanedKeepsEmojiMadeOfSeveralScalars() throws {
        let idea = try #require(Idea.cleaned(emoji: "❤️", title: "Brief", detail: "", placeSearch: "Papeterie", category: .gift))
        #expect(idea.emoji == "❤️")
    }

    @Test func cleanedFallsBackToTheCategory() throws {
        let idea = try #require(Idea.cleaned(emoji: "kein Emoji", title: "Kino", detail: "", placeSearch: "  ", category: .activity))
        #expect(idea.emoji == IdeaCategory.activity.emoji)
        #expect(idea.placeSearch == IdeaCategory.activity.fallbackPlaceSearch)
    }

    @Test func ideaWithoutTitleIsDropped() {
        #expect(Idea.cleaned(emoji: "🍷", title: " \"\" ", detail: "Etwas", placeSearch: "Bar", category: .date) == nil)
    }

    @Test func digitsAreNotTakenForEmoji() {
        #expect(Idea.firstEmoji(in: "3 Tage") == nil)
        #expect(Idea.firstEmoji(in: "#1") == nil)
    }

    // MARK: - Reminder

    @Test func reminderIsOneOffInAWeek() {
        let calendar = TestCalendar.zurich
        let now = TestCalendar.date(2026, 10, 12, 10)
        let idea = Idea(emoji: "💐", title: "Blumen holen", detail: "", placeSearch: "Blumenladen")
        let reminder = idea.makeReminder(now: now, calendar: calendar)

        #expect(reminder.title == "Blumen holen")
        #expect(reminder.emoji == "💐")
        #expect(reminder.isEnabled)
        #expect(reminder.schedule.frequency == .once)
        #expect(calendar.isDate(reminder.schedule.date, inSameDayAs: TestCalendar.date(2026, 10, 19)))
    }
}
