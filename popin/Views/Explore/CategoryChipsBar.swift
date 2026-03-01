import SwiftUI

struct CategoryChipsBar: View {
    @Binding var selected: SpotCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(SpotCategory.allCases) { category in
                    let isSelected = selected == category
                    Button {
                        withAnimation(.snappy) {
                            selected = isSelected ? nil : category
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(category.emoji)
                                .font(.subheadline)
                            Text(category.rawValue)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .glassEffect(
                            isSelected ? .regular.tint(.blue) : .regular,
                            in: .capsule
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
