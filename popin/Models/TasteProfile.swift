import ConvexMobile
import Foundation

struct TasteProfile: Decodable, Identifiable {
    let _id: String
    let userId: String
    let name: String
    let phoneNumber: String?
    let avatarEmoji: String?
    let budget: String?
    let vibes: [String]
    let foodLoves: [String]
    let foodAvoids: [String]
    let activities: [String]
    let dealbreakers: [String]
    let notes: String?

    var id: String { _id }

    var displayEmoji: String { avatarEmoji ?? "😊" }
}
