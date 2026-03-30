import SwiftUI

struct PopView: View {
    var body: some View {
        ZStack {
            AppBackground(accentColor: AppColors.pop)
            GlassCard(title: "Pop", icon: "circle.hexagongrid.fill", accentColor: AppColors.pop)
        }
    }
}
