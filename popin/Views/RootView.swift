import SwiftUI

struct RootView: View {
    @Environment(AuthManager.self) private var auth
    @Binding var selectedTab: AppTab

    var body: some View {
        Group {
            if auth.isLoading {
                ProgressView()
            } else if auth.isSignedIn {
                MainTabView(selectedTab: $selectedTab)
            } else {
                SignInView()
            }
        }
    }
}
