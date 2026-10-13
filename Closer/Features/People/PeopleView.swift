import SwiftUI

/// All people the user wants to stay close to, grouped by relationship.
struct PeopleView: View {
    @Environment(PeopleViewModel.self) private var viewModel
    @State private var showingAddPerson = false

    private var groups: [(title: String, people: [Person])] {
        var result: [(title: String, people: [Person])] = []
        for person in viewModel.sortedPeople {
            let title = person.relationship.isOther ? "Andere" : person.relationship.title
            if let index = result.firstIndex(where: { $0.title == title }) {
                result[index].people.append(person)
            } else {
                result.append((title, [person]))
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.people.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Personen")
            .navigationDestination(for: Person.ID.self) { id in
                PersonDetailView(personID: id)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Person hinzufügen", systemImage: "plus") {
                        showingAddPerson = true
                    }
                }
            }
            .sheet(isPresented: $showingAddPerson) {
                PersonFormView()
            }
        }
        .tint(.rosePrimary)
    }

    private var list: some View {
        List {
            ForEach(groups, id: \.title) { group in
                Section(group.title) {
                    ForEach(group.people) { person in
                        NavigationLink(value: person.id) {
                            PersonRowView(person: person)
                        }
                        .accessibilityIdentifier("personRow.\(person.name)")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Wer ist dir wichtig?", systemImage: "person.2.fill")
        } description: {
            Text("Füge deine Partnerin, deine Familie oder Freunde hinzu und lass dich daran erinnern, dich zu melden.")
        } actions: {
            Button("Person hinzufügen") {
                showingAddPerson = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    PeopleView()
        .environment(PeopleViewModel())
}
