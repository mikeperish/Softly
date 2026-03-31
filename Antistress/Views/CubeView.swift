import SwiftUI
import AudioToolbox

// MARK: - Config
private enum CubeConfig {
    static let cornerRadius: CGFloat = 20
    static let borderWidth: CGFloat = 1.5
    static let perspective: CGFloat = 0.5
    static let velocityDivisor: CGFloat = 20
    static let snapStiffness: Double = 160
    static let snapDamping: Double = 18
    static let columns = 4
    static let spacing: CGFloat = 12
    static let panelCount = 16
    static let swipeThreshold: CGFloat = 30
    static let flipMidDelay: Double = 0.15
    static let flipEndDelay: Double = 0.2
}

// MARK: - Panel colors
private let faceColors: [Color] = [
    AppColors.cube.opacity(0.35),
    AppColors.pop.opacity(0.45),
    AppColors.sound.opacity(0.45),
    AppColors.focus.opacity(0.45),
    AppColors.physics.opacity(0.45),
    Color(red: 0.30, green: 0.65, blue: 1.0).opacity(0.45),
]

private let faceBorders: [Color] = [
    AppColors.cube,
    AppColors.pop,
    AppColors.sound,
    AppColors.focus,
    AppColors.physics,
    Color(red: 0.30, green: 0.65, blue: 1.0),
]

// MARK: - Flip Sound
private enum FlipSound {
    static func play() {
        AudioServicesPlaySystemSound(1156)
    }
}

// MARK: - Swipe Direction
private enum SwipeDirection {
    case up, down, left, right

    func rotated(_ f: [Int]) -> [Int] {
        switch self {
        case .down:  return [f[4], f[5], f[2], f[3], f[1], f[0]]
        case .up:    return [f[5], f[4], f[2], f[3], f[0], f[1]]
        case .right: return [f[2], f[3], f[1], f[0], f[4], f[5]]
        case .left:  return [f[3], f[2], f[0], f[1], f[4], f[5]]
        }
    }

    var isVertical: Bool { self == .up || self == .down }

    var animationSign: Double {
        switch self {
        case .down, .right: return 1
        case .up, .left: return -1
        }
    }
}

// MARK: - Face Initializer
private func makeUniqueFaces() -> [Int] {
    let shuffled = Array(0..<faceColors.count).shuffled()
    return [shuffled[0], shuffled[1], shuffled[2], shuffled[3], shuffled[4], shuffled[5]]
}

// MARK: - CubePanel
struct CubePanel: View {
    let index: Int
    var hapticsEnabled: Bool = true
    var soundEnabled: Bool = true

    @State private var faces: [Int] = makeUniqueFaces()
    @State private var hasFlipped = false
    @State private var flipAngle: Double = 0
    @State private var flipAxisX = true
    @State private var isAnimating = false

    @GestureState private var isDragging = false
    private let haptic = UIImpactFeedbackGenerator(style: .rigid)

    private var currentColor: Color {
        hasFlipped ? faceColors[faces[0]] : .white.opacity(0.06)
    }

    private var currentBorder: Color {
        hasFlipped ? faceBorders[faces[0]] : .white.opacity(0.3)
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: CubeConfig.cornerRadius, style: .continuous)

        shape
            .fill(currentColor)
            .overlay {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [currentBorder.opacity(0.7), currentBorder.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: CubeConfig.borderWidth
                )
            }
            .overlay {
                LinearGradient(
                    colors: [.white.opacity(0.09), .clear],
                    startPoint: .topLeading,
                    endPoint: .center
                )
                .clipShape(shape)
            }
            .shadow(
                color: currentBorder.opacity(hasFlipped ? 0.45 : 0.1),
                radius: hasFlipped ? 16 : 6
            )
            .scaleEffect(isDragging ? 0.93 : 1.0)
            .rotation3DEffect(
                .degrees(flipAngle),
                axis: flipAxisX ? (1, 0, 0) : (0, 1, 0),
                perspective: CubeConfig.perspective
            )
            .animation(.spring(response: 0.2), value: isDragging)
            .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .updating($isDragging) { _, state, _ in state = true }
            .onEnded { value in
                guard !isAnimating else { return }
                guard let direction = swipeDirection(from: value) else { return }

                flipAxisX = direction.isVertical
                isAnimating = true

                let sign = direction.animationSign

                withAnimation(.interpolatingSpring(
                    stiffness: CubeConfig.snapStiffness,
                    damping: CubeConfig.snapDamping
                )) {
                    flipAngle = 90 * sign
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + CubeConfig.flipMidDelay) {
                    faces = direction.rotated(faces)
                    hasFlipped = true
                    flipAngle = -90 * sign

                    withAnimation(.interpolatingSpring(
                        stiffness: CubeConfig.snapStiffness,
                        damping: CubeConfig.snapDamping
                    )) {
                        flipAngle = 0
                    }

                    if hapticsEnabled { haptic.impactOccurred() }
                    if soundEnabled { FlipSound.play() }

                    DispatchQueue.main.asyncAfter(deadline: .now() + CubeConfig.flipEndDelay) {
                        isAnimating = false
                    }
                }
            }
    }

    private func swipeDirection(from value: DragGesture.Value) -> SwipeDirection? {
        let h = value.translation.height
        let w = value.translation.width
        let isVertical = abs(h) > abs(w)

        let main = isVertical ? h : w
        let velocity = isVertical ? value.velocity.height : value.velocity.width
        let total = main + velocity / CubeConfig.velocityDivisor

        guard abs(total) > CubeConfig.swipeThreshold else { return nil }

        if isVertical {
            return total > 0 ? .down : .up
        } else {
            return total > 0 ? .right : .left
        }
    }
}

// MARK: - CubeView
struct CubeView: View {
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: CubeConfig.spacing),
        count: CubeConfig.columns
    )

    var body: some View {
        ZStack {
            AppBackground(accentColor: AppColors.cube)

            VStack {
                Spacer()
                LazyVGrid(columns: columns, spacing: CubeConfig.spacing) {
                    ForEach(0..<CubeConfig.panelCount, id: \.self) { i in
                        CubePanel(
                            index: i,
                            hapticsEnabled: hapticsEnabled,
                            soundEnabled: soundEnabled
                        )
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(.horizontal, CubeConfig.spacing)
                Spacer()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CubeView(soundEnabled: .constant(true), hapticsEnabled: .constant(true))
        .preferredColorScheme(.dark)
}
