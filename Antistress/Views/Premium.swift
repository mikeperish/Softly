// MARK: - PremiumView.swift
// Fidget App — Premium Screen

import SwiftUI

// MARK: - PremiumView
struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero
                    heroSection

                    // Features list
                    featuresSection

                    // CTA button (placeholder)
                    ctaButton

                    // Restore
                    restoreButton

                    // Legal
                    legalSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .background(Color(hex: "#0A0A0F"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Premium")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .toolbarBackground(Color(hex: "#0A0A0F"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: "#0A0A0F"))
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(.white.opacity(0.07)))
            }
            .padding(.trailing, 20)
            .padding(.top, 16)
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 16) {
            Text("💎")
                .font(.system(size: 56))
                .padding(.top, 20)

            Text("Unlock Everything")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Get the full Softly experience with all patterns, sounds, and features.")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 0) {
            featureRow(
                icon: "circle.hexagongrid.fill",
                color: AppColors.pop,
                title: "All Pop Patterns",
                subtitle: "Unlock every silhouette shape"
            )

            featureDivider

            featureRow(
                icon: "waveform",
                color: AppColors.sound,
                title: "Extra Sound Types",
                subtitle: "Rain, ocean, forest & more"
            )

            featureDivider

            featureRow(
                icon: "gyroscope",
                color: AppColors.physics,
                title: "All Spinner Patterns",
                subtitle: "New visual patterns for the spinner"
            )

            featureDivider

            featureRow(
                icon: "paintpalette.fill",
                color: AppColors.cube,
                title: "Custom Themes",
                subtitle: "Personalize colors and styles"
            )

            featureDivider

            featureRow(
                icon: "heart.fill",
                color: Color(hex: "#FF6B9D"),
                title: "Support Indie Dev",
                subtitle: "Help keep Softly ad-free"
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.03))
        )
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.35))
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(color.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var featureDivider: some View {
        Divider()
            .background(.white.opacity(0.06))
            .padding(.leading, 66)
    }

    // MARK: - CTA Button
    private var ctaButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            // TODO: RevenueCat purchase
        } label: {
            VStack(spacing: 4) {
                Text("Coming Soon")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("We're working on premium features")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.50, green: 0.47, blue: 0.87),
                                Color(red: 0.36, green: 0.79, blue: 0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Restore Button
    private var restoreButton: some View {
        Button {
            // TODO: RevenueCat restore
        } label: {
            Text("Restore Purchases")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Legal Section
    private var legalSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Button {
                    // TODO: Terms
                } label: {
                    Text("Terms of Use")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.2))
                }

                Button {
                    // TODO: Privacy
                } label: {
                    Text("Privacy Policy")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.2))
                }
            }

            Text("Made with love for ADHD minds")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.12))
        }
    }
}

// MARK: - Preview
#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            PremiumView()
        }
}
