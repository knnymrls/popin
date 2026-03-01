import Combine
import SwiftUI

struct WhatsPopppingCard: View {
    let spots: [SpotData]
    var onTap: ((SpotData) -> Void)?

    @State private var currentIndex = 0

    private var currentSpot: SpotData? {
        guard !spots.isEmpty else { return nil }
        return spots[currentIndex % spots.count]
    }

    var body: some View {
        if let spot = currentSpot {
            Button {
                onTap?(spot)
            } label: {
                HStack(spacing: 8) {
                    Text("\u{1F525}")
                        .font(.system(size: 16))

                    if let photoUrl = spot.photoUrl, let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Circle().fill(Color(.systemGray5))
                        }
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(spot.name)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                        Text("popping rn")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let rating = spot.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.orange)
                            Text(String(format: "%.1f", rating))
                                .font(.caption2.weight(.bold))
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .frame(maxWidth: 280)
                .glassEffect(.regular, in: .capsule)
            }
            .buttonStyle(.plain)
            .id(spot.placeId)
            .transition(.asymmetric(
                insertion: .push(from: .trailing),
                removal: .push(from: .leading)
            ))
            .onReceive(
                Timer.publish(every: 5, on: .main, in: .common).autoconnect()
            ) { _ in
                guard spots.count > 1 else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentIndex = (currentIndex + 1) % spots.count
                }
            }
        }
    }
}
