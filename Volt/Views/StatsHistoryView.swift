import SwiftUI

struct StatsHistoryView: View {
    @ObservedObject var voltStore: VoltStore

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Battery health overview
                healthOverview

                // Recent sessions
                sessionsSection

                // Charge history
                historySection
            }
            .padding(16)
        }
    }

    // MARK: - Health Overview

    private var healthOverview: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Battery Health")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            HStack(spacing: 16) {
                healthGauge(
                    value: voltStore.currentCharge.healthPercent,
                    title: "Health",
                    color: healthColor
                )
                healthGauge(
                    value: voltStore.currentCharge.cycleCount,
                    title: "Cycles",
                    color: Theme.textSecondary,
                    isCount: true
                )
                healthGauge(
                    value: Int(voltStore.currentCharge.temperature),
                    title: "Temp °C",
                    color: temperatureColor,
                    isCount: true
                )
            }

            // Health bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Design Capacity")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("\(voltStore.currentCharge.maxCapacity) / \(voltStore.currentCharge.designCapacity) mAh")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.secondaryBg)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(healthColor)
                            .frame(width: geo.size.width * healthRatio, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(12)
        .background(Theme.secondaryBg)
        .cornerRadius(10)
    }

    private func healthGauge(value: Int, title: String, color: Color, isCount: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(isCount ? "\(value)" : "\(value)%")
                .font(.system(size: isCount ? 22 : 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var healthRatio: CGFloat {
        guard voltStore.currentCharge.designCapacity > 0 else { return 0 }
        return CGFloat(voltStore.currentCharge.maxCapacity) / CGFloat(voltStore.currentCharge.designCapacity)
    }

    private var healthColor: Color {
        let pct = voltStore.currentCharge.healthPercent
        if pct >= 80 { return Theme.accentGreen }
        if pct >= 60 { return Theme.accentOrange }
        return Theme.accentRed
    }

    private var temperatureColor: Color {
        let temp = voltStore.currentCharge.temperature
        if temp < 35 { return Theme.accentGreen }
        if temp < 40 { return Theme.accentOrange }
        return Theme.accentRed
    }

    // MARK: - Sessions Section

    private var sessionsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Recent Charge Sessions")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            let sessions = voltStore.recentSessions
            if sessions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "bolt.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.textSecondary)
                        Text("No sessions recorded yet")
                            .font(.system(size: 11))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 16)
            } else {
                ForEach(sessions.prefix(5)) { session in
                    SessionRowView(session: session)
                }
            }
        }
        .padding(12)
        .background(Theme.secondaryBg)
        .cornerRadius(10)
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("7-Day Charge History")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            if voltStore.weeklyHistory.isEmpty {
                HStack {
                    Spacer()
                    Text("Not enough data yet")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
                .padding(.vertical, 12)
            } else {
                weeklyChart
            }
        }
        .padding(12)
        .background(Theme.secondaryBg)
        .cornerRadius(10)
    }

    private var weeklyChart: some View {
        VStack(spacing: 8) {
            // Simple bar chart
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(voltStore.weeklyHistory, id: \.date) { day in
                    VStack(spacing: 2) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.accentGreen.opacity(0.8))
                                .frame(width: 28, height: CGFloat(day.maxCharge) * 1.2)

                            RoundedRectangle(cornerRadius: 3)
                                .fill(Theme.primaryBlue)
                                .frame(width: 28, height: CGFloat(day.minCharge) * 1.2)
                        }
                        .frame(height: 60)

                        Text(dayLabel(day.date))
                            .font(.system(size: 9))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }

            HStack {
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.accentGreen.opacity(0.8))
                        .frame(width: 10, height: 10)
                    Text("Max")
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.primaryBlue)
                        .frame(width: 10, height: 10)
                    Text("Min")
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textSecondary)
                }
            }
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

// MARK: - Session Row View

struct SessionRowView: View {
    let session: ChargingSession

    var body: some View {
        HStack(spacing: 8) {
            // Start charge
            Text("\(session.startCharge)%")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .frame(width: 36, alignment: .leading)

            // Arrow
            Image(systemName: "arrow.right")
                .font(.system(size: 9))
                .foregroundColor(Theme.textSecondary)

            // End charge
            if let endCharge = session.endCharge {
                Text("\(endCharge)%")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.accentGreen)
                    .frame(width: 36, alignment: .leading)
            } else {
                Text("In progress")
                    .font(.system(size: 11))
                    .foregroundColor(Theme.accentOrange)
            }

            Spacer()

            // Duration
            Text(session.durationString)
                .font(.system(size: 11))
                .foregroundColor(Theme.textSecondary)

            // Date
            Text(formattedDate)
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.black.opacity(0.03))
        .cornerRadius(6)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: session.startedAt)
    }
}
