// MARK: - PhysicsView.swift
// Fidget App — Physics Tab: Spinning Top (Дзига)
// 10 hypnotic patterns, premium gating

import SwiftUI
import SpriteKit
import CoreMotion
import AudioToolbox

// MARK: - Spinner Pattern Enum
enum SpinnerPattern: Int, CaseIterable {
    case pulse = 0
    case fibonacci = 1
    case spiral = 2
    case mandala = 3
    case starburst = 4
    case vortex = 5
    case dots = 6
    case waves = 7
    case galaxy = 8
    case hypno = 9

    var name: String {
        switch self {
        case .pulse:     return "Pulse"
        case .fibonacci: return "Fibonacci"
        case .spiral:    return "Spiral"
        case .mandala:   return "Mandala"
        case .starburst: return "Starburst"
        case .vortex:    return "Vortex"
        case .dots:      return "Dots"
        case .waves:     return "Waves"
        case .galaxy:    return "Galaxy"
        case .hypno:     return "Hypno"
        }
    }

    var isFree: Bool {
        switch self {
        case .pulse, .fibonacci: return true
        default: return false
        }
    }
}

// MARK: - PhysicsView (SwiftUI wrapper)
struct PhysicsView: View {
    @State private var currentPattern: SpinnerPattern = .pulse
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var showPaywall = false
    @Environment(SubscriptionManager.self) private var subscriptionManager

    private var isCurrentLocked: Bool {
        !currentPattern.isFree && !subscriptionManager.isPremium
    }

    var body: some View {
        ZStack {
            AppBackground(accentColor: AppColors.physics)

            SpriteView(
                scene: SpinnerScene.shared,
                options: [.allowsTransparency]
            )
            .ignoresSafeArea()
            .onAppear {
                SpinnerScene.shared.soundEnabled = soundEnabled
                SpinnerScene.shared.hapticsEnabled = hapticsEnabled
                SpinnerScene.shared.currentPattern = currentPattern
                SpinnerScene.shared.isLocked = isCurrentLocked
                SpinnerScene.shared.onLockedSpin = { [self] in
                    showPaywall = true
                }
            }
            .onChange(of: currentPattern) { _, _ in
                SpinnerScene.shared.isLocked = !currentPattern.isFree && !subscriptionManager.isPremium
            }

            // Pattern picker (bottom)
            VStack {
                Spacer()
                patternPicker
                    .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PremiumView()
        }
    }

    // MARK: - Pattern Picker
    private var patternPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(SpinnerPattern.allCases, id: \.rawValue) { pattern in
                        let isActive = pattern == currentPattern
                        let isLocked = !pattern.isFree && !subscriptionManager.isPremium

                        Button {
                            if pattern != currentPattern {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPattern = pattern
                                    SpinnerScene.shared.currentPattern = pattern
                                }
                                if hapticsEnabled {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                if isLocked {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 9))
                                        .foregroundStyle(.white.opacity(0.2))
                                }
                                Text(pattern.name)
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
                                    .fill(isActive ? AppColors.physics.opacity(0.25) : .clear)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                isActive ? AppColors.physics.opacity(0.4) :
                                                isLocked ? .white.opacity(0.05) : .white.opacity(0.08),
                                                lineWidth: 0.5
                                            )
                                    )
                            )
                        }
                        .id(pattern.rawValue)
                        .animation(.easeInOut(duration: 0.25), value: isActive)
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: currentPattern) { _, newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    proxy.scrollTo(newValue.rawValue, anchor: .center)
                }
            }
        }
    }
}

// MARK: - Aurora Color Palette
struct AuroraColors {
    static let blue = UIColor(red: 0.04, green: 0.52, blue: 0.89, alpha: 1.0)
    static let sky = UIColor(red: 0.20, green: 0.65, blue: 0.95, alpha: 1.0)
    static let ice = UIColor(red: 0.55, green: 0.82, blue: 1.0, alpha: 1.0)
    static let indigo = UIColor(red: 0.15, green: 0.35, blue: 0.75, alpha: 1.0)
    static let white = UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 1.0)

    static let all: [UIColor] = [blue, sky, ice, indigo, white]
}

// MARK: - SpinnerScene (SpriteKit)
class SpinnerScene: SKScene {

    static let shared: SpinnerScene = {
        let scene = SpinnerScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }()

    var soundEnabled = true
    var hapticsEnabled = true
    var isLocked = false
    var onLockedSpin: (() -> Void)?
    var currentPattern: SpinnerPattern = .pulse {
        didSet {
            guard sceneReady else { return }
            rebuildPattern()
        }
    }

    private var spinnerNode: SKNode!
    private var patternNode: SKNode!
    private var borderNode: SKShapeNode!
    private var centerDot: SKShapeNode!

    private let motionManager = CMMotionManager()
    private var angularVelocity: CGFloat = 0
    private var spinnerPosition: CGPoint = .zero
    private var spinnerVelocity: CGVector = .zero

    private var currentRotation: CGFloat = 0
    private var lastTouchAngle: CGFloat?
    private var lastTouchTime: TimeInterval?

    private let spinnerRadius: CGFloat = 80
    private let friction: CGFloat = 0.9965
    private let moveFriction: CGFloat = 0.98
    private let wallBounce: CGFloat = 1.1
    private let wallSpinLoss: CGFloat = 0.95
    private let gravityScale: CGFloat = 800.0

    private var ringNodes: [SKShapeNode] = []
    private var fibonacciNodes: [SKShapeNode] = []
    private let ringCount = 12

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)

    private var sceneReady = false

    // MARK: - Scene Setup
    override func didMove(to view: SKView) {
        guard !sceneReady else { return }
        sceneReady = true

        physicsWorld.gravity = .zero
        spinnerPosition = CGPoint(x: size.width / 2, y: size.height / 2)

        spinnerNode = SKNode()
        spinnerNode.position = spinnerPosition
        addChild(spinnerNode)

        patternNode = SKNode()
        spinnerNode.addChild(patternNode)

        borderNode = SKShapeNode(circleOfRadius: spinnerRadius)
        borderNode.strokeColor = AuroraColors.blue.withAlphaComponent(0.6)
        borderNode.lineWidth = 2.5
        borderNode.fillColor = .clear
        borderNode.glowWidth = 1
        spinnerNode.addChild(borderNode)

        centerDot = SKShapeNode(circleOfRadius: 6)
        centerDot.fillColor = AuroraColors.blue.withAlphaComponent(0.9)
        centerDot.strokeColor = AuroraColors.sky.withAlphaComponent(0.5)
        centerDot.lineWidth = 1.5
        spinnerNode.addChild(centerDot)

        rebuildPattern()
        startMotionUpdates()
    }

    // MARK: - Pattern Builders
    private func rebuildPattern() {
        patternNode.removeAllChildren()
        ringNodes.removeAll()
        fibonacciNodes.removeAll()

        switch currentPattern {
        case .pulse:     buildPulsePattern()
        case .fibonacci: buildFibonacciPattern()
        case .spiral:    buildSpiralPattern()
        case .mandala:   buildMandalaPattern()
        case .starburst: buildStarburstPattern()
        case .vortex:    buildVortexPattern()
        case .dots:      buildDotsPattern()
        case .waves:     buildWavesPattern()
        case .galaxy:    buildGalaxyPattern()
        case .hypno:     buildHypnoPattern()
        }
    }

    private func buildPulsePattern() {
        for i in 0..<ringCount {
            let radius = CGFloat(ringCount - i) * (spinnerRadius * 0.85 / CGFloat(ringCount))
            let ring = SKShapeNode(circleOfRadius: radius)
            let color = AuroraColors.all[i % AuroraColors.all.count]
            ring.strokeColor = color.withAlphaComponent(0.3 + CGFloat(i) * 0.03)
            ring.lineWidth = 2.5
            ring.fillColor = .clear
            patternNode.addChild(ring)
            ringNodes.append(ring)
        }
    }

    private func buildFibonacciPattern() {
        let arms = 8
        let pointsPerArm = 60
        for a in 0..<arms {
            let path = CGMutablePath()
            var firstPoint = true
            for p in 0..<pointsPerArm {
                let t = CGFloat(p) / CGFloat(pointsPerArm)
                let radius = t * (spinnerRadius - 8)
                let angle = t * .pi * 4 + CGFloat(a) * (.pi * 2 / CGFloat(arms))
                let x = cos(angle) * radius
                let y = sin(angle) * radius
                if firstPoint { path.move(to: CGPoint(x: x, y: y)); firstPoint = false }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            let arm = SKShapeNode(path: path)
            let color = AuroraColors.all[a % AuroraColors.all.count]
            arm.strokeColor = color.withAlphaComponent(0.5)
            arm.lineWidth = 2.5
            arm.fillColor = .clear
            arm.lineCap = .round
            patternNode.addChild(arm)
            fibonacciNodes.append(arm)
        }
        let dotCount = 34
        let goldenAngle: CGFloat = .pi * 2 / (1 + sqrt(5) / 2)
        for i in 0..<dotCount {
            let t = CGFloat(i) / CGFloat(dotCount)
            let radius = t * (spinnerRadius - 12)
            let angle = CGFloat(i) * goldenAngle
            let dot = SKShapeNode(circleOfRadius: 2.5 + t * 2)
            dot.position = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            let color = AuroraColors.all[i % AuroraColors.all.count]
            dot.fillColor = color.withAlphaComponent(0.3 + t * 0.4)
            dot.strokeColor = .clear
            patternNode.addChild(dot)
        }
    }

    private func buildSpiralPattern() {
        for s in 0..<2 {
            let path = CGMutablePath()
            var first = true
            let points = 200
            for p in 0..<points {
                let t = CGFloat(p) / CGFloat(points)
                let angle = t * 4 * 2 * .pi + CGFloat(s) * .pi
                let r = t * (spinnerRadius - 5)
                let x = cos(angle) * r
                let y = sin(angle) * r
                if first { path.move(to: CGPoint(x: x, y: y)); first = false }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            let spiral = SKShapeNode(path: path)
            spiral.strokeColor = AuroraColors.all[s].withAlphaComponent(0.6)
            spiral.lineWidth = 3
            spiral.lineCap = .round
            spiral.fillColor = .clear
            patternNode.addChild(spiral)
            ringNodes.append(spiral)
        }
    }

    private func buildMandalaPattern() {
        let petals = 12
        for i in 0..<petals {
            let angle = CGFloat(i) / CGFloat(petals) * 2 * .pi
            let path = CGMutablePath()
            let r = spinnerRadius * 0.7
            let cx = cos(angle) * r * 0.4
            let cy = sin(angle) * r * 0.4
            path.addEllipse(in: CGRect(x: cx - r * 0.3, y: cy - r * 0.12, width: r * 0.6, height: r * 0.24),
                          transform: CGAffineTransform(rotationAngle: angle))
            let petal = SKShapeNode(path: path)
            let color = AuroraColors.all[i % AuroraColors.all.count]
            petal.strokeColor = color.withAlphaComponent(0.5)
            petal.lineWidth = 2
            petal.fillColor = color.withAlphaComponent(0.08)
            patternNode.addChild(petal)
            ringNodes.append(petal)
        }
        for r in stride(from: 15, through: 45, by: 15) as StrideThrough<Int> {
            let ring = SKShapeNode(circleOfRadius: CGFloat(r))
            ring.strokeColor = AuroraColors.sky.withAlphaComponent(0.25)
            ring.lineWidth = 1.5
            ring.fillColor = .clear
            patternNode.addChild(ring)
        }
    }

    private func buildStarburstPattern() {
        let rays = 16
        for i in 0..<rays {
            let angle = CGFloat(i) / CGFloat(rays) * 2 * .pi
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 8 * cos(angle), y: 8 * sin(angle)))
            path.addLine(to: CGPoint(x: (spinnerRadius - 4) * cos(angle),
                                     y: (spinnerRadius - 4) * sin(angle)))
            let ray = SKShapeNode(path: path)
            let color = AuroraColors.all[i % AuroraColors.all.count]
            ray.strokeColor = color.withAlphaComponent(0.5)
            ray.lineWidth = i % 2 == 0 ? 3 : 1.5
            ray.lineCap = .round
            patternNode.addChild(ray)
            ringNodes.append(ray)
        }
    }

    private func buildVortexPattern() {
        let rings = 8
        for i in 0..<rings {
            let t = CGFloat(i + 1) / CGFloat(rings + 1)
            let r = t * spinnerRadius * 0.9
            let ring = SKShapeNode(circleOfRadius: r)
            let color = AuroraColors.all[i % AuroraColors.all.count]
            ring.strokeColor = color.withAlphaComponent(0.3 + t * 0.3)
            ring.lineWidth = 1.5 + t * 2
            ring.fillColor = .clear
            patternNode.addChild(ring)
            ringNodes.append(ring)
        }
    }

    private func buildDotsPattern() {
        let circles = 5
        let dotsPerCircle = [6, 8, 10, 12, 14]
        for c in 0..<circles {
            let r = CGFloat(c + 1) / CGFloat(circles + 1) * spinnerRadius * 0.95
            let count = dotsPerCircle[c]
            for d in 0..<count {
                let angle = CGFloat(d) / CGFloat(count) * 2 * .pi
                let dotR: CGFloat = 3.5 - CGFloat(c) * 0.3
                let dot = SKShapeNode(circleOfRadius: dotR)
                dot.position = CGPoint(x: cos(angle) * r, y: sin(angle) * r)
                let color = AuroraColors.all[(c + d) % AuroraColors.all.count]
                dot.fillColor = color.withAlphaComponent(0.6)
                dot.strokeColor = .clear
                patternNode.addChild(dot)
            }
        }
    }

    private func buildWavesPattern() {
        let waveCount = 6
        for w in 0..<waveCount {
            let baseAngle = CGFloat(w) / CGFloat(waveCount) * 2 * .pi
            let path = CGMutablePath()
            var first = true
            let points = 80
            for p in 0..<points {
                let t = CGFloat(p) / CGFloat(points)
                let r = t * (spinnerRadius - 5)
                let safeR = max(r, 1)
                let wobble = sin(t * 6 * .pi) * 8
                let angle = baseAngle + wobble / safeR
                let x = cos(angle) * r
                let y = sin(angle) * r
                if first { path.move(to: CGPoint(x: x, y: y)); first = false }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }
            let wave = SKShapeNode(path: path)
            let color = AuroraColors.all[w % AuroraColors.all.count]
            wave.strokeColor = color.withAlphaComponent(0.5)
            wave.lineWidth = 2.5
            wave.lineCap = .round
            wave.fillColor = .clear
            patternNode.addChild(wave)
            ringNodes.append(wave)
        }
    }

    private func buildGalaxyPattern() {
        let arms = 3
        let starsPerArm = 40
        for a in 0..<arms {
            let baseAngle = CGFloat(a) / CGFloat(arms) * 2 * .pi
            for s in 0..<starsPerArm {
                let t = CGFloat(s) / CGFloat(starsPerArm)
                let r = t * (spinnerRadius - 6)
                let spiralAngle = baseAngle + t * .pi * 3
                let jitterR = CGFloat.random(in: -5...5)
                let jitterA = CGFloat.random(in: -0.15...0.15)
                let x = cos(spiralAngle + jitterA) * (r + jitterR)
                let y = sin(spiralAngle + jitterA) * (r + jitterR)
                let starSize: CGFloat = 1.5 + t * 2.5 + CGFloat.random(in: 0...1)
                let star = SKShapeNode(circleOfRadius: starSize)
                star.position = CGPoint(x: x, y: y)
                let color = AuroraColors.all[(a + s) % AuroraColors.all.count]
                star.fillColor = color.withAlphaComponent(0.3 + t * 0.5)
                star.strokeColor = .clear
                patternNode.addChild(star)
            }
        }
    }

    private func buildHypnoPattern() {
        let sectors = 12
        for i in 0..<sectors {
            let startAngle = CGFloat(i) / CGFloat(sectors) * 2 * .pi
            let endAngle = CGFloat(i + 1) / CGFloat(sectors) * 2 * .pi
            let path = CGMutablePath()
            path.move(to: .zero)
            path.addArc(center: .zero, radius: spinnerRadius - 4,
                       startAngle: startAngle, endAngle: endAngle, clockwise: false)
            path.closeSubpath()
            let sector = SKShapeNode(path: path)
            if i % 2 == 0 {
                sector.fillColor = AuroraColors.ice.withAlphaComponent(0.15)
                sector.strokeColor = AuroraColors.ice.withAlphaComponent(0.3)
            } else {
                sector.fillColor = UIColor.clear
                sector.strokeColor = AuroraColors.blue.withAlphaComponent(0.15)
            }
            sector.lineWidth = 0.5
            patternNode.addChild(sector)
            ringNodes.append(sector)
        }
    }

    // MARK: - CoreMotion
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates()
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let dx = loc.x - spinnerNode.position.x
        let dy = loc.y - spinnerNode.position.y
        lastTouchAngle = atan2(dy, dx)
        lastTouchTime = touch.timestamp
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isLocked {
            // Fire only once per touch
            if lastTouchAngle != nil {
                lastTouchAngle = nil
                onLockedSpin?()
            }
            return
        }
        guard let touch = touches.first,
              let prevAngle = lastTouchAngle,
              let prevTime = lastTouchTime else { return }

        let loc = touch.location(in: self)
        let dx = loc.x - spinnerNode.position.x
        let dy = loc.y - spinnerNode.position.y
        let currentAngle = atan2(dy, dx)
        let timestamp = touch.timestamp

        var deltaAngle = currentAngle - prevAngle
        if deltaAngle > .pi { deltaAngle -= 2 * .pi }
        if deltaAngle < -.pi { deltaAngle += 2 * .pi }

        let dt = timestamp - prevTime
        guard dt > 0 else { return }

        let dist = hypot(dx, dy)
        let leverMultiplier = min(dist / spinnerRadius, 2.0)
        let swipeAngularVel = (deltaAngle / CGFloat(dt)) * leverMultiplier

        angularVelocity += swipeAngularVel * 0.6
        let maxVel: CGFloat = 50
        angularVelocity = max(-maxVel, min(maxVel, angularVelocity))

        if hapticsEnabled && abs(swipeAngularVel) > 5 {
            impactLight.impactOccurred(intensity: min(abs(swipeAngularVel) / 20, 1.0))
        }

        lastTouchAngle = currentAngle
        lastTouchTime = timestamp
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchAngle = nil
        lastTouchTime = nil
    }

    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        currentRotation += angularVelocity * (1.0 / 60.0)

        switch currentPattern {
        case .pulse:
            updatePulsePattern()
        case .vortex:
            updateVortexPattern()
        default:
            patternNode.zRotation = currentRotation
        }

        angularVelocity *= friction
        if abs(angularVelocity) < 0.01 { angularVelocity = 0 }

        if abs(angularVelocity) > 0.1, let motion = motionManager.deviceMotion {
            let gx = CGFloat(motion.gravity.x) * gravityScale
            let gy = CGFloat(motion.gravity.y) * gravityScale
            spinnerVelocity.dx += gx * (1.0 / 60.0)
            spinnerVelocity.dy += gy * (1.0 / 60.0)
        }

        if abs(angularVelocity) < 0.1 {
            spinnerVelocity.dx *= 0.9
            spinnerVelocity.dy *= 0.9
            if abs(spinnerVelocity.dx) < 0.5 { spinnerVelocity.dx = 0 }
            if abs(spinnerVelocity.dy) < 0.5 { spinnerVelocity.dy = 0 }
        }

        spinnerVelocity.dx *= moveFriction
        spinnerVelocity.dy *= moveFriction

        spinnerPosition.x += spinnerVelocity.dx * (1.0 / 60.0)
        spinnerPosition.y += spinnerVelocity.dy * (1.0 / 60.0)

        handleWallCollisions()

        if hapticsEnabled && abs(angularVelocity) > 2 {
            let spinSpeed = abs(angularVelocity)
            let tickInterval = max(2, Int(30.0 / spinSpeed))
            let frameCount = Int(currentRotation * 10)
            if frameCount % tickInterval == 0 {
                let intensity = min(spinSpeed / 25.0, 0.4)
                impactLight.impactOccurred(intensity: intensity)
            }
        }

        spinnerNode.position = spinnerPosition

        let speed = abs(angularVelocity)
        borderNode.glowWidth = speed > 1 ? min(speed / 4.0, 5.0) : 0.5

        let hue = (currentRotation.truncatingRemainder(dividingBy: .pi * 2)) / (.pi * 2)
        let borderColor = UIColor(
            hue: 0.57 + abs(hue) * 0.08,
            saturation: 0.7 + min(speed / 30, 0.25),
            brightness: 0.7 + min(speed / 20, 0.25),
            alpha: 0.7
        )
        borderNode.strokeColor = borderColor
    }

    private func updatePulsePattern() {
        let rot = currentRotation
        let speed = abs(angularVelocity)

        for (i, ring) in ringNodes.enumerated() {
            let fi = CGFloat(i)
            let wobbleAmount = min(speed * 0.3, 6.0)
            let wobble = sin(rot * 2.0 + fi * 0.8) * wobbleAmount
            ring.position = CGPoint(x: cos(rot + fi) * wobble, y: sin(rot + fi) * wobble)

            let alpha = 0.15 + 0.08 * sin(rot * 3.0 + fi) + min(speed * 0.005, 0.15)
            let color = AuroraColors.all[i % AuroraColors.all.count]
            ring.strokeColor = color.withAlphaComponent(alpha + fi * 0.03)
            ring.setScale(1.0 + sin(rot * 1.5 + fi * 0.5) * min(speed * 0.002, 0.05))
        }
    }

    private func updateVortexPattern() {
        let rot = currentRotation
        let speed = abs(angularVelocity)
        patternNode.zRotation = currentRotation

        for (i, ring) in ringNodes.enumerated() {
            let fi = CGFloat(i)
            let pulse = 1.0 + sin(rot * 2.0 + fi * 0.6) * min(speed * 0.003, 0.08)
            ring.setScale(pulse)
            let alpha = 0.2 + sin(rot * 1.5 + fi * 0.8) * 0.1 + min(speed * 0.005, 0.2)
            let color = AuroraColors.all[i % AuroraColors.all.count]
            ring.strokeColor = color.withAlphaComponent(alpha)
        }
    }

    // MARK: - Wall Collisions
    private func handleWallCollisions() {
        let margin = spinnerRadius + 4
        var hitWall = false
        var hitStrength: CGFloat = 0

        if spinnerPosition.x < margin {
            spinnerPosition.x = margin
            hitStrength = abs(spinnerVelocity.dx)
            spinnerVelocity.dx = -spinnerVelocity.dx * wallBounce
            angularVelocity *= wallSpinLoss
            hitWall = true
        }
        if spinnerPosition.x > size.width - margin {
            spinnerPosition.x = size.width - margin
            hitStrength = max(hitStrength, abs(spinnerVelocity.dx))
            spinnerVelocity.dx = -spinnerVelocity.dx * wallBounce
            angularVelocity *= wallSpinLoss
            hitWall = true
        }
        if spinnerPosition.y < margin {
            spinnerPosition.y = margin
            hitStrength = max(hitStrength, abs(spinnerVelocity.dy))
            spinnerVelocity.dy = -spinnerVelocity.dy * wallBounce
            angularVelocity *= wallSpinLoss
            hitWall = true
        }
        if spinnerPosition.y > size.height - margin {
            spinnerPosition.y = size.height - margin
            hitStrength = max(hitStrength, abs(spinnerVelocity.dy))
            spinnerVelocity.dy = -spinnerVelocity.dy * wallBounce
            angularVelocity *= wallSpinLoss
            hitWall = true
        }

        if hitWall && hapticsEnabled {
            if hitStrength > 400 { impactHeavy.impactOccurred() }
            else if hitStrength > 150 { impactMedium.impactOccurred() }
            else if hitStrength > 30 { impactLight.impactOccurred(intensity: min(hitStrength / 200, 1.0)) }
        }

        if hitWall && soundEnabled && hitStrength > 50 {
            AudioServicesPlaySystemSound(1104)
        }
    }

    override func willMove(from view: SKView) {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - Preview
#Preview {
    PhysicsView()
        .environment(SubscriptionManager.shared)
        .preferredColorScheme(.dark)
}
