import ConvexMobile
import Foundation

struct Favorite: Decodable, Identifiable {
    let _id: String
    let userId: String
    let name: String
    let address: String
    let photoUrl: String?
    @OptionalConvexFloat var priceLevel: Double?
    @OptionalConvexFloat var rating: Double?
    let types: [String]
    let description: String?

    var id: String { _id }
}
