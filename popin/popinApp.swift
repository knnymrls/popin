import SwiftUI

@main
struct popinApp: App {
    @State private var auth = AuthManager()
    @State private var locationManager = LocationManager()
    @State private var deepLinkInviteCode: String?
    @State private var selectedTab: AppTab = .explore

    var body: some Scene {
        WindowGroup {
            RootView(selectedTab: $selectedTab)
                .environment(auth)
                .environment(locationManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onChange(of: auth.isSignedIn) { _, isSignedIn in
                    // If user just signed in and we have a pending invite, claim it
                    if isSignedIn, let code = deepLinkInviteCode, let userId = auth.userId {
                        claimInvite(code: code, userId: userId)
                        deepLinkInviteCode = nil
                    }
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "popin" else { return }

        switch url.host {
        case "invite":
            // popin://invite?code=XXXXXXXX or popin://invite?from=USER_ID
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            if let code = components?.queryItems?.first(where: { $0.name == "code" })?.value {
                if let userId = auth.userId {
                    claimInvite(code: code, userId: userId)
                } else {
                    // Save for after sign-in
                    deepLinkInviteCode = code
                }
                selectedTab = .friends
            }

        case "plan":
            // popin://plan?shareId=XXXXXXXX — future: navigate to shared plan
            selectedTab = .explore

        default:
            break
        }
    }

    private func claimInvite(code: String, userId: String) {
        let vm = FriendsViewModel()
        vm.claimInvite(code: code, userId: userId)
        selectedTab = .friends
    }
}
