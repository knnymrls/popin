import CoreLocation
import SwiftUI

struct SearchOverlayView: View {
    @Bindable var vm: ExploreViewModel
    @Environment(LocationManager.self) private var locationManager
    @Environment(AuthManager.self) private var auth
    @FocusState private var isFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search a place or vibe...", text: Binding(
                    get: { vm.searchText },
                    set: { vm.updateSearchText($0) }
                ))
                .textFieldStyle(.plain)
                .focused($isFieldFocused)
                .submitLabel(.search)

                Button("Cancel") {
                    withAnimation(.snappy) {
                        vm.cancelSearch()
                    }
                }
                .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect()

            Divider()

            // Results list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Vibe search suggestion
                    if !vm.searchText.isEmpty {
                        VibeSearchRow(query: vm.searchText) {
                            let query = vm.searchText
                            vm.searchText = ""
                            withAnimation(.snappy) {
                                vm.cancelSearch()
                            }
                            if let coord = locationManager.coordinate {
                                vm.sendMessage(
                                    text: query,
                                    userId: auth.userId,
                                    latitude: coord.latitude,
                                    longitude: coord.longitude
                                )
                            }
                        }
                    }

                    // Place completions
                    ForEach(vm.completions, id: \.self) { completion in
                        PlaceCompletionRow(completion: completion) {
                            vm.selectCompletion(completion)
                        }
                    }
                }
            }
        }
        .background(.regularMaterial)
        .onAppear {
            isFieldFocused = true
        }
    }
}
