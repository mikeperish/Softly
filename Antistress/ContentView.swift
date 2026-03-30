import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var popSilhouette: BubbleSilhouette = .heart

    var body: some View {
        ZStack(alignment: .top) {
            // Таби
            TabView(selection: $selectedTab) {
                PopView(currentSilhouette: $popSilhouette)
                    .tabItem { Label("Pop", systemImage: "circle.hexagongrid.fill") }
                    .tag(0)

                SoundView()
                    .tabItem { Label("Sound", systemImage: "waveform") }
                    .tag(1)

                CubeView()
                    .tabItem { Label("Cube", systemImage: "cube.fill") }
                    .tag(2)

                FocusView()
                    .tabItem { Label("Focus", systemImage: "timer") }
                    .tag(3)

                PhysicsView()
                    .tabItem { Label("Physics", systemImage: "gyroscope") }
                    .tag(4)
            }
            .tint(accentForTab(selectedTab))
            .onAppear { configureTabBar() }

            // Глобальна шапка — поверх всіх табів
            HStack {
                // Преміум — зліва
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
                
                // Акаунт — справа
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(.white.opacity(0.07)))
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
