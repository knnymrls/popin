import SwiftUI

struct ExploreBottomBar: View {
    @Binding var selectedCategory: SpotCategory?

    var body: some View {
        CategoryChipsBar(selected: $selectedCategory)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
    }
}
