import SwiftUI

struct SavedSpotsView: View {
    @Environment(AuthManager.self) private var auth
    @State private var vm = SavedSpotsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.favorites.isEmpty {
                    emptyState
                } else {
                    savedList
                }
            }
            .navigationTitle("Saved")
        }
        .onAppear {
            if let userId = auth.userId {
                vm.startSubscription(userId: userId)
            }
        }
        .onDisappear {
            vm.stopSubscription()
        }
    }

    // MARK: - Saved List

    private var savedList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(vm.favorites) { favorite in
                    SavedSpotCard(favorite: favorite) {
                        if let userId = auth.userId {
                            vm.removeFavorite(name: favorite.name, userId: userId)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("no saved spots yet")
                .font(.title3.weight(.bold))

            Text("when you find a spot you love, tap the bookmark to save it here")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Saved Spot Card

private struct SavedSpotCard: View {
    let favorite: Favorite
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Photo
            if let photoUrl = favorite.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                }
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
                    .frame(width: 72, height: 72)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(favorite.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if let rating = favorite.rating {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let price = favorite.priceLevel {
                        Text(String(repeating: "$", count: Int(price)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(favorite.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Remove button
            Button(action: onRemove) {
                Image(systemName: "bookmark.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
