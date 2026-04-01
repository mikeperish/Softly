// PopView.swift
// Fidget App — Interactive Bubble Wrap
// iOS 17+, SwiftUI

import SwiftUI
import AudioToolbox

// MARK: - Silhouette Definition

enum BubbleSilhouette: Int, CaseIterable {
    case heart = 0
    case paw = 1
    case cactus = 2
    case cloud = 3
    case moon = 4
    case diamond = 5
    case flower = 6
    case cat = 7
    case mushroom = 8
    case fish = 9

    var displayName: String {
        switch self {
        case .heart:    "Heart"
        case .paw:     "Paw"
        case .cactus:   "Cactus"
        case .cloud:    "Cloud"
        case .moon:     "Moon"
        case .diamond:  "Diamond"
        case .flower:   "Flower"
        case .cat:      "Cat"
        case .mushroom: "Mushroom"
        case .fish:     "Fish"
        }
    }

    var isFree: Bool {
        switch self {
        case .heart, .paw: return true
        default: return false
        }
    }

    var accentColor: Color {
        switch self {
        case .heart:    Color(red: 1.0, green: 0.2, blue: 0.3)
        case .paw:     Color(red: 0.9, green: 0.65, blue: 0.35)
        case .cactus:   Color(red: 0.2, green: 0.75, blue: 0.3)
        case .cloud:    Color(red: 0.45, green: 0.70, blue: 1.0)
        case .moon:     Color(red: 0.7, green: 0.6, blue: 1.0)
        case .diamond:  Color(red: 0.4, green: 0.85, blue: 0.95)
        case .flower:   Color(red: 0.95, green: 0.45, blue: 0.65)
        case .cat:      Color(red: 0.75, green: 0.55, blue: 0.85)
        case .mushroom: Color(red: 0.85, green: 0.35, blue: 0.35)
        case .fish:     Color(red: 0.3, green: 0.75, blue: 0.85)
        }
    }

    var secondaryColor: Color {
        switch self {
        case .heart:    Color(red: 0.5, green: 0.05, blue: 0.15)
        case .paw:     Color(red: 0.45, green: 0.3, blue: 0.15)
        case .cactus:   Color(red: 0.1, green: 0.35, blue: 0.15)
        case .cloud:    Color(red: 0.18, green: 0.35, blue: 0.65)
        case .moon:     Color(red: 0.3, green: 0.25, blue: 0.55)
        case .diamond:  Color(red: 0.15, green: 0.4, blue: 0.5)
        case .flower:   Color(red: 0.5, green: 0.2, blue: 0.3)
        case .cat:      Color(red: 0.35, green: 0.25, blue: 0.45)
        case .mushroom: Color(red: 0.45, green: 0.15, blue: 0.15)
        case .fish:     Color(red: 0.12, green: 0.35, blue: 0.45)
        }
    }

    var bgGlow: Color {
        switch self {
        case .heart:    Color(red: 0.40, green: 0.08, blue: 0.15)
        case .paw:     Color(red: 0.22, green: 0.15, blue: 0.08)
        case .cactus:   Color(red: 0.05, green: 0.20, blue: 0.10)
        case .cloud:    Color(red: 0.08, green: 0.15, blue: 0.30)
        case .moon:     Color(red: 0.15, green: 0.12, blue: 0.30)
        case .diamond:  Color(red: 0.08, green: 0.20, blue: 0.25)
        case .flower:   Color(red: 0.25, green: 0.10, blue: 0.15)
        case .cat:      Color(red: 0.18, green: 0.12, blue: 0.22)
        case .mushroom: Color(red: 0.25, green: 0.08, blue: 0.08)
        case .fish:     Color(red: 0.06, green: 0.18, blue: 0.22)
        }
    }

    var bubbleCornerFraction: CGFloat {
        switch self {
        case .heart, .cloud, .moon, .flower, .fish: return 1.0
        case .cactus, .mushroom: return 0.35
        case .diamond: return 0.45
        case .cat, .paw: return 0.5
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

// MARK: - Shape Hit-Test (Pixel Matrices 11x13)

func shapeColorCode(_ shape: BubbleSilhouette, nx: Double, ny: Double) -> Int {
    let col = Int((nx + 1.0) / 2.0 * 11.0)
    let row = Int((ny + 1.0) / 2.0 * 13.0)
    guard col >= 0, col < 11, row >= 0, row < 13 else { return 0 }
    return shapeMatrices[shape]![row][col]
}

func isInsideShape(_ shape: BubbleSilhouette, nx: Double, ny: Double) -> Bool {
    return shapeColorCode(shape, nx: nx, ny: ny) != 0
}

// MARK: - Pixel Matrices (11x13 each)

private let shapeMatrices: [BubbleSilhouette: [[Int]]] = [
    .heart: [
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
    ],
    .paw: [
        [0,0,0,0,0,2,0,0,0,0,0],
        [0,0,0,0,2,3,2,0,0,0,0],
        [0,0,0,0,2,3,2,0,0,0,0],
        [0,0,2,0,2,1,2,0,2,0,0],
        [0,2,3,2,0,2,0,2,3,2,0],
        [0,2,1,2,0,0,0,2,1,2,0],
        [0,0,2,0,0,0,0,0,2,0,0],
        [0,0,0,2,2,2,2,2,0,0,0],
        [0,0,3,3,1,1,1,1,2,0,0],
        [0,2,3,3,1,1,1,1,1,2,0],
        [0,2,3,1,1,1,1,1,1,2,0],
        [0,0,2,1,1,1,1,1,2,0,0],
        [0,0,0,2,1,1,1,2,0,0,0],
    ],
    .cactus: [
        [0,0,0,0,0,1,1,0,0,0,0],
        [0,0,0,0,0,3,1,0,0,0,0],
        [0,1,1,0,0,3,1,0,0,0,0],
        [0,3,1,0,0,3,1,0,1,1,0],
        [0,3,1,1,1,1,1,1,3,1,0],
        [0,0,0,0,0,1,1,1,1,1,0],
        [0,0,0,0,0,3,1,0,0,0,0],
        [0,0,0,0,0,3,1,0,0,0,0],
        [0,0,0,0,0,3,1,0,0,0,0],
        [0,0,0,0,0,3,1,0,0,0,0],
        [0,0,0,0,0,3,1,0,0,0,0],
        [0,0,0,1,1,1,1,1,1,0,0],
        [0,0,0,2,2,2,2,2,1,0,0],
    ],
    .cloud: [
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,1,1,0,0,0,0,0,0],
        [0,0,1,3,3,1,0,1,1,0,0],
        [0,0,1,3,1,1,1,3,1,1,0],
        [0,1,1,1,1,1,1,3,1,1,0],
        [0,1,3,1,1,1,1,1,1,1,0],
        [1,1,1,1,1,1,1,1,1,2,1],
        [1,1,1,1,1,1,1,1,2,2,1],
        [0,1,2,2,1,2,2,2,2,1,0],
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
    ],
    .moon: [
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,1,1,1,0,0,0],
        [0,0,0,0,1,3,3,1,1,0,0],
        [0,0,0,1,3,3,1,0,0,0,0],
        [0,0,1,3,1,1,0,0,0,0,0],
        [0,0,1,1,1,0,0,0,0,0,0],
        [0,0,1,1,1,0,0,0,0,0,0],
        [0,0,1,1,1,0,0,0,0,0,0],
        [0,0,1,1,1,1,0,0,0,0,0],
        [0,0,0,1,1,1,1,0,0,0,0],
        [0,0,0,0,1,1,2,1,1,0,0],
        [0,0,0,0,0,1,1,1,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
    ],
    .diamond: [
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,2,2,2,2,2,0,0,0],
        [0,0,2,3,3,2,1,1,2,0,0],
        [0,2,3,1,3,2,1,1,1,2,0],
        [2,3,2,3,2,3,2,1,1,1,2],
        [3,3,3,3,3,3,3,3,3,3,3],
        [2,3,1,2,1,1,1,2,1,1,2],
        [0,2,3,1,2,1,2,1,1,2,0],
        [0,0,2,3,2,1,2,1,2,0,0],
        [0,0,0,2,3,2,1,2,0,0,0],
        [0,0,0,0,2,3,2,0,0,0,0],
        [0,0,0,0,0,2,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
    ],
    .flower: [
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,1,1,1,0,0,0,0],
        [0,0,0,1,3,3,1,1,0,0,0],
        [0,1,1,0,1,1,1,0,1,1,0],
        [1,3,1,0,0,0,0,0,1,2,1],
        [1,1,1,0,1,1,1,0,1,1,1],
        [0,1,0,1,3,1,2,1,0,1,0],
        [0,0,0,1,1,1,1,1,0,0,0],
        [0,1,1,0,1,1,1,0,1,1,0],
        [1,3,1,0,0,1,0,0,1,2,1],
        [1,1,1,0,0,1,0,0,1,1,1],
        [0,1,1,0,0,1,0,0,1,1,0],
        [0,0,0,0,0,0,0,0,0,0,0],
    ],
    .cat: [
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,1,1,0,0,0,0,0,1,1,0],
        [0,3,1,1,0,0,0,1,1,2,0],
        [0,3,1,1,0,0,0,1,1,2,0],
        [0,1,1,1,1,1,1,1,1,1,0],
        [0,1,3,1,1,1,1,1,1,1,0],
        [0,1,1,3,1,1,1,2,1,1,0],
        [0,1,1,1,1,1,1,1,1,1,0],
        [0,1,1,1,1,1,1,1,1,1,0],
        [0,0,1,1,1,1,1,1,1,0,0],
        [0,0,0,1,1,1,1,1,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
    ],
    .mushroom: [
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,1,1,1,0,0,0,0],
        [0,0,0,1,3,3,3,1,0,0,0],
        [0,0,1,3,3,1,1,1,1,0,0],
        [0,1,1,3,1,1,3,1,1,1,0],
        [1,1,1,1,1,1,1,1,1,1,1],
        [1,1,1,1,1,1,1,1,1,2,1],
        [0,2,2,2,1,1,1,2,2,2,0],
        [0,0,0,0,1,1,1,0,0,0,0],
        [0,0,0,0,1,1,1,0,0,0,0],
        [0,0,0,0,1,1,1,0,0,0,0],
        [0,0,0,1,1,1,1,1,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
    ],
    .fish: [
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,1,1,1,1,0,0,0],
        [1,1,0,1,3,3,1,1,1,0,0],
        [1,1,1,1,3,1,1,3,1,1,0],
        [1,1,1,1,1,1,1,1,1,1,1],
        [1,1,1,1,1,1,1,1,1,1,0],
        [1,1,0,1,1,1,2,2,1,0,0],
        [0,0,0,0,1,2,2,1,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
        [0,0,0,0,0,0,0,0,0,0,0],
    ],
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
    let isLocked: Bool
    let onPop: () -> Void
    let onLockedTap: () -> Void
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
                        if isLocked {
                            // Bounce back and show paywall
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                popScale = 1.0
                            }
                            onLockedTap()
                        } else {
                            performPop()
                        }
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
        Text(silhouette.displayName.prefix(1))
            .font(.system(size: size, weight: .semibold, design: .rounded))
            .foregroundStyle(silhouette.accentColor)
    }
}

// MARK: - Horizontal Scroll Picker

struct PopShapePicker: View {
    let current: BubbleSilhouette
    let isPremium: Bool
    let onSelect: (BubbleSilhouette) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(BubbleSilhouette.allCases, id: \.rawValue) { shape in
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
    @Environment(SubscriptionManager.self) private var subscriptionManager

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

    // Premium paywall
    @State private var showPaywall = false

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

    private var isCurrentLocked: Bool {
        !currentSilhouette.isFree && !subscriptionManager.isPremium
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

                    // Reset button (only for free silhouettes)
                    resetButton
                        .opacity(!isCurrentLocked && poppedCount > 0 ? 1 : 0)
                        .allowsHitTesting(!isCurrentLocked && poppedCount > 0)

                    // Horizontal scroll picker
                    PopShapePicker(
                        current: currentSilhouette,
                        isPremium: subscriptionManager.isPremium,
                        onSelect: { target in
                            let dir: SlideDirection = target.rawValue > currentSilhouette.rawValue ? .left : .right
                            transitionTo(target, direction: dir, screenWidth: screenWidth)
                        }
                    )
                    .padding(.bottom, 20)
                }
            }
            .gesture(swipeGesture(screenWidth: screenWidth))
        }
        .onAppear { ensureGrid(for: currentSilhouette) }
        .animation(.easeInOut(duration: 0.3), value: poppedCount)
        .sheet(isPresented: $showPaywall) {
            PremiumView()
        }
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
                    isLocked: isCurrentLocked,
                    onPop: { handlePop(bubbleId: bubble.id) },
                    onLockedTap: {
                        showPaywall = true
                        if hapticsEnabled {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    },
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
    .environment(SubscriptionManager.shared)
    .preferredColorScheme(.dark)
}
