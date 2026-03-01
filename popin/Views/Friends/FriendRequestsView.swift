import SwiftUI

private let accentBlue = Color(red: 0, green: 0.39, blue: 1)

struct FriendRequestsView: View {
    let viewModel: FriendsViewModel
    let userId: String

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if !viewModel.incomingRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(accentBlue)
                            Text("incoming")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 4)

                        ForEach(viewModel.incomingRequests) { request in
                            HStack(spacing: 12) {
                                AvatarView(
                                    imageUrl: request.requesterImageUrl,
                                    emoji: request.displayEmoji,
                                    size: 40
                                )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(request.displayName)
                                        .font(.subheadline.weight(.semibold))
                                    Text("wants to be friends")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    viewModel.acceptRequest(request.id, userId: userId)
                                } label: {
                                    Text("accept")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 7)
                                        .background(accentBlue, in: Capsule())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    viewModel.declineRequest(request.id, userId: userId)
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 28, height: 28)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }

                if !viewModel.outgoingRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(accentBlue)
                            Text("sent")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.leading, 4)

                        ForEach(viewModel.outgoingRequests) { request in
                            HStack(spacing: 12) {
                                AvatarView(
                                    imageUrl: request.addresseeImageUrl,
                                    emoji: request.displayEmoji,
                                    size: 40
                                )

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(request.displayName)
                                        .font(.subheadline.weight(.semibold))
                                    Text("pending")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }

                if viewModel.incomingRequests.isEmpty && viewModel.outgoingRequests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.clock")
                            .font(.system(size: 32))
                            .foregroundStyle(.tertiary)
                        Text("no pending requests")
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
        .navigationTitle("Requests")
        .navigationBarTitleDisplayMode(.inline)
    }
}
