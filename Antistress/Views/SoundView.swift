import SwiftUI

struct SoundView: View {
    var body: some View {
        ZStack {
            AppBackground(accentColor: AppColors.sound)
            GlassCard(title: "Sound", icon: "waveform", accentColor: AppColors.sound)
        }
    }
}
