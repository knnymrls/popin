import SwiftUI

struct PlanCard: View {
    let plan: PlanData
    var onTapStop: ((String) -> Void)?
    var onShare: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text(plan.title)
                    .font(.headline.weight(.bold))

                Text(plan.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Stops
            VStack(spacing: 0) {
                ForEach(Array(plan.stops.enumerated()), id: \.element.id) { index, stop in
                    Button {
                        onTapStop?(stop.name)
                    } label: {
                        PlanStopRow(
                            stop: stop,
                            index: index,
                            isLast: index == plan.stops.count - 1
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)

            // Footer
            HStack(spacing: 16) {
                Label(plan.totalTime, systemImage: "clock")
                Label(plan.totalCost, systemImage: "dollarsign.circle")
                Spacer()

                if onShare != nil {
                    Button {
                        onShare?()
                    } label: {
                        Label("Share", systemImage: "paperplane.fill")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(red: 0, green: 0.39, blue: 1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Plan Stop Row

private struct PlanStopRow: View {
    let stop: PlanStopData
    let index: Int
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0, green: 0.39, blue: 1))
                        .frame(width: 24, height: 24)
                    Text("\(index + 1)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                }

                if !isLast {
                    Rectangle()
                        .fill(Color(red: 0, green: 0.39, blue: 1).opacity(0.15))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 24)

            // Photo
            if let photoUrl = stop.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay {
                            Text(stop.emoji)
                                .font(.title3)
                        }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                // Emoji fallback
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0, green: 0.39, blue: 1).opacity(0.08))
                        .frame(width: 56, height: 56)
                    Text(stop.emoji)
                        .font(.title2)
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(stop.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 6) {
                    Text(stop.time)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.quaternary)
                    Text(stop.cost)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }

                Text(stop.note)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.bottom, isLast ? 4 : 12)
    }
}
