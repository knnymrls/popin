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

    var icon: String {
        switch self {
        case .restaurant: "fork.knife"
        case .cafe: "cup.and.saucer"
        case .bar: "wineglass"
        case .coffee: "mug"
        case .dessert: "birthday.cake"
        case .shop: "bag"
        case .outdoors: "leaf"
        case .nightlife: "moon.stars"
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
