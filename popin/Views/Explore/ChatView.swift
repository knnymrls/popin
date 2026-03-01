import CoreLocation
import SwiftUI

struct ChatView: View {
    @Bindable var vm: ExploreViewModel
    let friends: [Friend]
    @Environment(LocationManager.self) private var locationManager
    @Environment(AuthManager.self) private var auth
    @State private var planToShare: PlanData?

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        // Welcome header (always visible at top)
                        welcomeHeader
                            .padding(.bottom, 4)

                        // Initial suggestion chips (before any messages)
                        if vm.messages.isEmpty && !vm.isSending {
                            initialSuggestions
                        }

                        ForEach(vm.messages) { message in
                            ChatMessageView(
                                message: message,
                                onTapSpot: { spot in
                                    vm.selectSpot(spot)
                                },
                                onTapPlanSpot: { name in
                                    if let spot = vm.spots.first(where: { $0.name == name }) {
                                        vm.selectSpot(spot)
                                    }
                                },
                                onSharePlan: { plan in
                                    planToShare = plan
                                },
                                onTapSuggestion: { suggestion in
                                    sendSuggestion(suggestion)
                                }
                            )
                            .id(message.id)
                        }

                        // Invisible bottom anchor for reliable scrolling
                        Color.clear.frame(height: 1).id("bottomAnchor")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .defaultScrollAnchor(.bottom)
                .onChange(of: vm.messages.count) {
                    scrollToBottom(proxy)
                }
                .onChange(of: vm.messages.last?.id) {
                    scrollToBottom(proxy)
                }
            }

            // Input bar with @mention support
            ChatInputBar(
                text: $vm.chatInput,
                isSending: vm.isSending,
                friends: friends,
                mentionedFriends: vm.mentionedFriends,
                onSend: {
                    sendCurrentMessage()
                },
                onMention: { friend in
                    vm.addMention(friend)
                },
                onRemoveMention: { friend in
                    vm.removeMention(friend)
                }
            )
        }
        .sheet(item: $vm.selectedSpot) { spot in
            NavigationStack {
                SpotDetailView(
                    spot: spot,
                    detail: vm.spotDetail,
                    isLoading: vm.isLoadingDetail
                )
                .ignoresSafeArea(edges: .top)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            vm.dismissSpotDetail()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                }
            }
        }
        .sheet(item: $planToShare) { plan in
            QuickShareSheet(
                plan: plan,
                friends: friends,
                userId: auth.userId ?? ""
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Helpers

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            proxy.scrollTo("bottomAnchor", anchor: .bottom)
        }
    }

    // MARK: - Welcome Header

    private var welcomeHeader: some View {
        HStack(spacing: 10) {
            Text("🍿")
                .font(.title2)

            VStack(alignment: .leading, spacing: 1) {
                Text("Popin")
                    .font(.subheadline.weight(.bold))
                Text("your friend who always knows where to go")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Initial Suggestions

    private var initialSuggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("try asking...")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.leading, 46) // align with welcome text

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    suggestionChip("what's popping rn?", icon: "flame.fill")
                    suggestionChip("i'm hungry", icon: "fork.knife")
                    suggestionChip("plan a date night", icon: "heart.fill")
                    suggestionChip("cheap eats nearby", icon: "dollarsign.circle.fill")
                }
                .padding(.leading, 46)
            }
        }
    }

    private func suggestionChip(_ text: String, icon: String) -> some View {
        Button {
            sendSuggestion(text)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(Color(red: 0, green: 0.39, blue: 1))
                Text(text)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color(red: 0, green: 0.39, blue: 1).opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func sendCurrentMessage() {
        guard let coord = locationManager.coordinate else { return }
        vm.sendMessage(
            text: vm.chatInput,
            userId: auth.userId,
            latitude: coord.latitude,
            longitude: coord.longitude
        )
    }

    private func sendSuggestion(_ text: String) {
        guard let coord = locationManager.coordinate else { return }
        vm.sendMessage(
            text: text,
            userId: auth.userId,
            latitude: coord.latitude,
            longitude: coord.longitude
        )
    }
}
