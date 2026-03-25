import SwiftUI

/// Volt App Icon — Placeholder preview
/// This file renders the brand icon concept for visual reference.
/// Replace with actual asset catalog icons (Assets.xcassets/AppIcon.appiconset)
/// before shipping.
struct VoltAppIconView: View {
    var body: some View {
        VoltIconShape()
            .frame(width: 256, height: 256)
    }
}

struct VoltIconShape: View {
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)

            ZStack {
                // Dark charcoal background
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(Color(hex: "1E1E2E"))

                // Drop shadow
                RoundedRectangle(cornerRadius: size * 0.18)
                    .fill(Color.clear)
                    .shadow(color: .black.opacity(0.2), radius: size * 0.04, x: 0, y: size * 0.03)

                // Battery body
                VStack(spacing: 0) {
                    // Positive terminal nub
                    RoundedRectangle(cornerRadius: size * 0.02)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "00D4FF"), Color(hex: "34C759")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.22, height: size * 0.04)
                        .offset(y: size * 0.01)

                    // Main battery body
                    RoundedRectangle(cornerRadius: size * 0.06)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "00D4FF"), Color(hex: "34C759")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.5, height: size * 0.55)
                        .overlay(
                            ZStack {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: size * 0.28, weight: .bold, design: .default))
                                    .foregroundColor(.white)
                                    .shadow(color: Color(hex: "00D4FF").opacity(0.6), radius: size * 0.02)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: size * 0.06)
                                .stroke(Color.white.opacity(0.15), lineWidth: size * 0.01)
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

#Preview {
    VoltAppIconView()
        .frame(width: 512, height: 512)
}
