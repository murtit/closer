import SwiftUI

@main
struct CloserApp: App {
    @State private var viewModel = RemindersViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
        }
    }
}
