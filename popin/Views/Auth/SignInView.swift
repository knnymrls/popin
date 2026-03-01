import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @Environment(AuthManager.self) private var auth

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("popin")
                .font(.system(size: 48, weight: .bold, design: .rounded))

            Text("Find your next move.")
                .font(.title3)
                .foregroundStyle(.secondary)

            Spacer()

            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                        let uid = credential.user
                        if let data = uid.data(using: .utf8) {
                            KeychainHelper.save(data, for: "popin.userId")
                        }
                        // Trigger state update via AuthManager
                        auth.signInWithApple()
                    }
                case .failure(let error):
                    print("Sign in failed: \(error.localizedDescription)")
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 40)

            Spacer()
                .frame(height: 60)
        }
    }
}
