//
//  PaywallView.swift
//  Summit
//
//  Created on 2026-02-09
//

import SwiftUI

struct PaywallView: View {
    let title: String
    let subtitle: String
    let features: [String]
    let primaryTitle: String
    let primaryAction: () -> Void
    let secondaryTitle: String?
    let secondaryRole: ButtonRole?
    let secondaryAction: (() -> Void)?
    let showsRestore: Bool
    let restoreAction: (() -> Void)?
    let showsClose: Bool
    let closeAction: (() -> Void)?

    init(
        title: String,
        subtitle: String,
        features: [String],
        primaryTitle: String,
        primaryAction: @escaping () -> Void,
        secondaryTitle: String? = nil,
        secondaryRole: ButtonRole? = nil,
        secondaryAction: (() -> Void)? = nil,
        showsRestore: Bool = false,
        restoreAction: (() -> Void)? = nil,
        showsClose: Bool = false,
        closeAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.features = features
        self.primaryTitle = primaryTitle
        self.primaryAction = primaryAction
        self.secondaryTitle = secondaryTitle
        self.secondaryRole = secondaryRole
        self.secondaryAction = secondaryAction
        self.showsRestore = showsRestore
        self.restoreAction = restoreAction
        self.showsClose = showsClose
        self.closeAction = closeAction
    }

    var body: some View {
        ZStack {
            paywallBackground

            ScrollView {
                VStack(spacing: 20) {
                    if showsClose {
                        HStack {
                            Spacer()
                            Button("Close") {
                                closeAction?()
                            }
                            .foregroundStyle(Color.summitTextSecondary)
                        }
                    }

                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.summitOrange.opacity(0.15))
                                .frame(width: 64, height: 64)

                            Image(systemName: "sparkles")
                                .font(.system(size: 26, weight: .semibold))
                                .foregroundStyle(Color.summitOrange)
                        }

                        Text(title)
                            .font(.custom("Avenir Next", size: 24))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.summitText)

                        Text(subtitle)
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundStyle(Color.summitTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(features, id: \.self) { item in
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.summitOrange)
                                Text(item)
                                    .font(.custom("Avenir Next", size: 14))
                                    .foregroundStyle(Color.summitText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.summitCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                            )
                    )

                    Button {
                        primaryAction()
                    } label: {
                        Text(primaryTitle)
                            .font(.custom("Avenir Next", size: 16))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.summitBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.summitOrange,
                                                Color.summitOrange.opacity(0.75)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    if let secondaryTitle, let secondaryAction {
                        Button(secondaryTitle, role: secondaryRole) {
                            secondaryAction()
                        }
                        .font(.custom("Avenir Next", size: 14))
                        .foregroundStyle(Color.summitTextSecondary)
                    }

                    if showsRestore, let restoreAction {
                        Button("Restore Purchase") {
                            restoreAction()
                        }
                        .font(.custom("Avenir Next", size: 12))
                        .foregroundStyle(Color.summitTextTertiary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
    }

    private var paywallBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.summitBackground,
                    Color(hex: "#111114")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Color.summitOrange.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 140, y: -140)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    PaywallView(
        title: "Unlock Pro",
        subtitle: "Access analytics and full history.",
        features: [
            "Full workout history",
            "Progress analytics",
            "Plan comparison (coming soon)"
        ],
        primaryTitle: "Unlock Pro",
        primaryAction: {},
        secondaryTitle: "Not now",
        secondaryAction: {}
    )
}
