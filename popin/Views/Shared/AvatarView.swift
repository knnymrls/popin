import SwiftUI

private let accentBlue = Color(red: 0, green: 0.39, blue: 1)

struct AvatarView: View {
    let imageUrl: String?
    let emoji: String
    let size: CGFloat

    init(imageUrl: String?, emoji: String = "👤", size: CGFloat = 96) {
        self.imageUrl = imageUrl
        self.emoji = emoji
        self.size = size
    }

    var body: some View {
        Group {
            if let imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        emojiFallback
                    case .empty:
                        ProgressView()
                            .frame(width: size, height: size)
                    @unknown default:
                        emojiFallback
                    }
                }
            } else {
                emojiFallback
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .background(
            Circle()
                .fill(accentBlue.opacity(0.1))
        )
    }

    private var emojiFallback: some View {
        Text(emoji)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(accentBlue.opacity(0.1))
            )
    }
}
