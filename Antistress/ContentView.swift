import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var popSilhouette: BubbleSilhouette = .heart
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var showAccount = false
    @State private var showPremium = false

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

                SoundView(soundEnabled: $soundEnabled, hapticsEnabled: $hapticsEnabled)
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

                PhysicsView(soundEnabled: $soundEnabled, hapticsEnabled: $hapticsEnabled)
                    .tabItem { Label("Physics", systemImage: "gyroscope") }
                    .tag(4)
            }
            .tint(accentForTab(selectedTab))
            .onAppear { configureTabBar() }

            // Global header
            HStack {
                // Premium
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showPremium = true
                } label: {
                    Text("💎")
                        .font(.system(size: 18))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.white.opacity(0.07)))
                }
                .sheet(isPresented: $showPremium) {
                    PremiumView()
                }

                Spacer()

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
