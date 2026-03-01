import SwiftUI

struct FriendRequestsView: View {
    let viewModel: FriendsViewModel
    let userId: String

    var body: some View {
        List {
            if !viewModel.incomingRequests.isEmpty {
                Section("Incoming Requests") {
                    ForEach(viewModel.incomingRequests) { request in
                        HStack(spacing: 12) {
                            Text(request.displayEmoji)
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(request.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Text("Wants to be friends")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                viewModel.acceptRequest(request.id, userId: userId)
                            } label: {
                                Text("Accept")
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.orange)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            Button {
                                viewModel.declineRequest(request.id, userId: userId)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !viewModel.outgoingRequests.isEmpty {
                Section("Sent Requests") {
                    ForEach(viewModel.outgoingRequests) { request in
                        HStack(spacing: 12) {
                            Text(request.displayEmoji)
                                .font(.title2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(request.displayName)
                                    .font(.subheadline.weight(.semibold))
                                Text("Pending")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "clock")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if viewModel.incomingRequests.isEmpty && viewModel.outgoingRequests.isEmpty {
                ContentUnavailableView(
                    "No Requests",
                    systemImage: "person.badge.clock",
                    description: Text("No pending friend requests")
                )
            }
        }
        .navigationTitle("Friend Requests")
    }
}
