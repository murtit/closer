import SwiftUI

@main
struct CloserApp: App {
    @State private var viewModel = CloserApp.makeViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
                .task { viewModel.syncNotifications() }
        }
    }

    private static func makeViewModel() -> PeopleViewModel {
        #if DEBUG
        if DemoData.isRequested {
            return DemoData.makeViewModel()
        }
        #endif
        return PeopleViewModel()
    }
}
