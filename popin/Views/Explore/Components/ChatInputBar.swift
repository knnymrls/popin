import SwiftUI

struct ChatInputBar: View {
    @Binding var text: String
    let isSending: Bool
    let friends: [Friend]
    var mentionedFriends: [Friend]
    let onSend: () -> Void
    let onMention: (Friend) -> Void
    let onRemoveMention: (Friend) -> Void

    @FocusState private var isFocused: Bool
    @State private var showMentionPicker = false
    @State private var mentionQuery = ""

    var body: some View {
        VStack(spacing: 0) {
            // Mention picker dropdown
            if showMentionPicker && !filteredFriends.isEmpty {
                mentionPickerView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Mentioned friends pills
            if !mentionedFriends.isEmpty {
                mentionedPillsRow
            }

            // Input row
            HStack(spacing: 10) {
                // @ button
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        showMentionPicker.toggle()
                        mentionQuery = ""
                    }
                } label: {
                    Image(systemName: "at")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(showMentionPicker ? Color(red: 0, green: 0.39, blue: 1) : .secondary)
                        .frame(width: 32, height: 32)
                        .background(
                            showMentionPicker
                                ? Color(red: 0, green: 0.39, blue: 1).opacity(0.12)
                                : Color.clear,
                            in: Circle()
                        )
                }

                TextField("Ask anything...", text: $text)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
                    .submitLabel(.send)
                    .focused($isFocused)
                    .onSubmit {
                        if canSend {
                            isFocused = false
                            onSend()
                        }
                    }
                    .onChange(of: text) {
                        detectMentionTrigger()
                    }

                Button {
                    isFocused = false
                    onSend()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(canSend ? Color(red: 0, green: 0.39, blue: 1) : .secondary)
                }
                .disabled(!canSend)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Mention Picker

    private var mentionPickerView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filteredFriends) { friend in
                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            onMention(friend)
                            showMentionPicker = false
                            mentionQuery = ""
                            // Remove @query from text if user typed it
                            removeMentionQueryFromText()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            AvatarView(
                                imageUrl: friend.profileImageUrl,
                                emoji: friend.displayEmoji,
                                size: 22
                            )
                            Text(friend.name.components(separatedBy: " ").first ?? friend.name)
                                .font(.caption.weight(.medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.secondarySystemGroupedBackground), in: Capsule())
                        .overlay(
                            Capsule()
                                .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Mentioned Friends Pills

    private var mentionedPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ForEach(mentionedFriends) { friend in
                    HStack(spacing: 4) {
                        AvatarView(
                            imageUrl: friend.profileImageUrl,
                            emoji: friend.displayEmoji,
                            size: 18
                        )
                        Text(friend.name.components(separatedBy: " ").first ?? friend.name)
                            .font(.caption2.weight(.medium))
                        Button {
                            withAnimation(.snappy(duration: 0.2)) {
                                onRemoveMention(friend)
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0, green: 0.39, blue: 1).opacity(0.1), in: Capsule())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    private var filteredFriends: [Friend] {
        let available = friends.filter { friend in
            !mentionedFriends.contains(where: { $0.userId == friend.userId })
        }
        if mentionQuery.isEmpty {
            return available
        }
        return available.filter { $0.name.localizedCaseInsensitiveContains(mentionQuery) }
    }

    private func detectMentionTrigger() {
        // Check if user just typed "@"
        if text.hasSuffix("@") && !showMentionPicker {
            withAnimation(.snappy(duration: 0.2)) {
                showMentionPicker = true
                mentionQuery = ""
            }
        } else if showMentionPicker {
            // Update filter query based on text after last "@"
            if let atIndex = text.lastIndex(of: "@") {
                let afterAt = String(text[text.index(after: atIndex)...])
                if afterAt.contains(" ") {
                    withAnimation(.snappy(duration: 0.2)) {
                        showMentionPicker = false
                    }
                } else {
                    mentionQuery = afterAt
                }
            }
        }
    }

    private func removeMentionQueryFromText() {
        // Remove "@query" from the text input
        if let atIndex = text.lastIndex(of: "@") {
            text = String(text[..<atIndex])
        }
    }
}
