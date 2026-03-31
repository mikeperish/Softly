// MARK: - AccountView.swift
// Fidget App — Account Sheet

import SwiftUI

// MARK: - AccountView
struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var soundEnabled: Bool
    @Binding var hapticsEnabled: Bool
    
    @State private var showFeedbackForm = false
    @State private var feedbackText = ""
    @State private var feedbackSent = false
    @State private var showPremiumAlert = false
    @State private var showNameEditor = false
    @State private var userName: String = UserDefaults.standard.string(forKey: "userName") ?? "User"
    @State private var nameInput: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    feedbackBanner
                    profileSection
                    premiumBanner
                    settingsSection
                    coffeeBanner
                    aboutSection
                    
                    Text("Made with love for ADHD minds")
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.15))
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .scrollIndicators(.hidden)
            .background(Color(hex: "#0A0A0F"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Account")
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
    
    // MARK: - Feedback Banner
    @ViewBuilder
    private var feedbackBanner: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showFeedbackForm.toggle()
                feedbackSent = false
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.50, green: 0.47, blue: 0.87).opacity(0.2),
                                    Color(red: 0.36, green: 0.79, blue: 0.65).opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.50, green: 0.47, blue: 0.87),
                                    Color(red: 0.36, green: 0.79, blue: 0.65)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Share feedback")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Help us make the app better")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                
                Spacer()
                
                Image(systemName: showFeedbackForm ? "chevron.up" : "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.50, green: 0.47, blue: 0.87).opacity(0.08),
                                Color(red: 0.36, green: 0.79, blue: 0.65).opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.50, green: 0.47, blue: 0.87).opacity(0.2),
                                        Color(red: 0.36, green: 0.79, blue: 0.65).opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        
        if showFeedbackForm {
            feedbackFormView
        }
    }
    
    // MARK: - Feedback Form
    private var feedbackFormView: some View {
        VStack(spacing: 12) {
            if feedbackSent {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color(red: 0.36, green: 0.79, blue: 0.65))
                    Text("Thank you for your feedback!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.vertical, 16)
            } else {
                TextEditor(text: $feedbackText)
                    .scrollContentBackground(.hidden)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.04))
                    )
                    .overlay(alignment: .topLeading) {
                        if feedbackText.isEmpty {
                            Text("What can we improve?")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.2))
                                .padding(.horizontal, 16)
                                .padding(.top, 20)
                                .allowsHitTesting(false)
                        }
                    }
                
                Button {
                    sendFeedback()
                } label: {
                    Text("Send feedback")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    feedbackText.isEmpty
                                    ? Color.white.opacity(0.05)
                                    : Color(red: 0.50, green: 0.47, blue: 0.87)
                                )
                        )
                }
                .disabled(feedbackText.isEmpty)
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.03))
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Profile Section
    @ViewBuilder
    private var profileSection: some View {
        AccountSectionHeader(title: "PROFILE")
        
        VStack(spacing: 0) {
            // Name row — tappable to edit
            Button {
                nameInput = userName
                showNameEditor = true
            } label: {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(red: 0.50, green: 0.47, blue: 0.87))
                            .frame(width: 20)
                        Text("Name")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Text(userName)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.25))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.15))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)
            .alert("Your name", isPresented: $showNameEditor) {
                TextField("Enter name", text: $nameInput)
                Button("Save") {
                    if !nameInput.trimmingCharacters(in: .whitespaces).isEmpty {
                        userName = nameInput.trimmingCharacters(in: .whitespaces)
                        UserDefaults.standard.set(userName, forKey: "userName")
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This name is shown only to you")
            }
            
            Divider().background(.white.opacity(0.06)).padding(.leading, 46)
            
            AccountRow(icon: "crown.fill", iconColor: Color(hex: "#FFD700"), title: "Plan", trailingText: "Free", showDivider: false)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.white.opacity(0.03))
        )
    }
    
    // MARK: - Premium Banner
    private var premiumBanner: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showPremiumAlert = true
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation { showPremiumAlert = false }
            }
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: "#FFD700").opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(hex: "#FFD700"))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Unlock Premium")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("All patterns, themes & sounds")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.2))
                }
                .padding(16)
                
                if showPremiumAlert {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("More features coming soon!")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(Color(hex: "#FFD700").opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.50, green: 0.47, blue: 0.87).opacity(0.08),
                                Color(red: 0.36, green: 0.79, blue: 0.65).opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#FFD700").opacity(0.15), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(spacing: 8) {
            AccountSectionHeader(title: "SETTINGS")
            
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 20)
                        Text("Sound")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Toggle("", isOn: $soundEnabled)
                        .labelsHidden()
                        .tint(Color(red: 0.36, green: 0.79, blue: 0.65))
                        .scaleEffect(0.85)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                
                Divider().background(.white.opacity(0.06)).padding(.leading, 46)
                
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.5))
                            .frame(width: 20)
                        Text("Haptics")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    Toggle("", isOn: $hapticsEnabled)
                        .labelsHidden()
                        .tint(Color(red: 0.36, green: 0.79, blue: 0.65))
                        .scaleEffect(0.85)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.03))
            )
        }
    }
    
    // MARK: - Coffee Banner
    private var coffeeBanner: some View {
        Button {
            if let url = URL(string: "https://buymeacoffee.com") {
                UIApplication.shared.open(url)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.06, green: 0.55, blue: 0.50).opacity(0.25),
                                    Color(red: 0.20, green: 0.70, blue: 0.65).opacity(0.25)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Text("☕")
                        .font(.system(size: 16))
                        .frame(width: 20, height: 20)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Buy me a coffee")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Support indie development")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.4))
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.2))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.06, green: 0.55, blue: 0.50).opacity(0.08),
                                Color(red: 0.20, green: 0.70, blue: 0.65).opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.06, green: 0.55, blue: 0.50).opacity(0.2),
                                        Color(red: 0.20, green: 0.70, blue: 0.65).opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 8) {
            AccountSectionHeader(title: "ABOUT")
            
            VStack(spacing: 0) {
                AccountRow(icon: "info.circle.fill", iconColor: .white.opacity(0.4), title: "Version", trailingText: "1.0.0", showDivider: true)
                AccountRow(icon: "heart.fill", iconColor: Color(red: 0.83, green: 0.33, blue: 0.49), title: "Rate the app", showChevron: true, showDivider: true)
                AccountRow(icon: "doc.text.fill", iconColor: .white.opacity(0.4), title: "Privacy Policy", showChevron: true, showDivider: false)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.03))
            )
        }
    }
    
    // MARK: - Send Feedback
    private func sendFeedback() {
        let subject = "Fidget App Feedback"
        let body = feedbackText
        let email = "mykhailo.mirzaiev@icloud.com"
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
        
        withAnimation {
            feedbackSent = true
            feedbackText = ""
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Helper Views

struct AccountSectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

struct AccountRow: View {
    let icon: String
    var iconColor: Color = .white.opacity(0.5)
    let title: String
    var trailingText: String? = nil
    var showChevron: Bool = false
    var showDivider: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(iconColor)
                        .frame(width: 20)
                    Text(title)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                if let text = trailingText {
                    Text(text)
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.25))
                }
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.15))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            
            if showDivider {
                Divider()
                    .background(.white.opacity(0.06))
                    .padding(.leading, 46)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    Color.black
        .sheet(isPresented: .constant(true)) {
            AccountView(
                soundEnabled: .constant(true),
                hapticsEnabled: .constant(true)
            )
        }
}
