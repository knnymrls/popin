import SwiftUI

struct FriendProfileView: View {
    let friend: Friend
    let userId: String
    let viewModel: FriendsViewModel

    @State private var showRemoveAlert = false
    @State private var showSharePlan = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text(friend.displayEmoji)
                        .font(.system(size: 72))

                    Text(friend.name)
                        .font(.title.bold())

                    HStack(spacing: 8) {
                        Label(friend.budgetLabel, systemImage: "dollarsign.circle")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.orange.opacity(0.15))
                            .clipShape(Capsule())

                        if !friend.vibes.isEmpty {
                            Text(friend.topVibes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top)

                // Taste Profile Sections
                VStack(spacing: 16) {
                    if !friend.foodLoves.isEmpty {
                        tagSection(title: "Loves", icon: "heart.fill", tags: friend.foodLoves, color: .pink)
                    }

                    if !friend.foodAvoids.isEmpty {
                        tagSection(title: "Avoids", icon: "xmark.circle", tags: friend.foodAvoids, color: .red)
                    }

                    if !friend.vibes.isEmpty {
                        tagSection(title: "Vibes", icon: "sparkles", tags: friend.vibes, color: .purple)
                    }

                    if !friend.activities.isEmpty {
                        tagSection(title: "Activities", icon: "figure.walk", tags: friend.activities, color: .blue)
                    }

                    if !friend.dealbreakers.isEmpty {
                        tagSection(title: "Dealbreakers", icon: "hand.raised", tags: friend.dealbreakers, color: .orange)
                    }

                    if let notes = friend.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Notes", systemImage: "note.text")
                                .font(.subheadline.weight(.semibold))
                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                // Actions
                VStack(spacing: 12) {
                    Button {
                        showSharePlan = true
                    } label: {
                        Label("Share a Plan", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.orange)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(role: .destructive) {
                        showRemoveAlert = true
                    } label: {
                        Label("Remove Friend", systemImage: "person.badge.minus")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.red.opacity(0.1))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.top, 8)
            }
            .padding()
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

    // MARK: - Tag Section

    private func tagSection(title: String, icon: String, tags: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)

            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Flow Layout (wrapping tags)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return LayoutResult(
            size: CGSize(width: maxWidth, height: y + rowHeight),
            positions: positions,
            sizes: sizes
        )
    }

    struct LayoutResult {
        let size: CGSize
        let positions: [CGPoint]
        let sizes: [CGSize]
    }
}
