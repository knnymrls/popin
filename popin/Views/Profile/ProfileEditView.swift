import SwiftUI

struct ProfileEditView: View {
    @Bindable var vm: ProfileViewModel
    let userId: String
    @Environment(\.dismiss) private var dismiss

    private let emojiOptions = [
        "😊", "😎", "🤩", "🥳", "😋", "🤤", "🧑‍🍳", "👨‍🎤",
        "🍕", "🍔", "🌮", "🍣", "🍜", "🍩", "🧋", "🍷",
        "🎸", "🎨", "🏄", "🚴", "🎯", "🌶️", "🍦", "☕",
        "🐶", "🐱", "🦊", "🐻", "🌸", "🔥",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Emoji Avatar Picker
                    VStack(spacing: 12) {
                        Text(vm.avatarEmoji)
                            .font(.system(size: 52))
                            .frame(width: 80, height: 80)
                            .background(
                                Circle()
                                    .fill(.orange.opacity(0.15))
                            )

                        Text("Pick your avatar")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 8), spacing: 8) {
                            ForEach(emojiOptions, id: \.self) { emoji in
                                Button {
                                    vm.avatarEmoji = emoji
                                } label: {
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 40, height: 40)
                                        .background(
                                            vm.avatarEmoji == emoji
                                                ? Color.orange.opacity(0.2)
                                                : Color.clear
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(
                                                    vm.avatarEmoji == emoji ? Color.orange : .clear,
                                                    lineWidth: 2
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                        TextField("Your name", text: $vm.name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Phone Number
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.headline)
                        TextField("+1 (555) 123-4567", text: $vm.phoneNumber)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)
                        Text("So friends can find you on PopIn")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Budget
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Budget")
                            .font(.headline)

                        HStack(spacing: 10) {
                            ForEach(ProfilePresets.budgets, id: \.self) { level in
                                BudgetChip(
                                    label: budgetDisplay(level),
                                    isSelected: vm.budget == level
                                ) {
                                    vm.budget = vm.budget == level ? nil : level
                                }
                            }
                        }
                    }

                    // Vibes
                    TagChipSection(
                        title: "Your vibe",
                        presets: ProfilePresets.vibes,
                        selected: $vm.vibes
                    )

                    // Food Loves
                    TagChipSection(
                        title: "Food you love",
                        presets: ProfilePresets.foodLoves,
                        selected: $vm.foodLoves
                    )

                    // Food Avoids
                    TagChipSection(
                        title: "Food to avoid",
                        presets: ProfilePresets.foodAvoids,
                        selected: $vm.foodAvoids
                    )

                    // Activities
                    TagChipSection(
                        title: "Activities you're into",
                        presets: ProfilePresets.activities,
                        selected: $vm.activities
                    )

                    // Dealbreakers
                    TagChipSection(
                        title: "Dealbreakers",
                        presets: ProfilePresets.dealbreakers,
                        selected: $vm.dealbreakers
                    )

                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Anything else?")
                            .font(.headline)
                        TextField("e.g. wheelchair accessible, dog-friendly...", text: $vm.notes, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                }
                .padding()
            }
            .navigationTitle(vm.hasProfile ? "Edit Profile" : "Set Up Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        vm.cancelEditing()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        vm.save(userId: userId)
                    } label: {
                        if vm.isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                                .bold()
                        }
                    }
                    .disabled(vm.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isSaving)
                }
            }
        }
    }

    private func budgetDisplay(_ level: String) -> String {
        switch level {
        case "cheap": return "$ Cheap"
        case "moderate": return "$$ Moderate"
        case "splurge": return "$$$ Splurge"
        default: return level
        }
    }
}

// MARK: - Budget Chip

private struct BudgetChip: View {
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.orange.opacity(0.15) : Color(.systemGray6))
                .foregroundStyle(isSelected ? .orange : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isSelected ? Color.orange.opacity(0.4) : .clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }
}
