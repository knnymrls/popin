import Combine
import ConvexMobile
import SwiftUI

struct SharePlanSheet: View {
    let friends: [Friend]
    let userId: String
    let viewModel: FriendsViewModel

    @State private var plans: [Plan] = []
    @State private var selectedPlanId: String?
    @State private var selectedFriendIds: Set<String> = []
    @State private var shareType: ShareMode = .hangout
    @State private var message = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var didSend = false
    @Environment(\.dismiss) private var dismiss

    enum ShareMode: String, CaseIterable {
        case hangout = "hangout"
        case recommendation = "recommendation"

        var label: String {
            switch self {
            case .hangout: return "Hangout"
            case .recommendation: return "Just Sharing"
            }
        }

        var icon: String {
            switch self {
            case .hangout: return "person.2.fill"
            case .recommendation: return "hand.thumbsup.fill"
            }
        }

        var description: String {
            switch self {
            case .hangout: return "You're both going — they can accept or decline"
            case .recommendation: return "Just sharing a cool spot — no RSVP needed"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Plan picker
                    planPickerSection

                    // Friend picker (if not pre-set)
                    if friends.count != 1 {
                        friendPickerSection
                    }

                    // Share type
                    shareTypeSection

                    // Message
                    messageSection

                    // Send button
                    sendButton
                }
                .padding()
            }
            .navigationTitle("Share Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                // Pre-select friends if passed in
                if friends.count == 1, let friend = friends.first {
                    selectedFriendIds = [friend.userId]
                }
                loadPlans()
            }
            .overlay {
                if didSend {
                    successOverlay
                }
            }
        }
    }

    // MARK: - Plan Picker

    private var planPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose a Plan")
                .font(.subheadline.weight(.semibold))

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else if plans.isEmpty {
                Text("No plans yet. Create one in the Explore tab!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                ForEach(plans) { plan in
                    Button {
                        selectedPlanId = plan.id
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.title)
                                    .font(.subheadline.weight(.medium))
                                Text(plan.aiSummary)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            Image(systemName: selectedPlanId == plan.id ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedPlanId == plan.id ? .orange : .secondary)
                        }
                        .padding()
                        .background(selectedPlanId == plan.id ? .orange.opacity(0.1) : .clear)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Friend Picker

    private var friendPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Share With")
                .font(.subheadline.weight(.semibold))

            ForEach(viewModel.friends) { friend in
                Button {
                    if selectedFriendIds.contains(friend.userId) {
                        selectedFriendIds.remove(friend.userId)
                    } else {
                        selectedFriendIds.insert(friend.userId)
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text(friend.displayEmoji)
                            .font(.title3)

                        Text(friend.name)
                            .font(.subheadline)

                        Spacer()

                        Image(
                            systemName: selectedFriendIds.contains(friend.userId)
                                ? "checkmark.circle.fill" : "circle"
                        )
                        .foregroundStyle(
                            selectedFriendIds.contains(friend.userId) ? .orange : .secondary
                        )
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Share Type

    private var shareTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How are you sharing?")
                .font(.subheadline.weight(.semibold))

            ForEach(ShareMode.allCases, id: \.rawValue) { mode in
                Button {
                    shareType = mode
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: mode.icon)
                            .font(.title3)
                            .foregroundStyle(shareType == mode ? .orange : .secondary)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.label)
                                .font(.subheadline.weight(.medium))
                            Text(mode.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: shareType == mode ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(shareType == mode ? .orange : .secondary)
                    }
                    .padding()
                    .background(shareType == mode ? .orange.opacity(0.1) : .clear)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Message

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add a message (optional)")
                .font(.subheadline.weight(.semibold))

            TextField("e.g. this place looks fire", text: $message)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Send

    private var sendButton: some View {
        Button {
            sendPlan()
        } label: {
            Label(
                isSending ? "Sending..." : "Send",
                systemImage: "paperplane.fill"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(canSend ? .orange : .gray.opacity(0.3))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSend || isSending)
    }

    private var canSend: Bool {
        selectedPlanId != nil && !selectedFriendIds.isEmpty
    }

    // MARK: - Success

    private var successOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("Plan shared!")
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }

    // MARK: - Logic

    private func loadPlans() {
        Task {
            do {
                let args: [String: ConvexEncodable?] = ["userId": userId]
                let userPlans: [Plan] = try await convex.query(
                    "plans:getByUser",
                    with: args
                )
                await MainActor.run {
                    self.plans = userPlans
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
                print("Failed to load plans: \(error)")
            }
        }
    }

    private func sendPlan() {
        guard let planId = selectedPlanId else { return }
        isSending = true

        for friendId in selectedFriendIds {
            viewModel.sharePlan(
                planId: planId,
                senderId: userId,
                recipientId: friendId,
                shareType: shareType.rawValue,
                message: message.isEmpty ? nil : message
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSending = false
            didSend = true
        }
    }
}
