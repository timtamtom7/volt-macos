import SwiftUI
import AppKit

enum Theme {
    // MARK: - macOS 26 Liquid Glass Design System

    // MARK: - Colors

    /// Liquid Glass tint color - adaptive blue for primary actions
    static let liquidGlassTint = Color.accentColor

    /// Primary action color
    static let primaryBlue = Color.accentColor

    /// Battery health / charged state
    static let primaryGreen = Color(hex: "34C759")

    /// Charging / active energy
    static let accentCyan = Color(hex: "00D4FF")

    /// Degrading health / recommendations
    static let warning = Color.orange

    /// Critical health / issues
    static let danger = Color.red

    // MARK: - macOS System Colors (adaptive to light/dark mode)

    static let background = Color(nsColor: .windowBackgroundColor)
    static let secondaryBackground = Color(nsColor: .controlBackgroundColor)
    static let tertiaryBackground = Color(nsColor: .textBackgroundColor)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let surfaceLight = Color(nsColor: .underPageBackgroundColor)

    static let textPrimary = Color(nsColor: .labelColor)
    static let textSecondary = Color(nsColor: .secondaryLabelColor)
    static let textTertiary = Color(nsColor: .tertiaryLabelColor)

    // MARK: - Color Aliases

    static let secondaryBg = secondaryBackground
    static let accentGreen = primaryGreen
    static let accentOrange = warning
    static let accentRed = danger

    // MARK: - macOS 26 Spacing (8pt Grid System)

    static let spacing2: CGFloat = 2
    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
    static let spacing40: CGFloat = 40

    // Legacy aliases for compatibility
    static let spacingXS: CGFloat = spacing4
    static let spacingSM: CGFloat = spacing8
    static let spacingMD: CGFloat = spacing12
    static let spacingLG: CGFloat = spacing16
    static let spacingXL: CGFloat = spacing24

    // MARK: - macOS 26 Animations

    static let springAnimation = Animation.spring(response: 0.35, dampingFraction: 0.65, blendDuration: 0.15)
    static let quickSpringAnimation = Animation.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0)
    static let hoverSpringAnimation = Animation.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.1)

    // MARK: - macOS 26 Shadows

    static let shadowSmall = (color: Color.black.opacity(0.08), radius: CGFloat(6), x: CGFloat(0), y: CGFloat(3))
    static let shadowMedium = (color: Color.black.opacity(0.12), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(6))
    static let shadowLarge = (color: Color.black.opacity(0.16), radius: CGFloat(20), x: CGFloat(0), y: CGFloat(10))

    // MARK: - macOS 26 Shape System

    /// Rounded rectangles for Medium controls (desktop)
    static let cornerRadiusSM: CGFloat = 6
    static let cornerRadiusMD: CGFloat = 8
    static let cornerRadiusLG: CGFloat = 12

    /// Capsules for Large/XLarge controls (touch-friendly)
    static let capsuleRadius: CGFloat = .infinity

    // MARK: - Typography

    static let fontSizeCaption2: CGFloat = 10
    static let fontSizeCaption: CGFloat = 11
    static let fontSizeSubheadline: CGFloat = 12
    static let fontSizeBody: CGFloat = 13
    static let fontSizeHeadline: CGFloat = 14
    static let fontSizeTitle3: CGFloat = 16
    static let fontSizeTitle2: CGFloat = 18
    static let fontSizeTitle1: CGFloat = 22
    static let fontSizeLargeTitle: CGFloat = 28

    // MARK: - Battery Health Color

    static func healthColor(for percentage: Double) -> Color {
        if percentage >= 0.8 {
            return primaryGreen
        } else if percentage >= 0.5 {
            return warning
        } else {
            return danger
        }
    }

    static func batteryColor(charge: Int, isCharging: Bool) -> Color {
        if isCharging { return primaryGreen }
        if charge <= 20 { return danger }
        if charge <= 50 { return warning }
        return textPrimary
    }
}

// MARK: - Visual Effect View for Backgrounds

struct VisualEffectView: NSViewRepresentable {
    enum Material {
        case sidebar
        case windowBackground
        case hudWindow
        case menu
        case popover
        case sheet
        case fullScreenUI
    }

    let material: Material
    var cornerRadius: CGFloat = 0

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        switch material {
        case .sidebar:
            nsView.material = .sidebar
        case .windowBackground:
            nsView.material = .windowBackground
        case .hudWindow:
            nsView.material = .hudWindow
        case .menu:
            nsView.material = .menu
        case .popover:
            nsView.material = .popover
        case .sheet:
            nsView.material = .sheet
        case .fullScreenUI:
            nsView.material = .fullScreenUI
        }
        nsView.state = .active
        nsView.wantsLayer = true
        nsView.layer?.cornerRadius = cornerRadius
    }
}

// MARK: - Liquid Glass Background Modifier

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = Theme.cornerRadiusLG
    var isHovered: Bool = false

    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.linearGradient(
                        colors: [
                            .white.opacity(0.3),
                            .white.opacity(0.1),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 0.5)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0), value: isPressed)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = Theme.cornerRadiusLG) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }

    func liquidGlassHover(cornerRadius: CGFloat = Theme.cornerRadiusLG) -> some View {
        modifier(LiquidGlassHoverModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Liquid Glass Hover Modifier with Buoyancy

struct LiquidGlassHoverModifier: ViewModifier {
    var cornerRadius: CGFloat = Theme.cornerRadiusLG

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var hoverAmount: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(.linearGradient(
                        colors: [
                            .white.opacity(isHovered ? 0.5 : 0.3),
                            .white.opacity(isHovered ? 0.2 : 0.1),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: isHovered ? 1 : 0.5)
            )
            .shadow(
                color: .black.opacity(isHovered ? 0.15 : 0.08),
                radius: isHovered ? 12 : 6,
                x: 0,
                y: isHovered ? 6 : 3
            )
            .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
            .offset(y: isHovered ? -2 : 0)
            .animation(.spring(response: 0.35, dampingFraction: 0.65, blendDuration: 0.15), value: isHovered)
            .animation(.spring(response: 0.2, dampingFraction: 0.7, blendDuration: 0), value: isPressed)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - Hover Effect Modifier

struct HoverEffectModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0.1), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func hoverEffect() -> some View {
        modifier(HoverEffectModifier())
    }
}

// MARK: - Capsule Button Style

struct CapsuleButtonStyle: ButtonStyle {
    var tintColor: Color = Theme.primaryBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(configuration.isPressed ? tintColor.opacity(0.7) : tintColor)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
    }
}

// MARK: - Rounded Rectangle Button Style

struct RoundedRectButtonStyle: ButtonStyle {
    var tintColor: Color = Theme.primaryBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                    .fill(configuration.isPressed ? tintColor.opacity(0.7) : tintColor)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6, blendDuration: 0), value: configuration.isPressed)
    }
}

// MARK: - Glass Card Button Style

struct GlassCardButtonStyle: ButtonStyle {
    var tintColor: Color = Theme.primaryBlue

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(Theme.spacing16)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusLG)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusLG)
                    .stroke(configuration.isPressed ? tintColor.opacity(0.5) : tintColor.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(
                color: .black.opacity(configuration.isPressed ? 0.05 : 0.1),
                radius: configuration.isPressed ? 2 : 6,
                x: 0,
                y: configuration.isPressed ? 1 : 3
            )
            .animation(.spring(response: 0.25, dampingFraction: 0.7, blendDuration: 0), value: configuration.isPressed)
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
