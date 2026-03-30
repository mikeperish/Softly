import SwiftUI

struct MagnetsView: View {
    var body: some View {
        ZStack {
            AppBackground()
            GlassCard(title: "Magnets", icon: "magnet.fill")
        }
    }
}
