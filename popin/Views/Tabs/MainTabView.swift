import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Explore", systemImage: "magnifyingglass") {
                ExploreView()
            }

            Tab("Lists", systemImage: "rectangle.stack") {
                PlaceholderTab(title: "Lists", icon: "rectangle.stack")
            }

            Tab("Profile", systemImage: "person.crop.circle") {
                ProfileView()
            }
        }
    }
}

private struct PlaceholderTab: View {
    let title: String
    let icon: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.title2.bold())
            }
            .navigationTitle(title)
        }
    }
}
