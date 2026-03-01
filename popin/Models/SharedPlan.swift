import ConvexMobile
import Foundation

struct SharedPlanItem: Decodable, Identifiable {
    let _id: String
    let planId: String
    let senderId: String
    let recipientId: String
    let shareType: String
    let message: String?
    let rsvp: String
    @ConvexFloat var createdAt: Double
    let senderName: String?
    let senderEmoji: String?
    let planTitle: String?
    let planSummary: String?

    var id: String { _id }

    var isHangout: Bool { shareType == "hangout" }
    var isRecommendation: Bool { shareType == "recommendation" }
    var isPending: Bool { rsvp == "pending" }

    var displaySenderName: String { senderName ?? "Someone" }
    var displaySenderEmoji: String { senderEmoji ?? "👤" }

    var typeLabel: String {
        isHangout ? "wants to hang" : "recommends"
    }
}

struct FriendProfileDetail: Decodable, Identifiable {
    let _id: String
    let userId: String
    let name: String
    let avatarEmoji: String?
    let budget: String?
    let vibes: [String]
    let foodLoves: [String]
    let foodAvoids: [String]
    let activities: [String]
    let dealbreakers: [String]
    let notes: String?
    let friendshipId: String
    let mutualPlans: [MutualPlanItem]

    var id: String { _id }
    var displayEmoji: String { avatarEmoji ?? "👤" }
}

struct MutualPlanItem: Decodable, Identifiable {
    let _id: String
    let shareType: String
    let rsvp: String
    let planTitle: String
    let planSummary: String
    @ConvexFloat var createdAt: Double

    var id: String { _id }
}

struct ContactMatchResult: Decodable {
    let matched: [MatchedContact]
    let unmatched: [String]
}

struct MatchedContact: Decodable, Identifiable {
    let userId: String
    let name: String
    let phoneNumber: String
    let avatarEmoji: String?

    var id: String { userId }
    var displayEmoji: String { avatarEmoji ?? "👤" }
}

struct InviteResult: Decodable {
    let inviteCode: String
}

struct SeedResult: Decodable {
    let seeded: Bool
    let message: String
}
