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

// MARK: - Panel colors (6 кольорів = 6 граней, всі унікальні)
private let faceColors: [Color] = [
    AppColors.cube.opacity(0.35),                       // 0 фіолетовий
    AppColors.pop.opacity(0.45),                        // 1 рожевий
    AppColors.sound.opacity(0.45),                      // 2 бірюзовий
    AppColors.focus.opacity(0.45),                      // 3 зелений
    AppColors.physics.opacity(0.45),                    // 4 оранжевий
    Color(red: 0.30, green: 0.65, blue: 1.0).opacity(0.45), // 5 синій #4DA6FF
]

private let faceBorders: [Color] = [
    AppColors.cube,
    AppColors.pop,
    AppColors.sound,
    AppColors.focus,
    AppColors.physics,
    Color(red: 0.30, green: 0.65, blue: 1.0),          // 5 синій
]

// MARK: - Flip Sound
private enum FlipSound {
    static func play() {
        AudioServicesPlaySystemSound(1104)
    }
}

// MARK: - Swipe Direction
private enum SwipeDirection {
    case up, down, left, right

    /// Ротація масиву [front, back, left, right, top, bottom]
    func rotated(_ f: [Int]) -> [Int] {
        switch self {
        case .down:
            return [f[4], f[5], f[2], f[3], f[1], f[0]]
        case .up:
            return [f[5], f[4], f[2], f[3], f[0], f[1]]
        case .right:
            return [f[2], f[3], f[1], f[0], f[4], f[5]]
        case .left:
            return [f[3], f[2], f[0], f[1], f[4], f[5]]
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
/// 6 кольорів, 6 граней — кожна грань гарантовано унікальна.
/// Будь-який свайп в будь-якому напрямку завжди дає новий колір.
private func makeUniqueFaces() -> [Int] {
    let shuffled = Array(0..<faceColors.count).shuffled()
    // [front, back, left, right, top, bottom]
    return [shuffled[0], shuffled[1], shuffled[2], shuffled[3], shuffled[4], shuffled[5]]
}

// MARK: - CubePanel
struct CubePanel: View {
    let index: Int
    var hapticsEnabled: Bool = true
    var soundEnabled: Bool = true

    /// 6 граней куба: [front, back, left, right, top, bottom]
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

    // MARK: - Gesture

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

// MARK: - Cube Settings
private struct CubeSettings: View {
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool

    var body: some View {
        VStack(spacing: 0) {
            row(icon: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                title: "Sound", binding: $soundEnabled)
            Divider().background(.white.opacity(0.1))
            row(icon: hapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash",
                title: "Haptics", binding: $hapticsEnabled)
        }
        .frame(width: 190)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
    }

    private func row(icon: String, title: String, binding: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(binding.wrappedValue ? AppColors.cube : .white.opacity(0.3))
                .frame(width: 22)
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(AppColors.cube)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

// MARK: - CubeView
struct CubeView: View {
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var showSettings = false

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

            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showSettings.toggle()
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(.white.opacity(0.07)))
                        }

                        if showSettings {
                            CubeSettings(
                                soundEnabled: $soundEnabled,
                                hapticsEnabled: $hapticsEnabled
                            )
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9, anchor: .topTrailing)
                                    .combined(with: .opacity),
                                removal: .scale(scale: 0.9, anchor: .topTrailing)
                                    .combined(with: .opacity)
                            ))
                        }
                    }
                    .padding(.top, 16)
                    .padding(.trailing, 64)
                }
                Spacer()
            }
        }
        .onTapGesture {
            if showSettings {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showSettings = false
                }
            }
        }
    }
}
