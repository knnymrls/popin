import Foundation

enum SpotCategory: String, CaseIterable, Identifiable {
    case restaurant = "Restaurant"
    case cafe = "Cafe"
    case bar = "Bar"
    case coffee = "Coffee"
    case dessert = "Dessert"
    case shop = "Shop"
    case outdoors = "Outdoors"
    case nightlife = "Nightlife"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .restaurant: "\u{1F37D}\u{FE0F}"
        case .cafe: "\u{2615}"
        case .bar: "\u{1F378}"
        case .coffee: "\u{2615}"
        case .dessert: "\u{1F370}"
        case .shop: "\u{1F6CD}\u{FE0F}"
        case .outdoors: "\u{1F333}"
        case .nightlife: "\u{1F3B6}"
        }
    }

    var googlePlaceType: String {
        switch self {
        case .restaurant: "restaurant"
        case .cafe: "cafe"
        case .bar: "bar"
        case .coffee: "coffee_shop"
        case .dessert: "bakery"
        case .shop: "shopping_mall"
        case .outdoors: "park"
        case .nightlife: "night_club"
        }
    }
}
