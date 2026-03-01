import ConvexMobile
import Foundation

struct FriendRequest: Decodable, Identifiable {
    let _id: String
    let requesterId: String
    let addresseeId: String
    let status: String
    @ConvexFloat var createdAt: Double
    let requesterName: String?
    let requesterEmoji: String?

    var id: String { _id }

    var displayName: String { requesterName ?? "Unknown" }
    var displayEmoji: String { requesterEmoji ?? "👤" }
}

struct OutgoingRequest: Decodable, Identifiable {
    let _id: String
    let requesterId: String
    let addresseeId: String
    let status: String
    @ConvexFloat var createdAt: Double
    let addresseeName: String?
    let addresseeEmoji: String?

    var id: String { _id }

    var displayName: String { addresseeName ?? "Unknown" }
    var displayEmoji: String { addresseeEmoji ?? "👤" }
}
