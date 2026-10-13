import SwiftUI

@main
struct CloserApp: App {
    @State private var viewModel = CloserApp.makeViewModel()
    @AppStorage(AppearancePreference.storageKey) private var appearance: AppearancePreference = .system

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
                .preferredColorScheme(Self.colorSchemeOverride ?? appearance.colorScheme)
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
