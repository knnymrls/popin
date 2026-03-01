import SwiftUI

private let accentBlue = Color(red: 0, green: 0.39, blue: 1)

struct FriendsListView: View {
    @Environment(AuthManager.self) private var auth
    @State private var viewModel = FriendsViewModel()
    @State private var showInvite = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.friends.isEmpty && viewModel.incomingRequests.isEmpty {
                    emptyState
                } else {
                    friendsContent
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showInvite) {
                if let userId = auth.userId {
                    InviteFriendsView(
                        userId: userId,
                        viewModel: viewModel
                    )
                }
            }
            .onAppear {
                if let userId = auth.userId {
                    viewModel.startSubscriptions(userId: userId)
                }
            }
            .onDisappear {
                viewModel.stopSubscriptions()
            }
        }
    }

    // MARK: - Main Content

    private var friendsContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header row
                HStack {
                    Text("friends")
                        .font(.title2.weight(.bold))
                    Spacer()
                    Button {
                        showInvite = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(accentBlue)
                            .frame(width: 36, height: 36)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }

                // Pending requests
                if viewModel.pendingRequestCount > 0 {
                    pendingRequestsBanner
                }

                // Active plans section
                let activeHangouts = viewModel.sharedPlans.filter { $0.isHangout && $0.rsvp == "accepted" }
                let pendingHangouts = viewModel.sharedPlans.filter { $0.isHangout && $0.isPending }

                if !pendingHangouts.isEmpty {
                    planInvitesSection(pendingHangouts)
                }

                if !activeHangouts.isEmpty {
                    activePlansSection(activeHangouts)
                }

                // Friends grid
                if !viewModel.friends.isEmpty {
                    friendsGrid
                }

                // All shared plans
                let recommendations = viewModel.sharedPlans.filter { $0.isRecommendation }
                if !recommendations.isEmpty {
                    recommendationsSection(recommendations)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Pending Requests Banner

    private var pendingRequestsBanner: some View {
        NavigationLink {
            FriendRequestsView(viewModel: viewModel, userId: auth.userId ?? "")
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(accentBlue.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.badge.clock")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(accentBlue)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(viewModel.pendingRequestCount) friend request\(viewModel.pendingRequestCount == 1 ? "" : "s")")
                        .font(.subheadline.weight(.semibold))
                    Text("tap to review")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Plan Invites

    private func planInvitesSection(_ invites: [SharedPlanItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "envelope.fill", title: "plan invites")

            ForEach(invites) { item in
                SharedPlanCard(item: item) {
                    HStack(spacing: 8) {
                        Button {
                            viewModel.respondToSharedPlan(item.id, userId: auth.userId ?? "", accept: true)
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
                            viewModel.respondToSharedPlan(item.id, userId: auth.userId ?? "", accept: false)
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

    // MARK: - Active Plans

    private func activePlansSection(_ plans: [SharedPlanItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "calendar", title: "upcoming plans")

            ForEach(plans) { item in
                SharedPlanCard(item: item) {
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

    // MARK: - Friends Grid

    private var friendsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "person.2.fill", title: "your crew")

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(viewModel.friends) { friend in
                    NavigationLink {
                        FriendProfileView(
                            friend: friend,
                            userId: auth.userId ?? "",
                            viewModel: viewModel
                        )
                    } label: {
                        FriendCard(friend: friend)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Recommendations

    private func recommendationsSection(_ recs: [SharedPlanItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(icon: "hand.thumbsup.fill", title: "shared with you")

            ForEach(recs) { item in
                SharedPlanCard(item: item) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                            .foregroundStyle(accentBlue)
                        Text("recommendation")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Section Header

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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(accentBlue.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "person.2.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(accentBlue)
            }

            VStack(spacing: 6) {
                Text("no friends yet")
                    .font(.title3.weight(.bold))
                Text("invite your crew and start planning together")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                Button {
                    showInvite = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.caption.weight(.semibold))
                        Text("Add Friends")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accentBlue, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                Button {
                    if let userId = auth.userId {
                        viewModel.seedMockFriends(userId: userId)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.semibold))
                        Text(viewModel.isSeeding ? "adding..." : "add demo friends")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSeeding)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
    }
}

// MARK: - Friend Card

private struct FriendCard: View {
    let friend: Friend

    var body: some View {
        VStack(spacing: 8) {
            AvatarView(
                imageUrl: friend.profileImageUrl,
                emoji: friend.displayEmoji,
                size: 48
            )

            Text(friend.name.components(separatedBy: " ").first ?? friend.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text(friend.topVibes)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(friend.budgetLabel)
                .font(.caption2.weight(.medium))
                .foregroundStyle(accentBlue)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(accentBlue.opacity(0.1), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Shared Plan Card

private struct SharedPlanCard<Actions: View>: View {
    let item: SharedPlanItem
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Sender + plan info
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

            // Summary
            if let summary = item.planSummary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            // Message
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
