import SwiftUI

@main
struct CloserApp: App {
    @State private var viewModel = PeopleViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
                .task { viewModel.syncNotifications() }
        }
    }
}
