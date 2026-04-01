import SwiftUI

// MARK: - SoundView
struct SoundView: View {
    @StateObject private var engine = SoundEngine()
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var showSettings = false
    @State private var touchRipples: [Ripple] = []
    @State private var isTouching = false
    
    var body: some View {
        ZStack {
            AppBackground(accentColor: AppColors.sound)
            
            // MARK: - Touch Area
            touchLayer
            
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
            
            // MARK: - Settings Overlay
            settingsOverlay
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
        
        guard engine.isPlaying else { return }
        
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

// MARK: - Settings Overlay
private extension SoundView {
    var settingsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showSettings.toggle()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.07)))
                    }
                    
                    if showSettings {
                        SoundSettingsPanel(
                            soundEnabled: $soundEnabled,
                            hapticsEnabled: $hapticsEnabled
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)))
                    }
                }
                .padding(.trailing, 64)
                .padding(.top, 16)
            }
            Spacer()
        }
    }
}

// MARK: - Settings Panel
struct SoundSettingsPanel: View {
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            settingRow(
                icon: soundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill",
                title: "Sound",
                isOn: $soundEnabled
            )
            
            Divider().background(.white.opacity(0.1))
            
            settingRow(
                icon: hapticsEnabled ? "iphone.radiowaves.left.and.right" : "iphone.slash",
                title: "Haptics",
                isOn: $hapticsEnabled
            )
        }
        .frame(width: 190)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                }
        }
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
    }
    
    private func settingRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(isOn.wrappedValue ? AppColors.sound : .white.opacity(0.3))
                .frame(width: 22)
            Text(title)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(AppColors.sound)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }
}

// MARK: - Float Clamped
private extension Float {
    func clamped(to range: ClosedRange<Float>) -> Float {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
