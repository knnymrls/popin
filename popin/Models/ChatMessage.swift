import ConvexMobile
import Foundation

// MARK: - Chat Message

enum ChatMessage: Identifiable {
    case user(id: UUID = UUID(), text: String)
    case assistant(id: UUID = UUID(), text: String)
    case spots(id: UUID = UUID(), spots: [SpotData])
    case plan(id: UUID = UUID(), plan: PlanData)
    case loading(id: UUID = UUID(), stage: String)

    var id: UUID {
        switch self {
        case .user(let id, _),
             .assistant(let id, _),
             .spots(let id, _),
             .plan(let id, _),
             .loading(let id, _):
            return id
        }
    }
}

// MARK: - Spot Data (from chat response)

struct SpotData: Decodable, Identifiable {
    let placeId: String
    let name: String
    let address: String
    @ConvexFloat var latitude: Double
    @ConvexFloat var longitude: Double
    let photoUrl: String?
    @OptionalConvexFloat var rating: Double?
    @OptionalConvexFloat var priceLevel: Double?

    var id: String { placeId }
}

// MARK: - Spot Detail (from getSpotDetail action)

struct SpotDetail: Decodable {
    let placeId: String
    let name: String
    let address: String
    let phone: String?
    let website: String?
    let hours: [String]?
    let isOpenNow: Bool?
    @OptionalConvexFloat var rating: Double?
    @OptionalConvexFloat var priceLevel: Double?
    @OptionalConvexFloat var reviewCount: Double?
    let reviews: [SpotReview]?
    let editorialSummary: String?
    let photoUrls: [String]
    let perplexitySummary: String?
}

struct SpotReview: Decodable, Identifiable {
    @ConvexFloat var rating: Double
    let text: String
    let time: String

    var id: String { "\(time)-\(text.prefix(20))" }
}

// MARK: - Plan Data (from chat response)

struct PlanData: Decodable {
    let title: String
    let summary: String
    let stops: [PlanStopData]
    let totalCost: String
    let totalTime: String
    let shareId: String?
}

struct PlanStopData: Decodable, Identifiable {
    @ConvexFloat var order: Double
    let emoji: String
    let name: String
    let time: String
    let cost: String
    let note: String

    var id: Int { Int(order) }
}

// MARK: - Chat Response (Convex action return type)

struct ChatResponse: Decodable {
    let text: String
    let spots: [SpotData]?
    let plan: PlanData?
}
