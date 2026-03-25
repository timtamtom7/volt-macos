import SwiftUI

struct WidgetView: View {
    @EnvironmentObject var voltStore: VoltStore
    @Binding var isPresented: Bool

    @State private var selectedWidgetSize: WidgetSize = .small

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Widgets")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(spacing: 16) {
                    // Widget Preview
                    widgetPreviewSection

                    // Widget Sizes
                    widgetSizesSection
                }
                .padding(16)
            }
        }
        .frame(width: 460, height: 480)
        .background(Theme.background)
    }

    private var widgetPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.secondaryBg)
                    .frame(
                        width: widgetPreviewSize.width,
                        height: widgetPreviewSize.height
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                widgetContent
                    .frame(width: widgetPreviewSize.width - 24, height: widgetPreviewSize.height - 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }

    private var widgetSizesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Available Widgets")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: 8) {
                widgetOption(
                    title: "Small Widget",
                    description: "Battery level and status",
                    icon: "bolt.fill",
                    size: .small
                )

                widgetOption(
                    title: "Medium Widget",
                    description: "Battery level, health, and time remaining",
                    icon: "rectangle.grid.1x2.fill",
                    size: .medium
                )

                widgetOption(
                    title: "Large Widget",
                    description: "Full battery dashboard with all metrics",
                    icon: "rectangle.grid.2x2.fill",
                    size: .large
                )
            }
        }
    }

    private func widgetOption(title: String, description: String, icon: String, size: WidgetSize) -> some View {
        Button(action: { selectedWidgetSize = size }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Theme.primaryBlue)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                if selectedWidgetSize == size {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.accentGreen)
                }
            }
            .padding(12)
            .background(selectedWidgetSize == size ? Theme.primaryBlue.opacity(0.1) : Theme.secondaryBg)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }

    private var widgetContent: some View {
        let info = voltStore.currentCharge
        return VStack(spacing: 8) {
            switch selectedWidgetSize {
            case .small:
                smallWidget(info: info)
            case .medium:
                mediumWidget(info: info)
            case .large:
                largeWidget(info: info)
            }
        }
    }

    private func smallWidget(info: BatteryInfo) -> some View {
        VStack(spacing: 6) {
            Image(systemName: info.isCharging ? "bolt.fill" : "bolt")
                .font(.system(size: 24))
                .foregroundColor(info.isCharging ? Theme.accentGreen : Theme.primaryBlue)

            Text("\(info.charge)%")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            Text(info.isCharging ? "Charging" : (info.isPluggedIn ? "Plugged" : "Battery"))
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
        }
    }

    private func mediumWidget(info: BatteryInfo) -> some View {
        HStack(spacing: 16) {
            VStack(spacing: 4) {
                Image(systemName: info.isCharging ? "bolt.fill" : "bolt")
                    .font(.system(size: 28))
                    .foregroundColor(info.isCharging ? Theme.accentGreen : Theme.primaryBlue)

                Text("\(info.charge)%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundColor(healthColor(info.healthPercent))
                    Text("\(info.healthPercent)% health")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }

                HStack {
                    Image(systemName: "thermometer")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                    Text(String(format: "%.1f°C", info.temperature))
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }

                HStack {
                    Image(systemName: "arrow.2.circlepath")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                    Text("\(info.cycleCount) cycles")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private func largeWidget(info: BatteryInfo) -> some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Volt")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Theme.textPrimary)
                    Text(info.isCharging ? "Charging" : (info.isPluggedIn ? "Plugged In" : "On Battery"))
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: info.isCharging ? "bolt.fill" : "bolt")
                    .font(.system(size: 28))
                    .foregroundColor(info.isCharging ? Theme.accentGreen : Theme.primaryBlue)
            }

            // Main charge
            Text("\(info.charge)%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)

            // Grid of stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                widgetStatCard(icon: "heart.fill", label: "Health", value: "\(info.healthPercent)%", color: healthColor(info.healthPercent))
                widgetStatCard(icon: "thermometer", label: "Temp", value: String(format: "%.1f°C", info.temperature), color: tempColor(info.temperature))
                widgetStatCard(icon: "arrow.2.circlepath", label: "Cycles", value: "\(info.cycleCount)", color: Theme.primaryBlue)
                widgetStatCard(icon: "battery.100", label: "Capacity", value: "\(info.maxCapacity)mAh", color: Theme.primaryBlue)
            }
        }
    }

    private func widgetStatCard(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(Theme.textPrimary)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Theme.secondaryBg)
        .cornerRadius(8)
    }

    // MARK: - Helpers

    private var widgetPreviewSize: CGSize {
        switch selectedWidgetSize {
        case .small: return CGSize(width: 140, height: 140)
        case .medium: return CGSize(width: 280, height: 140)
        case .large: return CGSize(width: 300, height: 300)
        }
    }

    private func healthColor(_ percent: Int) -> Color {
        switch percent {
        case 80...: return Theme.accentGreen
        case 60..<80: return Theme.accentOrange
        default: return Theme.accentRed
        }
    }

    private func tempColor(_ temp: Double) -> Color {
        if temp >= 40 { return Theme.accentRed }
        if temp >= 35 { return Theme.accentOrange }
        return Theme.accentGreen
    }
}

enum WidgetSize: String, CaseIterable {
    case small
    case medium
    case large
}
