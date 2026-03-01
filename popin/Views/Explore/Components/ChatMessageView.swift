import SwiftUI

struct ChatMessageView: View {
    let message: ChatMessage
    var onTapSpot: ((SpotData) -> Void)?
    var onTapPlanSpot: ((String) -> Void)?
    var onSharePlan: ((PlanData) -> Void)?
    var onTapSuggestion: ((String) -> Void)?

    var body: some View {
        switch message {
        case .user(_, let text):
            userBubble(text)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
        case .assistant(_, let text):
            assistantBubble(text)
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .opacity
                ))
        case .spots(_, let spots):
            spotsRow(spots)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
        case .plan(_, let plan):
            PlanCard(plan: plan, onTapStop: onTapPlanSpot, onShare: {
                onSharePlan?(plan)
            })
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .opacity
                ))
        case .loading(_, let stage):
            loadingView(stage)
                .transition(.opacity)
        case .suggestions(_, let suggestions):
            suggestionsRow(suggestions)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
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
                .background(Color(red: 0, green: 0.39, blue: 1), in: RoundedRectangle(cornerRadius: 18))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Assistant Bubble

    @ViewBuilder
    private func assistantBubble(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 0) {
            Text(text)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
            Spacer(minLength: 40)
        }
    }

    // MARK: - Spots Row

    @ViewBuilder
    private func spotsRow(_ spots: [SpotData]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                    SpotDataCard(spot: spot, rank: index + 1)
                        .frame(width: 200)
                        .onTapGesture {
                            onTapSpot?(spot)
                        }
                }
            }
        }
    }

    // MARK: - Suggestions Row

    @ViewBuilder
    private func suggestionsRow(_ suggestions: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button {
                        onTapSuggestion?(suggestion)
                    } label: {
                        Text(suggestion)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color(red: 0, green: 0.39, blue: 1).opacity(0.2), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Loading

    @ViewBuilder
    private func loadingView(_ stage: String) -> some View {
        HStack(spacing: 8) {
            LoadingPulseView()
            Text(stage)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Loading Pulse Animation

struct LoadingPulseView: View {
    @State private var isAnimating = false

    var body: some View {
        Circle()
            .fill(Color(red: 0, green: 0.39, blue: 1))
            .frame(width: 8, height: 8)
            .scaleEffect(isAnimating ? 1.3 : 0.7)
            .opacity(isAnimating ? 1 : 0.4)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear { isAnimating = true }
    }
}

// MARK: - Spot Data Card (compact, for chat)

struct SpotDataCard: View {
    let spot: SpotData
    var rank: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo with rank badge overlay
            ZStack(alignment: .topLeading) {
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
                    .frame(height: 110)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 110)
                        .overlay {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                }

                // Rank badge
                if rank > 0 {
                    Text("#\(rank)")
                        .font(.caption2.weight(.heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(red: 0, green: 0.39, blue: 1), in: Capsule())
                        .padding(8)
                }
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 12))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(spot.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    if let rating = spot.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.caption2.weight(.medium))
                        }
                    }

                    if let price = spot.priceLevel {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(String(repeating: "$", count: Int(price)))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Text(spot.address)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}
