// PopView.swift
// Fidget App — Interactive Bubble Wrap
// iOS 17+, SwiftUI

import SwiftUI
import AudioToolbox

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

private let cloudMatrix: [[Int]] = [
    [0,0,0,0,0,0,0,0,0,0,0],
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
]

// MARK: - Pop Sound

private enum PopSound {
    static func play() {
        AudioServicesPlaySystemSound(1306)
    }
}

// MARK: - Bubble Model

struct PopBubble: Identifiable {
    let id: Int
    let col: Int
    let row: Int
    let colorCode: Int
    var isPopped: Bool = false
}

// MARK: - Single Bubble View

struct BubbleCell: View {
    let silhouette: BubbleSilhouette
    let size: CGFloat
    let colorCode: Int
    let isAlreadyPopped: Bool
    let onPop: () -> Void
    let hapticsEnabled: Bool
    let soundEnabled: Bool

    @State private var isPopped = false
    @State private var popScale: CGFloat = 1.0

    private var cornerRadius: CGFloat {
        size * 0.5 * silhouette.bubbleCornerFraction
    }

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
                    .gesture(pressGesture)
            }
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: popScale)
        .onAppear {
            if isAlreadyPopped {
                isPopped = true
                popScale = 0
            }
        }
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
        if soundEnabled {
            PopSound.play()
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

// MARK: - Silhouette Icon View

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

// MARK: - Text Shape Picker

struct PopShapePicker: View {
    let current: BubbleSilhouette
    let onSelect: (BubbleSilhouette) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(BubbleSilhouette.allCases.enumerated()), id: \.element.rawValue) { index, shape in
                let isActive = shape == current

                Button {
                    if shape != current {
                        onSelect(shape)
                    }
                } label: {
                    Text(shape.displayName)
                        .font(.system(size: 15, weight: isActive ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(isActive ? shape.accentColor : .white.opacity(0.3))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
                .animation(.easeInOut(duration: 0.25), value: isActive)

                if index < BubbleSilhouette.allCases.count - 1 {
                    Text("·")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white.opacity(0.15))
                }
            }
        }
    }
}

// MARK: - Transition Direction

private enum SlideDirection {
    case left, right

    var outOffset: CGFloat { self == .left ? -1 : 1 }
    var inOffset: CGFloat { self == .left ? 1 : -1 }
}

// MARK: - Pop View (Main)

struct PopView: View {
    @Binding var currentSilhouette: BubbleSilhouette
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool

    // Per-silhouette bubble state
    @State private var bubbleStates: [BubbleSilhouette: [PopBubble]] = [:]
    @State private var poppedCounts: [BubbleSilhouette: Int] = [:]
    @State private var totalCounts: [BubbleSilhouette: Int] = [:]

    @State private var isTransitioning = false
    @State private var gridOffset: CGFloat = 0
    @State private var gridOpacity: Double = 1.0
    @State private var dragOffset: CGFloat = 0

    // Reset button
    @State private var showResetConfirmation = false

    private let cols = 11
    private let rows = 13

    private var bubbles: [PopBubble] {
        bubbleStates[currentSilhouette] ?? []
    }

    private var poppedCount: Int {
        poppedCounts[currentSilhouette] ?? 0
    }

    private var totalBubbles: Int {
        totalCounts[currentSilhouette] ?? 0
    }

    var body: some View {
        GeometryReader { geo in
            let layout = PopGridLayout(geoSize: geo.size, cols: cols, rows: rows)
            let screenWidth = geo.size.width

            ZStack {
                backgroundView

                VStack(spacing: 12) {
                    Spacer()

                    gridSection(layout: layout)
                        .offset(x: gridOffset + dragOffset)
                        .opacity(gridOpacity)
                        .frame(maxWidth: .infinity)

                    Spacer()

                    // Reset button (only when some bubbles are popped)
                    if poppedCount > 0 {
                        resetButton
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    // Text picker
                    PopShapePicker(current: currentSilhouette) { target in
                        let dir: SlideDirection = target.rawValue > currentSilhouette.rawValue ? .left : .right
                        transitionTo(target, direction: dir, screenWidth: screenWidth)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)
                }
            }
            .gesture(swipeGesture(screenWidth: screenWidth))
        }
        .onAppear { ensureGrid(for: currentSilhouette) }
        .animation(.easeInOut(duration: 0.3), value: poppedCount)
    }

    // MARK: - Reset Button

    private var resetButton: some View {
        Button {
            resetCurrentGrid()
            if hapticsEnabled {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: showResetConfirmation ? "checkmark" : "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .medium))
                Text(showResetConfirmation ? "Done" : "Reset")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundStyle(.white.opacity(showResetConfirmation ? 0.6 : 0.3))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(.white.opacity(0.06))
            )
        }
        .animation(.easeInOut(duration: 0.2), value: showResetConfirmation)
    }

    private func resetCurrentGrid() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showResetConfirmation = true
        }

        regenerateGrid(for: currentSilhouette)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation { showResetConfirmation = false }
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
                    isAlreadyPopped: bubble.isPopped,
                    onPop: { handlePop(bubbleId: bubble.id) },
                    hapticsEnabled: hapticsEnabled,
                    soundEnabled: soundEnabled
                )
                .position(
                    x: CGFloat(bubble.col) * cellSize + cellSize * 0.5,
                    y: CGFloat(bubble.row) * cellSize + cellSize * 0.5
                )
                .id("\(currentSilhouette.rawValue)-\(bubble.id)-\(bubble.isPopped)")
            }
        }
    }

    // MARK: - Swipe Gesture

    private func swipeGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 30)
            .onChanged { value in
                guard !isTransitioning else { return }
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                if isHorizontal {
                    dragOffset = value.translation.width * 0.4
                }
            }
            .onEnded { value in
                guard !isTransitioning else { return }
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                guard isHorizontal else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                    return
                }

                let threshold: CGFloat = 50
                if value.translation.width < -threshold {
                    transitionTo(currentSilhouette.next, direction: .left, screenWidth: screenWidth)
                } else if value.translation.width > threshold {
                    transitionTo(currentSilhouette.previous, direction: .right, screenWidth: screenWidth)
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        dragOffset = 0
                    }
                }
            }
    }

    // MARK: - Grid Logic

    private func ensureGrid(for shape: BubbleSilhouette) {
        if bubbleStates[shape] == nil {
            regenerateGrid(for: shape)
        }
    }

    private func regenerateGrid(for shape: BubbleSilhouette) {
        var result: [PopBubble] = []
        var idx = 0

        for row in 0..<rows {
            for col in 0..<cols {
                let nx = (Double(col) + 0.5) / Double(cols) * 2.0 - 1.0
                let ny = (Double(row) + 0.5) / Double(rows) * 2.0 - 1.0

                let code = shapeColorCode(shape, nx: nx, ny: ny)
                if code != 0 {
                    result.append(PopBubble(id: idx, col: col, row: row, colorCode: code))
                    idx += 1
                }
            }
        }

        bubbleStates[shape] = result
        totalCounts[shape] = result.count
        poppedCounts[shape] = 0
    }

    private func handlePop(bubbleId: Int) {
        // Mark bubble as popped in state
        if var stateBubbles = bubbleStates[currentSilhouette],
           let index = stateBubbles.firstIndex(where: { $0.id == bubbleId }) {
            stateBubbles[index] = PopBubble(
                id: stateBubbles[index].id,
                col: stateBubbles[index].col,
                row: stateBubbles[index].row,
                colorCode: stateBubbles[index].colorCode,
                isPopped: true
            )
            bubbleStates[currentSilhouette] = stateBubbles
        }

        poppedCounts[currentSilhouette] = (poppedCounts[currentSilhouette] ?? 0) + 1

        if poppedCount >= totalBubbles {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                transitionTo(currentSilhouette.next, direction: .left, screenWidth: UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.screen.bounds.width ?? 393)
            }
        }
    }

    private func transitionTo(_ target: BubbleSilhouette, direction: SlideDirection, screenWidth: CGFloat) {
        guard !isTransitioning else { return }
        guard target != currentSilhouette else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                dragOffset = 0
            }
            return
        }
        isTransitioning = true

        if hapticsEnabled {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        // Ensure target grid exists
        ensureGrid(for: target)

        let slideOut = screenWidth * 0.5 * direction.outOffset

        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            gridOffset = slideOut
            gridOpacity = 0
            dragOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            currentSilhouette = target

            gridOffset = screenWidth * 0.4 * direction.inOffset
            gridOpacity = 0

            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                gridOffset = 0
                gridOpacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isTransitioning = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PopView(
        currentSilhouette: .constant(.heart),
        soundEnabled: .constant(true),
        hapticsEnabled: .constant(true)
    )
    .preferredColorScheme(.dark)
}
