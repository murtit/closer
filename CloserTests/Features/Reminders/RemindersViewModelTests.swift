import Foundation
import Testing
@testable import Closer

@MainActor
struct RemindersViewModelTests {
    private let defaults: UserDefaults

    init() {
        let suiteName = "CloserTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test func firstLaunchSeedsPredefinedReminders() {
        let viewModel = RemindersViewModel(defaults: defaults)
        #expect(viewModel.totalCount == Reminder.predefined.count)
        #expect(viewModel.activeCount == 0)
        #expect(viewModel.custom.isEmpty)
        #expect(defaults.data(forKey: RemindersViewModel.storageKey) != nil)
    }

    @Test func addedCustomReminderIsPersisted() {
        let viewModel = RemindersViewModel(defaults: defaults)
        let reminder = Reminder(title: "Kaffee trinken", emoji: "☕", isCustom: true)
        viewModel.add(reminder)

        let reloaded = RemindersViewModel(defaults: defaults)
        #expect(reloaded.custom == [reminder])
        #expect(reloaded.totalCount == Reminder.predefined.count + 1)
    }

    @Test func updateReplacesExistingReminder() {
        let viewModel = RemindersViewModel(defaults: defaults)
        var reminder = viewModel.reminders[0]
        reminder.title = "Geändert"
        viewModel.update(reminder)

        #expect(viewModel.reminders[0].title == "Geändert")
        #expect(RemindersViewModel(defaults: defaults).reminders[0].title == "Geändert")
    }

    @Test func deleteRemovesReminder() {
        let viewModel = RemindersViewModel(defaults: defaults)
        let reminder = Reminder(title: "Temporär", emoji: "🗑️", isCustom: true)
        viewModel.add(reminder)
        viewModel.delete(reminder)

        #expect(!viewModel.reminders.contains(reminder))
        #expect(!RemindersViewModel(defaults: defaults).reminders.contains(reminder))
    }
}
