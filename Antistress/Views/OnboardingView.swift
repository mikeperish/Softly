// MARK: - OnboardingView.swift
// Fidget App — ADHD-friendly tap-through onboarding

import SwiftUI
import AudioToolbox

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case hey = 0
    case cantFocus
    case brainWontStop
    case builtForMe
    case builtForYou
    case distracted
    case heart
    case feltNice
    case noPressure
    case letsGo

    var text: String? {
        switch self {
        case .hey:           return "Hey! I'm Mike"
        case .cantFocus:     return "I can't focus"
        case .brainWontStop: return "My brain won't shut up"
        case .builtForMe:    return "I built this app for myself"
        case .builtForYou:   return "Then I built it for you"
        case .distracted:    return "Got distracted 500 times making it"
        case .heart:         return nil
        case .feltNice:      return "See? That felt nice"
        case .noPressure:    return "No pressure. Really."
        case .letsGo:        return "But if you stay..."
        }
    }

    var isHeartStep: Bool { self == .heart }
    var isFinalStep: Bool { self == .letsGo }
}

// MARK: - Heart Colors

private let heartColors: [Color] = [
    Color(red: 0.95, green: 0.3, blue: 0.45),
    Color(red: 0.48, green: 0.41, blue: 0.93),
    Color(red: 0.31, green: 0.80, blue: 0.77),
]

// MARK: - Heart Shape

struct OnboardingHeart: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.25))
        path.addCurve(
            to: CGPoint(x: 0, y: h * 0.35),
            control1: CGPoint(x: w * 0.35, y: 0),
            control2: CGPoint(x: 0, y: h * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: 0, y: h * 0.65),
            control2: CGPoint(x: w * 0.35, y: h * 0.85)
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.35),
            control1: CGPoint(x: w * 0.65, y: h * 0.85),
            control2: CGPoint(x: w, y: h * 0.65)
        )
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.25),
            control1: CGPoint(x: w, y: h * 0.1),
            control2: CGPoint(x: w * 0.65, y: 0)
        )
        return path
    }
}

// MARK: - OnboardingView

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var currentStep: OnboardingStep = .hey
    @State private var textOpacity: Double = 0
    @State private var heartTapCount: Int = 0
    @State private var heartFlipAngle: Double = 0
    @State private var heartScale: CGFloat = 1.0
    @State private var heartColorIndex: Int = 0
    @State private var heartOpacity: Double = 1

    private let purple = Color(red: 0.48, green: 0.41, blue: 0.93)
    private let teal = Color(red: 0.31, green: 0.80, blue: 0.77)

    var body: some View {
        ZStack {
            // Background
            Color(hex: "#0A0A0F")
                .ignoresSafeArea()

            // Glow
            RadialGradient(
                colors: [
                    purple.opacity(0.08),
                    Color.clear
                ],
                center: .init(x: 0.5, y: 0.53),
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Skip — top right
            VStack {
                HStack {
                    Spacer()
                    if !currentStep.isFinalStep {
                        Button {
                            onComplete()
                        } label: {
                            Text("Skip")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.2))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.trailing, 12)
                .padding(.top, 16)
                Spacer()
            }

            // Center content — true center
            if currentStep.isHeartStep {
                heartContent
            } else {
                textContent
            }

            // Bottom — separate layer, doesn't affect centering
            VStack {
                Spacer()

                if currentStep.isFinalStep {
                    Button {
                        onComplete()
                    } label: {
                        Text("Let's go")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [purple, teal],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .padding(.horizontal, 40)
                    .opacity(textOpacity)
                    .padding(.bottom, 40)
                } else if !currentStep.isHeartStep {
                    Text("tap anywhere")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.12))
                        .padding(.bottom, 40)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !currentStep.isFinalStep && !currentStep.isHeartStep {
                advanceStep()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                textOpacity = 1
            }
        }
    }

    // MARK: - Text Content

    private var textContent: some View {
        VStack(spacing: 16) {
            if let text = currentStep.text {
                Text(text)
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
                    .opacity(textOpacity)
                    .id(currentStep.rawValue)
            }
        }
    }

    // MARK: - Heart Content

    private var heartContent: some View {
        VStack(spacing: 24) {
            ZStack {
                OnboardingHeart()
                    .fill(
                        LinearGradient(
                            colors: [
                                heartColors[heartColorIndex].opacity(0.8),
                                heartColors[heartColorIndex].opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 110)

                OnboardingHeart()
                    .fill(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .frame(width: 110, height: 100)

                OnboardingHeart()
                    .stroke(
                        heartColors[heartColorIndex].opacity(0.4),
                        lineWidth: 1.5
                    )
                    .frame(width: 120, height: 110)
            }
            .scaleEffect(heartScale)
            .rotation3DEffect(.degrees(heartFlipAngle), axis: (0, 1, 0), perspective: 0.5)
            .opacity(heartOpacity)
            .onTapGesture {
                tapHeart()
            }

            Text(heartTapCount == 0 ? "Tap the heart" : heartTapCount == 1 ? "Again!" : "One more!")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
                .opacity(textOpacity)
                .id("heart-hint-\(heartTapCount)")
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                textOpacity = 1
            }
        }
    }

    // MARK: - Logic

    private func advanceStep() {
        let allSteps = OnboardingStep.allCases
        guard let currentIndex = allSteps.firstIndex(of: currentStep),
              currentIndex + 1 < allSteps.count else { return }

        withAnimation(.easeOut(duration: 0.15)) {
            textOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            currentStep = allSteps[currentIndex + 1]
            withAnimation(.easeOut(duration: 0.4)) {
                textOpacity = 1
            }
        }
    }

    private func tapHeart() {
        heartTapCount += 1

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        if heartTapCount < 3 {
            withAnimation(.interpolatingSpring(stiffness: 160, damping: 18)) {
                heartFlipAngle += 180
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                heartColorIndex = heartTapCount % heartColors.count

                withAnimation(.easeOut(duration: 0.15)) {
                    textOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        textOpacity = 1
                    }
                }
            }
        } else {
            AudioServicesPlaySystemSound(1306)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

            withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                heartScale = 1.3
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) {
                    heartScale = 0
                    heartOpacity = 0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    advanceStep()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
}
