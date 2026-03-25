import SwiftUI

struct HealthDetailView: View {
    @EnvironmentObject var voltStore: VoltStore
    @Binding var isPresented: Bool

    @State private var showHealthHistory = false

    private let healthService = HealthTrackingService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Battery Health")
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
                    // Health Status Card
                    healthStatusCard

                    // Cycle Count
                    cycleCountCard

                    // Capacity Info
                    capacityCard

                    // Health Alerts
                    if !healthAlerts.isEmpty {
                        alertsSection
                    }

                    // Health Trend
                    healthTrendCard
                }
                .padding(16)
            }
        }
        .frame(width: 420, height: 500)
        .background(Theme.background)
    }

    private var batteryInfo: BatteryInfo {
        voltStore.currentCharge
    }

    private var healthAlerts: [HealthAlert] {
        healthService.checkHealthAlerts(batteryInfo: batteryInfo)
    }

    private var healthStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .stroke(Theme.textSecondary.opacity(0.3), lineWidth: 8)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: CGFloat(batteryInfo.healthPercent) / 100)
                        .stroke(healthColor, lineWidth: 8)
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 2) {
                        Text("\(batteryInfo.healthPercent)%")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Theme.textPrimary)
                        Text("Health")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(batteryInfo.healthDescription)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(healthColor)

                    if let snapshot = healthService.getLatestSnapshot() {
                        HStack(spacing: 4) {
                            Image(systemName: trendIcon)
                                .font(.system(size: 12))
                                .foregroundColor(trendColor)
                            Text(trendDescription)
                                .font(.system(size: 12))
                                .foregroundColor(Theme.textSecondary)
                        }
                    }

                    Text("Based on charging capacity vs design")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                }
                .padding(.leading, 8)

                Spacer()
            }
        }
        .padding(16)
        .background(Theme.secondaryBg)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.textSecondary.opacity(0.3), lineWidth: 1)
        )
    }

    private var cycleCountCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Cycle Count")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                Text("\(batteryInfo.cycleCount)")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.textPrimary)
                Text("/ 1000 rated")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("Est. Remaining")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                Text("\(healthService.estimatedFullCyclesRemaining(currentCycles: batteryInfo.cycleCount))")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primaryBlue)
                Text("cycles")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(16)
        .background(Theme.secondaryBg)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.textSecondary.opacity(0.3), lineWidth: 1)
        )
    }

    private var capacityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Capacity Details")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            VStack(spacing: 8) {
                capacityRow(label: "Design Capacity", value: "\(batteryInfo.designCapacity) mAh", color: Theme.textSecondary)
                capacityRow(label: "Current Max", value: "\(batteryInfo.maxCapacity) mAh", color: Theme.textPrimary)
                capacityRow(label: "Current Charge", value: "\(batteryInfo.currentCapacity) mAh", color: Theme.primaryBlue)

                Divider()

                let healthValue = batteryInfo.maxCapacity > 0
                    ? (Double(batteryInfo.maxCapacity) / Double(batteryInfo.designCapacity)) * 100
                    : 0
                capacityRow(label: "Health", value: String(format: "%.1f%%", healthValue), color: healthColor)
            }
        }
        .padding(16)
        .background(Theme.secondaryBg)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.textSecondary.opacity(0.3), lineWidth: 1)
        )
    }

    private func capacityRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Theme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(color)
        }
    }

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(healthAlerts) { alert in
                HStack(spacing: 8) {
                    Image(systemName: alertIcon(for: alert.type))
                        .foregroundColor(alertColor(for: alert.type))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(alert.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Theme.textPrimary)
                        Text(alert.message)
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
                .padding(8)
                .background(alertColor(for: alert.type).opacity(0.1))
                .cornerRadius(6)
            }
        }
    }

    private var healthTrendCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Health Trend")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            let avgChange = healthService.averageHealthChangePerMonth()
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Monthly Change")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                    Text(String(format: "%+.2f%%", avgChange))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(avgChange >= 0 ? Theme.accentGreen : Theme.accentRed)
                }

                Spacer()

                if let snapshot = healthService.getLatestSnapshot() {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Last Snapshot")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                        Text(snapshot.healthPercent == batteryInfo.healthPercent ? "Today" : "\(snapshot.healthPercent)%")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.secondaryBg)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Theme.textSecondary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var healthColor: Color {
        switch batteryInfo.healthPercent {
        case 80...: return Theme.accentGreen
        case 60..<80: return Theme.accentOrange
        default: return Theme.accentRed
        }
    }

    private var trendIcon: String {
        let snapshot = healthService.getLatestSnapshot()
        guard let last = snapshot else { return "equal.circle.fill" }
        if batteryInfo.healthPercent > last.healthPercent + 2 { return "arrow.up.circle.fill" }
        if batteryInfo.healthPercent < last.healthPercent - 2 { return "arrow.down.circle.fill" }
        return "equal.circle.fill"
    }

    private var trendColor: Color {
        let snapshot = healthService.getLatestSnapshot()
        guard let last = snapshot else { return Theme.primaryBlue }
        if batteryInfo.healthPercent > last.healthPercent + 2 { return Theme.accentGreen }
        if batteryInfo.healthPercent < last.healthPercent - 2 { return Theme.accentRed }
        return Theme.primaryBlue
    }

    private var trendDescription: String {
        let snapshot = healthService.getLatestSnapshot()
        guard let last = snapshot else { return "No history" }
        if batteryInfo.healthPercent > last.healthPercent + 2 { return "Improving" }
        if batteryInfo.healthPercent < last.healthPercent - 2 { return "Degrading" }
        return "Stable"
    }

    private func alertIcon(for type: HealthAlert.AlertType) -> String {
        switch type {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }

    private func alertColor(for type: HealthAlert.AlertType) -> Color {
        switch type {
        case .info: return Theme.primaryBlue
        case .warning: return Theme.accentOrange
        case .critical: return Theme.accentRed
        }
    }
}
