import SwiftUI

struct SpotMapPin: View {
    let spot: Spot

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: iconForSpot)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .glassEffect(.regular.tint(.blue), in: .circle)

            // Triangle pointer
            Triangle()
                .fill(.blue)
                .frame(width: 10, height: 6)
                .offset(y: -1)
        }
    }

    private var iconForSpot: String {
        let tags = spot.vibeTags.joined(separator: " ").lowercased()
        if tags.contains("coffee") || tags.contains("cafe") { return "cup.and.saucer.fill" }
        if tags.contains("bar") || tags.contains("cocktail") { return "wineglass.fill" }
        if tags.contains("restaurant") || tags.contains("food") { return "fork.knife" }
        if tags.contains("shop") { return "bag.fill" }
        if tags.contains("park") || tags.contains("outdoor") { return "leaf.fill" }
        return "mappin"
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
        }
    }
}
