import Combine
import ConvexMobile
import Foundation

@Observable
final class FriendsViewModel {

    // MARK: - State

    var friends: [Friend] = []
    var incomingRequests: [FriendRequest] = []
    var outgoingRequests: [OutgoingRequest] = []
    var sharedPlans: [SharedPlanItem] = []
    var matchedContacts: [MatchedContact] = []
    var unmatchedPhones: [String] = []
    var isLoading = false
    var isSeeding = false
    var errorMessage: String?

    // For group planning — selected friend userIds
    var selectedFriendIds: Set<String> = []

    // MARK: - Derived

    var pendingRequestCount: Int { incomingRequests.count }
    var pendingSharedPlansCount: Int {
        sharedPlans.filter { $0.isHangout && $0.isPending }.count
    }
    var hasPendingItems: Bool { pendingRequestCount > 0 || pendingSharedPlansCount > 0 }

    // MARK: - Private

    private var friendsSub: AnyCancellable?
    private var requestsSub: AnyCancellable?
    private var outgoingSub: AnyCancellable?
    private var sharedPlansSub: AnyCancellable?

    // MARK: - Subscriptions

    func startSubscriptions(userId: String) {
        guard friendsSub == nil else { return }

        let friendsPublisher: AnyPublisher<[Friend], ClientError> = convex.subscribe(
            to: "friends:getFriends",
            with: ["userId": userId]
        )
        friendsSub = friendsPublisher
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] friends in
                self?.friends = friends
            }

        let requestsPublisher: AnyPublisher<[FriendRequest], ClientError> = convex.subscribe(
            to: "friends:getPendingRequests",
            with: ["userId": userId]
        )
        requestsSub = requestsPublisher
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] requests in
                self?.incomingRequests = requests
            }

        let outgoingPublisher: AnyPublisher<[OutgoingRequest], ClientError> = convex.subscribe(
            to: "friends:getOutgoingRequests",
            with: ["userId": userId]
        )
        outgoingSub = outgoingPublisher
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] requests in
                self?.outgoingRequests = requests
            }

        let sharedPlansPublisher: AnyPublisher<[SharedPlanItem], ClientError> = convex.subscribe(
            to: "friends:getSharedPlans",
            with: ["userId": userId]
        )
        sharedPlansSub = sharedPlansPublisher
            .replaceError(with: [])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] plans in
                self?.sharedPlans = plans
            }
    }

    func stopSubscriptions() {
        friendsSub?.cancel()
        friendsSub = nil
        requestsSub?.cancel()
        requestsSub = nil
        outgoingSub?.cancel()
        outgoingSub = nil
        sharedPlansSub?.cancel()
        sharedPlansSub = nil
    }

    // MARK: - Friend Actions

    func sendFriendRequest(from requesterId: String, to addresseeId: String) {
        Task {
            do {
                let args: [String: ConvexEncodable?] = [
                    "requesterId": requesterId,
                    "addresseeId": addresseeId,
                ]
                try await convex.mutation("friends:sendFriendRequest", with: args)
            } catch {
                errorMessage = "Failed to send friend request"
                print("Send request failed: \(error)")
            }
        }
    }

    func acceptRequest(_ friendshipId: String, userId: String) {
        Task {
            do {
                let args: [String: ConvexEncodable?] = [
                    "friendshipId": friendshipId,
                    "userId": userId,
                ]
                try await convex.mutation("friends:acceptFriendRequest", with: args)
            } catch {
                errorMessage = "Failed to accept request"
                print("Accept failed: \(error)")
            }
        }
    }

    func declineRequest(_ friendshipId: String, userId: String) {
        Task {
            do {
                let args: [String: ConvexEncodable?] = [
                    "friendshipId": friendshipId,
                    "userId": userId,
                ]
                try await convex.mutation("friends:declineFriendRequest", with: args)
            } catch {
                errorMessage = "Failed to decline request"
                print("Decline failed: \(error)")
            }
        }
    }

    func removeFriend(_ friendshipId: String, userId: String) {
        Task {
            do {
                let args: [String: ConvexEncodable?] = [
                    "friendshipId": friendshipId,
                    "userId": userId,
                ]
                try await convex.mutation("friends:removeFriend", with: args)
            } catch {
                errorMessage = "Failed to remove friend"
                print("Remove failed: \(error)")
            }
        }
    }

    // MARK: - Plan Sharing

    func sharePlan(
        planId: String,
        senderId: String,
        recipientId: String,
        shareType: String,
        message: String? = nil
    ) {
        Task {
            do {
                var args: [String: ConvexEncodable?] = [
                    "planId": planId,
                    "senderId": senderId,
                    "recipientId": recipientId,
                    "shareType": shareType,
                ]
                args["message"] = message
                try await convex.mutation("friends:sharePlan", with: args)
            } catch {
                errorMessage = "Failed to share plan"
                print("Share plan failed: \(error)")
            }
        }
    }

    func respondToSharedPlan(_ sharedPlanId: String, userId: String, accept: Bool) {
        Task {
            do {
                let args: [String: ConvexEncodable?] = [
                    "sharedPlanId": sharedPlanId,
                    "userId": userId,
                    "accept": accept,
                ]
                try await convex.mutation("friends:respondToSharedPlan", with: args)
            } catch {
                errorMessage = "Failed to respond to shared plan"
                print("Respond failed: \(error)")
            }
        }
    }

    // MARK: - Contact Matching

    func matchContacts(userId: String, phoneNumbers: [String]) {
        isLoading = true
        Task {
            do {
                let phonesEnc: [ConvexEncodable?] = phoneNumbers.map { $0 }
                let args: [String: ConvexEncodable?] = [
                    "userId": userId,
                    "phoneNumbers": phonesEnc,
                ]
                let result: ContactMatchResult = try await convex.mutation(
                    "friends:matchContacts",
                    with: args
                )
                await MainActor.run {
                    self.matchedContacts = result.matched
                    self.unmatchedPhones = result.unmatched
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to match contacts"
                    self.isLoading = false
                }
                print("Match contacts failed: \(error)")
            }
        }
    }

    // MARK: - Invites

    func createInvite(userId: String, phone: String?) async -> String? {
        do {
            var args: [String: ConvexEncodable?] = ["inviterId": userId]
            args["inviteePhone"] = phone
            let result: InviteResult = try await convex.mutation(
                "friends:createInvite",
                with: args
            )
            return result.inviteCode
        } catch {
            errorMessage = "Failed to create invite"
            print("Create invite failed: \(error)")
            return nil
        }
    }

    func claimInvite(code: String, userId: String) {
        Task {
            do {
                let args: [String: ConvexEncodable?] = [
                    "inviteCode": code,
                    "claimedByUserId": userId,
                ]
                try await convex.mutation("friends:claimInvite", with: args)
            } catch {
                errorMessage = "Failed to claim invite"
                print("Claim invite failed: \(error)")
            }
        }
    }

    // MARK: - Mock Data

    func seedMockFriends(userId: String) {
        isSeeding = true
        Task {
            do {
                let args: [String: ConvexEncodable?] = ["currentUserId": userId]
                let result: SeedResult = try await convex.mutation(
                    "friends:seedMockFriends",
                    with: args
                )
                await MainActor.run {
                    self.isSeeding = false
                    if !result.seeded {
                        self.errorMessage = result.message
                    }
                }
            } catch {
                await MainActor.run {
                    self.isSeeding = false
                    self.errorMessage = "Failed to seed mock friends"
                }
                print("Seed failed: \(error)")
            }
        }
    }

    // MARK: - Group Planning Helpers

    func toggleFriendForPlan(_ friendId: String) {
        if selectedFriendIds.contains(friendId) {
            selectedFriendIds.remove(friendId)
        } else {
            selectedFriendIds.insert(friendId)
        }
    }

    var selectedFriendIdsArray: [String] {
        Array(selectedFriendIds)
    }

    func clearPlanSelection() {
        selectedFriendIds.removeAll()
    }
}
