import CoreLocation
import SwiftUI

struct ChatView: View {
    @Bindable var vm: ExploreViewModel
    @Environment(LocationManager.self) private var locationManager
    @Environment(AuthManager.self) private var auth

    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.messages) { message in
                            ChatMessageView(message: message) { spot in
                                vm.selectSpot(spot)
                            }
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .onChange(of: vm.messages.count) {
                    if let last = vm.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Input bar
            ChatInputBar(
                text: $vm.chatInput,
                isSending: vm.isSending
            ) {
                sendCurrentMessage()
            }
        }
        .sheet(item: $vm.selectedSpot) { spot in
            NavigationStack {
                SpotDetailView(
                    spot: spot,
                    detail: vm.spotDetail,
                    isLoading: vm.isLoadingDetail
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            vm.dismissSpotDetail()
                        }
                    }
                }
            }
        }
        .onAppear {
            guard let coord = locationManager.coordinate else { return }
            vm.sendGreeting(
                userId: auth.userId,
                latitude: coord.latitude,
                longitude: coord.longitude
            )
        }
    }

    private func sendCurrentMessage() {
        guard let coord = locationManager.coordinate else { return }
        vm.sendMessage(
            text: vm.chatInput,
            userId: auth.userId,
            latitude: coord.latitude,
            longitude: coord.longitude
        )
    }
}
