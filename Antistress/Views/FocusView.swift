// FocusView.swift
// Fidget App — Pomodoro Timer UI
// iOS 17+, SwiftUI

import SwiftUI

// MARK: - Focus Accent Colors

private let focusRed = Color(red: 0.9, green: 0.2, blue: 0.2)
private let focusRedGlow = Color(red: 0.35, green: 0.06, blue: 0.06)
private let breakGreen = Color(red: 0.3, green: 0.78, blue: 0.55)
private let breakGreenGlow = Color(red: 0.06, green: 0.25, blue: 0.12)

// MARK: - Circular Progress

struct FocusRing: View {
    let progress: Double
    let timeString: String
    let phaseLabel: String
    let accent: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(accent.opacity(0.12), lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    accent.opacity(0.3),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    accent,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text(timeString)
                    .font(.system(size: 52, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())

                Text(phaseLabel.uppercased())
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent.opacity(0.7))
                    .tracking(3)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: progress)
    }
}

// MARK: - Mode Switcher

struct FocusModeSwitcher: View {
    @Binding var preset: FocusPreset
    let accent: Color
    let onSelect: (FocusPreset) -> Void

    var body: some View {
        HStack(spacing: 20) {
            ForEach(FocusPreset.allCases) { p in
                let isActive = p == preset
                Button {
                    guard p != preset else { return }
                    onSelect(p)
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Text(p.rawValue)
                        .font(.system(size: 13, weight: isActive ? .semibold : .regular, design: .rounded))
                        .foregroundStyle(isActive ? .white : .white.opacity(0.3))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background {
                            if isActive {
                                Capsule()
                                    .fill(accent.opacity(0.2))
                                    .overlay {
                                        Capsule()
                                            .strokeBorder(accent.opacity(0.3), lineWidth: 0.5)
                                    }
                            }
                        }
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: preset)
    }
}

// MARK: - Stats Bar

struct FocusStatsBar: View {
    let sessionsToday: Int
    let minutesToday: Int
    let streak: Int

    var body: some View {
        HStack(spacing: 20) {
            statItem(value: "\(sessionsToday)", label: "sessions")
            statItem(value: "\(minutesToday)", label: "min")
            if streak > 0 {
                statItem(value: "\(streak)", label: "streak")
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
            Text(label)
                .font(.system(size: 11, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.25))
        }
    }
}

// MARK: - FocusView (Main)

struct FocusView: View {
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    @ObservedObject var timer: FocusTimer

    @StateObject private var store = FocusStore()
    @State private var showSettings = false

    private var activeAccent: Color {
        return timer.phase.isFocus ? focusRed : breakGreen
    }

    private var activeGlow: Color {
        return timer.phase.isFocus ? focusRedGlow : breakGreenGlow
    }

    var body: some View {
        ZStack {
            backgroundView

            VStack(spacing: 0) {
                Spacer()

                // Timer ring
                FocusRing(
                    progress: timer.progress,
                    timeString: timer.timeString,
                    phaseLabel: timer.phaseLabel,
                    accent: activeAccent
                )
                .frame(width: 260, height: 260)

                // Long break dots
                if timer.focusSessionsInCycle > 0 {
                    sessionDots
                        .padding(.top, 16)
                }

                // Stats
                FocusStatsBar(
                    sessionsToday: store.sessionsToday,
                    minutesToday: store.focusMinutesToday,
                    streak: store.currentStreak
                )
                .padding(.top, 20)

                Spacer()
                    .frame(height: 36)

                // Controls
                controlButtons

                Spacer()

                // Mode switcher
                FocusModeSwitcher(
                    preset: $timer.preset,
                    accent: activeAccent
                ) { newPreset in
                    timer.applyPreset(newPreset)
                }
                .padding(.bottom, 28)
            }

            // MARK: - Settings Overlay
            focusSettingsOverlay

            // Tap to dismiss
            if showSettings {
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            showSettings = false
                        }
                    }
                    .zIndex(98)
            }
        }
        .animation(.easeInOut(duration: 0.6), value: timer.phase.isFocus)
        .onAppear {
            timer.requestNotificationPermission()
            timer.soundEnabled = soundEnabled
            timer.hapticsEnabled = hapticsEnabled
            timer.onPhaseComplete = { phase, wasSkipped in
                guard phase == .focus, !wasSkipped else { return }
                store.recordCompletedFocus(durationMinutes: timer.workMinutes)
            }
        }
        .onChange(of: soundEnabled) { _, val in timer.soundEnabled = val }
        .onChange(of: hapticsEnabled) { _, val in timer.hapticsEnabled = val }
    }

    // MARK: - Session Dots

    private var sessionDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i < timer.focusSessionsInCycle
                          ? activeAccent
                          : Color.white.opacity(0.12))
                    .frame(width: 6, height: 6)
            }
        }
        .animation(.spring(response: 0.3), value: timer.focusSessionsInCycle)
    }

    // MARK: - Background

    private var backgroundView: some View {
        ZStack {
            Color(red: 0.039, green: 0.039, blue: 0.059)
                .ignoresSafeArea()

            RadialGradient(
                colors: [activeGlow.opacity(0.4), Color.clear],
                center: .center,
                startRadius: 30,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        HStack(spacing: 20) {
            // Reset
            controlButton(icon: "arrow.counterclockwise", size: 48, iconSize: 16) {
                timer.reset()
                if hapticsEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }

            // Play / Pause
            Button {
                timer.toggle()
                if hapticsEnabled {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            } label: {
                Image(systemName: timer.isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 68)
                    .background(
                        Circle()
                            .fill(activeAccent.opacity(0.2))
                            .overlay(
                                Circle()
                                    .strokeBorder(activeAccent.opacity(0.35), lineWidth: 0.5)
                            )
                    )
                    .shadow(color: activeAccent.opacity(0.25), radius: 20, x: 0, y: 4)
            }

            // Skip
            controlButton(icon: "forward.fill", size: 48, iconSize: 16) {
                timer.skip()
            }
        }
    }

    private func controlButton(icon: String, size: CGFloat, iconSize: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(.white.opacity(0.05))
                        .overlay(
                            Circle().strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
                        )
                )
        }
    }

    // MARK: - Focus Settings Overlay

    private var focusSettingsOverlay: some View {
        VStack {
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showSettings.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.07)))
                    }

                    if showSettings {
                        focusSettingsPanel
                            .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topTrailing)))
                    }
                }
                .padding(.trailing, 64)
                .padding(.top, 16)
            }
            Spacer()
        }
        .zIndex(99)
    }

    // MARK: - Focus Settings Panel

    private var focusSettingsPanel: some View {
        VStack(spacing: 0) {
            // Auto-start toggle
            focusToggleRow(
                icon: "play.circle.fill",
                title: "Auto-start",
                isOn: Binding(
                    get: { timer.autoStartNext },
                    set: { timer.autoStartNext = $0 }
                )
            )

            focusDivider

            // Work stepper
            focusStepperRow(
                icon: "brain.head.profile.fill",
                title: "Work",
                value: timer.workMinutes,
                range: 1...60
            ) { v in
                timer.updateWorkMinutes(v)
            }

            focusDivider

            // Break stepper
            focusStepperRow(
                icon: "cup.and.saucer.fill",
                title: "Break",
                value: timer.breakMinutes,
                range: 1...30
            ) { v in
                timer.updateBreakMinutes(v)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
        .frame(width: 210)
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
    }

    private var focusDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }

    private func focusToggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
                .frame(width: 22)

            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.75))

            Spacer()

            FocusToggle(isOn: isOn, accent: activeAccent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func focusStepperRow(icon: String, title: String, value: Int, range: ClosedRange<Int>, onChange: @escaping (Int) -> Void) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
                .frame(width: 22)

            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.75))

            Spacer()

            HStack(spacing: 6) {
                Button {
                    if value > range.lowerBound {
                        onChange(value - 1)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(.white.opacity(0.08)))
                }

                Text("\(value)")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(width: 24, alignment: .center)

                Button {
                    if value < range.upperBound {
                        onChange(value + 1)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(.white.opacity(0.08)))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Focus Toggle

struct FocusToggle: View {
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

// MARK: - Preview

#Preview {
    FocusView(
        soundEnabled: .constant(true),
        hapticsEnabled: .constant(true),
        timer: FocusTimer()
    )
    .preferredColorScheme(.dark)
}
