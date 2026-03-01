import SwiftUI

struct PlanCard: View {
    let plan: PlanData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "map.fill")
                    .foregroundStyle(.blue)
                Text(plan.title)
                    .font(.subheadline.weight(.semibold))
            }

            Text(plan.summary)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Stops
            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.stops) { stop in
                    HStack(alignment: .top, spacing: 10) {
                        Text(stop.emoji)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(stop.name)
                                .font(.caption.weight(.semibold))

                            HStack(spacing: 6) {
                                Text(stop.time)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("·")
                                    .foregroundStyle(.secondary)
                                Text(stop.cost)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Text(stop.note)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Divider()

            // Footer
            HStack {
                Label(plan.totalTime, systemImage: "clock")
                Spacer()
                Label(plan.totalCost, systemImage: "dollarsign.circle")
            }
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
