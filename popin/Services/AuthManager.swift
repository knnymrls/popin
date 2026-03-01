import AuthenticationServices
import SwiftUI

@Observable
final class AuthManager: NSObject {
    private(set) var userId: String?
    private(set) var isLoading = true

    private static let userIdKey = "popin.userId"

    var isSignedIn: Bool { userId != nil }

    override init() {
        super.init()
        restoreSession()
    }

    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    func signOut() {
        userId = nil
        KeychainHelper.delete(for: Self.userIdKey)
    }

    private func restoreSession() {
        if let data = KeychainHelper.read(for: Self.userIdKey),
           let stored = String(data: data, encoding: .utf8) {
            userId = stored
        }
        isLoading = false
    }

    private func persist(userId: String) {
        if let data = userId.data(using: .utf8) {
            KeychainHelper.save(data, for: Self.userIdKey)
        }
    }
}

extension AuthManager: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            return
        }
        let uid = credential.user
        MainActor.assumeIsolated {
            self.userId = uid
            self.persist(userId: uid)
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        print("Apple Sign In failed: \(error.localizedDescription)")
    }
}
