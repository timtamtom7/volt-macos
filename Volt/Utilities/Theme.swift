import SwiftUI

enum Theme {
    // MARK: - Colors

    /// Dark charcoal background
    static let background = Color(hex: "1E1E2E")

    /// Card/panel surfaces
    static let surface = Color(hex: "2A2A3E")

    /// Elevated surfaces
    static let surfaceLight = Color(hex: "363650")

    /// Battery health / charged state
    static let primaryGreen = Color(hex: "34C759")

    /// Charging / active energy / lightning bolt
    static let accentCyan = Color(hex: "00D4FF")

    /// Degrading health / recommendations
    static let warning = Color(hex: "FF9500")

    /// Critical health / issues
    static let danger = Color(hex: "FF3B30")

    /// Main text on dark backgrounds
    static let textPrimary = Color.white

    /// Secondary labels
    static let textSecondary = Color(hex: "8E8E93")

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24

    // MARK: - Corner Radius

    static let cornerRadiusSM: CGFloat = 4
    static let cornerRadiusMD: CGFloat = 8
    static let cornerRadiusLG: CGFloat = 12

    // MARK: - Battery Health Color

    /// Returns the appropriate color for a given battery health percentage
    static func healthColor(for percentage: Double) -> Color {
        if percentage >= 0.8 {
            return primaryGreen
        } else if percentage >= 0.5 {
            return warning
        } else {
            return danger
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
