import ConvexMobile
import SwiftUI

struct QuickShareSheet: View {
    let plan: PlanData
    let friends: [Friend]
    let userId: String

    @State private var selectedFriendIds: Set<String> = []
    @State private var isSending = false
    @State private var didSend = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Plan preview
                HStack(spacing: 10) {
                    Image(systemName: "map.fill")
                        .foregroundStyle(Color(red: 0, green: 0.39, blue: 1))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.title)
                            .font(.subheadline.weight(.semibold))
                        Text(plan.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))

                // Friend picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("send to")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if friends.isEmpty {
                        Text("no friends added yet")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, minHeight: 60)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(friends) { friend in
                                    Button {
                                        if selectedFriendIds.contains(friend.userId) {
                                            selectedFriendIds.remove(friend.userId)
                                        } else {
                                            selectedFriendIds.insert(friend.userId)
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            AvatarView(
                                                imageUrl: friend.profileImageUrl,
                                                emoji: friend.displayEmoji,
                                                size: 32
                                            )
                                            Text(friend.name)
                                                .font(.subheadline)
                                            Spacer()
                                            Image(
                                                systemName: selectedFriendIds.contains(friend.userId)
                                                    ? "checkmark.circle.fill" : "circle"
                                            )
                                            .foregroundStyle(
                                                selectedFriendIds.contains(friend.userId)
                                                    ? Color(red: 0, green: 0.39, blue: 1) : .secondary
                                            )
                                        }
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // Send button — always pinned at bottom
                Button {
                    sharePlan()
                } label: {
                    Label(
                        isSending ? "Sending..." : "Share Plan",
                        systemImage: "paperplane.fill"
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selectedFriendIds.isEmpty
                            ? Color.gray.opacity(0.3)
                            : Color(red: 0, green: 0.39, blue: 1)
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedFriendIds.isEmpty || isSending)
            }
            .padding()
            .navigationTitle("Share Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if didSend {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                        Text("sent!")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.9))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func sharePlan() {
        guard let planId = plan.planId else { return }
        isSending = true

        Task {
            for friendId in selectedFriendIds {
                let args: [String: ConvexEncodable?] = [
                    "planId": planId,
                    "senderId": userId,
                    "recipientId": friendId,
                    "shareType": "hangout",
                ]
                do {
                    try await convex.mutation("friends:sharePlan", with: args)
                } catch {
                    print("Share plan failed: \(error)")
                }
            }
            await MainActor.run {
                isSending = false
                didSend = true
            }
        }
    }
}
