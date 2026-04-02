import SwiftUI

// MARK: - Background
struct AppBackground: View {
    var accentColor: Color = Color(hex: "#9B6DFF")

    var body: some View {
        Color(hex: "#0A0A0F")
            .ignoresSafeArea()
            .overlay {
                RadialGradient(
                    colors: [
                        accentColor.opacity(0.12),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 500
                )
                .ignoresSafeArea()
            }
    }
}

// MARK: - Glass Card Placeholder
struct GlassCard: View {
    let title: String
    let icon: String
    var accentColor: Color = Color(hex: "#9B6DFF")

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(accentColor)

            Text(title)
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundStyle(.white)

            Text("Coming soon")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(width: 200, height: 200)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.white.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    accentColor.opacity(0.4),
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .shadow(color: accentColor.opacity(0.2), radius: 30, x: 0, y: 10)
    }
}

// MARK: - App Colors
struct AppColors {
    static let cube    = Color(hex: "#9B6DFF") // фіолетовий
    static let pop     = Color(hex: "#FF6B9D") // рожевий/кораловий
    static let sound   = Color(hex: "#4ECDC4") // синій/бірюзовий
    static let focus   = Color(red: 0.9, green: 0.2, blue: 0.2)
    static let physics = Color(red: 0.04, green: 0.52, blue: 0.89)
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
