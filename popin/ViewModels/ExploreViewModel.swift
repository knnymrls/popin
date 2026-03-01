import Combine
import ConvexMobile
import MapKit
import SwiftUI

enum ExploreMode: Equatable {
    case chat
    case searching
}

@Observable
final class ExploreViewModel: NSObject, MKLocalSearchCompleterDelegate {

    // MARK: - Chat State

    var messages: [ChatMessage] = []
    var chatInput = ""
    var isSending = false
    var mentionedFriends: [Friend] = []
    var hasGreeted = false

    // MARK: - Spot Detail State

    var selectedSpot: SpotData?
    var spotDetail: SpotDetail?
    var isLoadingDetail = false
    var highlightedSpotId: String?

    // MARK: - Map State

    var nearbySpots: [SpotData] = []
    var planMapSpots: [SpotData] = []
    var isLoadingNearby = false

    // MARK: - Search State

    var mode: ExploreMode = .chat
    var searchText = ""
    var completions: [MKLocalSearchCompletion] = []
    var selectedCategory: SpotCategory?
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    // MARK: - Derived

    /// All spots for the map: nearby + chat results, deduplicated
    var spots: [SpotData] {
        let chatSpots = messages.compactMap { message in
            if case .spots(_, let spots) = message {
                return spots
            }
            return nil
        }.flatMap { $0 }

        // Merge nearby + chat, dedup by placeId
        var seen = Set<String>()
        var result: [SpotData] = []
        for spot in chatSpots + nearbySpots + planMapSpots {
            if seen.contains(spot.placeId) { continue }
            seen.insert(spot.placeId)
            result.append(spot)
        }
        return result
    }

    /// Top-rated spots that are "popping" — shown in the floating card
    var poppingSpots: [SpotData] {
        spots
            .filter { ($0.rating ?? 0) >= 4.3 }
            .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Private

    private let completer = MKLocalSearchCompleter()
    private var chatTask: Task<Void, Never>?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    // MARK: - Mentions

    func addMention(_ friend: Friend) {
        guard !mentionedFriends.contains(where: { $0.userId == friend.userId }) else { return }
        mentionedFriends.append(friend)
    }

    func removeMention(_ friend: Friend) {
        mentionedFriends.removeAll { $0.userId == friend.userId }
    }

    // MARK: - Chat

    func sendGreeting(userId: String?, latitude: Double, longitude: Double) {
        guard !hasGreeted else { return }
        hasGreeted = true

        let greetingPrompt = "what's popping right now? search for what's open and good nearby and give me your top pick."

        sendMessage(
            text: greetingPrompt,
            userId: userId,
            latitude: latitude,
            longitude: longitude,
            showUserMessage: false
        )
    }

    func sendMessage(
        text: String,
        userId: String?,
        latitude: Double,
        longitude: Double,
        showUserMessage: Bool = true
    ) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if showUserMessage {
            messages.append(.user(text: trimmed))
        }
        chatInput = ""

        let loadingId = UUID()
        messages.append(.loading(id: loadingId, stage: "Searching nearby..."))
        isSending = true

        // Progressive loading stages
        let stages = ["Checking what's open...", "Picking the best spots...", "Almost done..."]
        var stageIndex = 0
        let loadingTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] timer in
            guard let self, self.isSending, stageIndex < stages.count else {
                timer.invalidate()
                return
            }
            if let idx = self.messages.firstIndex(where: {
                if case .loading(let id, _) = $0 { return id == loadingId }
                return false
            }) {
                self.messages[idx] = .loading(id: loadingId, stage: stages[stageIndex])
            }
            stageIndex += 1
        }

        // Build messages array for Convex (text-only conversation history)
        var convexMessages: [ConvexEncodable?] = []
        for msg in messages {
            switch msg {
            case .user(_, let t):
                let dict: [String: ConvexEncodable?] = ["role": "user", "content": t]
                convexMessages.append(dict)
            case .assistant(_, let t):
                let dict: [String: ConvexEncodable?] = ["role": "assistant", "content": t]
                convexMessages.append(dict)
            default:
                break
            }
        }

        // Always include current message (needed when showUserMessage is false, e.g. greeting)
        if !showUserMessage {
            let dict: [String: ConvexEncodable?] = ["role": "user", "content": trimmed]
            convexMessages.append(dict)
        }

        // Capture mentioned friend IDs and clear
        let friendIds: [ConvexEncodable?] = mentionedFriends.map { $0.userId as ConvexEncodable? }
        let hasMentions = !mentionedFriends.isEmpty
        mentionedFriends.removeAll()

        chatTask?.cancel()
        chatTask = Task {
            do {
                var args: [String: ConvexEncodable?] = [
                    "messages": convexMessages,
                    "latitude": latitude,
                    "longitude": longitude,
                ]
                args["userId"] = userId
                if hasMentions {
                    args["friendIds"] = friendIds
                }

                let response: ChatResponse = try await convex.action(
                    "ai:chat",
                    with: args
                )

                // Remove loading indicator
                messages.removeAll { msg in
                    if case .loading(let id, _) = msg { return id == loadingId }
                    return false
                }

                // Append plan if present
                let hasPlan = response.plan != nil
                if let planData = response.plan {
                    messages.append(.plan(plan: planData))
                }

                // Append spots for map + chat cards (skip cards when a plan exists)
                if let spotData = response.spots, !spotData.isEmpty {
                    if hasPlan {
                        // Add to map only — don't show as chat cards
                        planMapSpots = spotData
                    } else {
                        messages.append(.spots(spots: spotData))
                    }
                    zoomToFitSpots()
                }

                // Append assistant text (strip markdown since chat is plain text)
                if !response.text.isEmpty {
                    let cleanText = response.text
                        .replacingOccurrences(of: "**", with: "")
                        .replacingOccurrences(of: "__", with: "")
                        .replacingOccurrences(of: "~~", with: "")
                    messages.append(.assistant(text: cleanText))
                }

                // Add follow-up suggestions after AI responds
                appendSuggestionsIfNeeded()
            } catch is CancellationError {
                messages.removeAll { msg in
                    if case .loading(let id, _) = msg { return id == loadingId }
                    return false
                }
            } catch {
                print("Chat failed: \(error)")
                messages.removeAll { msg in
                    if case .loading(let id, _) = msg { return id == loadingId }
                    return false
                }
                messages.append(.assistant(text: "Something went wrong. Try again."))
            }

            loadingTimer.invalidate()
            isSending = false
        }
    }

    private func appendSuggestionsIfNeeded() {
        // Remove any existing suggestion chips
        messages.removeAll { msg in
            if case .suggestions = msg { return true }
            return false
        }

        // Check what the latest AI response included
        let hasSpots = messages.contains { if case .spots = $0 { return true }; return false }
        let hasPlan = messages.contains { if case .plan = $0 { return true }; return false }

        var suggestions: [String] = []
        if hasPlan {
            suggestions = ["swap a stop", "make it cheaper", "add drinks"]
        } else if hasSpots {
            suggestions = ["plan it out", "something cheaper", "different vibe"]
        } else {
            // AI is asking a question — don't show chips, let user type their answer
            return
        }

        messages.append(.suggestions(suggestions: suggestions))
    }

    // MARK: - Nearby Spots

    private var lastLoadedCategory: SpotCategory?
    private var lastCoordinate: (lat: Double, lng: Double)?

    func loadNearbySpots(latitude: Double, longitude: Double) {
        lastCoordinate = (latitude, longitude)
        // Skip if already loaded this category
        guard lastLoadedCategory != selectedCategory || nearbySpots.isEmpty else { return }
        fetchNearbySpots(latitude: latitude, longitude: longitude, category: selectedCategory)
    }

    func filterByCategory(_ category: SpotCategory?) {
        selectedCategory = category
        guard let coord = lastCoordinate else { return }
        fetchNearbySpots(latitude: coord.lat, longitude: coord.lng, category: category)
    }

    private func fetchNearbySpots(latitude: Double, longitude: Double, category: SpotCategory?) {
        guard !isLoadingNearby else { return }
        isLoadingNearby = true
        lastLoadedCategory = category

        Task {
            do {
                var args: [String: ConvexEncodable?] = [
                    "latitude": latitude,
                    "longitude": longitude,
                ]
                if let category {
                    args["type"] = category.googlePlaceType
                }
                let spots: [SpotData] = try await convex.action(
                    "ai:getNearbySpots",
                    with: args
                )
                self.nearbySpots = spots
            } catch {
                print("Nearby spots failed: \(error)")
            }
            isLoadingNearby = false
        }
    }

    // MARK: - Map

    func zoomToFitSpots() {
        let allSpots = spots
        guard !allSpots.isEmpty else { return }

        var minLat = allSpots[0].latitude
        var maxLat = allSpots[0].latitude
        var minLng = allSpots[0].longitude
        var maxLng = allSpots[0].longitude

        for spot in allSpots {
            minLat = min(minLat, spot.latitude)
            maxLat = max(maxLat, spot.latitude)
            minLng = min(minLng, spot.longitude)
            maxLng = max(maxLng, spot.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )

        let latDelta = max((maxLat - minLat) * 1.5, 0.01)
        let lngDelta = max((maxLng - minLng) * 1.5, 0.01)

        withAnimation(.easeInOut(duration: 0.5)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
            ))
        }
    }

    func highlightSpot(_ spot: SpotData) {
        highlightedSpotId = spot.placeId

        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            ))
        }
    }

    // MARK: - Spot Detail

    func selectSpot(_ spot: SpotData) {
        highlightedSpotId = spot.placeId
        selectedSpot = spot
        spotDetail = nil
        isLoadingDetail = true

        withAnimation(.easeInOut(duration: 0.3)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: spot.latitude, longitude: spot.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            ))
        }

        Task {
            do {
                let args: [String: ConvexEncodable?] = [
                    "placeId": spot.placeId,
                ]
                let detail: SpotDetail = try await convex.action(
                    "ai:getSpotDetail",
                    with: args
                )
                self.spotDetail = detail
            } catch {
                print("Spot detail failed: \(error)")
            }
            isLoadingDetail = false
        }
    }

    func dismissSpotDetail() {
        selectedSpot = nil
        spotDetail = nil
        isLoadingDetail = false
        highlightedSpotId = nil
    }

    // MARK: - Search Mode

    func beginSearch() {
        mode = .searching
    }

    func cancelSearch() {
        searchText = ""
        completions = []
        mode = .chat
    }

    func updateSearchText(_ text: String) {
        searchText = text
        if text.isEmpty {
            completions = []
        } else {
            completer.queryFragment = text
        }
    }

    // MARK: - Place Selection

    func selectCompletion(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        Task {
            guard let response = try? await search.start(),
                  let item = response.mapItems.first else { return }
            let coordinate = item.location.coordinate
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            ))
            mode = .chat
            searchText = ""
            completions = []
        }
    }

    // MARK: - MKLocalSearchCompleterDelegate

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        MainActor.assumeIsolated {
            self.completions = completer.results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Silently fail
    }
}
