//
//  AntistressApp.swift
//  Antistress
//
//  Created by Mykhailo Mirzaiev on 30.03.2026.
//

import SwiftUI

@main
struct AntistressApp: App {
    init() {
        SubscriptionManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(SubscriptionManager.shared)
        }
    }
}

// MARK: - Root View (Splash → Content)

struct RootView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var ringScale: CGFloat = 0.8
    @State private var ringOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0F")
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(red: 0.48, green: 0.41, blue: 0.93).opacity(glowOpacity * 0.12),
                    Color.clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: 250
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.48, green: 0.41, blue: 0.93).opacity(0.3),
                                    Color(red: 0.31, green: 0.80, blue: 0.77).opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 160, height: 160)
                        .scaleEffect(ringScale)
                        .opacity(ringOpacity)

                    Image("LaunchLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }

                Text("Softly")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.9),
                                .white.opacity(0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                logoOpacity = 1
                logoScale = 1.0
                glowOpacity = 1
            }

            withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
                ringScale = 1.15
                ringOpacity = 1
            }

            withAnimation(.easeInOut(duration: 0.8).delay(1.0)) {
                ringScale = 1.3
                ringOpacity = 0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                textOpacity = 1
            }

            withAnimation(.easeIn(duration: 0.4).delay(1.8)) {
                textOpacity = 0
                glowOpacity = 0
            }
        }
    }
}
