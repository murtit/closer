import SwiftUI

/// One person: quick contact actions, their reminders and further suggestions.
struct PersonDetailView: View {
    @Environment(PeopleViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let personID: Person.ID

    @State private var showingEditPerson = false
    @State private var showingNewReminder = false
    @State private var editingReminder: Reminder?
    @State private var showingAnniversaryForm = false

    var body: some View {
        if let person = viewModel.person(withID: personID) {
            content(for: person)
        } else {
            ContentUnavailableView("Person nicht gefunden", systemImage: "person.slash")
        }
    }

    private func content(for person: Person) -> some View {
        List {
            header(for: person)
            if person.isPartner {
                anniversarySection(for: person)
            }
            remindersSection(for: person)
            if !person.openSuggestions.isEmpty {
                suggestionsSection(for: person)
            }
        }
        .listStyle(.insetGrouped)
        .closerListBackground()
        .navigationTitle(person.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Bearbeiten") { showingEditPerson = true }
            }
        }
        .sheet(isPresented: $showingEditPerson) {
            PersonFormView(person: person, onDelete: { dismiss() })
        }
        .sheet(isPresented: $showingNewReminder) {
            ReminderFormView(personID: personID)
        }
        .sheet(item: $editingReminder) { reminder in
            ReminderFormView(personID: personID, reminder: reminder)
        }
        .sheet(isPresented: $showingAnniversaryForm) {
            AnniversaryFormView(personID: personID, anniversary: person.anniversary)
        }
    }

    // MARK: - Sections

    private func header(for person: Person) -> some View {
        Section {
            VStack(spacing: 12) {
                PersonAvatarView(person: person, size: 96)
                VStack(spacing: 4) {
                    Text(person.name)
                        .font(.title2.weight(.bold))
                    Text("\(person.relationship.emoji) \(person.relationship.title)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    ContactActionButton(title: "Anrufen", systemImage: "phone.fill", url: person.phoneURL)
                    ContactActionButton(title: "Nachricht", systemImage: "message.fill", url: person.messageURL)
                    ContactActionButton(title: "E-Mail", systemImage: "envelope.fill", url: person.emailURL)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
        }
    }

    private func anniversarySection(for person: Person) -> some View {
        Section {
            Button {
                showingAnniversaryForm = true
            } label: {
                if let anniversary = person.anniversary {
                    HStack(spacing: 14) {
                        Text("💞")
                            .font(.system(size: 22))
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(Color.closerAccentSoft))
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Zusammen seit \(anniversary.date.formatted(date: .long, time: .omitted))")
                                .foregroundStyle(.primary)
                            Text(anniversary.togetherText())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let countdown = anniversary.countdownText() {
                                Text(countdown)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.closerAccent)
                            }
                            Text(anniversary.remindersSummary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 2)
                } else {
                    Label("Jahrestag hinzufügen", systemImage: "calendar.badge.plus")
                        .foregroundStyle(.closerAccent)
                }
            }
            // Plain, so only the countdown is tinted and not the whole row.
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityIdentifier("anniversaryRow")
        } header: {
            Text("Jahrestag")
        } footer: {
            if person.anniversary == nil {
                Text("Closer erinnert dich am Jahrestag und schon vorher, damit du ein Date planen oder ein Geschenk besorgen kannst.")
            }
        }
        .listRowBackground(Color.closerSurface)
    }

    private func remindersSection(for person: Person) -> some View {
        Section {
            ForEach(person.reminders) { reminder in
                PersonReminderRowView(
                    reminder: reminder,
                    isEnabled: Binding(
                        get: { reminder.isEnabled },
                        set: { viewModel.setReminder(reminder.id, enabled: $0, for: personID) }
                    )
                )
                .contentShape(Rectangle())
                .onTapGesture { editingReminder = reminder }
                .swipeActions {
                    Button("Löschen", systemImage: "trash", role: .destructive) {
                        viewModel.deleteReminder(reminder.id, for: personID)
                    }
                }
            }

            Button {
                showingNewReminder = true
            } label: {
                Label("Eigene Erinnerung hinzufügen", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("Erinnerungen")
        } footer: {
            if person.reminders.isEmpty {
                Text("Noch keine Erinnerungen. Nimm einen Vorschlag oder erstelle eine eigene.")
            }
        }
        .listRowBackground(Color.closerSurface)
    }

    private func suggestionsSection(for person: Person) -> some View {
        Section {
            ForEach(person.openSuggestions) { suggestion in
                Button {
                    withAnimation {
                        viewModel.save(suggestion.makeReminder(), for: personID)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text(suggestion.emoji)
                        Text(suggestion.title)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "plus.circle")
                    }
                }
            }
        } header: {
            Text("Vorschläge für \(person.relationship.title)")
        }
        .listRowBackground(Color.closerSurface)
    }
}

#Preview {
    let viewModel = PeopleViewModel()
    NavigationStack {
        PersonDetailView(personID: UUID())
    }
    .environment(viewModel)
}
