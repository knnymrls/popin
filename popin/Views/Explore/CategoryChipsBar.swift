import SwiftUI

struct CategoryChipsBar: View {
    @Binding var selected: SpotCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer {
                HStack(spacing: 8) {
                    ForEach(SpotCategory.allCases) { category in
                        let isSelected = selected == category
                        Button {
                            withAnimation(.snappy) {
                                selected = isSelected ? nil : category
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: category.icon)
                                    .font(.caption2)
                                Text(category.rawValue)
                                    .font(.caption.weight(.medium))
                            }
                            .padding(.horizontal, 12)
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
                .padding(.horizontal, 16)
            }
        }
    }
}
