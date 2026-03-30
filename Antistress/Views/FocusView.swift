import SwiftUI

struct FocusView: View {
    var body: some View {
        ZStack {
            AppBackground(accentColor: AppColors.focus)
            GlassCard(title: "Focus", icon: "timer", accentColor: AppColors.focus)
        }
    }
}
