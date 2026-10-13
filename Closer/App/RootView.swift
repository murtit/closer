import SwiftUI

/// Root tab navigation of the app.
struct RootView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Heute", systemImage: "heart.fill")
                }

            RemindersView()
                .tabItem {
                    Label("Erinnerungen", systemImage: "bell.fill")
                }
        }
        .tint(.rosePrimary)
    }
}

#Preview {
    RootView()
        .environment(RemindersViewModel())
}
