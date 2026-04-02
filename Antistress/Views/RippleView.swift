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
                    let maxDuration: Double = 2.0

                    guard elapsed < maxDuration else { continue }

                    switch soundType {
                    case .white, .stream, .forest:
                        drawParticleRipple(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    case .brown, .ocean, .storm:
                        drawWaveRipple(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    case .pink, .rain, .wind, .fire:
                        drawGlowRipple(context: context, ripple: ripple, elapsed: elapsed, maxDuration: maxDuration, size: size)
                    }
                }
            }
        }
    }

    // MARK: - Particles (white, stream, forest)
    private func drawParticleRipple(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration
        let opacity = 1.0 - progress
        let particleCount = 8
        let maxRadius = min(size.width, size.height) * 0.25 * CGFloat(ripple.intensity + 0.3)

        for p in 0..<particleCount {
            let angle = (Double(p) / Double(particleCount)) * 2 * .pi + Double(ripple.id.hashValue % 100) * 0.01
            let radius = progress * maxRadius
            let jitter = CGFloat.random(in: -4...4)

            let x = ripple.center.x + cos(angle) * radius + jitter
            let y = ripple.center.y + sin(angle) * radius + jitter

            let dotSize: CGFloat = max(1.5, 4 * (1 - progress))
            let rect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)

            context.fill(
                Circle().path(in: rect),
                with: .color(accentColor.opacity(opacity * 0.7))
            )
        }
    }

    // MARK: - Waves (brown, ocean, storm)
    private func drawWaveRipple(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration
        let opacity = 1.0 - progress
        let maxRadius = min(size.width, size.height) * 0.45 * CGFloat(ripple.intensity + 0.3)

        for ring in 0..<2 {
            let delay = Double(ring) * 0.3
            let ringProgress = max(0, (elapsed - delay) / maxDuration)

            guard ringProgress > 0 && ringProgress < 1 else { continue }

            let radius = ringProgress * maxRadius
            let ringOpacity = opacity * (1.0 - Double(ring) * 0.4)

            let rect = CGRect(
                x: ripple.center.x - radius,
                y: ripple.center.y - radius,
                width: radius * 2,
                height: radius * 2
            )

            context.stroke(
                Circle().path(in: rect),
                with: .color(accentColor.opacity(ringOpacity * 0.5)),
                lineWidth: max(2, 6 * (1 - ringProgress))
            )
        }
    }

    // MARK: - Glow (pink, rain, wind, fire)
    private func drawGlowRipple(context: GraphicsContext, ripple: Ripple, elapsed: Double, maxDuration: Double, size: CGSize) {
        let progress = elapsed / maxDuration
        let opacity = 1.0 - progress
        let maxRadius = min(size.width, size.height) * 0.35 * CGFloat(ripple.intensity + 0.3)
        let radius = progress * maxRadius

        for layer in 0..<3 {
            let layerScale = 1.0 - Double(layer) * 0.25
            let r = radius * layerScale
            let layerOpacity = opacity * (0.15 - Double(layer) * 0.04)

            let rect = CGRect(
                x: ripple.center.x - r,
                y: ripple.center.y - r,
                width: r * 2,
                height: r * 2
            )

            context.fill(
                Circle().path(in: rect),
                with: .color(accentColor.opacity(layerOpacity))
            )
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
                if active {
                    startAmbient()
                } else {
                    stopAmbient()
                }
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
        case .white, .stream, .forest: return 0.6
        case .brown, .ocean, .storm:   return 1.8
        default:                        return 1.2
        }
    }

    private func startAmbient() {
        timer = Timer.scheduledTimer(withTimeInterval: ambientInterval, repeats: true) { _ in
            let screenW = UIScreen.main.bounds.width
            let screenH = UIScreen.main.bounds.height

            let ripple = Ripple(
                center: CGPoint(
                    x: CGFloat.random(in: screenW * 0.15...screenW * 0.85),
                    y: CGFloat.random(in: screenH * 0.15...screenH * 0.55)
                ),
                startTime: Date(),
                intensity: Float.random(in: 0.2...0.5)
            )

            ripples.append(ripple)
            ripples.removeAll { Date().timeIntervalSince($0.startTime) > 2.5 }
        }
    }

    private func stopAmbient() {
        timer?.invalidate()
        timer = nil
        ripples = []
    }
}
