import SwiftUI

struct ExploreTopBar: View {
    let searchText: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)

                Text(searchText.isEmpty ? "Search places..." : searchText)
                    .font(.subheadline)
                    .foregroundStyle(searchText.isEmpty ? .secondary : .primary)

                Spacer()

                Image(systemName: "slider.horizontal.3")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }
}
