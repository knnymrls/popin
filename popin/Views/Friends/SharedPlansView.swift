import SwiftUI

struct SharedPlansView: View {
    let viewModel: FriendsViewModel
    let userId: String

    var body: some View {
        List {
            // Pending hangout invites
            let pendingHangouts = viewModel.sharedPlans.filter { $0.isHangout && $0.isPending }
            if !pendingHangouts.isEmpty {
                Section("Hangout Invites") {
                    ForEach(pendingHangouts) { item in
                        SharedPlanRow(item: item) {
                            HStack(spacing: 8) {
                                Button {
                                    viewModel.respondToSharedPlan(item.id, userId: userId, accept: true)
                                } label: {
                                    Text("I'm in!")
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(.orange)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    viewModel.respondToSharedPlan(item.id, userId: userId, accept: false)
                                } label: {
                                    Text("Pass")
                                        .font(.caption.weight(.medium))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(.secondary.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            // Accepted hangouts
            let acceptedHangouts = viewModel.sharedPlans.filter { $0.isHangout && $0.rsvp == "accepted" }
            if !acceptedHangouts.isEmpty {
                Section("Upcoming Hangouts") {
                    ForEach(acceptedHangouts) { item in
                        SharedPlanRow(item: item) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("You're going")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
            }

            // Recommendations
            let recommendations = viewModel.sharedPlans.filter { $0.isRecommendation }
            if !recommendations.isEmpty {
                Section("Recommendations") {
                    ForEach(recommendations) { item in
                        SharedPlanRow(item: item) {
                            HStack(spacing: 4) {
                                Image(systemName: "hand.thumbsup")
                                    .foregroundStyle(.blue)
                                Text("Shared spot")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            // Declined
            let declined = viewModel.sharedPlans.filter { $0.rsvp == "declined" }
            if !declined.isEmpty {
                Section("Declined") {
                    ForEach(declined) { item in
                        SharedPlanRow(item: item) {
                            Text("Declined")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if viewModel.sharedPlans.isEmpty {
                ContentUnavailableView(
                    "No Shared Plans",
                    systemImage: "map",
                    description: Text("When friends share plans with you, they'll appear here")
                )
            }
        }
        .navigationTitle("Shared Plans")
    }
}

// MARK: - Shared Plan Row

private struct SharedPlanRow<Actions: View>: View {
    let item: SharedPlanItem
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(item.displaySenderEmoji)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(item.displaySenderName)
                            .font(.subheadline.weight(.semibold))
                        Text(item.typeLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(item.planTitle ?? "Untitled Plan")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                }
            }

            if let summary = item.planSummary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if let message = item.message, !message.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.caption)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }

            actions()
        }
        .padding(.vertical, 4)
    }
}
