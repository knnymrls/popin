import SwiftUI

private let accentBlue = Color(red: 0, green: 0.39, blue: 1)

struct SharedPlansView: View {
    let viewModel: FriendsViewModel
    let userId: String

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Pending hangout invites
                let pendingHangouts = viewModel.sharedPlans.filter { $0.isHangout && $0.isPending }
                if !pendingHangouts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader(icon: "envelope.fill", title: "invites")

                        ForEach(pendingHangouts) { item in
                            planCard(item: item) {
                                HStack(spacing: 8) {
                                    Button {
                                        viewModel.respondToSharedPlan(item.id, userId: userId, accept: true)
                                    } label: {
                                        Text("i'm in")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 7)
                                            .background(accentBlue, in: Capsule())
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        viewModel.respondToSharedPlan(item.id, userId: userId, accept: false)
                                    } label: {
                                        Text("pass")
                                            .font(.caption.weight(.medium))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 7)
                                            .background(.ultraThinMaterial, in: Capsule())
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
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader(icon: "calendar", title: "upcoming")

                        ForEach(acceptedHangouts) { item in
                            planCard(item: item) {
                                HStack(spacing: 5) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(.green)
                                    Text("you're going")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }

                // Recommendations
                let recommendations = viewModel.sharedPlans.filter { $0.isRecommendation }
                if !recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader(icon: "hand.thumbsup.fill", title: "recommendations")

                        ForEach(recommendations) { item in
                            planCard(item: item) {
                                HStack(spacing: 5) {
                                    Image(systemName: "sparkles")
                                        .font(.caption2)
                                        .foregroundStyle(accentBlue)
                                    Text("shared spot")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                // Declined
                let declined = viewModel.sharedPlans.filter { $0.rsvp == "declined" }
                if !declined.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionHeader(icon: "xmark.circle", title: "declined")

                        ForEach(declined) { item in
                            planCard(item: item) {
                                Text("declined")
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if viewModel.sharedPlans.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "map")
                            .font(.system(size: 32))
                            .foregroundStyle(.tertiary)
                        Text("no shared plans yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationTitle("Plans")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(accentBlue)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.leading, 4)
    }

    private func planCard<Actions: View>(item: SharedPlanItem, @ViewBuilder actions: () -> Actions) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AvatarView(
                    imageUrl: item.senderImageUrl,
                    emoji: item.displaySenderEmoji,
                    size: 36
                )

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(item.displaySenderName)
                            .font(.caption.weight(.semibold))
                        Text(item.typeLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text(item.planTitle ?? "Untitled Plan")
                        .font(.subheadline.weight(.semibold))
                }

                Spacer()
            }

            if let summary = item.planSummary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let message = item.message, !message.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(accentBlue)
                    Text(message)
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }

            actions()
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
