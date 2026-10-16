import SwiftUI

/// Root tab navigation of the app.
struct RootView: View {
    @Environment(PeopleViewModel.self) private var viewModel

    var body: some View {
        @Bindable var vm = viewModel
        TabView {
            HomeView()
                .tabItem {
                    Label("Heute", systemImage: "heart.fill")
                }

            PeopleView()
                .tabItem {
                    Label("Personen", systemImage: "person.2.fill")
                }
        }
        .tint(.closerAccent)
        .alert("Benachrichtigungen deaktiviert", isPresented: $vm.showPermissionAlert) {
            Button("Einstellungen öffnen") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Bitte erlaube Benachrichtigungen in den Einstellungen, damit Closer dich erinnern kann.")
        }
        .alert(
            "Speicherfehler",
            isPresented: Binding(
                get: { viewModel.storageError != nil },
                set: { if !$0 { viewModel.storageError = nil } }
            )
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.storageError ?? "")
        }
    }
}

#Preview {
    RootView()
        .environment(PeopleViewModel())
        .environment(IdeaServices())
}
