import SwiftUI

// MARK: - SoundView
struct SoundView: View {
    @StateObject private var engine = SoundEngine()
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var touchRipples: [Ripple] = []
    @State private var isTouching = false
    
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
            
            // MARK: - Type Picker (bottom)
            VStack {
                Spacer()
                typePicker
                    .padding(.bottom, 20)
            }
            
        }
        .animation(.easeInOut(duration: 0.5), value: engine.isPlaying)
    }
}

// MARK: - Idle Hint
private extension SoundView {
    var idleHint: some View {
        VStack(spacing: 16) {
            // Pulsing waveform icon
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
        
        // Auto-start on first touch
        if !engine.isPlaying {
            engine.play()
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

// MARK: - Type Picker
private extension SoundView {
    var typePicker: some View {
        HStack(spacing: 0) {
            pickerItem(label: "Off", isActive: !engine.isPlaying) {
                engine.stop()
                if hapticsEnabled {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
            
            pickerDot
            
            ForEach(Array(SoundType.allCases.enumerated()), id: \.element.id) { index, type in
                pickerItem(
                    label: type.displayName,
                    isActive: engine.isPlaying && engine.currentType == type
                ) {
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
                
                if index < SoundType.allCases.count - 1 {
                    pickerDot
                }
            }
        }
    }
    
    func pickerItem(label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: isActive ? .semibold : .regular, design: .rounded))
                .foregroundStyle(isActive ? AppColors.sound : .white.opacity(0.3))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .animation(.easeInOut(duration: 0.25), value: isActive)
    }
    
    var pickerDot: some View {
        Text("·")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.white.opacity(0.15))
    }
}

// MARK: - Float Clamped
private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
