import SwiftUI

// MARK: - Ripple Model
struct Ripple: Identifiable {
    let id = UUID()
    let center: CGPoint
    let startTime: Date
    let intensity: Float
}

// MARK: - RippleView
struct RippleView: View {
    let ripples: [Ripple]
    let accentColor: Color
    let soundType: SoundType

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date

                for ripple in ripples {
                    let elapsed = now.timeIntervalSince(ripple.startTime)
                    let maxDuration: Double = 2.5

                    guard elapsed < maxDuration else { continue }

                    switch soundType {
                    case .white:
                        drawSparkBurst(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    case .brown:
                        drawDeepWaves(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    case .pink:
                        drawSoftPulse(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    case .rain:
                        drawRainDrops(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    case .ocean:
                        drawOceanSwell(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    case .wind:
                        drawWindStreaks(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    case .fire:
                        drawEmbers(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    case .forest:
                        drawLeafDrift(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    case .stream:
                        drawFlowLines(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    case .storm:
                        drawLightningFlash(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    }
                }
            }
        }
    }

    // MARK: - White: Spark Burst — fast tiny particles exploding outward
    private func drawSparkBurst(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration
        let opacity = pow(1.0 - progress, 1.5)
        let particleCount = 12
        let maxRadius = min(size.width, size.height) * 0.3 * CGFloat(ripple.intensity + 0.3)
        let hash = abs(ripple.id.hashValue)

        for p in 0..<particleCount {
            let baseAngle = (Double(p) / Double(particleCount)) * 2 * .pi
            let angleJitter = Double(hash % (p + 1)) * 0.15
            let angle = baseAngle + angleJitter

            let speed = 0.7 + Double(p % 3) * 0.15
            let radius = pow(progress, speed) * maxRadius

            let x = ripple.center.x + cos(angle) * radius
            let y = ripple.center.y + sin(angle) * radius

            let dotSize: CGFloat = max(1.0, 3.5 * (1 - progress))
            let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)

            context.fill(
                Circle().path(in: rect),
                with: .color(accentColor.opacity(opacity * 0.8))
            )
        }

        // Central flash
        if progress < 0.15 {
            let flashOpacity = (1.0 - progress / 0.15) * 0.6
            let flashSize: CGFloat = 12 * (1 - CGFloat(progress / 0.15))
            let rect = CGRect(x: ripple.center.x - flashSize / 2, y: ripple.center.y - flashSize / 2,
                              width: flashSize, height: flashSize)
            context.fill(Circle().path(in: rect), with: .color(.white.opacity(flashOpacity)))
        }
    }

    // MARK: - Brown: Deep Waves — thick slow concentric rings
    private func drawDeepWaves(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration
        let opacity = pow(1.0 - progress, 1.2)
        let maxRadius = min(size.width, size.height) * 0.5 * CGFloat(ripple.intensity + 0.4)

        for ring in 0..<3 {
            let delay = Double(ring) * 0.25
            let ringProgress = max(0, (elapsed - delay) / (maxDuration * 0.8))
            guard ringProgress > 0 && ringProgress < 1 else { continue }

            let eased = sin(ringProgress * .pi * 0.5) // ease-out
            let radius = eased * maxRadius
            let ringOpacity = opacity * (1.0 - Double(ring) * 0.3) * (1.0 - ringProgress)
            let lineW = max(1.5, 8 * (1 - ringProgress))

            let rect = CGRect(x: ripple.center.x - radius, y: ripple.center.y - radius,
                              width: radius * 2, height: radius * 2)

            context.stroke(
                Circle().path(in: rect),
                with: .color(accentColor.opacity(ringOpacity * 0.5)),
                lineWidth: lineW
            )
        }
    }

    // MARK: - Pink: Soft Pulse — breathing glow that expands and fades
    private func drawSoftPulse(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration
        let breathe = sin(progress * .pi) // peaks at 0.5
        let maxRadius = min(size.width, size.height) * 0.4 * CGFloat(ripple.intensity + 0.3)
        let radius = progress * maxRadius

        for layer in 0..<5 {
            let layerT = Double(layer) / 4.0
            let r = radius * (1.0 - layerT * 0.2)
            let layerOpacity = breathe * (0.12 - layerT * 0.02)

            let rect = CGRect(x: ripple.center.x - r, y: ripple.center.y - r,
                              width: r * 2, height: r * 2)
            context.fill(Circle().path(in: rect), with: .color(accentColor.opacity(layerOpacity)))
        }
    }

    // MARK: - Rain: Rain Drops — small dots falling downward from touch point
    private func drawRainDrops(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration
        let opacity = pow(1.0 - progress, 1.8)
        let dropCount = 6
        let hash = abs(ripple.id.hashValue)

        for d in 0..<dropCount {
            let spreadX = CGFloat(((hash + d * 37) % 100) - 50) * 0.6
            let fallSpeed = 80 + CGFloat(d * 15)
            let fallDelay = Double(d) * 0.05

            let adjustedElapsed = max(0, elapsed - fallDelay)

            let x = ripple.center.x + spreadX + sin(CGFloat(adjustedElapsed) * 3) * 4
            let y = ripple.center.y + CGFloat(adjustedElapsed) * fallSpeed

            guard y < size.height else { continue }

            // Drop shape — elongated
            let dropW: CGFloat = 2.0
            let dropH: CGFloat = max(2, 6 * (1 - progress))
            let rect = CGRect(x: x - dropW / 2, y: y - dropH / 2, width: dropW, height: dropH)

            context.fill(
                Capsule().path(in: rect),
                with: .color(accentColor.opacity(opacity * 0.7))
            )
        }

        // Splash ring at touch point
        if progress < 0.4 {
            let splashProgress = progress / 0.4
            let splashRadius = splashProgress * 20
            let splashOpacity = (1.0 - splashProgress) * 0.4
            let rect = CGRect(x: ripple.center.x - splashRadius, y: ripple.center.y - splashRadius,
                              width: splashRadius * 2, height: splashRadius * 2)
            context.stroke(Circle().path(in: rect),
                          with: .color(accentColor.opacity(splashOpacity)),
                          lineWidth: 1.5)
        }
    }

    // MARK: - Ocean: Ocean Swell — wide horizontal waves
    private func drawOceanSwell(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration
        let opacity = pow(1.0 - progress, 1.3)
        let maxSpread = size.width * 0.5 * CGFloat(ripple.intensity + 0.3)

        for wave in 0..<2 {
            let delay = Double(wave) * 0.3
            let waveProgress = max(0, (elapsed - delay) / maxDuration)
            guard waveProgress > 0 && waveProgress < 1 else { continue }

            let spread = waveProgress * maxSpread
            let waveH: CGFloat = max(1, 20 * (1 - waveProgress))
            let waveOpacity = opacity * (1.0 - Double(wave) * 0.35) * 0.4

            // Elliptical wave — wider than tall
            let rect = CGRect(x: ripple.center.x - spread,
                              y: ripple.center.y - waveH / 2,
                              width: spread * 2,
                              height: waveH)

            context.stroke(
                Ellipse().path(in: rect),
                with: .color(accentColor.opacity(waveOpacity)),
                lineWidth: max(1.5, 5 * (1 - waveProgress))
            )
        }
    }

    // MARK: - Wind: Wind Streaks — horizontal lines that drift sideways
    private func drawWindStreaks(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration
        let opacity = pow(1.0 - progress, 1.5)
        let streakCount = 5
        let hash = abs(ripple.id.hashValue)

        for s in 0..<streakCount {
            let yOffset = CGFloat(((hash + s * 23) % 80) - 40)
            let speed = 120 + CGFloat(s * 20)
            let length: CGFloat = max(8, 35 * (1 - progress))

            let x = ripple.center.x + CGFloat(elapsed) * speed
            let y = ripple.center.y + yOffset + sin(CGFloat(elapsed) * 2 + CGFloat(s)) * 8

            guard x < size.width + 50 else { continue }

            let path = Path { p in
                p.move(to: CGPoint(x: x, y: y))
                p.addLine(to: CGPoint(x: x - length, y: y))
            }

            context.stroke(
                path,
                with: .color(accentColor.opacity(opacity * 0.5)),
                lineWidth: max(1, 2.5 * (1 - progress))
            )
        }
    }

    // MARK: - Fire: Embers — particles rising upward with flicker
    private func drawEmbers(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration
        let opacity = pow(1.0 - progress, 1.4)
        let emberCount = 8
        let hash = abs(ripple.id.hashValue)

        for e in 0..<emberCount {
            let spreadX = CGFloat(((hash + e * 47) % 60) - 30)
            let riseSpeed = 60 + CGFloat(e * 12)
            let riseDelay = Double(e) * 0.04

            let adjustedElapsed = max(0, elapsed - riseDelay)
            let drift = sin(CGFloat(adjustedElapsed) * 4 + CGFloat(e)) * 10

            let x = ripple.center.x + spreadX + drift
            let y = ripple.center.y - CGFloat(adjustedElapsed) * riseSpeed

            guard y > 0 else { continue }

            // Flickering size
            let flicker = 1.0 + sin(CGFloat(adjustedElapsed) * 12 + CGFloat(e * 3)) * 0.3
            let dotSize = max(1.5, 4 * (1 - progress) * flicker)

            let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)

            // Warm color shift — from accent toward orange/yellow
            let warmShift = min(progress * 1.5, 1.0)
            let color = e % 3 == 0
                ? Color.orange.opacity(opacity * 0.7 * warmShift)
                : accentColor.opacity(opacity * 0.7)

            context.fill(Circle().path(in: rect), with: .color(color))
        }

        // Base glow
        if progress < 0.3 {
            let glowOpacity = (1.0 - progress / 0.3) * 0.15
            let glowR: CGFloat = 25
            let rect = CGRect(x: ripple.center.x - glowR, y: ripple.center.y - glowR,
                              width: glowR * 2, height: glowR * 2)
            context.fill(Circle().path(in: rect), with: .color(Color.orange.opacity(glowOpacity)))
        }
    }

    // MARK: - Forest: Leaf Drift — organic shapes floating outward
    private func drawLeafDrift(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration
        let opacity = pow(1.0 - progress, 1.6)
        let leafCount = 6
        let hash = abs(ripple.id.hashValue)
        let maxRadius = min(size.width, size.height) * 0.25 * CGFloat(ripple.intensity + 0.3)

        for l in 0..<leafCount {
            let baseAngle = (Double(l) / Double(leafCount)) * 2 * .pi + Double(hash % 100) * 0.01
            let wobble = sin(elapsed * 2 + Double(l)) * 0.3
            let angle = baseAngle + wobble

            let speed = 0.5 + Double(l % 3) * 0.2
            let radius = pow(progress, speed) * maxRadius
            let driftY = sin(elapsed * 1.5 + Double(l)) * 8

            let x = ripple.center.x + cos(angle) * radius
            let y = ripple.center.y + sin(angle) * radius + driftY

            // Small ellipse rotated — like a leaf
            let leafW: CGFloat = max(2, 7 * (1 - progress))
            let leafH: CGFloat = leafW * 0.5
            let rect = CGRect(x: x - leafW / 2, y: y - leafH / 2, width: leafW, height: leafH)

            var leafContext = context
            leafContext.rotate(by: .radians(angle + elapsed * 2))
            context.fill(Ellipse().path(in: rect), with: .color(accentColor.opacity(opacity * 0.6)))
        }
    }

    // MARK: - Stream: Flow Lines — smooth curved lines flowing outward
    private func drawFlowLines(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration
        let opacity = pow(1.0 - progress, 1.3)
        let lineCount = 4
        let hash = abs(ripple.id.hashValue)
        let maxRadius = min(size.width, size.height) * 0.3 * CGFloat(ripple.intensity + 0.3)

        for l in 0..<lineCount {
            let baseAngle = (Double(l) / Double(lineCount)) * 2 * .pi + Double(hash % 50) * 0.02
            let radius = progress * maxRadius

            let path = Path { p in
                let startR = radius * 0.3
                let endR = radius
                let steps = 12
                for s in 0..<steps {
                    let t = Double(s) / Double(steps)
                    let r = startR + (endR - startR) * t
                    let curve = sin(t * .pi * 2 + elapsed * 3) * 10 * t
                    let a = baseAngle + curve / max(r, 1)
                    let pt = CGPoint(x: ripple.center.x + cos(a) * r,
                                     y: ripple.center.y + sin(a) * r)
                    if s == 0 { p.move(to: pt) }
                    else { p.addLine(to: pt) }
                }
            }

            context.stroke(
                path,
                with: .color(accentColor.opacity(opacity * 0.5)),
                lineWidth: max(1, 3 * (1 - progress))
            )
        }
    }

    // MARK: - Storm: Lightning Flash — bright flash then crackle lines
    private func drawLightningFlash(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration

        // Bright flash at start
        if progress < 0.1 {
            let flashOpacity = (1.0 - progress / 0.1) * 0.5
            let flashR = 60 * CGFloat(ripple.intensity + 0.5)
            let rect = CGRect(x: ripple.center.x - flashR, y: ripple.center.y - flashR,
                              width: flashR * 2, height: flashR * 2)
            context.fill(Circle().path(in: rect), with: .color(.white.opacity(flashOpacity)))
        }

        // Crackle lines
        if progress > 0.05 && progress < 0.7 {
            let crackleOpacity = pow(1.0 - (progress - 0.05) / 0.65, 2.0)
            let hash = abs(ripple.id.hashValue)
            let branches = 3

            for b in 0..<branches {
                let path = Path { p in
                    p.move(to: ripple.center)
                    var pt = ripple.center
                    let segments = 5
                    let baseAngle = Double(b) / Double(branches) * 2 * .pi + Double(hash % 100) * 0.03
                    for s in 0..<segments {
                        let segLen: CGFloat = 15 + CGFloat(s * 8)
                        let jitter = CGFloat(((hash + b * 13 + s * 7) % 60) - 30) * 0.03
                        let angle = baseAngle + jitter
                        pt = CGPoint(x: pt.x + cos(angle) * segLen,
                                     y: pt.y + sin(angle) * segLen)
                        p.addLine(to: pt)
                    }
                }

                context.stroke(
                    path,
                    with: .color(accentColor.opacity(crackleOpacity * 0.7)),
                    lineWidth: max(0.5, 2.5 * crackleOpacity)
                )
            }
        }

        // Afterglow dots
        if progress > 0.1 && progress < 0.5 {
            let dotOpacity = (1.0 - (progress - 0.1) / 0.4) * 0.4
            let dotCount = 4
            let hash = abs(ripple.id.hashValue)
            for d in 0..<dotCount {
                let x = ripple.center.x + CGFloat(((hash + d * 31) % 80) - 40)
                let y = ripple.center.y + CGFloat(((hash + d * 17) % 60) - 30)
                let dotSize: CGFloat = 2
                let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                context.fill(Circle().path(in: rect), with: .color(.white.opacity(dotOpacity)))
            }
        }
    }
}

// MARK: - Ambient Ripple Background
struct AmbientRippleView: View {
    let isActive: Bool
    let accentColor: Color
    let soundType: SoundType

    @State private var ripples: [Ripple] = []
    @State private var timer: Timer?

    var body: some View {
        RippleView(ripples: ripples, accentColor: accentColor, soundType: soundType)
            .onChange(of: isActive) { _, active in
                if active { startAmbient() }
                else { stopAmbient() }
            }
            .onChange(of: soundType) { _, _ in
                if isActive {
                    stopAmbient()
                    startAmbient()
                }
            }
            .onDisappear { stopAmbient() }
    }

    private var ambientInterval: TimeInterval {
        switch soundType {
        case .white, .stream, .forest: return 0.5
        case .brown, .ocean:           return 1.6
        case .storm:                   return 2.0
        case .fire:                    return 0.7
        case .wind:                    return 0.8
        case .rain:                    return 0.4
        case .pink:                    return 1.2
        }
    }

    private func startAmbient() {
        timer = Timer.scheduledTimer(withTimeInterval: ambientInterval, repeats: true) { _ in
            let screenW = UIScreen.main.bounds.width
            let screenH = UIScreen.main.bounds.height

            let ripple = Ripple(
                center: CGPoint(
                    x: CGFloat.random(in: screenW * 0.1...screenW * 0.9),
                    y: CGFloat.random(in: screenH * 0.1...screenH * 0.6)
                ),
                startTime: Date(),
                intensity: Float.random(in: 0.2...0.6)
            )

            ripples.append(ripple)
            ripples.removeAll { Date().timeIntervalSince($0.startTime) > 3.0 }
        }
    }

    private func stopAmbient() {
        timer?.invalidate()
        timer = nil
        ripples = []
    }
}
