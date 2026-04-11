import SwiftUI

struct AppStoreScreenshotView: View {
    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: Theme.spacing24) {
                batteryStatusSection
                healthCard
                chargingSessionCard
                settingsToggle
            }
            .padding(Theme.spacing24)
        }
        .frame(width: 400, height: 500)
    }

    private var batteryStatusSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.spacing4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("87")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.primaryGreen)
                    Text("%")
                        .font(.system(size: Theme.fontSizeTitle2, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                HStack(spacing: Theme.spacing4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: Theme.fontSizeCaption))
                        .foregroundColor(Theme.accentGreen)
                    Text("Charging")
                        .font(.system(size: Theme.fontSizeCaption))
                        .foregroundColor(Theme.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                DetailRow(label: "Health", value: "87%")
                DetailRow(label: "Cycles", value: "142")
                DetailRow(label: "Temp", value: "34°C")
            }
        }
        .padding(Theme.spacing16)
        .background(Theme.secondaryBg)
        .cornerRadius(Theme.cornerRadiusLG)
    }

    private var healthCard: some View {
        VStack(spacing: Theme.spacing12) {
            HStack {
                Text("Battery Health")
                    .font(.system(size: Theme.fontSizeHeadline, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("Normal")
                    .font(.system(size: Theme.fontSizeSubheadline, weight: .medium))
                    .foregroundColor(Theme.primaryGreen)
            }
            HStack {
                ZStack {
                    Circle()
                        .stroke(Theme.textSecondary.opacity(0.3), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    Circle()
                        .trim(from: 0, to: 0.87)
                        .stroke(Theme.primaryGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    Text("87%")
                        .font(.system(size: Theme.fontSizeCaption, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Maximum Capacity")
                        .font(.system(size: Theme.fontSizeCaption))
                        .foregroundColor(Theme.textSecondary)
                    Text("5,432 mAh")
                        .font(.system(size: Theme.fontSizeSubheadline, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Text("Design: 6,000 mAh")
                        .font(.system(size: Theme.fontSizeCaption))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
        .padding(Theme.spacing16)
        .background(Theme.secondaryBg)
        .cornerRadius(Theme.cornerRadiusLG)
    }

    private var chargingSessionCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacing12) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(Theme.accentCyan)
                Text("Charging Session")
                    .font(.system(size: Theme.fontSizeSubheadline, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Text("2h 15m")
                    .font(.system(size: Theme.fontSizeCaption))
                    .foregroundColor(Theme.textSecondary)
            }
            HStack(spacing: Theme.spacing8) {
                HStack(spacing: 4) {
                    Text("42%")
                        .font(.system(size: Theme.fontSizeCaption, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 8))
                        .foregroundColor(Theme.textTertiary)
                    Text("89%")
                        .font(.system(size: Theme.fontSizeCaption, weight: .medium))
                        .foregroundColor(Theme.primaryGreen)
                }
                Spacer()
                Text("+47% charged")
                    .font(.system(size: Theme.fontSizeCaption))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(Theme.spacing16)
        .background(Theme.secondaryBg)
        .cornerRadius(Theme.cornerRadiusLG)
    }

    private var settingsToggle: some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundColor(Theme.accentOrange)
            Text("Low Battery Alert")
                .font(.system(size: Theme.fontSizeSubheadline))
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Circle()
                .fill(Theme.primaryGreen)
                .frame(width: 8, height: 8)
        }
        .padding(Theme.spacing16)
        .background(Theme.secondaryBg)
        .cornerRadius(Theme.cornerRadiusLG)
    }
}

#Preview {
    AppStoreScreenshotView()
}
