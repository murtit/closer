import SwiftUI

/// One person: quick contact actions, their reminders and further suggestions.
struct PersonDetailView: View {
    @Environment(PeopleViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let personID: Person.ID

    @State private var showingEditPerson = false
    @State private var showingNewReminder = false
    @State private var editingReminder: Reminder?

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
            remindersSection(for: person)
            if !person.openSuggestions.isEmpty {
                suggestionsSection(for: person)
            }
        }
        .listStyle(.insetGrouped)
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
    }
}

#Preview {
    let viewModel = PeopleViewModel()
    NavigationStack {
        PersonDetailView(personID: UUID())
    }
    .environment(viewModel)
}
