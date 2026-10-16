import SwiftUI

@main
struct CloserApp: App {
    @State private var viewModel = CloserApp.makeViewModel()
    @State private var ideaServices = CloserApp.makeIdeaServices()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(AppearancePreference.storageKey) private var appearance: AppearancePreference = .system

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(viewModel)
                .environment(ideaServices)
                .preferredColorScheme(Self.colorSchemeOverride ?? appearance.colorScheme)
                .task { viewModel.syncNotifications() }
        }
        .onChange(of: scenePhase) { _, phase in
            // Apple Intelligence may have been turned on, or its model finished downloading.
            if phase == .active { ideaServices.refreshAvailability() }
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

    private static func makeIdeaServices() -> IdeaServices {
        #if DEBUG
        if DemoData.isRequested {
            return DemoData.makeIdeaServices()
        }
        #endif
        return IdeaServices()
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
