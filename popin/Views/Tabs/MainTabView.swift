import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: AppTab
    @State private var askAITrigger = false

    var body: some View {
        ZStack {
            ExploreView(askAITrigger: $askAITrigger)
                .opacity(selectedTab == .explore ? 1 : 0)
                .allowsHitTesting(selectedTab == .explore)

            FriendsListView()
                .opacity(selectedTab == .friends ? 1 : 0)
                .allowsHitTesting(selectedTab == .friends)

            SavedSpotsView()
                .opacity(selectedTab == .archive ? 1 : 0)
                .allowsHitTesting(selectedTab == .archive)

            ProfileView()
                .opacity(selectedTab == .profile ? 1 : 0)
                .allowsHitTesting(selectedTab == .profile)
        }
        .safeAreaInset(edge: .bottom) {
            FloatingNavBar(selected: $selectedTab) {
                selectedTab = .explore
                askAITrigger = true
            }
            .padding(.horizontal, 33)
            .padding(.bottom, -6)
        }
    }
}

enum AppTab: Hashable {
    case explore
    case friends
    case archive
    case profile
}
