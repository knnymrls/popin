import SwiftUI

struct FloatingNavBar: View {
    @Binding var selected: AppTab
    let onAskAI: () -> Void

    var body: some View {
        GlassEffectContainer {
            HStack(spacing: 0) {
                navButton(.explore, icon: "map.fill")

                Spacer()

                navButton(.friends, icon: "person.2.fill")

                Spacer()

                // Ask AI — center pill (3D)
                Button(action: onAskAI) {
                    Text("Ask AI")
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundStyle(.white)
                        .fixedSize()
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                // Bottom shadow layer for depth
                                Capsule()
                                    .fill(Color(red: 0, green: 0.25, blue: 0.75))
                                    .offset(y: 3)
                                // Main button face
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.2, green: 0.55, blue: 1),
                                                Color(red: 0, green: 0.39, blue: 1),
                                                Color(red: 0, green: 0.3, blue: 0.85),
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                // Top highlight for shine
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .white.opacity(0.3),
                                                .clear,
                                            ],
                                            startPoint: .top,
                                            endPoint: .center
                                        )
                                    )
                                    .padding(1)
                            }
                        )
                        .shadow(color: Color(red: 0, green: 0.3, blue: 0.9).opacity(0.4), radius: 8, y: 4)
                }

                Spacer()

                navButton(.archive, icon: "archivebox.fill")

                Spacer()

                navButton(.profile, icon: "person.crop.circle.fill")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .glassEffect(.regular, in: .capsule)
        }
    }

    private func navButton(_ tab: AppTab, icon: String) -> some View {
        Button {
            selected = tab
        } label: {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(selected == tab ? Color(red: 0, green: 0.39, blue: 1) : .primary.opacity(0.6))
                .frame(width: 28, height: 28)
        }
    }
}
