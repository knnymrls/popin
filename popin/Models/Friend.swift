import ConvexMobile
import Foundation

struct Friend: Decodable, Identifiable {
    let _id: String
    let friendshipId: String
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

    var id: String { _id }

    var displayEmoji: String { avatarEmoji ?? "👤" }

    var topVibes: String {
        vibes.prefix(3).joined(separator: ", ")
    }

    var budgetLabel: String {
        switch budget {
        case "cheap": return "$"
        case "moderate": return "$$"
        case "splurge": return "$$$"
        default: return "$$"
        }
    }
}
