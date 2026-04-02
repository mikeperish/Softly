import SwiftUI

// MARK: - SoundView
struct SoundView: View {
    @StateObject private var engine = SoundEngine()
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var touchRipples: [Ripple] = []
    @State private var isTouching = false
    @State private var showPaywall = false
    @Environment(SubscriptionManager.self) private var subscriptionManager

    var body: some View {
        ZStack {
            AppBackground(accentColor: AppColors.sound)

            // MARK: - Touch Area
            touchLayer

            // MARK: - Idle Hint (when not playing)
            if !engine.isPlaying {
                idleHint
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            // MARK: - Ripples from finger
            RippleView(
                ripples: touchRipples,
                accentColor: AppColors.sound,
                soundType: engine.currentType
            )
            .allowsHitTesting(false)

            // MARK: - Ambient ripples when playing
            AmbientRippleView(
                isActive: engine.isPlaying && !isTouching,
                accentColor: AppColors.sound,
                soundType: engine.currentType
            )
            .allowsHitTesting(false)

            // MARK: - Picker (bottom)
            VStack {
                Spacer()
                soundPicker
                    .padding(.bottom, 20)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: engine.isPlaying)
        .sheet(isPresented: $showPaywall) {
            PremiumView()
        }
    }
}

// MARK: - Idle Hint
private extension SoundView {
    var idleHint: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 44, weight: .thin))
                .foregroundStyle(AppColors.sound.opacity(0.35))
                .symbolEffect(.pulse, options: .repeating)

            Text("Touch to begin")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.25))
        }
    }
}

// MARK: - Touch Layer
private extension SoundView {
    var touchLayer: some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleTouch(at: value.location, in: geo.size)
                        }
                        .onEnded { _ in
                            isTouching = false
                        }
                )
        }
    }

    func handleTouch(at point: CGPoint, in size: CGSize) {
        if !isTouching {
            isTouching = true
            if hapticsEnabled {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }

        // Auto-start on first touch (only if current type is accessible)
        if !engine.isPlaying {
            if engine.currentType.isFree || subscriptionManager.isPremium {
                engine.play()
            } else {
                // Playing a locked type — switch to white first
                engine.switchType(.white)
                engine.play()
            }
        }

        let toneValue = Float(point.x / size.width).clamped(to: 0...1)
        let volumeValue = Float(point.y / size.height).clamped(to: 0...1)

        if soundEnabled {
            engine.updateTone(toneValue)
            engine.updateVolume(volumeValue)
        }

        // Spawn ripple
        let ripple = Ripple(
            center: point,
            startTime: Date(),
            intensity: volumeValue
        )
        touchRipples.append(ripple)
        touchRipples.removeAll { Date().timeIntervalSince($0.startTime) > 2.5 }

        if hapticsEnabled && Int(point.x + point.y) % 40 == 0 {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.3)
        }
    }
}

// MARK: - Sound Picker (horizontal scroll with Off + types)
private extension SoundView {
    var soundPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // Off button
                    Button {
                        engine.stop()
                        if hapticsEnabled {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    } label: {
                        Text("Off")
                            .font(.system(size: 14, weight: !engine.isPlaying ? .semibold : .regular, design: .rounded))
                            .foregroundStyle(!engine.isPlaying ? AppColors.sound : .white.opacity(0.35))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(!engine.isPlaying ? AppColors.sound.opacity(0.25) : .clear)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                !engine.isPlaying ? AppColors.sound.opacity(0.4) : .white.opacity(0.08),
                                                lineWidth: 0.5
                                            )
                                    )
                            )
                    }
                    .id("off")

                    // Sound types
                    ForEach(SoundType.allCases) { type in
                        let isActive = engine.isPlaying && engine.currentType == type
                        let isLocked = !type.isFree && !subscriptionManager.isPremium

                        Button {
                            if isLocked {
                                showPaywall = true
                                if hapticsEnabled {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            } else {
                                if engine.isPlaying && engine.currentType == type {
                                    engine.stop()
                                } else {
                                    engine.switchType(type)
                                    if !engine.isPlaying {
                                        engine.play()
                                    }
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
                                Text(type.displayName)
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
                                    .fill(isActive ? AppColors.sound.opacity(0.25) : .clear)
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(
                                                isActive ? AppColors.sound.opacity(0.4) :
                                                isLocked ? .white.opacity(0.05) : .white.opacity(0.08),
                                                lineWidth: 0.5
                                            )
                                    )
                            )
                        }
                        .id(type.rawValue)
                        .animation(.easeInOut(duration: 0.25), value: isActive)
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: engine.currentType) { _, newValue in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    proxy.scrollTo(newValue.rawValue, anchor: .center)
                }
            }
        }
    }
}

// MARK: - Float Clamped
private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
