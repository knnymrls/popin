import SwiftUI

struct ChatMessageView: View {
    let message: ChatMessage
    var onTapSpot: ((SpotData) -> Void)?

    var body: some View {
        switch message {
        case .user(_, let text):
            userBubble(text)
        case .assistant(_, let text):
            assistantBubble(text)
        case .spots(_, let spots):
            spotsRow(spots)
        case .plan(_, let plan):
            PlanCard(plan: plan)
                .padding(.trailing, 40)
        case .loading(_, let stage):
            loadingView(stage)
        }
    }

    // MARK: - User Bubble

    @ViewBuilder
    private func userBubble(_ text: String) -> some View {
        HStack {
            Spacer(minLength: 60)
            Text(text)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.blue, in: RoundedRectangle(cornerRadius: 18))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Assistant Bubble

    @ViewBuilder
    private func assistantBubble(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            Spacer(minLength: 60)
        }
    }

    // MARK: - Spots Row

    @ViewBuilder
    private func spotsRow(_ spots: [SpotData]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(spots) { spot in
                    SpotDataCard(spot: spot)
                        .frame(width: 220)
                        .onTapGesture {
                            onTapSpot?(spot)
                        }
                }
            }
        }
    }

    // MARK: - Loading

    @ViewBuilder
    private func loadingView(_ stage: String) -> some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
            Text(stage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

// MARK: - Spot Data Card (compact, for chat)

struct SpotDataCard: View {
    let spot: SpotData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Photo
            if let photoUrl = spot.photoUrl, let url = URL(string: photoUrl) {
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
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Text(spot.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)

            HStack(spacing: 4) {
                if let rating = spot.rating {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(String(format: "%.1f", rating))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let price = spot.priceLevel {
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(String(repeating: "$", count: Int(price)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(spot.address)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}
