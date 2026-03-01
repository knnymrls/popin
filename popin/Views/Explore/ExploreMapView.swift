import CoreLocation
import MapKit
import SwiftUI

struct ExploreMapView: View {
    @Binding var cameraPosition: MapCameraPosition
    let spots: [SpotData]
    var highlightedSpotId: String?
    var onTapSpot: ((SpotData) -> Void)?

    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()

            ForEach(spots) { spot in
                let isHighlighted = highlightedSpotId == spot.placeId
                Annotation(
                    "",
                    coordinate: CLLocationCoordinate2D(
                        latitude: spot.latitude,
                        longitude: spot.longitude
                    ),
                    anchor: .bottom
                ) {
                    SpotDataMapPin(
                        spot: spot,
                        isHighlighted: isHighlighted
                    )
                    .onTapGesture {
                        onTapSpot?(spot)
                    }
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
    }
}

// MARK: - Map Pin

struct SpotDataMapPin: View {
    let spot: SpotData
    var isHighlighted: Bool = false

    private var pinSize: CGFloat { isHighlighted ? 44 : 34 }

    var body: some View {
        VStack(spacing: 2) {
            // Name label (shown when highlighted)
            if isHighlighted {
                Text(spot.name)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 6))
                    .transition(.scale.combined(with: .opacity))
            }

            // Photo pin
            ZStack {
                if let photoUrl = spot.photoUrl, let url = URL(string: photoUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            fallbackIcon
                        }
                    }
                    .frame(width: pinSize, height: pinSize)
                    .clipShape(Circle())
                } else {
                    fallbackIcon
                        .frame(width: pinSize, height: pinSize)
                        .clipShape(Circle())
                }
            }
            .overlay(
                Circle()
                    .strokeBorder(isHighlighted ? Color.blue : .white, lineWidth: isHighlighted ? 3 : 2)
            )
            .shadow(color: .black.opacity(0.25), radius: 4, y: 2)

            // Pointer
            Triangle()
                .fill(isHighlighted ? Color.blue : .white)
                .frame(width: 10, height: 6)
                .offset(y: -2)
        }
        .animation(.spring(response: 0.3), value: isHighlighted)
    }

    private var fallbackIcon: some View {
        ZStack {
            Color(.systemGray5)
            Image(systemName: "fork.knife")
                .font(.system(size: isHighlighted ? 16 : 12, weight: .semibold))
                .foregroundStyle(.secondary)
        }
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
