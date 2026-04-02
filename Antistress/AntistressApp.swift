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
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - S Line Shape

struct SLine: Shape {
    let inset: CGFloat

    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let scale = min(w, h) / 280

        let cx = w / 2
        let cy = h / 2

        let s = (140 - inset) * scale

        var path = Path()
        path.move(to: CGPoint(
            x: cx,
            y: cy - s
        ))
        path.addCurve(
            to: CGPoint(x: cx + s * 0.7, y: cy - s * 0.35),
            control1: CGPoint(x: cx + s * 0.35, y: cy - s),
            control2: CGPoint(x: cx + s * 0.7, y: cy - s * 0.75)
        )
        path.addCurve(
            to: CGPoint(x: cx, y: cy + s * 0.05),
            control1: CGPoint(x: cx + s * 0.7, y: cy + s * 0.05),
            control2: CGPoint(x: cx + s * 0.3, y: cy + s * 0.05)
        )
        path.addCurve(
            to: CGPoint(x: cx - s * 0.7, y: cy + s * 0.45),
            control1: CGPoint(x: cx - s * 0.3, y: cy + s * 0.05),
            control2: CGPoint(x: cx - s * 0.7, y: cy + s * 0.1)
        )
        path.addCurve(
            to: CGPoint(x: cx, y: cy + s),
            control1: CGPoint(x: cx - s * 0.7, y: cy + s * 0.8),
            control2: CGPoint(x: cx - s * 0.35, y: cy + s)
        )
        return path
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var trim1: CGFloat = 0
    @State private var trim2: CGFloat = 0
    @State private var trim3: CGFloat = 0
    @State private var trim4: CGFloat = 0
    @State private var dotOpacity: Double = 0
    @State private var fadeOut: Double = 1

    private let purple = Color(red: 0.48, green: 0.41, blue: 0.93)
    private let teal = Color(red: 0.31, green: 0.80, blue: 0.77)

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0F")
                .ignoresSafeArea()

            ZStack {
                SLine(inset: 0)
                    .trim(from: 0, to: trim1)
                    .stroke(
                        LinearGradient(
                            colors: [purple, teal],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .opacity(0.75)

                SLine(inset: 25)
                    .trim(from: 0, to: trim2)
                    .stroke(
                        LinearGradient(
                            colors: [purple, teal],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .opacity(0.5)

                SLine(inset: 48)
                    .trim(from: 0, to: trim3)
                    .stroke(
                        LinearGradient(
                            colors: [purple, teal],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .opacity(0.3)

                SLine(inset: 68)
                    .trim(from: 0, to: trim4)
                    .stroke(
                        LinearGradient(
                            colors: [purple, teal],
                            startPoint: .topTrailing,
                            endPoint: .bottomLeading
                        ),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
                    .opacity(0.15)

                Circle()
                    .fill(.white.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .opacity(dotOpacity)
            }
            .frame(width: 200, height: 200)
            .opacity(fadeOut)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                trim1 = 1
            }
            withAnimation(.easeInOut(duration: 0.7).delay(0.15)) {
                trim2 = 1
            }
            withAnimation(.easeInOut(duration: 0.6).delay(0.3)) {
                trim3 = 1
            }
            withAnimation(.easeInOut(duration: 0.5).delay(0.45)) {
                trim4 = 1
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.7)) {
                dotOpacity = 1
            }
            withAnimation(.easeIn(duration: 0.4).delay(2.3)) {
                fadeOut = 0
            }
        }
    }
}
