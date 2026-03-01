import SwiftUI

@main
struct popinApp: App {
    @State private var auth = AuthManager()
    @State private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(locationManager)
        }
    }
}
