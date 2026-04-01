// MARK: - PremiumView.swift
// Fidget App — Premium Screen with RevenueCat Paywall

import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - PremiumView
struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subscriptionManager

    var body: some View {
        PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { customerInfo in
                print("Purchase completed!")
                Task {
                    await subscriptionManager.refreshStatus()
                }
                dismiss()
            }
            .onRestoreCompleted { customerInfo in
                print("Restore completed!")
                Task {
                    await subscriptionManager.refreshStatus()
                }
                dismiss()
            }
    }
}

// MARK: - Preview
#Preview {
    PremiumView()
        .environment(SubscriptionManager.shared)
}
