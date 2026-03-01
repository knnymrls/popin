import Combine
import ConvexMobile
import SwiftUI

@Observable
final class ProfileViewModel {

    // MARK: - State

    var profile: TasteProfile?
    var isLoading = true
    var isSaving = false
    var isEditing = false

    // MARK: - Editable Fields

    var name = ""
    var phoneNumber = ""
    var avatarEmoji = "😊"
    var profileImageUrl = ""
    var budget: String?
    var vibes: [String] = []
    var foodLoves: [String] = []
    var foodAvoids: [String] = []
    var activities: [String] = []
    var dealbreakers: [String] = []
    var notes = ""

    // MARK: - Derived

    var hasProfile: Bool { profile != nil }

    // MARK: - Private

    private var cancellable: AnyCancellable?
    private var hasInitialized = false

    // MARK: - Subscription

    func startSubscription(userId: String) {
        guard cancellable == nil else { return }

        let publisher: AnyPublisher<TasteProfile?, ClientError> = convex.subscribe(
            to: "profiles:get",
            with: ["userId": userId]
        )

        cancellable = publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Profile subscription failed: \(error)")
                        self?.isLoading = false
                    }
                },
                receiveValue: { [weak self] profile in
                    guard let self else { return }
                    self.profile = profile
                    if let profile, !self.hasInitialized {
                        self.populateFields(from: profile)
                        self.hasInitialized = true
                    }
                    self.isLoading = false
                }
            )
    }

    func stopSubscription() {
        cancellable?.cancel()
        cancellable = nil
    }

    // MARK: - Save

    func save(userId: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isSaving = true

        Task {
            do {
                let vibesEnc: [ConvexEncodable?] = vibes.map { $0 }
                let foodLovesEnc: [ConvexEncodable?] = foodLoves.map { $0 }
                let foodAvoidsEnc: [ConvexEncodable?] = foodAvoids.map { $0 }
                let activitiesEnc: [ConvexEncodable?] = activities.map { $0 }
                let dealbreakersEnc: [ConvexEncodable?] = dealbreakers.map { $0 }

                let trimmedPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                var args: [String: ConvexEncodable?] = [
                    "userId": userId,
                    "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                    "avatarEmoji": avatarEmoji,
                    "vibes": vibesEnc,
                    "foodLoves": foodLovesEnc,
                    "foodAvoids": foodAvoidsEnc,
                    "activities": activitiesEnc,
                    "dealbreakers": dealbreakersEnc,
                ]
                // Only include optional fields when non-nil (Convex rejects null for v.optional)
                if !trimmedPhone.isEmpty { args["phoneNumber"] = trimmedPhone }
                if let budget { args["budget"] = budget }
                if !notes.isEmpty { args["notes"] = notes }
                if !profileImageUrl.isEmpty { args["profileImageUrl"] = profileImageUrl }
                try await convex.mutation("profiles:upsert", with: args)
                hasInitialized = false // Let subscription refresh
            } catch {
                print("Profile save failed: \(error)")
            }

            isSaving = false
            isEditing = false
        }
    }

    // MARK: - Seed

    func seedProfile(userId: String, name: String, preset: String) {
        isSaving = true
        Task {
            do {
                let args: [String: ConvexEncodable?] = [
                    "userId": userId,
                    "name": name,
                    "preset": preset,
                ]
                let _: SeedResult = try await convex.mutation(
                    "profiles:seedProfile",
                    with: args
                )
            } catch {
                print("Seed profile failed: \(error)")
            }
            isSaving = false
        }
    }

    // MARK: - Edit Helpers

    func beginEditing() {
        if let profile {
            populateFields(from: profile)
        }
        isEditing = true
    }

    func cancelEditing() {
        if let profile {
            populateFields(from: profile)
        } else {
            resetFields()
        }
        isEditing = false
    }

    func toggleTag(_ tag: String, in list: inout [String]) {
        if let index = list.firstIndex(of: tag) {
            list.remove(at: index)
        } else {
            list.append(tag)
        }
    }

    // MARK: - Private

    private func populateFields(from profile: TasteProfile) {
        name = profile.name
        phoneNumber = profile.phoneNumber ?? ""
        avatarEmoji = profile.avatarEmoji ?? "😊"
        profileImageUrl = profile.profileImageUrl ?? ""
        budget = profile.budget
        vibes = profile.vibes
        foodLoves = profile.foodLoves
        foodAvoids = profile.foodAvoids
        activities = profile.activities
        dealbreakers = profile.dealbreakers
        notes = profile.notes ?? ""
    }

    private func resetFields() {
        name = ""
        phoneNumber = ""
        avatarEmoji = "😊"
        profileImageUrl = ""
        budget = nil
        vibes = []
        foodLoves = []
        foodAvoids = []
        activities = []
        dealbreakers = []
        notes = ""
    }
}

// MARK: - Preset Options

enum ProfilePresets {
    static let vibes = [
        "chill", "cozy", "trendy", "dive-y", "upscale", "lively",
        "romantic", "hipster", "casual", "bougie", "adventurous", "lowkey",
    ]

    static let foodLoves = [
        "tacos", "ramen", "pizza", "sushi", "burgers", "thai",
        "indian", "italian", "mexican", "bbq", "korean", "vietnamese",
        "mediterranean", "brunch", "coffee", "dessert", "seafood",
        "steak", "vegan", "wings",
    ]

    static let foodAvoids = [
        "spicy", "seafood", "sushi", "gluten", "dairy",
        "meat", "pork", "shellfish", "nuts", "eggs",
    ]

    static let activities = [
        "live music", "bars", "clubs", "hiking", "shopping",
        "movies", "bowling", "karaoke", "arcade", "museums",
        "comedy shows", "board games", "wine tasting", "breweries",
        "coffee shops", "thrifting", "concerts", "sports", "outdoor dining",
    ]

    static let dealbreakers = [
        "too crowded", "too loud", "no parking", "cash only",
        "slow service", "bad wifi", "no outdoor seating",
        "long wait", "expensive", "far away",
    ]

    static let budgets = ["cheap", "moderate", "splurge"]
}
