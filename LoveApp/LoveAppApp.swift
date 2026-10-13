import SwiftUI

@main
struct LoveAppApp: App {
    @State private var viewModel = RemindersViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
    }
}
