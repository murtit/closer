import SwiftUI

struct RemindersView: View {
    @Environment(RemindersViewModel.self) var viewModel
    @State private var showingAdd = false
    @State private var editingReminder: Reminder?

    var body: some View {
        // @Bindable wird benötigt, um $viewModel.property mit @Observable zu nutzen
        @Bindable var vm = viewModel
        NavigationStack {
            List {
                predefinedSection
                customSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Erinnerungen")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .tint(.rosePrimary)
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEditReminderView(mode: .add)
                    .presentationDetents([.medium, .large])
                    .environment(viewModel)
            }
            .sheet(item: $editingReminder) { reminder in
                AddEditReminderView(mode: .edit(reminder))
                    .presentationDetents([.medium, .large])
                    .environment(viewModel)
            }
            .alert("Benachrichtigungen deaktiviert", isPresented: $vm.showPermissionAlert) {
                Button("Einstellungen öffnen") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Abbrechen", role: .cancel) { }
            } message: {
                Text("Bitte erlaube Benachrichtigungen in den Einstellungen, um Erinnerungen zu erhalten.")
            }
        }
    }

    // MARK: - Sections

    private var predefinedSection: some View {
        Section {
            ForEach(viewModel.predefined) { reminder in
                ReminderRowView(reminder: reminder)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            editingReminder = reminder
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }
        } header: {
            sectionHeader(title: "Liebesgesten", icon: "sparkles")
        }
    }

    private var customSection: some View {
        Section {
            ForEach(viewModel.custom) { reminder in
                ReminderRowView(reminder: reminder)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            withAnimation {
                                viewModel.delete(reminder)
                            }
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                        Button {
                            editingReminder = reminder
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }

            Button {
                showingAdd = true
            } label: {
                Label("Eigene Geste hinzufügen", systemImage: "plus.circle.fill")
                    .foregroundStyle(.rosePrimary)
                    .font(.body)
            }
            .padding(.vertical, 2)
        } header: {
            sectionHeader(title: "Meine Gesten", icon: "star.fill")
        } footer: {
            if viewModel.custom.isEmpty {
                Text("Füge persönliche Ideen hinzu – ganz nach eurer Beziehung.")
                    .font(.footnote)
            }
        }
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .textCase(nil)
            .padding(.bottom, 2)
    }
}

#Preview {
    RemindersView()
        .environment(RemindersViewModel())
}
