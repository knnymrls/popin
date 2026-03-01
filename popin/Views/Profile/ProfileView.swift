import SwiftUI

private let accentBlue = Color(red: 0, green: 0.39, blue: 1)

struct ProfileView: View {
    @Environment(AuthManager.self) private var auth
    @State private var vm = ProfileViewModel()

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.hasProfile {
                profileContent
            } else {
                emptyState
            }
        }
        .sheet(isPresented: $vm.isEditing) {
            ProfileEditView(vm: vm, userId: auth.userId ?? "")
        }
        .onAppear {
            if let userId = auth.userId {
                vm.startSubscription(userId: userId)
            }
        }
        .onDisappear {
            vm.stopSubscription()
        }
    }

    // MARK: - Profile Content

    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerCard

                if let profile = vm.profile {
                    if !profile.vibes.isEmpty {
                        tasteSection(
                            icon: "sparkles",
                            title: "vibes",
                            tags: profile.vibes
                        )
                    }

                    if !profile.foodLoves.isEmpty {
                        tasteSection(
                            icon: "heart.fill",
                            title: "food loves",
                            tags: profile.foodLoves
                        )
                    }

                    if !profile.foodAvoids.isEmpty {
                        tasteSection(
                            icon: "xmark.circle.fill",
                            title: "avoids",
                            tags: profile.foodAvoids
                        )
                    }

                    if !profile.activities.isEmpty {
                        tasteSection(
                            icon: "figure.run",
                            title: "activities",
                            tags: profile.activities
                        )
                    }

                    if !profile.dealbreakers.isEmpty {
                        tasteSection(
                            icon: "hand.raised.fill",
                            title: "dealbreakers",
                            tags: profile.dealbreakers
                        )
                    }

                    if let notes = profile.notes, !notes.isEmpty {
                        notesCard(notes)
                    }
                }

                // Edit + Sign Out
                VStack(spacing: 10) {
                    Button {
                        vm.beginEditing()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.caption.weight(.semibold))
                            Text("Edit Profile")
                                .font(.subheadline.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        auth.signOut()
                    } label: {
                        Text("Sign Out")
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
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 14) {
            // Avatar
            AvatarView(
                imageUrl: vm.profile?.profileImageUrl,
                emoji: vm.profile?.displayEmoji ?? "😊",
                size: 96
            )

            // Name
            Text(vm.profile?.name ?? "")
                .font(.title2.weight(.bold))

            // Budget + Phone pills
            HStack(spacing: 8) {
                if let budget = vm.profile?.budget {
                    infoPill(
                        budgetLabel(budget),
                        icon: "dollarsign.circle.fill"
                    )
                }

                if let phone = vm.profile?.phoneNumber, !phone.isEmpty {
                    infoPill(phone, icon: "phone.fill")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func infoPill(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(accentBlue.opacity(0.1), in: Capsule())
        .foregroundStyle(accentBlue)
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(accentBlue.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(accentBlue)
            }

            VStack(spacing: 6) {
                Text("build your taste profile")
                    .font(.title3.weight(.bold))
                Text("so we know what spots to find you")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    presetButton(name: "Kenny", emoji: "🔥", preset: "kenny")
                    presetButton(name: "Alyn", emoji: "💜", preset: "alyn")
                }

                Button {
                    vm.isEditing = true
                } label: {
                    Text("build from scratch")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func presetButton(name: String, emoji: String, preset: String) -> some View {
        Button {
            if let userId = auth.userId {
                vm.seedProfile(userId: userId, name: name, preset: preset)
            }
        } label: {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 24))
                Text(name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(accentBlue, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(vm.isSaving)
    }

    private func budgetLabel(_ budget: String) -> String {
        switch budget {
        case "cheap": return "budget-friendly"
        case "moderate": return "moderate"
        case "splurge": return "splurge"
        default: return budget
        }
    }
}
