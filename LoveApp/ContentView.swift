import SwiftUI

struct ContentView: View {
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
