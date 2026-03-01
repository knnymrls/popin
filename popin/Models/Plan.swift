import ConvexMobile
import Foundation

struct Plan: Decodable, Identifiable {
    let _id: String
    let userId: String?
    let title: String
    let aiSummary: String
    let estimatedCost: String?
    let totalDistance: String?
    let totalTime: String?
    let profiles: [String]?
    let shareId: String?
    @ConvexFloat var createdAt: Double

    var id: String { _id }
}

struct PlanStop: Decodable, Identifiable {
    let _id: String
    let planId: String
    let spotId: String?
    let emoji: String?
    let name: String?
    let cost: String?
    @ConvexFloat var order: Double
    let suggestedTime: String?
    let notes: String?

    var id: String { _id }

    var orderIndex: Int { Int(order) }
}

struct PlanWithStops: Identifiable {
    let plan: Plan
    let stops: [PlanStop]

    var id: String { plan.id }
}
