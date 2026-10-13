import SwiftUI

@main
struct CloserApp: App {
    @State private var viewModel = CloserApp.makeViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
                .preferredColorScheme(Self.colorSchemeOverride)
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

    private static var colorSchemeOverride: ColorScheme? {
        #if DEBUG
        switch DemoData.appearance {
        case "light": return .light
        case "dark": return .dark
        default: break
        }
        #endif
        return nil
    }
}
