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

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.summitText)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.summitTextSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(features, id: \.self) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.summitOrange)
                        Text(item)
                            .foregroundStyle(Color.summitText)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.summitCard)
            )

            Button {
                primaryAction()
            } label: {
                Text(primaryTitle)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.summitOrange)

            if let secondaryTitle, let secondaryAction {
                Button(secondaryTitle, role: secondaryRole) {
                    secondaryAction()
                }
                .foregroundStyle(Color.summitTextSecondary)
            }

            if showsRestore, let restoreAction {
                Button("Restore Purchase") {
                    restoreAction()
                }
                .font(.footnote)
                .foregroundStyle(Color.summitTextSecondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.summitBackground)
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
