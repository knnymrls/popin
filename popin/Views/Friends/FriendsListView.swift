import SwiftUI

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
                    friendsList
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showInvite = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
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

    // MARK: - Friends List

    private var friendsList: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Pending requests banner
                if viewModel.pendingRequestCount > 0 {
                    NavigationLink {
                        FriendRequestsView(viewModel: viewModel, userId: auth.userId ?? "")
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.clock")
                                .font(.title3)
                                .foregroundStyle(.orange)
                            Text("\(viewModel.pendingRequestCount) friend request\(viewModel.pendingRequestCount == 1 ? "" : "s")")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                // Shared plans banner
                if viewModel.pendingSharedPlansCount > 0 {
                    NavigationLink {
                        SharedPlansView(viewModel: viewModel, userId: auth.userId ?? "")
                    } label: {
                        HStack {
                            Image(systemName: "map.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                            Text("\(viewModel.pendingSharedPlansCount) plan invite\(viewModel.pendingSharedPlansCount == 1 ? "" : "s")")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }

                // Friends grid
                if !viewModel.friends.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Friends")
                            .font(.headline)

                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 12
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

                // All shared plans link
                if !viewModel.sharedPlans.isEmpty {
                    NavigationLink {
                        SharedPlansView(viewModel: viewModel, userId: auth.userId ?? "")
                    } label: {
                        HStack {
                            Image(systemName: "square.stack.3d.up")
                                .foregroundStyle(.secondary)
                            Text("All Shared Plans (\(viewModel.sharedPlans.count))")
                                .font(.subheadline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("👋")
                .font(.system(size: 64))

            Text("No friends yet")
                .font(.title2.bold())

            Text("Invite your crew to PopIn and start\nplanning hangouts together")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button {
                    showInvite = true
                } label: {
                    Label("Add Friends", systemImage: "person.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    if let userId = auth.userId {
                        viewModel.seedMockFriends(userId: userId)
                    }
                } label: {
                    Label(
                        viewModel.isSeeding ? "Adding..." : "Add Demo Friends",
                        systemImage: "sparkles"
                    )
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(viewModel.isSeeding)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Friend Card

private struct FriendCard: View {
    let friend: Friend

    var body: some View {
        VStack(spacing: 8) {
            Text(friend.displayEmoji)
                .font(.system(size: 40))

            Text(friend.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text(friend.topVibes)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(friend.budgetLabel)
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.orange.opacity(0.15))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
