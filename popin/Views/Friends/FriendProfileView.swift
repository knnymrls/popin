import SwiftUI

private let accentBlue = Color(red: 0, green: 0.39, blue: 1)

struct FriendProfileView: View {
    let friend: Friend
    let userId: String
    let viewModel: FriendsViewModel

    @State private var showRemoveAlert = false
    @State private var showSharePlan = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                headerCard

                // Taste sections
                if !friend.vibes.isEmpty {
                    tasteSection(icon: "sparkles", title: "vibes", tags: friend.vibes)
                }

                if !friend.foodLoves.isEmpty {
                    tasteSection(icon: "heart.fill", title: "loves", tags: friend.foodLoves)
                }

                if !friend.foodAvoids.isEmpty {
                    tasteSection(icon: "xmark.circle.fill", title: "avoids", tags: friend.foodAvoids)
                }

                if !friend.activities.isEmpty {
                    tasteSection(icon: "figure.run", title: "activities", tags: friend.activities)
                }

                if !friend.dealbreakers.isEmpty {
                    tasteSection(icon: "hand.raised.fill", title: "dealbreakers", tags: friend.dealbreakers)
                }

                if let notes = friend.notes, !notes.isEmpty {
                    notesCard(notes)
                }

                // Actions
                VStack(spacing: 10) {
                    Button {
                        showSharePlan = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption.weight(.semibold))
                            Text("Share a Plan")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accentBlue, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        showRemoveAlert = true
                    } label: {
                        Text("remove friend")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove Friend", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                viewModel.removeFriend(friend.friendshipId, userId: userId)
                dismiss()
            }
        } message: {
            Text("Are you sure you want to remove \(friend.name) as a friend?")
        }
        .sheet(isPresented: $showSharePlan) {
            SharePlanSheet(
                friends: [friend],
                userId: userId,
                viewModel: viewModel
            )
        }
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 14) {
            AvatarView(
                imageUrl: friend.profileImageUrl,
                emoji: friend.displayEmoji,
                size: 96
            )

            Text(friend.name)
                .font(.title2.weight(.bold))

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text(friend.budgetLabel)
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(accentBlue.opacity(0.1), in: Capsule())
                .foregroundStyle(accentBlue)

                if !friend.vibes.isEmpty {
                    Text(friend.topVibes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Taste Section

    private func tasteSection(icon: String, title: String, tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentBlue)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)

            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Notes Card

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentBlue)
                Text("notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, 4)

            Text(notes)
                .font(.subheadline)
                .foregroundStyle(.primary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
