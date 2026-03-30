import SwiftUI

struct PhysicsView: View {
    var body: some View {
        ZStack {
            AppBackground(accentColor: AppColors.physics)
            GlassCard(title: "Physics", icon: "gyroscope", accentColor: AppColors.physics)
        }
    }
}
