import Combine
import ConvexMobile
import SwiftUI

@Observable
final class SavedSpotsViewModel {

    // MARK: - State

    var favorites: [Favorite] = []
    var isLoading = true

    // MARK: - Private

    private var cancellable: AnyCancellable?

    // MARK: - Subscription

    func startSubscription(userId: String) {
        guard cancellable == nil else { return }

        let publisher: AnyPublisher<[Favorite], ClientError> = convex.subscribe(
            to: "favorites:list",
            with: ["userId": userId]
        )

        cancellable = publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Favorites subscription failed: \(error)")
                        self?.isLoading = false
                    }
                },
                receiveValue: { [weak self] favorites in
                    guard let self else { return }
                    self.favorites = favorites
                    self.isLoading = false
                }
            )
    }

    func stopSubscription() {
        cancellable?.cancel()
        cancellable = nil
    }

    // MARK: - Actions

    func saveFavorite(spot: SpotData, userId: String) {
        Task {
            do {
                var args: [String: ConvexEncodable?] = [
                    "userId": userId,
                    "name": spot.name,
                    "address": spot.address,
                    "types": [] as [ConvexEncodable?],
                ]
                if let photoUrl = spot.photoUrl { args["photoUrl"] = photoUrl }
                if let rating = spot.rating { args["rating"] = rating }
                if let priceLevel = spot.priceLevel { args["priceLevel"] = priceLevel }

                try await convex.mutation("favorites:add", with: args)
            } catch {
                print("Save favorite failed: \(error)")
            }
        }
    }

    func removeFavorite(name: String, userId: String) {
        Task {
            do {
                let args: [String: ConvexEncodable?] = [
                    "userId": userId,
                    "name": name,
                ]
                try await convex.mutation("favorites:remove", with: args)
            } catch {
                print("Remove favorite failed: \(error)")
            }
        }
    }

    func isSaved(_ name: String) -> Bool {
        favorites.contains { $0.name == name }
    }
}
