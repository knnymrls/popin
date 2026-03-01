import ConvexMobile
import CoreLocation
import Foundation

struct Spot: Decodable, Identifiable {
    let _id: String
    let searchId: String
    let placeId: String
    let name: String
    @ConvexFloat var latitude: Double
    @ConvexFloat var longitude: Double
    let address: String
    let photoUrl: String?
    @OptionalConvexFloat var rating: Double?
    @OptionalConvexFloat var priceLevel: Double?
    let oneLiner: String
    let vibeTags: [String]
    let deepDetail: String?

    var id: String { _id }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
