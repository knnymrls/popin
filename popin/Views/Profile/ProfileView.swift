import SwiftUI

struct ProfileView: View {
    @Environment(AuthManager.self) private var auth
    @State private var vm = ProfileViewModel()

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Profile")
            .toolbar {
                if vm.hasProfile && !vm.isEditing {
                    Button {
                        vm.beginEditing()
                    } label: {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                    }
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
    }

    // MARK: - Profile Content

    private var profileContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                headerCard

                // Taste Cards
                if let profile = vm.profile {
                    if !profile.vibes.isEmpty {
                        tasteCard(
                            icon: "sparkles",
                            title: "Vibes",
                            tags: profile.vibes,
                            color: .purple
                        )
                    }

                    if !profile.foodLoves.isEmpty {
                        tasteCard(
                            icon: "heart.fill",
                            title: "Food Loves",
                            tags: profile.foodLoves,
                            color: .orange
                        )
                    }

                    if !profile.foodAvoids.isEmpty {
                        tasteCard(
                            icon: "xmark.circle.fill",
                            title: "Food Avoids",
                            tags: profile.foodAvoids,
                            color: .red
                        )
                    }

                    if !profile.activities.isEmpty {
                        tasteCard(
                            icon: "figure.run",
                            title: "Activities",
                            tags: profile.activities,
                            color: .green
                        )
                    }

                    if !profile.dealbreakers.isEmpty {
                        tasteCard(
                            icon: "hand.raised.fill",
                            title: "Dealbreakers",
                            tags: profile.dealbreakers,
                            color: .red.opacity(0.8)
                        )
                    }

                    if let notes = profile.notes, !notes.isEmpty {
                        notesCard(notes)
                    }
                }

                // Sign Out
                Button(role: .destructive) {
                    auth.signOut()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .padding(.top, 4)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 14) {
            // Emoji Avatar
            Text(vm.profile?.displayEmoji ?? "😊")
                .font(.system(size: 56))
                .frame(width: 88, height: 88)
                .background(
                    Circle()
                        .fill(.orange.opacity(0.15))
                )

            // Name
            Text(vm.profile?.name ?? "")
                .font(.title2.bold())

            // Budget + Phone
            HStack(spacing: 10) {
                if let budget = vm.profile?.budget {
                    Label(budgetLabel(budget), systemImage: "dollarsign.circle.fill")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.green.opacity(0.12))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }

                if let phone = vm.profile?.phoneNumber, !phone.isEmpty {
                    Label(phone, systemImage: "phone.fill")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.blue.opacity(0.12))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Taste Card

    private func tasteCard(icon: String, title: String, tags: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }

            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(color.opacity(0.12))
                        .foregroundStyle(color)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Notes Card

    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "note.text")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Notes")
                    .font(.subheadline.weight(.semibold))
            }

            Text(notes)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("🍕")
                .font(.system(size: 64))

            Text("Build your taste profile")
                .font(.title2.bold())

            Text("Tell us what you love (and what to skip) so we can find your perfect spots.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                vm.isEditing = true
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding(.horizontal, 48)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func budgetLabel(_ budget: String) -> String {
        switch budget {
        case "cheap": return "Budget-friendly"
        case "moderate": return "Moderate"
        case "splurge": return "Splurge"
        default: return budget
        }
    }
}
