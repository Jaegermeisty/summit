//
//  SettingsView.swift
//  Summit
//
//  Created on 2026-02-10
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage(WeightUnit.storageKey) private var weightUnitRaw: String = WeightUnit.kg.rawValue

    private var weightUnit: WeightUnit {
        WeightUnit(rawValue: weightUnitRaw) ?? .kg
    }

    private let privacyPolicyURL = URL(string: "https://jpventures.dev/summit/privacy/")!
    private let supportURL = URL(string: "mailto:mathias.jpventures@gmail.com")!
    private let iconCreditsURL = URL(string: "https://www.flaticon.com/free-icons/warm-up")!

    var body: some View {
        ZStack {
            settingsBackground

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    settingsHeader

                    settingsSection(title: "Units") {
                        unitPicker
                    }

                    settingsSection(title: "Pro") {
                        HStack {
                            Text("Status")
                                .font(.custom("Avenir Next", size: 14))
                                .foregroundStyle(Color.summitTextSecondary)
                            Spacer()
                            Text(purchaseManager.isPro ? "Unlocked" : "Free")
                                .font(.custom("Avenir Next", size: 14))
                                .foregroundStyle(purchaseManager.isPro ? Color.summitOrange : Color.summitTextSecondary)
                        }

                        if !purchaseManager.isPro {
                            Button("Restore Purchase") {
                                Task { await purchaseManager.restorePurchases() }
                            }
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundStyle(Color.summitOrange)
                        }
                    }

                    settingsSection(title: "Support") {
                        Link("Contact Support", destination: supportURL)
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundStyle(Color.summitOrange)
                    }

                    settingsSection(title: "Legal") {
                        Link("Privacy Policy", destination: privacyPolicyURL)
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundStyle(Color.summitOrange)

                        Link("Icon Credits (Flaticon)", destination: iconCreditsURL)
                            .font(.custom("Avenir Next", size: 14))
                            .foregroundStyle(Color.summitOrange)
                    }

                    settingsSection(title: "About") {
                        HStack {
                            Text("Version")
                                .font(.custom("Avenir Next", size: 14))
                                .foregroundStyle(Color.summitTextSecondary)
                            Spacer()
                            Text(appVersion)
                                .font(.custom("Avenir Next", size: 14))
                                .foregroundStyle(Color.summitText)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
                .foregroundStyle(Color.summitTextSecondary)
            }
        }
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Preferences")
                .font(.custom("Avenir Next", size: 22))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitText)
        }
    }

    private var unitPicker: some View {
        HStack(spacing: 8) {
            ForEach(WeightUnit.allCases) { unit in
                Button {
                    weightUnitRaw = unit.rawValue
                } label: {
                    Text(unit.symbol.uppercased())
                        .font(.custom("Avenir Next", size: 14))
                        .fontWeight(weightUnit == unit ? .semibold : .regular)
                        .foregroundStyle(weightUnit == unit ? Color.summitText : Color.summitTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(weightUnit == unit ? Color.summitCardElevated : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.summitCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.custom("Avenir Next", size: 12))
                .fontWeight(.semibold)
                .foregroundStyle(Color.summitTextSecondary)

            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.summitCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.summitOrange.opacity(0.12), lineWidth: 1)
                    )
            )
        }
    }

    private var settingsBackground: some View {
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
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: 140, y: -140)
        }
        .ignoresSafeArea()
    }

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(PurchaseManager())
    }
}
