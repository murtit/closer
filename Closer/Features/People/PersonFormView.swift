import SwiftUI

/// Add a new person (from contacts or by hand) or edit an existing one.
struct PersonFormView: View {
    @Environment(PeopleViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    private let original: Person?
    /// Called after a person was deleted, so a detail screen underneath can close as well.
    var onDelete: (() -> Void)?

    @State private var name: String
    @State private var relationship: Relationship
    @State private var phoneNumber: String
    @State private var email: String
    @State private var photoData: Data?
    @State private var contactIdentifier: String?
    @State private var selectedSuggestions: Set<String>
    @State private var showingContactPicker = false
    @State private var confirmingDelete = false

    /// `person == nil` adds a new person.
    init(person: Person? = nil, onDelete: (() -> Void)? = nil) {
        self.original = person
        self.onDelete = onDelete
        let relationship = person?.relationship ?? .partner
        _name = State(initialValue: person?.name ?? "")
        _relationship = State(initialValue: relationship)
        _phoneNumber = State(initialValue: person?.phoneNumber ?? "")
        _email = State(initialValue: person?.email ?? "")
        _photoData = State(initialValue: person?.photoData)
        _contactIdentifier = State(initialValue: person?.contactIdentifier)
        _selectedSuggestions = State(initialValue: Self.preselected(for: relationship))
    }

    private var isAdding: Bool { original == nil }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Group {
                    contactSection
                    relationshipSection
                    if isAdding {
                        suggestionsSection
                    }
                    detailsSection
                    if !isAdding {
                        deleteSection
                    }
                }
                .listRowBackground(Color.closerSurface)
            }
            .closerListBackground()
            .navigationTitle(isAdding ? "Person hinzufügen" : "Person bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isAdding ? "Hinzufügen" : "Sichern", action: save)
                        .fontWeight(.semibold)
                        .disabled(trimmedName.isEmpty)
                }
            }
            .tint(.closerAccent)
            .contactPicker(isPresented: $showingContactPicker, onSelect: apply)
            .onChange(of: relationship.sortIndex) {
                selectedSuggestions = Self.preselected(for: relationship)
            }
            .confirmationDialog(
                "\(trimmedName) und alle Erinnerungen löschen?",
                isPresented: $confirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Löschen", role: .destructive, action: delete)
            }
        }
    }

    // MARK: - Sections

    private var contactSection: some View {
        Section {
            HStack(spacing: 14) {
                PersonAvatarView(name: trimmedName, photoData: photoData, size: 56)
                TextField("Name", text: $name)
                    .font(.title3.weight(.semibold))
                    .textContentType(.name)
            }
            .padding(.vertical, 4)

            Button {
                showingContactPicker = true
            } label: {
                Label(
                    contactIdentifier == nil ? "Aus Kontakten übernehmen" : "Anderen Kontakt wählen",
                    systemImage: "person.crop.circle.badge.plus"
                )
            }
        } footer: {
            if isAdding && contactIdentifier == nil {
                Text("Foto, Telefonnummer und E-Mail werden aus deinen Kontakten übernommen.")
            }
        }
    }

    private var relationshipSection: some View {
        Section("Beziehung") {
            RelationshipPicker(relationship: $relationship)
        }
    }

    private var suggestionsSection: some View {
        Section {
            ForEach(relationship.suggestions) { suggestion in
                Button {
                    toggle(suggestion)
                } label: {
                    HStack(spacing: 12) {
                        Text(suggestion.emoji)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(suggestion.title)
                                .foregroundStyle(.primary)
                            Text(suggestion.schedule.summary())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: selectedSuggestions.contains(suggestion.id) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(selectedSuggestions.contains(suggestion.id) ? Color.closerAccent : Color.secondary)
                    }
                }
                .accessibilityAddTraits(selectedSuggestions.contains(suggestion.id) ? .isSelected : [])
            }
        } header: {
            Text("Erinnerungen")
        } footer: {
            Text("Du kannst Text, Emoji und Zeitpunkt später anpassen und eigene Erinnerungen ergänzen.")
        }
    }

    private var detailsSection: some View {
        Section("Kontaktdaten") {
            TextField("Telefon", text: $phoneNumber)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
            TextField("E-Mail", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Person löschen", role: .destructive) {
                confirmingDelete = true
            }
        }
    }

    // MARK: - Actions

    private static func preselected(for relationship: Relationship) -> Set<String> {
        Set(relationship.suggestions.filter(\.isPreselected).map(\.id))
    }

    private func toggle(_ suggestion: ReminderSuggestion) {
        if selectedSuggestions.contains(suggestion.id) {
            selectedSuggestions.remove(suggestion.id)
        } else {
            selectedSuggestions.insert(suggestion.id)
        }
    }

    private func apply(_ contact: ImportedContact) {
        if !contact.name.isEmpty { name = contact.name }
        phoneNumber = contact.phoneNumber ?? ""
        email = contact.email ?? ""
        photoData = contact.photoData
        contactIdentifier = contact.identifier
    }

    private func save() {
        let phone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let mail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if var person = original {
            person.name = trimmedName
            person.relationship = relationship
            person.phoneNumber = phone.isEmpty ? nil : phone
            person.email = mail.isEmpty ? nil : mail
            person.photoData = photoData
            person.contactIdentifier = contactIdentifier
            viewModel.update(person)
        } else {
            let reminders = relationship.suggestions
                .filter { selectedSuggestions.contains($0.id) }
                .map { $0.makeReminder() }
            viewModel.add(Person(
                name: trimmedName,
                relationship: relationship,
                phoneNumber: phone.isEmpty ? nil : phone,
                email: mail.isEmpty ? nil : mail,
                photoData: photoData,
                contactIdentifier: contactIdentifier,
                reminders: reminders
            ))
        }
        dismiss()
    }

    private func delete() {
        guard let original else { return }
        viewModel.delete(original)
        dismiss()
        onDelete?()
    }
}

#Preview {
    PersonFormView()
        .environment(PeopleViewModel())
}
