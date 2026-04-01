// MARK: - PhysicsView.swift
// Fidget App — Physics Tab: Spinning Top (Дзига)
// Pattern: Aurora (purple + mint + pink)

import SwiftUI
import SpriteKit
import CoreMotion
import AudioToolbox

// MARK: - Spinner Pattern Enum
enum SpinnerPattern: Int, CaseIterable {
    case pulse = 0
    case fibonacci = 1
    
    var name: String {
        switch self {
        case .pulse: return "Pulse"
        case .fibonacci: return "Fibonacci"
        }
    }
}

// MARK: - PhysicsView (SwiftUI wrapper)
struct PhysicsView: View {
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var currentPattern: SpinnerPattern = .pulse
    
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
            }
            
            // Pattern dots (bottom, above tab bar)
            VStack {
                Spacer()
                HStack(spacing: 12) {
                    ForEach(SpinnerPattern.allCases, id: \.rawValue) { pattern in
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentPattern = pattern
                                SpinnerScene.shared.currentPattern = pattern
                            }
                            if hapticsEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        } label: {
                            Circle()
                                .fill(currentPattern == pattern
                                      ? Color(red: 0.50, green: 0.47, blue: 0.87)
                                      : Color.white.opacity(0.2))
                                .frame(width: 10, height: 10)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                )
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Aurora Color Palette
struct AuroraColors {
    static let purple = UIColor(red: 0.50, green: 0.47, blue: 0.87, alpha: 1.0)
    static let mint = UIColor(red: 0.36, green: 0.79, blue: 0.65, alpha: 1.0)
    static let pink = UIColor(red: 0.83, green: 0.33, blue: 0.49, alpha: 1.0)
    static let deepPurple = UIColor(red: 0.16, green: 0.13, blue: 0.36, alpha: 1.0)
    static let white = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    static let all: [UIColor] = [purple, mint, pink, deepPurple, white]
}

// MARK: - SpinnerScene (SpriteKit)
class SpinnerScene: SKScene {
    
    static let shared: SpinnerScene = {
        let scene = SpinnerScene()
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        return scene
    }()
    
    // MARK: - Public Properties
    var soundEnabled = true
    var hapticsEnabled = true
    var currentPattern: SpinnerPattern = .pulse {
        didSet {
            guard sceneReady else { return }
            rebuildPattern()
        }
    }
    
    // MARK: - Private Properties
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
    
    // Pulse pattern nodes
    private var ringNodes: [SKShapeNode] = []
    private let ringCount = 12
    
    // Fibonacci pattern nodes
    private var fibonacciNodes: [SKShapeNode] = []
    
    // Haptics
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
        
        // Border circle
        borderNode = SKShapeNode(circleOfRadius: spinnerRadius)
        borderNode.strokeColor = AuroraColors.purple.withAlphaComponent(0.6)
        borderNode.lineWidth = 2.5
        borderNode.fillColor = .clear
        borderNode.glowWidth = 1
        spinnerNode.addChild(borderNode)
        
        // Center dot
        centerDot = SKShapeNode(circleOfRadius: 6)
        centerDot.fillColor = AuroraColors.purple.withAlphaComponent(0.9)
        centerDot.strokeColor = AuroraColors.mint.withAlphaComponent(0.5)
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
        case .pulse:
            buildPulsePattern()
        case .fibonacci:
            buildFibonacciPattern()
        }
    }
    
    private func buildPulsePattern() {
        for i in 0..<ringCount {
            let radius = CGFloat(ringCount - i) * (spinnerRadius * 0.85 / CGFloat(ringCount))
            let ring = SKShapeNode(circleOfRadius: radius)
            let colorIndex = i % AuroraColors.all.count
            let color = AuroraColors.all[colorIndex]
            ring.strokeColor = color.withAlphaComponent(0.3 + CGFloat(i) * 0.03)
            ring.lineWidth = 2.5
            ring.fillColor = .clear
            patternNode.addChild(ring)
            ringNodes.append(ring)
        }
    }
    
    private func buildFibonacciPattern() {
        // Spiral arms
        let arms = 8
        let pointsPerArm = 60
        let goldenAngle: CGFloat = .pi * 2 / (1 + sqrt(5) / 2)
        
        for a in 0..<arms {
            let path = CGMutablePath()
            var firstPoint = true
            
            for p in 0..<pointsPerArm {
                let t = CGFloat(p) / CGFloat(pointsPerArm)
                let radius = t * (spinnerRadius - 8)
                let angle = t * .pi * 4 + CGFloat(a) * (.pi * 2 / CGFloat(arms))
                
                let x = cos(angle) * radius
                let y = sin(angle) * radius
                
                if firstPoint {
                    path.move(to: CGPoint(x: x, y: y))
                    firstPoint = false
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            
            let arm = SKShapeNode(path: path)
            let colorIndex = a % AuroraColors.all.count
            let color = AuroraColors.all[colorIndex]
            arm.strokeColor = color.withAlphaComponent(0.5 + CGFloat(a % 3) * 0.1)
            arm.lineWidth = 2.5
            arm.fillColor = .clear
            arm.lineCap = .round
            patternNode.addChild(arm)
            fibonacciNodes.append(arm)
        }
        
        // Golden ratio dots
        let dotCount = 34
        for i in 0..<dotCount {
            let t = CGFloat(i) / CGFloat(dotCount)
            let radius = t * (spinnerRadius - 12)
            let angle = CGFloat(i) * goldenAngle
            
            let dot = SKShapeNode(circleOfRadius: 2.5 + t * 2)
            dot.position = CGPoint(
                x: cos(angle) * radius,
                y: sin(angle) * radius
            )
            let colorIndex = i % AuroraColors.all.count
            let color = AuroraColors.all[colorIndex]
            dot.fillColor = color.withAlphaComponent(0.3 + t * 0.4)
            dot.strokeColor = .clear
            patternNode.addChild(dot)
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
        // 1. Rotation
        currentRotation += angularVelocity * (1.0 / 60.0)
        
        // 2. Pattern-specific animation
        switch currentPattern {
        case .pulse:
            updatePulsePattern()
        case .fibonacci:
            patternNode.zRotation = currentRotation
        }
        
        // 3. Friction
        angularVelocity *= friction
        if abs(angularVelocity) < 0.01 { angularVelocity = 0 }
        
        // 4. Gyroscope gravity — only when spinning
        if abs(angularVelocity) > 0.1, let motion = motionManager.deviceMotion {
            let gx = CGFloat(motion.gravity.x) * gravityScale
            let gy = CGFloat(motion.gravity.y) * gravityScale
            spinnerVelocity.dx += gx * (1.0 / 60.0)
            spinnerVelocity.dy += gy * (1.0 / 60.0)
        }
        
        // Stop movement when not spinning
        if abs(angularVelocity) < 0.1 {
            spinnerVelocity.dx *= 0.9
            spinnerVelocity.dy *= 0.9
            if abs(spinnerVelocity.dx) < 0.5 { spinnerVelocity.dx = 0 }
            if abs(spinnerVelocity.dy) < 0.5 { spinnerVelocity.dy = 0 }
        }
        
        spinnerVelocity.dx *= moveFriction
        spinnerVelocity.dy *= moveFriction
        
        // 5. Position update
        spinnerPosition.x += spinnerVelocity.dx * (1.0 / 60.0)
        spinnerPosition.y += spinnerVelocity.dy * (1.0 / 60.0)
        
        // 6. Wall collisions
        handleWallCollisions()
        
        // Continuous spin haptic
        if hapticsEnabled && abs(angularVelocity) > 2 {
            let spinSpeed = abs(angularVelocity)
            // Tick every N frames based on speed
            let tickInterval = max(2, Int(30.0 / spinSpeed))
            let frameCount = Int(currentRotation * 10)
            if frameCount % tickInterval == 0 {
                let intensity = min(spinSpeed / 25.0, 0.4)
                impactLight.impactOccurred(intensity: intensity)
            }
        }
        
        // 7. Apply position
        spinnerNode.position = spinnerPosition
        
        // 8. Visual glow based on speed
        let speed = abs(angularVelocity)
        borderNode.glowWidth = speed > 1 ? min(speed / 4.0, 5.0) : 0.5
        
        // Dynamic border color
        let hue = (currentRotation.truncatingRemainder(dividingBy: .pi * 2)) / (.pi * 2)
        let borderColor = UIColor(
            hue: 0.72 + abs(hue) * 0.15,
            saturation: 0.5 + min(speed / 30, 0.4),
            brightness: 0.6 + min(speed / 20, 0.3),
            alpha: 0.7
        )
        borderNode.strokeColor = borderColor
    }
    
    // MARK: - Pulse Pattern Animation
    private func updatePulsePattern() {
        let rot = currentRotation
        let speed = abs(angularVelocity)
        
        for (i, ring) in ringNodes.enumerated() {
            let fi = CGFloat(i)
            
            let wobbleAmount = min(speed * 0.3, 6.0)
            let wobble = sin(rot * 2.0 + fi * 0.8) * wobbleAmount
            let ox = cos(rot + fi) * wobble
            let oy = sin(rot + fi) * wobble
            ring.position = CGPoint(x: ox, y: oy)
            
            let alpha = 0.15 + 0.08 * sin(rot * 3.0 + fi) + min(speed * 0.005, 0.15)
            let colorIndex = i % AuroraColors.all.count
            let color = AuroraColors.all[colorIndex]
            ring.strokeColor = color.withAlphaComponent(alpha + fi * 0.03)
            
            let scalePulse = 1.0 + sin(rot * 1.5 + fi * 0.5) * min(speed * 0.002, 0.05)
            ring.setScale(scalePulse)
        }
    }
    
    // MARK: - Wall Collisions
    private func handleWallCollisions() {
        let margin = spinnerRadius + 4
        var hitWall = false
        var hitStrength: CGFloat = 0
        
        if spinnerPosition.x < margin {
            spinnerPosition.x = margin
            let impact = abs(spinnerVelocity.dx)
            spinnerVelocity.dx = -spinnerVelocity.dx * wallBounce
            angularVelocity *= wallSpinLoss
            hitWall = true
            hitStrength = impact
        }
        if spinnerPosition.x > size.width - margin {
            spinnerPosition.x = size.width - margin
            let impact = abs(spinnerVelocity.dx)
            spinnerVelocity.dx = -spinnerVelocity.dx * wallBounce
            angularVelocity *= wallSpinLoss
            hitWall = true
            hitStrength = max(hitStrength, impact)
        }
        if spinnerPosition.y < margin {
            spinnerPosition.y = margin
            let impact = abs(spinnerVelocity.dy)
            spinnerVelocity.dy = -spinnerVelocity.dy * wallBounce
            angularVelocity *= wallSpinLoss
            hitWall = true
            hitStrength = max(hitStrength, impact)
        }
        if spinnerPosition.y > size.height - margin {
            spinnerPosition.y = size.height - margin
            let impact = abs(spinnerVelocity.dy)
            spinnerVelocity.dy = -spinnerVelocity.dy * wallBounce
            angularVelocity *= wallSpinLoss
            hitWall = true
            hitStrength = max(hitStrength, impact)
        }
        
        if hitWall && hapticsEnabled {
            if hitStrength > 400 {
                impactHeavy.impactOccurred()
            } else if hitStrength > 150 {
                impactMedium.impactOccurred()
            } else if hitStrength > 30 {
                impactLight.impactOccurred(intensity: min(hitStrength / 200, 1.0))
            }
        }
        
        if hitWall && soundEnabled && hitStrength > 50 {
            AudioServicesPlaySystemSound(1104)
        }
    }
    
    // MARK: - Cleanup
    override func willMove(from view: SKView) {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - Preview
#Preview {
    PhysicsView()
        .preferredColorScheme(.dark)
}
