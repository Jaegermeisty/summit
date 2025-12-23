//
//  Colors.swift
//  summit
//
//  Created on 2025-12-23
//

import SwiftUI

extension Color {
    // MARK: - Summit Theme Colors

    /// Primary background color - charcoal/dark grey
    static let summitBackground = Color(hex: "#1C1C1E")

    /// Card/section background - slightly lighter than main background
    static let summitCard = Color(hex: "#2C2C2E")

    /// Elevated card background - for prominent cards
    static let summitCardElevated = Color(hex: "#3A3A3C")

    /// Primary accent color - orange
    static let summitOrange = Color(hex: "#FF9500")

    /// Secondary accent - dimmed orange for less prominent elements
    static let summitOrangeDim = Color(hex: "#FF9500").opacity(0.7)

    /// Primary text color - white
    static let summitText = Color.white

    /// Secondary text color - light grey
    static let summitTextSecondary = Color(hex: "#AEAEB2")

    /// Tertiary text color - dimmer grey
    static let summitTextTertiary = Color(hex: "#8E8E93")

    /// Success color - green for checkmarks, completion
    static let summitSuccess = Color(hex: "#34C759")

    /// Destructive color - red for delete actions
    static let summitDestructive = Color(hex: "#FF3B30")

    /// Divider/separator color
    static let summitDivider = Color(hex: "#3A3A3C")

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
