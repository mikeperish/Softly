// PopView.swift
// Fidget App — Interactive Bubble Wrap
// iOS 17+, SwiftUI

import SwiftUI

// MARK: - Silhouette Definition

enum BubbleSilhouette: Int, CaseIterable {
    case heart = 0
    case cactus = 1
    case cloud = 2

    var displayName: String {
        switch self {
        case .heart:  "Heart"
        case .cactus: "Cactus"
        case .cloud:  "Cloud"
        }
    }

    var iconSymbol: String? {
        switch self {
        case .heart: return "heart.fill"
        case .cloud: return "cloud.fill"
        case .cactus: return nil
        }
    }

    var iconEmoji: String? {
        switch self {
        case .cactus: return "🌵"
        default: return nil
        }
    }

    var accentColor: Color {
        switch self {
        case .heart:  Color(red: 1.0, green: 0.2, blue: 0.3)
        case .cactus: Color(red: 0.2, green: 0.75, blue: 0.3)
        case .cloud:  Color(red: 0.45, green: 0.70, blue: 1.0)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .heart:  Color(red: 0.5, green: 0.05, blue: 0.15)
        case .cactus: Color(red: 0.1, green: 0.35, blue: 0.15)
        case .cloud:  Color(red: 0.18, green: 0.35, blue: 0.65)
        }
    }

    var bgGlow: Color {
        switch self {
        case .heart:  Color(red: 0.40, green: 0.08, blue: 0.15)
        case .cactus: Color(red: 0.05, green: 0.20, blue: 0.10)
        case .cloud:  Color(red: 0.08, green: 0.15, blue: 0.30)
        }
    }

    var bubbleCornerFraction: CGFloat {
        switch self {
        case .heart:  1.0
        case .cactus: 0.35
        case .cloud:  1.0
        }
    }

    var next: BubbleSilhouette {
        let total = BubbleSilhouette.allCases.count
        return BubbleSilhouette(rawValue: (rawValue + 1) % total)!
    }

    var previous: BubbleSilhouette {
        let total = BubbleSilhouette.allCases.count
        return BubbleSilhouette(rawValue: (rawValue - 1 + total) % total)!
    }
}

// MARK: - Shape Hit-Test (Pixel Matrices 11×13)

/// Returns the color code at (nx, ny) or 0 if outside shape
func shapeColorCode(_ shape: BubbleSilhouette, nx: Double, ny: Double) -> Int {
    let col = Int((nx + 1.0) / 2.0 * 11.0)
    let row = Int((ny + 1.0) / 2.0 * 13.0)
    guard col >= 0, col < 11, row >= 0, row < 13 else { return 0 }

    let matrix: [[Int]]
    switch shape {
    case .heart:  matrix = heartMatrix
    case .cactus: matrix = cactusMatrix
    case .cloud:  matrix = cloudMatrix
    }

    return matrix[row][col]
}

func isInsideShape(_ shape: BubbleSilhouette, nx: Double, ny: Double) -> Bool {
    return shapeColorCode(shape, nx: nx, ny: ny) != 0
}

// Heart: classic pixel heart with highlights (3) and shadows (2)
private let heartMatrix: [[Int]] = [
    [0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0],
    [0,0,1,1,0,0,0,1,1,0,0],
    [0,1,3,3,1,0,1,1,2,1,0],
    [1,3,3,1,1,0,1,1,1,2,1],
    [1,3,1,1,1,1,1,1,1,2,1],
    [1,1,1,1,1,1,1,1,2,2,1],
    [0,1,1,1,1,1,1,2,2,1,0],
    [0,0,1,1,1,1,2,2,1,0,0],
    [0,0,0,1,1,2,2,1,0,0,0],
    [0,0,0,0,1,2,1,0,0,0,0],
    [0,0,0,0,0,1,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0],
]

// Cactus: trunk with highlights (3) and shadow (2) on pot
private let cactusMatrix: [[Int]] = [
    [0,0,0,0,0,1,1,0,0,0,0],
    [0,0,0,0,0,3,1,0,0,0,0],
    [0,1,1,0,0,3,1,0,0,0,0],
    [0,3,1,0,0,3,1,0,1,1,0],
    [0,3,1,1,1,1,1,0,3,1,0],
    [0,0,0,0,0,1,1,1,1,1,0],
    [0,0,0,0,0,3,1,0,0,0,0],
    [0,0,0,0,0,3,1,0,0,0,0],
    [0,0,0,0,0,3,1,0,0,0,0],
    [0,0,0,0,0,3,1,0,0,0,0],
    [0,0,0,1,1,1,1,1,1,0,0],
    [0,0,0,2,2,2,2,2,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0],
]

// Cloud: highlight (3) on left edge, shadow (2) on right/bottom
private let cloudMatrix: [[Int]] = [
    [0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,1,1,0,0,0,0,0,0],
    [0,0,1,3,3,1,0,1,1,0,0],
    [0,0,1,3,1,1,1,3,1,1,0],
    [0,1,1,1,1,1,1,3,1,1,0],
    [0,1,3,1,1,1,1,1,1,1,0],
    [1,3,1,1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1,1,2,1],
    [1,1,1,1,1,1,1,1,2,2,1],
    [0,1,2,2,1,2,2,2,2,1,0],
    [0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0],
    [0,0,0,0,0,0,0,0,0,0,0],
]

// MARK: - Bubble Model

struct PopBubble: Identifiable {
    let id: Int
    let col: Int
    let row: Int
    let colorCode: Int  // 1=accent, 2=dark/secondary, 3=light/highlight
}

// MARK: - Single Bubble View

struct BubbleCell: View {
    let silhouette: BubbleSilhouette
    let size: CGFloat
    let colorCode: Int
    let onPop: () -> Void
    let hapticsEnabled: Bool

    @State private var isPopped = false
    @State private var isRegrowing = false
    @State private var popScale: CGFloat = 1.0

    private var cornerRadius: CGFloat {
        size * 0.5 * silhouette.bubbleCornerFraction
    }

    /// Resolve bubble fill colors based on colorCode
    private var bubblePrimaryColor: Color {
        switch colorCode {
        case 2: return silhouette.secondaryColor
        case 3: return Color.white.opacity(0.85)
        default: return silhouette.accentColor
        }
    }

    private var bubbleSecondaryColor: Color {
        switch colorCode {
        case 2: return silhouette.secondaryColor.opacity(0.6)
        case 3: return Color.white.opacity(0.5)
        default: return silhouette.secondaryColor
        }
    }

    var body: some View {
        ZStack {
            if !isPopped {
                bubbleShape
                    .scaleEffect(popScale)
                    .opacity(isRegrowing ? 0.0 : 1.0)
                    .gesture(pressGesture)
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: popScale)
    }

    private var bubbleShape: some View {
        let primary = bubblePrimaryColor
        let secondary = bubbleSecondaryColor
        let cr = cornerRadius
        let bSize = size - 3

        return ZStack {
            RoundedRectangle(cornerRadius: cr)
                .fill(
                    LinearGradient(
                        colors: [primary.opacity(0.7), secondary.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: bSize, height: bSize)

            RoundedRectangle(cornerRadius: cr)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.05), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .padding(size * 0.08)
                .frame(width: bSize, height: bSize)

            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: size * 0.15, height: size * 0.15)
                .offset(x: -size * 0.14, y: -size * 0.14)

            RoundedRectangle(cornerRadius: cr)
                .strokeBorder(primary.opacity(0.25), lineWidth: 0.5)
                .frame(width: bSize, height: bSize)
        }
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isPopped else { return }
                if popScale == 1.0 {
                    withAnimation(.spring(response: 0.12, dampingFraction: 0.5)) {
                        popScale = 0.72
                    }
                    if hapticsEnabled {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        guard popScale < 1.0 else { return }
                        performPop()
                    }
                }
            }
            .onEnded { _ in
                guard !isPopped else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    popScale = 1.0
                }
            }
    }

    private func performPop() {
        guard !isPopped else { return }

        if hapticsEnabled {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }

        withAnimation(.spring(response: 0.08, dampingFraction: 0.3)) {
            popScale = 1.25
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) {
            isPopped = true
            popScale = 0
            onPop()
        }
    }
}

// MARK: - Grid Layout Data

struct PopGridLayout {
    let cellSize: CGFloat
    let gridWidth: CGFloat
    let gridHeight: CGFloat

    init(geoSize: CGSize, cols: Int, rows: Int) {
        let hPad: CGFloat = 24
        let availW = geoSize.width - hPad * 2
        let availH = geoSize.height - 180
        let cs = min(availW / CGFloat(cols), availH / CGFloat(rows))
        self.cellSize = cs
        self.gridWidth = cs * CGFloat(cols)
        self.gridHeight = cs * CGFloat(rows)
    }
}

// MARK: - Silhouette Icon View (SF Symbol or Emoji)

struct SilhouetteIconView: View {
    let silhouette: BubbleSilhouette
    let size: CGFloat

    var body: some View {
        if let emoji = silhouette.iconEmoji {
            Text(emoji)
                .font(.system(size: size))
        } else if let symbol = silhouette.iconSymbol {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(silhouette.accentColor)
        }
    }
}

// MARK: - Shape Indicator Dots (Clickable)

struct PopShapeIndicator: View {
    let current: BubbleSilhouette
    let onSelect: (BubbleSilhouette) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(BubbleSilhouette.allCases, id: \.rawValue) { shape in
                let isActive = shape == current
                Circle()
                    .fill(isActive ? shape.accentColor : Color.white.opacity(0.15))
                    .frame(width: isActive ? 10 : 6, height: isActive ? 10 : 6)
                    .frame(width: 20, height: 20)
                    .contentShape(Circle())
                    .onTapGesture {
                        if shape != current {
                            onSelect(shape)
                        }
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
    }
}

// MARK: - Progress Bar

struct PopProgressBar: View {
    let popped: Int
    let total: Int
    let width: CGFloat
    let silhouette: BubbleSilhouette

    var body: some View {
        VStack(spacing: 5) {
            progressCapsule
            counterText
        }
    }

    private var progressCapsule: some View {
        let barWidth = width * 0.5
        let fraction: CGFloat = total > 0 ? CGFloat(popped) / CGFloat(total) : 0
        let fillWidth = max(3, barWidth * fraction)

        return ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white.opacity(0.06))
                .frame(width: barWidth, height: 3)

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [silhouette.accentColor, silhouette.secondaryColor],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: fillWidth, height: 3)
                .animation(.spring(response: 0.3), value: popped)
        }
    }

    private var counterText: some View {
        Text("\(popped) / \(total)")
            .font(.system(size: 11, weight: .medium, design: .monospaced))
            .foregroundStyle(Color.white.opacity(0.25))
    }
}

// MARK: - Settings Panel

struct PopSettingsPanel: View {
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    let accent: Color
    let onDismiss: () -> Void

    var body: some View {
        VStack {
            HStack {
                Spacer()
                panelContent
                    .padding(.trailing, 20)
            }
            Spacer()
        }
        .padding(.top, 52)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.92, anchor: .topTrailing).combined(with: .opacity),
                removal: .scale(scale: 0.96, anchor: .topTrailing).combined(with: .opacity)
            )
        )
        .zIndex(10)
        .onTapGesture { onDismiss() }
    }

    private var panelContent: some View {
        VStack(spacing: 0) {
            toggleRow(icon: "speaker.wave.2.fill", title: "Sound", isOn: $soundEnabled)
            dividerLine
            toggleRow(icon: "hand.tap.fill", title: "Haptics", isOn: $hapticsEnabled)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .frame(width: 190)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
                .frame(width: 22)

            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.75))

            Spacer()

            PopToggle(isOn: isOn, accent: accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Custom Toggle

struct PopToggle: View {
    @Binding var isOn: Bool
    var accent: Color

    var body: some View {
        ZStack {
            Capsule()
                .fill(isOn ? accent.opacity(0.5) : Color.white.opacity(0.12))
                .frame(width: 40, height: 24)

            Circle()
                .fill(Color.white)
                .frame(width: 18, height: 18)
                .shadow(color: Color.black.opacity(0.2), radius: 1.5, y: 1)
                .offset(x: isOn ? 8 : -8)
        }
        .animation(.spring(response: 0.22, dampingFraction: 0.7), value: isOn)
        .onTapGesture { isOn.toggle() }
    }
}

// MARK: - Pop View (Main)

struct PopView: View {
    @Binding var currentSilhouette: BubbleSilhouette
    @State private var bubbles: [PopBubble] = []
    @State private var poppedCount = 0
    @State private var totalBubbles = 0
    @State private var isTransitioning = false
    @State private var showSettings = false
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var contentOpacity: Double = 1.0

    private let cols = 11
    private let rows = 13

    var body: some View {
        GeometryReader { geo in
            let layout = PopGridLayout(geoSize: geo.size, cols: cols, rows: rows)

            ZStack {
                backgroundView

                VStack(spacing: 12) {
                                Spacer()

                                gridSection(layout: layout)
                        .opacity(contentOpacity)
                        .frame(maxWidth: .infinity)

                    Spacer()

                    PopShapeIndicator(current: currentSilhouette) { target in
                        transitionTo(target)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)
                }

                // Ellipsis button (top-right)
                ellipsisOverlay

                // Settings panel
                if showSettings {
                    PopSettingsPanel(
                        soundEnabled: $soundEnabled,
                        hapticsEnabled: $hapticsEnabled,
                        accent: currentSilhouette.accentColor
                    ) {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            showSettings = false
                        }
                    }
                }
            }
        }
        .onAppear { regenerateGrid() }
        .gesture(swipeGesture)
    }

    // MARK: - Title Row

    private var titleRow: some View {
        HStack(spacing: 6) {
            SilhouetteIconView(silhouette: currentSilhouette, size: 15)

            Text(currentSilhouette.displayName)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.8))
                .id(currentSilhouette.rawValue)
        }
        .animation(.easeInOut(duration: 0.35), value: currentSilhouette)
    }
    // MARK: - Ellipsis Overlay

    private var ellipsisOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showSettings.toggle()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.07)))
                }
                .padding(.trailing, 64)
                .padding(.top, 16)
            }
            Spacer()
        }
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            Color(red: 0.039, green: 0.039, blue: 0.059)
                .ignoresSafeArea()

            RadialGradient(
                colors: [currentSilhouette.bgGlow.opacity(0.35), Color.clear],
                center: .center,
                startRadius: 30,
                endRadius: 380
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.8), value: currentSilhouette)
        }
    }

    // MARK: - Grid Section

    private func gridSection(layout: PopGridLayout) -> some View {
        ZStack {
            Ellipse()
                .fill(currentSilhouette.bgGlow.opacity(0.25))
                .frame(width: layout.gridWidth * 0.9, height: layout.gridHeight * 0.7)
                .blur(radius: 50)

            gridContent(cellSize: layout.cellSize)
                .frame(width: layout.gridWidth, height: layout.gridHeight)
        }
    }

    private func gridContent(cellSize: CGFloat) -> some View {
        ZStack {
            ForEach(bubbles) { bubble in
                BubbleCell(
                    silhouette: currentSilhouette,
                    size: cellSize,
                    colorCode: bubble.colorCode,
                    onPop: { handlePop() },
                    hapticsEnabled: hapticsEnabled
                )
                .position(
                    x: CGFloat(bubble.col) * cellSize + cellSize * 0.5,
                    y: CGFloat(bubble.row) * cellSize + cellSize * 0.5
                )
                .id(currentSilhouette.rawValue * 1000 + bubble.id)
            }
        }
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 50)
            .onEnded { value in
                guard !isTransitioning else { return }
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                guard isHorizontal else { return }

                if value.translation.width < 0 {
                    transitionTo(currentSilhouette.next)
                } else {
                    transitionTo(currentSilhouette.previous)
                }
            }
    }

    // MARK: - Logic

    private func regenerateGrid() {
        var result: [PopBubble] = []
        var idx = 0

        for row in 0..<rows {
            for col in 0..<cols {
                let nx = (Double(col) + 0.5) / Double(cols) * 2.0 - 1.0
                let ny = (Double(row) + 0.5) / Double(rows) * 2.0 - 1.0

                let code = shapeColorCode(currentSilhouette, nx: nx, ny: ny)
                if code != 0 {
                    result.append(PopBubble(id: idx, col: col, row: row, colorCode: code))
                    idx += 1
                }
            }
        }

        bubbles = result
        totalBubbles = result.count
        poppedCount = 0
    }

    private func handlePop() {
        poppedCount += 1

        if poppedCount >= totalBubbles {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                transitionTo(currentSilhouette.next)
            }
        }
    }

    private func transitionTo(_ target: BubbleSilhouette) {
        guard !isTransitioning else { return }
        guard target != currentSilhouette else { return }
        isTransitioning = true

        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        withAnimation(.easeInOut(duration: 0.35)) {
            contentOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            currentSilhouette = target
            regenerateGrid()

            withAnimation(.easeInOut(duration: 0.4)) {
                contentOpacity = 1.0
            }

            isTransitioning = false
        }
    }
}

// MARK: - Preview

#Preview {
    PopView(currentSilhouette: .constant(.heart))
        .preferredColorScheme(.dark)
}
