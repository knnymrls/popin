import CoreLocation
import MapKit
import SwiftUI

enum ExploreSheet: Identifiable {
    case chat
    case spotDetail(SpotData)

    var id: String {
        switch self {
        case .chat: return "chat"
        case .spotDetail(let spot): return "spotDetail-\(spot.placeId)"
        }
    }
}

struct ExploreView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(AuthManager.self) private var auth
    @State private var vm = ExploreViewModel()
    @State private var friendsVM = FriendsViewModel()
    @State private var activeSheet: ExploreSheet?
    @State private var chatDetent: PresentationDetent = .medium
    @Binding var askAITrigger: Bool

    var body: some View {
        ZStack {
            // Full-screen map
            ExploreMapView(
                cameraPosition: $vm.cameraPosition,
                spots: vm.spots,
                highlightedSpotId: vm.highlightedSpotId
            ) { spot in
                vm.selectSpot(spot)
                activeSheet = .spotDetail(spot)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // "What's Popping" floating card
                if !vm.poppingSpots.isEmpty && vm.mode != .searching && activeSheet == nil {
                    HStack {
                        WhatsPopppingCard(spots: vm.poppingSpots) { spot in
                            vm.selectSpot(spot)
                            activeSheet = .spotDetail(spot)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                // Location recenter button
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            vm.cameraPosition = .userLocation(fallback: .automatic)
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                }

                // Bottom bar (hidden during search)
                if vm.mode != .searching {
                    ExploreBottomBar(selectedCategory: $vm.selectedCategory)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }

            // Search overlay
            if vm.mode == .searching {
                SearchOverlayView(vm: vm)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .onChange(of: askAITrigger) {
            if askAITrigger {
                chatDetent = .medium
                activeSheet = .chat
                askAITrigger = false
            }
        }
        .onChange(of: vm.isSending) {
            // Expand to full when AI finishes responding
            if !vm.isSending && vm.messages.contains(where: { if case .assistant = $0 { return true }; return false }) {
                withAnimation {
                    chatDetent = .large
                }
            }
        }
        .sheet(item: $activeSheet, onDismiss: {
            vm.dismissSpotDetail()
        }) { sheet in
            switch sheet {
            case .chat:
                ChatView(vm: vm, friends: friendsVM.friends)
                    .presentationDetents([.medium, .large], selection: $chatDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                    .presentationCornerRadius(20)
            case .spotDetail(let spot):
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
                                activeSheet = nil
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
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationCornerRadius(20)
            }
        }
        .onAppear {
            locationManager.requestPermission()
            if let userId = auth.userId {
                friendsVM.startSubscriptions(userId: userId)
            }
        }
        .onChange(of: locationManager.location) {
            if let coord = locationManager.coordinate {
                vm.loadNearbySpots(latitude: coord.latitude, longitude: coord.longitude)
            }
        }
        .onChange(of: vm.selectedCategory) {
            vm.filterByCategory(vm.selectedCategory)
        }
    }
}
