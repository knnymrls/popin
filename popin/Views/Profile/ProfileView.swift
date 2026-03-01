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
                    Button("Edit") {
                        vm.beginEditing()
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
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 60, height: 60)
                        .overlay {
                            Text(vm.profile?.name.prefix(1).uppercased() ?? "?")
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.profile?.name ?? "")
                            .font(.title2.bold())

                        if let budget = vm.profile?.budget {
                            Text(budgetLabel(budget))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Sections
                if let profile = vm.profile {
                    if !profile.vibes.isEmpty {
                        tagSection("Vibes", tags: profile.vibes, color: .purple)
                    }

                    if !profile.foodLoves.isEmpty {
                        tagSection("Food Loves", tags: profile.foodLoves, color: .orange)
                    }

                    if !profile.foodAvoids.isEmpty {
                        tagSection("Food Avoids", tags: profile.foodAvoids, color: .red)
                    }

                    if !profile.activities.isEmpty {
                        tagSection("Activities", tags: profile.activities, color: .green)
                    }

                    if !profile.dealbreakers.isEmpty {
                        tagSection("Dealbreakers", tags: profile.dealbreakers, color: .red)
                    }

                    if let notes = profile.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Sign out
                Button(role: .destructive) {
                    auth.signOut()
                } label: {
                    Text("Sign Out")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top, 16)
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Set up your taste profile")
                .font(.title2.bold())

            Text("Tell us what you're into so we can give you better recommendations.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                vm.isEditing = true
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func tagSection(_ title: String, tags: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

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
    }

    private func budgetLabel(_ budget: String) -> String {
        switch budget {
        case "cheap": return "Budget-friendly ($)"
        case "moderate": return "Moderate ($$)"
        case "splurge": return "Splurge ($$$)"
        default: return budget
        }
    }
}
