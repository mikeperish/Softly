// MARK: - SubscriptionManager.swift
// Fidget App — RevenueCat Subscription Management

import SwiftUI
import RevenueCat
import Observation

// MARK: - SubscriptionManager
@Observable
final class SubscriptionManager {

    static let shared = SubscriptionManager()

    // MARK: - State
    var isPremium: Bool = false

    // MARK: - Constants
    static let apiKey = "test_wYJIzcCOYXjHFXvDckHoaaBYSHP"
    static let entitlementID = "Softly Premium"

    // MARK: - Init
    private init() {}

    // MARK: - Configure (call once on app launch)
    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Self.apiKey)

        // Listen for customer info updates
        Task { @MainActor in
            for await info in Purchases.shared.customerInfoStream {
                self.isPremium = info.entitlements[Self.entitlementID]?.isActive == true
            }
        }

        // Initial fetch
        Task { @MainActor in
            await refreshStatus()
        }
    }

    // MARK: - Refresh Status
    func refreshStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            self.isPremium = info.entitlements[Self.entitlementID]?.isActive == true
        } catch {
            print("RevenueCat: Failed to fetch customer info: \(error)")
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async -> Bool {
        do {
            let info = try await Purchases.shared.restorePurchases()
            self.isPremium = info.entitlements[Self.entitlementID]?.isActive == true
            return isPremium
        } catch {
            print("RevenueCat: Restore failed: \(error)")
            return false
        }
    }
}
