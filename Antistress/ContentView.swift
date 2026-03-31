import SwiftUI

// MARK: - Global Settings Panel

struct GlobalSettingsPanel: View {
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    var focusTimer: FocusTimer?
    let accent: Color

    var body: some View {
        VStack {
            HStack {
                Spacer()
                panelContent
                    .padding(.trailing, 20)
            }
            Spacer()
        }
        .padding(.top, 52)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.92, anchor: .topTrailing).combined(with: .opacity),
                removal: .scale(scale: 0.96, anchor: .topTrailing).combined(with: .opacity)
            )
        )
        .zIndex(100)
    }

    private var panelContent: some View {
        VStack(spacing: 0) {
            toggleRow(icon: "speaker.wave.2.fill", title: "Sound", isOn: $soundEnabled)
            dividerLine
            toggleRow(icon: "hand.tap.fill", title: "Haptics", isOn: $hapticsEnabled)

            if let timer = focusTimer {
                dividerLine
                toggleRow(icon: "play.circle.fill", title: "Auto-start", isOn: Binding(
                    get: { timer.autoStartNext },
                    set: { timer.autoStartNext = $0 }
                ))
                dividerLine
                stepperRow(icon: "brain.head.profile.fill", title: "Work", value: timer.workMinutes) { v in
                    timer.updateWorkMinutes(v)
                }
                dividerLine
                stepperRow(icon: "cup.and.saucer.fill", title: "Break", value: timer.breakMinutes) { v in
                    timer.updateBreakMinutes(v)
                }
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
        .frame(width: focusTimer != nil ? 210 : 190)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 0.5)
            .padding(.horizontal, 12)
    }

    private func toggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.5))
                .frame(width: 22)

            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.75))

            Spacer()

            GlobalToggle(isOn: isOn, accent: accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func stepperRow(icon: String, title: String, value: Int, onChange: @escaping (Int) -> Void) -> some View {
        let range: ClosedRange<Int> = title == "Work" ? 1...60 : 1...30

        return HStack(spacing: 10) {
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

// MARK: - Global Toggle

struct GlobalToggle: View {
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

// MARK: - ContentView

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var popSilhouette: BubbleSilhouette = .heart
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var showGlobalSettings = false
    @State private var showAccount = false

    @StateObject private var focusTimer = FocusTimer()

    var body: some View {
        ZStack(alignment: .top) {
            // Tabs
            TabView(selection: $selectedTab) {
                PopView(
                    currentSilhouette: $popSilhouette,
                    soundEnabled: $soundEnabled,
                    hapticsEnabled: $hapticsEnabled
                )
                .tabItem { Label("Pop", systemImage: "circle.hexagongrid.fill") }
                .tag(0)

                SoundView()
                    .tabItem { Label("Sound", systemImage: "waveform") }
                    .tag(1)

                CubeView(
                    soundEnabled: $soundEnabled,
                    hapticsEnabled: $hapticsEnabled
                )
                .tabItem { Label("Cube", systemImage: "cube.fill") }
                .tag(2)

                FocusView(
                    soundEnabled: $soundEnabled,
                    hapticsEnabled: $hapticsEnabled,
                    timer: focusTimer
                )
                .tabItem { Label("Focus", systemImage: "timer") }
                .tag(3)

                PhysicsView()
                    .tabItem { Label("Physics", systemImage: "gyroscope") }
                    .tag(4)
            }
            .tint(accentForTab(selectedTab))
            .onAppear { configureTabBar() }
            .onChange(of: selectedTab) { _, _ in
                if showGlobalSettings {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        showGlobalSettings = false
                    }
                }
            }

            // Global header
            HStack {
                // Premium
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.white.opacity(0.07)))
                }

                Spacer()

                // Pop silhouette title
                if selectedTab == 0 {
                    HStack(spacing: 6) {
                        SilhouetteIconView(silhouette: popSilhouette, size: 15)

                        Text(popSilhouette.displayName)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                            .id(popSilhouette.rawValue)
                    }
                    .animation(.easeInOut(duration: 0.35), value: popSilhouette)
                }

                Spacer()

                // Ellipsis — global settings
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showGlobalSettings.toggle()
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.white.opacity(0.07)))
                }

                // Account
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showAccount = true
                } label: {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.white.opacity(0.07)))
                }
                .sheet(isPresented: $showAccount) {
                    AccountView(
                        soundEnabled: $soundEnabled,
                        hapticsEnabled: $hapticsEnabled
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Settings overlay
            if showGlobalSettings {
                Color.black.opacity(0.01)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            showGlobalSettings = false
                        }
                    }
                    .zIndex(99)

                GlobalSettingsPanel(
                    soundEnabled: $soundEnabled,
                    hapticsEnabled: $hapticsEnabled,
                    focusTimer: selectedTab == 3 ? focusTimer : nil,
                    accent: accentForTab(selectedTab)
                )
            }
        }
    }

    private func accentForTab(_ tab: Int) -> Color {
        switch tab {
        case 0: return AppColors.pop
        case 1: return AppColors.sound
        case 2: return AppColors.cube
        case 3: return AppColors.focus
        case 4: return AppColors.physics
        default: return AppColors.cube
        }
    }

    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 0.95)

        let item = UITabBarItemAppearance()
        item.normal.iconColor = UIColor.white.withAlphaComponent(0.35)
        item.normal.titleTextAttributes = [.foregroundColor: UIColor.white.withAlphaComponent(0.35)]

        appearance.stackedLayoutAppearance = item
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
