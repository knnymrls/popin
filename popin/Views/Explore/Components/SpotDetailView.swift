import CoreLocation
import MapKit
import SwiftUI

struct SpotDetailView: View {
    let spot: SpotData
    let detail: SpotDetail?
    let isLoading: Bool
    @Environment(AuthManager.self) private var auth
    @Environment(LocationManager.self) private var locationManager
    @State private var savedVM = SavedSpotsViewModel()
    @State private var showAllHours = false

    private var isSaved: Bool { savedVM.isSaved(spot.name) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image
                heroImage

                // Photo thumbnails
                if let detail, detail.photoUrls.count > 1 {
                    photoThumbnails(Array(detail.photoUrls.dropFirst()))
                }

                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerSection

                    // Type tags
                    if let types = detail?.types, !types.isEmpty {
                        typeTags(types)
                    }

                    // Quick actions
                    quickActions

                    // Loading
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .padding(.vertical, 24)
                            Spacer()
                        }
                    }

                    if let detail {
                        // AI Insights
                        insightSection(detail)

                        // Service & attributes
                        if hasAnyService(detail) {
                            serviceSection(detail)
                        }

                        // Hours
                        if let hours = detail.hours, !hours.isEmpty {
                            hoursSection(hours, isOpen: detail.isOpenNow)
                        }

                        // Reviews
                        if let reviews = detail.reviews, !reviews.isEmpty {
                            reviewsSection(reviews)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            if let userId = auth.userId {
                savedVM.startSubscription(userId: userId)
            }
        }
        .onDisappear {
            savedVM.stopSubscription()
        }
    }

    // MARK: - Hero Image

    private var heroImage: some View {
        ZStack(alignment: .bottomLeading) {
            if let detail, !detail.photoUrls.isEmpty, let url = URL(string: detail.photoUrls[0]) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(.quaternary)
                }
                .frame(height: 260)
                .clipped()
            } else if let photoUrl = spot.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(.quaternary)
                }
                .frame(height: 260)
                .clipped()
            } else {
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 260)
                    .overlay {
                        Image(systemName: "mappin.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Overlaid badges
            HStack(spacing: 8) {
                if let isOpen = detail?.isOpenNow {
                    Text(isOpen ? "Open" : "Closed")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(isOpen ? .green : .red, in: Capsule())
                }

                if let rating = detail?.rating ?? spot.rating {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                        Text(String(format: "%.1f", rating))
                            .font(.caption.weight(.bold))
                        if let count = detail?.reviewCount {
                            Text("(\(Int(count)))")
                                .font(.caption2)
                                .opacity(0.8)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())
                }

                if let price = detail?.priceLevel ?? spot.priceLevel {
                    Text(String(repeating: "$", count: Int(price)))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .padding(16)
        }
        .frame(height: 260)
        .clipped()
    }

    // MARK: - Photo Thumbnails

    private func photoThumbnails(_ urls: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(urls, id: \.self) { urlString in
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(.quaternary)
                        }
                        .frame(width: 80, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(spot.name)
                .font(.title2.weight(.bold))

            HStack(spacing: 6) {
                Image(systemName: "mappin")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(detail?.address ?? spot.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let dist = distanceText {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(dist)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(red: 0, green: 0.39, blue: 1))
                }
            }
        }
    }

    // MARK: - Type Tags

    private func typeTags(_ types: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(types, id: \.self) { type in
                    Text(type)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(red: 0, green: 0.39, blue: 1).opacity(0.1), in: Capsule())
                        .foregroundStyle(Color(red: 0, green: 0.39, blue: 1))
                }
            }
        }
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Save
                actionButton(
                    icon: isSaved ? "bookmark.fill" : "bookmark",
                    label: isSaved ? "Saved" : "Save",
                    tinted: isSaved
                ) {
                    if let userId = auth.userId {
                        if isSaved {
                            savedVM.removeFavorite(name: spot.name, userId: userId)
                        } else {
                            savedVM.saveFavorite(spot: spot, userId: userId)
                        }
                    }
                }

                // Directions
                actionButton(icon: "arrow.triangle.turn.up.right.diamond.fill", label: "Directions") {
                    let mapItem = MKMapItem(
                        location: CLLocation(latitude: spot.latitude, longitude: spot.longitude),
                        address: nil
                    )
                    mapItem.name = spot.name
                    mapItem.openInMaps(launchOptions: [
                        MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault,
                    ])
                }

                // Call
                if let phone = detail?.phone,
                   let phoneUrl = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                    actionLink(icon: "phone.fill", label: "Call", url: phoneUrl)
                }

                // Website
                if let website = detail?.website, let webUrl = URL(string: website) {
                    actionLink(icon: "safari.fill", label: "Website", url: webUrl)
                }

                // Google Maps
                if let mapsUrl = detail?.googleMapsUrl, let url = URL(string: mapsUrl) {
                    actionLink(icon: "map.fill", label: "Maps", url: url)
                }

                // Share
                ShareLink(item: "Check out \(spot.name)! \(detail?.googleMapsUrl ?? "")") {
                    VStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 48, height: 48)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        Text("Share")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func actionButton(icon: String, label: String, tinted: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tinted ? Color(red: 0, green: 0.39, blue: 1) : .primary)
                    .frame(width: 48, height: 48)
                    .background(
                        tinted ? AnyShapeStyle(Color(red: 0, green: 0.39, blue: 1).opacity(0.12)) : AnyShapeStyle(.regularMaterial),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private func actionLink(icon: String, label: String, url: URL) -> some View {
        Link(destination: url) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 48, height: 48)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - AI Insight

    @ViewBuilder
    private func insightSection(_ detail: SpotDetail) -> some View {
        let hasStructured = detail.knownFor != nil || detail.mustTry != nil || detail.proTip != nil || detail.vibe != nil
        let hasSummary = detail.perplexitySummary != nil
        let hasEditorial = detail.editorialSummary != nil

        if hasStructured || hasSummary || hasEditorial {
            VStack(alignment: .leading, spacing: 14) {
                Label("The Lowdown", systemImage: "sparkles")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red: 0, green: 0.39, blue: 1))

                if let knownFor = detail.knownFor {
                    insightRow(label: "Known for", text: knownFor)
                }

                if let mustTry = detail.mustTry, !mustTry.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Must try")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 6) {
                            ForEach(mustTry, id: \.self) { item in
                                Text(item)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(.orange.opacity(0.12), in: Capsule())
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }

                if let proTip = detail.proTip {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .padding(.top, 2)
                        insightRow(label: "Pro tip", text: proTip)
                    }
                }

                if let vibe = detail.vibe {
                    insightRow(label: "Vibe", text: vibe)
                }

                // Fallback: raw Perplexity summary
                if !hasStructured, let summary = detail.perplexitySummary {
                    Text(summary)
                        .font(.subheadline)
                }

                // Fallback: editorial summary when no Perplexity data at all
                if !hasStructured && !hasSummary, let editorial = detail.editorialSummary {
                    Text(editorial)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private func insightRow(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.subheadline)
        }
    }

    // MARK: - Service & Attributes

    private func hasAnyService(_ detail: SpotDetail) -> Bool {
        detail.dineIn == true || detail.takeout == true || detail.delivery == true ||
        detail.reservable == true || detail.servesBeer == true || detail.servesWine == true ||
        detail.servesVegetarianFood == true || detail.wheelchairAccessible == true
    }

    private func serviceSection(_ detail: SpotDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Details")
                .font(.subheadline.weight(.bold))

            FlowLayout(spacing: 8) {
                if detail.dineIn == true { serviceChip("Dine-in", icon: "fork.knife") }
                if detail.takeout == true { serviceChip("Takeout", icon: "bag") }
                if detail.delivery == true { serviceChip("Delivery", icon: "car.side") }
                if detail.reservable == true { serviceChip("Reservable", icon: "calendar") }
                if detail.servesBeer == true { serviceChip("Beer", icon: "mug") }
                if detail.servesWine == true { serviceChip("Wine", icon: "wineglass") }
                if detail.servesVegetarianFood == true { serviceChip("Vegetarian", icon: "leaf") }
                if detail.wheelchairAccessible == true { serviceChip("Accessible", icon: "figure.roll") }
            }

            // Meal times
            let meals = mealTimes(detail)
            if !meals.isEmpty {
                HStack(spacing: 4) {
                    Text("Serves:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(meals.joined(separator: ", "))
                        .font(.caption.weight(.medium))
                }
            }
        }
    }

    private func serviceChip(_ label: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6), in: Capsule())
    }

    private func mealTimes(_ detail: SpotDetail) -> [String] {
        var meals: [String] = []
        if detail.servesBreakfast == true { meals.append("Breakfast") }
        if detail.servesLunch == true { meals.append("Lunch") }
        if detail.servesDinner == true { meals.append("Dinner") }
        return meals
    }

    // MARK: - Hours

    private func hoursSection(_ hours: [String], isOpen: Bool?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Hours")
                    .font(.subheadline.weight(.bold))
                Spacer()
                if let isOpen {
                    Text(isOpen ? "Open now" : "Closed")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isOpen ? .green : .red)
                }
            }

            // Today's hours
            if let today = todayHours(from: hours) {
                Text(today)
                    .font(.subheadline.weight(.medium))
            }

            // All hours (expandable)
            if showAllHours {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(hours, id: \.self) { line in
                        let isToday = isTodayLine(line)
                        Text(line)
                            .font(.caption)
                            .foregroundStyle(isToday ? .primary : .secondary)
                            .fontWeight(isToday ? .semibold : .regular)
                    }
                }
                .padding(.top, 2)
            }

            Button {
                withAnimation(.snappy) {
                    showAllHours.toggle()
                }
            } label: {
                Text(showAllHours ? "Hide hours" : "See all hours")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(red: 0, green: 0.39, blue: 1))
            }
        }
    }

    // MARK: - Reviews

    private func reviewsSection(_ reviews: [SpotReview]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reviews")
                .font(.subheadline.weight(.bold))

            ForEach(reviews) { review in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        HStack(spacing: 2) {
                            ForEach(0..<5, id: \.self) { i in
                                Image(systemName: i < Int(review.rating) ? "star.fill" : "star")
                                    .font(.system(size: 10))
                                    .foregroundStyle(i < Int(review.rating) ? .orange : Color(.systemGray4))
                            }
                        }
                        Spacer()
                        Text(review.time)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Text(review.text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Helpers

    private var distanceText: String? {
        guard let userCoord = locationManager.coordinate else { return nil }
        let spotLocation = CLLocation(latitude: spot.latitude, longitude: spot.longitude)
        let userLocation = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let distanceMiles = userLocation.distance(from: spotLocation) / 1609.34
        if distanceMiles < 0.1 {
            return "Right here"
        } else if distanceMiles < 10 {
            return String(format: "%.1f mi", distanceMiles)
        } else {
            return String(format: "%.0f mi", distanceMiles)
        }
    }

    private func todayHours(from hours: [String]) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let today = formatter.string(from: Date())
        return hours.first { $0.hasPrefix(today) }
    }

    private func isTodayLine(_ line: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let today = formatter.string(from: Date())
        return line.hasPrefix(today)
    }
}

