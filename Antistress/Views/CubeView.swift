import SwiftUI
import AudioToolbox

// MARK: - Custom Tile Shapes

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.25))
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.35),
            control1: CGPoint(x: w * 0.35, y: 0),
            control2: CGPoint(x: 0, y: h * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: 0, y: h * 0.65),
            control2: CGPoint(x: w * 0.35, y: h * 0.85)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.35),
            control1: CGPoint(x: w * 0.65, y: h * 0.85),
            control2: CGPoint(x: w, y: h * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.25),
            control1: CGPoint(x: w, y: h * 0.1),
            control2: CGPoint(x: w * 0.65, y: 0)
        )
        return path
    }
}

struct TriangleUp: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

struct TriangleDown: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

// MARK: - Tile Shape Type

enum TileShapeType {
    case roundedRect(CGFloat)
    case circle
    case heart
    case triangleUp
    case triangleDown
}

// MARK: - CubeShape Enum

enum CubeShape: Int, CaseIterable {
    case classic = 0
    case circles = 1
    case canvas = 2
    case mini = 3
    case heart = 4
    case big = 5
    case ring = 6
    case triangle = 7
    case checkers = 8
    case large = 9

    var displayName: String {
        switch self {
        case .classic:  "Classic"
        case .circles:  "Circles"
        case .canvas:   "Canvas"
        case .mini:     "Mini"
        case .heart:    "Heart"
        case .big:      "Big"
        case .ring:     "Ring"
        case .triangle: "Triangle"
        case .checkers: "Checkers"
        case .large:    "Large"
        }
    }

    var isFree: Bool {
        switch self {
        case .classic, .circles: return true
        default: return false
        }
    }

    var accentColor: Color {
        switch self {
        case .classic:  AppColors.cube
        case .circles:  Color(red: 0.4, green: 0.75, blue: 1.0)
        case .canvas:   Color(red: 1.0, green: 0.5, blue: 0.3)
        case .mini:     Color(red: 0.5, green: 0.9, blue: 0.8)
        case .heart:    Color(red: 0.95, green: 0.3, blue: 0.45)
        case .big:      Color(red: 0.95, green: 0.75, blue: 0.2)
        case .ring:     Color(red: 0.3, green: 0.85, blue: 0.6)
        case .triangle: Color(red: 0.65, green: 0.55, blue: 0.95)
        case .checkers: Color(red: 0.85, green: 0.4, blue: 0.7)
        case .large:    Color(red: 0.9, green: 0.35, blue: 0.35)
        }
    }

    var columns: Int {
        switch self {
        case .classic:  return 4
        case .circles:  return 7
        case .canvas:   return 12
        case .mini:     return 6
        case .heart:    return 8
        case .big:      return 1
        case .ring:     return 5
        case .triangle: return 8
        case .checkers: return 4
        case .large:    return 2
        }
    }

    var rows: Int {
        switch self {
        case .classic:  return 4
        case .circles:  return 7
        case .canvas:   return 12
        case .mini:     return 6
        case .heart:    return 8
        case .big:      return 1
        case .ring:     return 5
        case .triangle: return 8
        case .checkers: return 4
        case .large:    return 2
        }
    }

    var spacing: CGFloat {
        switch self {
        case .canvas:   return 2
        case .mini:     return 6
        case .large:    return 16
        case .big:      return 0
        case .heart:    return 4
        case .triangle: return 4
        case .circles:  return 6
        default:        return 12
        }
    }

    var isRainbow: Bool { self == .canvas }

    func tileShape(col: Int, row: Int) -> TileShapeType {
        switch self {
        case .circles, .ring:
            return .circle
        case .heart:
            return .heart
        case .triangle:
            let isUp = (col + row) % 2 == 0
            return isUp ? .triangleUp : .triangleDown
        case .big:
            return .circle
        default:
            return .roundedRect(20)
        }
    }

    func isCellActive(col: Int, row: Int) -> Bool {
        switch self {
        case .circles:
            let mask: [[Int]] = [
                [0,0,1,1,1,0,0],
                [0,1,1,1,1,1,0],
                [1,1,1,1,1,1,1],
                [1,1,1,1,1,1,1],
                [1,1,1,1,1,1,1],
                [0,1,1,1,1,1,0],
                [0,0,1,1,1,0,0],
            ]
            guard row < mask.count, col < mask[0].count else { return false }
            return mask[row][col] == 1

        case .ring:
            let cx = 2.0, cy = 2.0
            let dx = Double(col) - cx
            let dy = Double(row) - cy
            let dist = dx * dx + dy * dy
            return dist <= 5.5 && dist >= 0.5

        case .checkers:
            return (col + row) % 2 == 0

        default:
            return true
        }
    }
}

// MARK: - Color Palettes

private let classicFaceColors: [Color] = [
    AppColors.cube.opacity(0.35),
    AppColors.pop.opacity(0.45),
    AppColors.sound.opacity(0.45),
    AppColors.focus.opacity(0.45),
    AppColors.physics.opacity(0.45),
    Color(red: 0.30, green: 0.65, blue: 1.0).opacity(0.45),
]

private let classicBorderColors: [Color] = [
    AppColors.cube,
    AppColors.pop,
    AppColors.sound,
    AppColors.focus,
    AppColors.physics,
    Color(red: 0.30, green: 0.65, blue: 1.0),
]

private let rainbowColors: [Color] = [
    Color(red: 0.95, green: 0.25, blue: 0.25),
    Color(red: 0.95, green: 0.55, blue: 0.20),
    Color(red: 0.95, green: 0.85, blue: 0.25),
    Color(red: 0.30, green: 0.85, blue: 0.40),
    Color(red: 0.25, green: 0.75, blue: 0.95),
    Color(red: 0.35, green: 0.45, blue: 0.95),
    Color(red: 0.65, green: 0.35, blue: 0.95),
    Color(red: 0.95, green: 0.40, blue: 0.70),
    Color.white.opacity(0.85),
]

private let rainbowBorders: [Color] = [
    Color(red: 0.95, green: 0.25, blue: 0.25),
    Color(red: 0.95, green: 0.55, blue: 0.20),
    Color(red: 0.95, green: 0.85, blue: 0.25),
    Color(red: 0.30, green: 0.85, blue: 0.40),
    Color(red: 0.25, green: 0.75, blue: 0.95),
    Color(red: 0.35, green: 0.45, blue: 0.95),
    Color(red: 0.65, green: 0.35, blue: 0.95),
    Color(red: 0.95, green: 0.40, blue: 0.70),
    Color.white,
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

// MARK: - Tile Shape View

struct TileShapeView: View {
    let tileType: TileShapeType
    let fillColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let showGloss: Bool

    var body: some View {
        ZStack {
            switch tileType {
            case .roundedRect(let cr):
                RoundedRectangle(cornerRadius: cr, style: .continuous)
                    .fill(fillColor)
                RoundedRectangle(cornerRadius: cr, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [borderColor.opacity(0.7), borderColor.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: borderWidth
                    )
                if showGloss {
                    LinearGradient(colors: [.white.opacity(0.09), .clear], startPoint: .topLeading, endPoint: .center)
                        .clipShape(RoundedRectangle(cornerRadius: cr, style: .continuous))
                }

            case .circle:
                Circle().fill(fillColor)
                Circle().strokeBorder(
                    LinearGradient(
                        colors: [borderColor.opacity(0.7), borderColor.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: borderWidth
                )
                if showGloss {
                    LinearGradient(colors: [.white.opacity(0.09), .clear], startPoint: .topLeading, endPoint: .center)
                        .clipShape(Circle())
                }

            case .heart:
                HeartShape().fill(fillColor)
                HeartShape().stroke(
                    LinearGradient(
                        colors: [borderColor.opacity(0.7), borderColor.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: borderWidth
                )
                if showGloss {
                    LinearGradient(colors: [.white.opacity(0.09), .clear], startPoint: .topLeading, endPoint: .center)
                        .clipShape(HeartShape())
                }

            case .triangleUp:
                TriangleUp().fill(fillColor)
                TriangleUp().stroke(
                    LinearGradient(
                        colors: [borderColor.opacity(0.7), borderColor.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: borderWidth
                )

            case .triangleDown:
                TriangleDown().fill(fillColor)
                TriangleDown().stroke(
                    LinearGradient(
                        colors: [borderColor.opacity(0.7), borderColor.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: borderWidth
                )
            }
        }
    }
}

// MARK: - CubePanel

struct CubePanel: View {
    let index: Int
    let shape: CubeShape
    let col: Int
    let row: Int
    var hapticsEnabled: Bool = true
    var soundEnabled: Bool = true
    var isLocked: Bool = false
    var onLockedTap: () -> Void = {}

    @State private var faces: [Int] = Array(0..<6).shuffled()
    @State private var hasFlipped = false
    @State private var flipAngle: Double = 0
    @State private var flipAxisX = true
    @State private var isAnimating = false
    @State private var rainbowIndex: Int = Int.random(in: 0..<9)

    @GestureState private var isDragging = false
    private let haptic = UIImpactFeedbackGenerator(style: .rigid)

    private var tileType: TileShapeType {
        shape.tileShape(col: col, row: row)
    }

    private var currentColor: Color {
        guard hasFlipped else { return .white.opacity(0.06) }
        if shape.isRainbow {
            return rainbowColors[rainbowIndex].opacity(0.5)
        }
        return classicFaceColors[faces[0]]
    }

    private var currentBorder: Color {
        guard hasFlipped else { return .white.opacity(0.3) }
        if shape.isRainbow {
            return rainbowBorders[rainbowIndex]
        }
        return classicBorderColors[faces[0]]
    }

    var body: some View {
        TileShapeView(
            tileType: tileType,
            fillColor: currentColor,
            borderColor: currentBorder,
            borderWidth: shape == .canvas ? 0.5 : 1.5,
            showGloss: shape != .canvas
        )
        .shadow(
            color: shape == .canvas ? .clear : currentBorder.opacity(hasFlipped ? 0.25 : 0.04),
            radius: hasFlipped ? 8 : 2
        )
        .scaleEffect(isDragging ? 0.93 : 1.0)
        .rotation3DEffect(
            .degrees(flipAngle),
            axis: flipAxisX ? (1, 0, 0) : (0, 1, 0),
            perspective: 0.5
        )
        .animation(.spring(response: 0.2), value: isDragging)
        .gesture(dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: shape == .canvas ? 6 : 12)
            .updating($isDragging) { _, state, _ in state = true }
            .onEnded { value in
                guard !isAnimating else { return }

                if isLocked {
                    onLockedTap()
                    return
                }

                guard let direction = swipeDirection(from: value) else { return }

                flipAxisX = direction.isVertical
                isAnimating = true
                let sign = direction.animationSign

                withAnimation(.interpolatingSpring(stiffness: 160, damping: 18)) {
                    flipAngle = 90 * sign
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if shape.isRainbow {
                        let delta = (direction == .up || direction == .left) ? -1 : 1
                        rainbowIndex = (rainbowIndex + delta + rainbowColors.count) % rainbowColors.count
                    } else {
                        faces = direction.rotated(faces)
                    }
                    hasFlipped = true
                    flipAngle = -90 * sign

                    withAnimation(.interpolatingSpring(stiffness: 160, damping: 18)) {
                        flipAngle = 0
                    }

                    if hapticsEnabled { haptic.impactOccurred() }
                    if soundEnabled { FlipSound.play() }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
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
        let total = main + velocity / 20
        let threshold: CGFloat = shape == .canvas ? 15 : 30
        guard abs(total) > threshold else { return nil }
        return isVertical ? (total > 0 ? .down : .up) : (total > 0 ? .right : .left)
    }
}

// MARK: - Big Coin Panel (single large circle)

struct BigCoinPanel: View {
    var hapticsEnabled: Bool = true
    var soundEnabled: Bool = true
    var isLocked: Bool = false
    var onLockedTap: () -> Void = {}

    @State private var currentColorIndex: Int = Int.random(in: 0..<classicFaceColors.count)
    @State private var hasFlipped = false
    @State private var flipAngle: Double = 0
    @State private var flipAxisX = true
    @State private var isAnimating = false

    @GestureState private var isDragging = false
    private let haptic = UIImpactFeedbackGenerator(style: .heavy)

    private var currentColor: Color {
        hasFlipped ? classicFaceColors[currentColorIndex] : .white.opacity(0.06)
    }

    private var currentBorder: Color {
        hasFlipped ? classicBorderColors[currentColorIndex] : .white.opacity(0.3)
    }

    var body: some View {
        ZStack {
            Circle().fill(currentColor)
            Circle().strokeBorder(
                LinearGradient(
                    colors: [currentBorder.opacity(0.7), currentBorder.opacity(0.15)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
            LinearGradient(colors: [.white.opacity(0.09), .clear], startPoint: .topLeading, endPoint: .center)
                .clipShape(Circle())
        }
        .shadow(color: currentBorder.opacity(hasFlipped ? 0.4 : 0.1), radius: hasFlipped ? 30 : 10)
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .rotation3DEffect(
            .degrees(flipAngle),
            axis: flipAxisX ? (1, 0, 0) : (0, 1, 0),
            perspective: 0.4
        )
        .animation(.spring(response: 0.2), value: isDragging)
        .gesture(coinGesture)
        .frame(width: 220, height: 220)
    }

    private var coinGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .updating($isDragging) { _, state, _ in state = true }
            .onEnded { value in
                guard !isAnimating else { return }

                if isLocked {
                    onLockedTap()
                    return
                }

                let h = value.translation.height
                let w = value.translation.width
                flipAxisX = abs(h) > abs(w)
                let main = flipAxisX ? h : w
                let sign: Double = main > 0 ? 1 : -1

                isAnimating = true

                withAnimation(.interpolatingSpring(stiffness: 120, damping: 14)) {
                    flipAngle = 180 * sign
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    currentColorIndex = Int.random(in: 0..<classicFaceColors.count)
                    hasFlipped = true

                    withAnimation(.interpolatingSpring(stiffness: 120, damping: 14)) {
                        flipAngle = 0
                    }

                    if hapticsEnabled { haptic.impactOccurred() }
                    if soundEnabled { FlipSound.play() }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isAnimating = false
                    }
                }
            }
    }
}

// MARK: - Cube Shape Picker

struct CubeShapePicker: View {
    let current: CubeShape
    let isPremium: Bool
    let onSelect: (CubeShape) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(CubeShape.allCases, id: \.rawValue) { shape in
                        let isActive = shape == current
                        let isLocked = !shape.isFree && !isPremium

                        Button {
                            if shape != current {
                                onSelect(shape)
                            }
                        } label: {
                            HStack(spacing: 5) {
                                if isLocked {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.white.opacity(0.2))
                                }
                                Text(shape.displayName)
                                    .font(.system(size: 14, weight: isActive ? .semibold : .regular, design: .rounded))
                                    .foregroundStyle(
                                        isActive ? .white :
                                        isLocked ? .white.opacity(0.2) : .white.opacity(0.35)
                                    )
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(isActive ? shape.accentColor.opacity(0.25) : .clear)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                isActive ? shape.accentColor.opacity(0.4) :
                                                isLocked ? .white.opacity(0.05) : .white.opacity(0.08),
                                                lineWidth: 0.5
                                            )
                                    )
                            )
                        }
                        .id(shape.rawValue)
                        .animation(.easeInOut(duration: 0.25), value: isActive)
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: current) { _, newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    proxy.scrollTo(newValue.rawValue, anchor: .center)
                }
            }
        }
    }
}

// MARK: - CubeView

struct CubeView: View {
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var currentShape: CubeShape = .classic
    @State private var showPaywall = false

    private var isCurrentLocked: Bool {
        !currentShape.isFree && !subscriptionManager.isPremium
    }

    var body: some View {
        ZStack {
            AppBackground(accentColor: currentShape.accentColor)

            VStack {
                Spacer()

                if currentShape == .big {
                    BigCoinPanel(
                        hapticsEnabled: hapticsEnabled,
                        soundEnabled: soundEnabled,
                        isLocked: isCurrentLocked,
                        onLockedTap: {
                            showPaywall = true
                            if hapticsEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    )
                } else {
                    gridForShape(currentShape)
                        .padding(.horizontal, currentShape == .canvas ? 8 : currentShape.spacing)
                }

                Spacer()

                CubeShapePicker(
                    current: currentShape,
                    isPremium: subscriptionManager.isPremium,
                    onSelect: { shape in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentShape = shape
                        }
                        if hapticsEnabled {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                )
                .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: currentShape)
        .sheet(isPresented: $showPaywall) {
            PremiumView()
        }
    }

    @ViewBuilder
    private func gridForShape(_ shape: CubeShape) -> some View {
        let columns = Array(
            repeating: GridItem(.flexible(), spacing: shape.spacing),
            count: shape.columns
        )

        LazyVGrid(columns: columns, spacing: shape.spacing) {
            ForEach(0..<(shape.rows * shape.columns), id: \.self) { i in
                let col = i % shape.columns
                let row = i / shape.columns

                if shape.isCellActive(col: col, row: row) {
                    CubePanel(
                        index: i,
                        shape: shape,
                        col: col,
                        row: row,
                        hapticsEnabled: hapticsEnabled,
                        soundEnabled: soundEnabled,
                        isLocked: isCurrentLocked,
                        onLockedTap: {
                            showPaywall = true
                            if hapticsEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }
                    )
                    .aspectRatio(1, contentMode: .fit)
                } else {
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .id(shape.rawValue)
    }
}

// MARK: - Preview

#Preview {
    CubeView(soundEnabled: .constant(true), hapticsEnabled: .constant(true))
        .environment(SubscriptionManager.shared)
        .preferredColorScheme(.dark)
}
