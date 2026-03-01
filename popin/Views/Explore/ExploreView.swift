import CoreLocation
import SwiftUI

struct ExploreView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(AuthManager.self) private var auth
    @State private var vm = ExploreViewModel()
    @State private var showChat = false
    @State private var sheetDetent: PresentationDetent = .medium

    var body: some View {
        ZStack {
            // Full-screen map
            ExploreMapView(
                cameraPosition: $vm.cameraPosition,
                spots: vm.spots,
                highlightedSpotId: vm.highlightedSpotId
            ) { spot in
                vm.selectSpot(spot)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar + category chips
                GlassEffectContainer {
                    VStack(spacing: 8) {
                        ExploreTopBar(searchText: vm.searchText) {
                            withAnimation(.snappy) {
                                vm.beginSearch()
                            }
                        }

                        CategoryChipsBar(selected: $vm.selectedCategory)
                    }
                    .padding(.top, 8)
                }

                Spacer()

                // Floating chat button
                if !showChat && vm.mode != .searching {
                    HStack {
                        Spacer()
                        Button {
                            showChat = true
                        } label: {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.blue.gradient, in: Circle())
                                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 16)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }

            // Search overlay
            if vm.mode == .searching {
                SearchOverlayView(vm: vm)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .sheet(isPresented: $showChat) {
            ChatView(vm: vm)
                .presentationDetents([.medium, .large], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .medium))
                .presentationCornerRadius(20)
        }
        .onAppear {
            locationManager.requestPermission()
        }
        .onChange(of: locationManager.location) {
            if let coord = locationManager.coordinate {
                vm.loadNearbySpots(latitude: coord.latitude, longitude: coord.longitude)
            }
        }
    }
}
