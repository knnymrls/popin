import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Explore", systemImage: "magnifyingglass", value: .explore) {
                ExploreView()
            }

            Tab("Friends", systemImage: "person.2", value: .friends) {
                FriendsListView()
            }

            Tab("Profile", systemImage: "person.crop.circle", value: .profile) {
                ProfileView()
            }
        }
    }
}

enum AppTab: Hashable {
    case explore
    case friends
    case profile
}
