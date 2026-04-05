import SwiftUI

struct StatsHistoryView: View {
    @ObservedObject var voltStore: VoltStore
    @State private var showHeatmap = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing16) {
                healthOverview
                sessionsSection
                historySection
            }
            .padding(Theme.spacing16)
        }
        .background(Theme.background)
        .sheet(isPresented: $showHeatmap) {
            ChargingHeatmapView(isPresented: $showHeatmap)
                .environmentObject(voltStore)
        }
    }

    private var healthOverview: some View {
        VStack(spacing: Theme.spacing12) {
            HStack {
                Text("Battery Health")
                    .font(.system(size: Theme.fontSizeBody, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Button(action: { showHeatmap = true }) {
                    HStack(spacing: Theme.spacing4) {
                        Image(systemName: "calendar")
                            .font(.system(size: Theme.fontSizeCaption2))
                        Text("Heatmap")
                            .font(.system(size: Theme.fontSizeCaption))
                    }
                    .foregroundColor(Theme.primaryBlue)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: Theme.spacing16) {
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

            VStack(alignment: .leading, spacing: Theme.spacing4) {
                HStack {
                    Text("Design Capacity")
                        .font(.system(size: Theme.fontSizeCaption2))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                    Text("\(voltStore.currentCharge.maxCapacity) / \(voltStore.currentCharge.designCapacity) mAh")
                        .font(.system(size: Theme.fontSizeCaption2, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                            .fill(Theme.secondaryBg)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                            .fill(healthColor)
                            .frame(width: geo.size.width * healthRatio, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(Theme.spacing12)
        .background(Theme.secondaryBg)
        .cornerRadius(Theme.cornerRadiusMD)
    }

    private func healthGauge(value: Int, title: String, color: Color, isCount: Bool = false) -> some View {
        VStack(spacing: Theme.spacing4) {
            Text(isCount ? "\(value)" : "\(value)%")
                .font(.system(size: isCount ? 22 : 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: Theme.fontSizeCaption2))
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

    private var sessionsSection: some View {
        VStack(spacing: Theme.spacing8) {
            HStack {
                Text("Recent Charge Sessions")
                    .font(.system(size: Theme.fontSizeBody, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            let sessions = voltStore.recentSessions
            if sessions.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: Theme.spacing4) {
                        Image(systemName: "bolt.circle")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.textSecondary)
                        Text("No sessions recorded yet")
                            .font(.system(size: Theme.fontSizeCaption))
                            .foregroundColor(Theme.textSecondary)
                    }
                    Spacer()
                }
                .padding(.vertical, Theme.spacing16)
            } else {
                ForEach(sessions.prefix(5)) { session in
                    SessionRowView(session: session)
                }
            }
        }
        .padding(Theme.spacing12)
        .background(Theme.secondaryBg)
        .cornerRadius(Theme.cornerRadiusMD)
    }

    private var historySection: some View {
        VStack(spacing: Theme.spacing8) {
            HStack {
                Text("7-Day Charge History")
                    .font(.system(size: Theme.fontSizeBody, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)
                Spacer()
            }

            if voltStore.weeklyHistory.isEmpty {
                HStack {
                    Spacer()
                    Text("Not enough data yet")
                        .font(.system(size: Theme.fontSizeCaption))
                        .foregroundColor(Theme.textSecondary)
                    Spacer()
                }
                .padding(.vertical, Theme.spacing12)
            } else {
                weeklyChart
            }
        }
        .padding(Theme.spacing12)
        .background(Theme.secondaryBg)
        .cornerRadius(Theme.cornerRadiusMD)
    }

    private var weeklyChart: some View {
        VStack(spacing: Theme.spacing8) {
            HStack(alignment: .bottom, spacing: Theme.spacing4) {
                ForEach(voltStore.weeklyHistory, id: \.date) { day in
                    VStack(spacing: 2) {
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                                .fill(Theme.accentGreen.opacity(0.8))
                                .frame(width: 28, height: CGFloat(day.maxCharge) * 1.2)

                            RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                                .fill(Theme.primaryBlue)
                                .frame(width: 28, height: CGFloat(day.minCharge) * 1.2)
                        }
                        .frame(height: 60)

                        Text(dayLabel(day.date))
                            .font(.system(size: Theme.fontSizeCaption2))
                            .foregroundColor(Theme.textSecondary)
                    }
                }
            }

            HStack {
                HStack(spacing: Theme.spacing2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.accentGreen.opacity(0.8))
                        .frame(width: 10, height: 10)
                    Text("Max")
                        .font(.system(size: Theme.fontSizeCaption2))
                        .foregroundColor(Theme.textSecondary)
                }
                Spacer()
                HStack(spacing: Theme.spacing2) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.primaryBlue)
                        .frame(width: 10, height: 10)
                    Text("Min")
                        .font(.system(size: Theme.fontSizeCaption2))
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

struct SessionRowView: View {
    let session: ChargingSession

    var body: some View {
        HStack(spacing: Theme.spacing8) {
            Text("\(session.startCharge)%")
                .font(.system(size: Theme.fontSizeSubheadline, weight: .medium, design: .rounded))
                .foregroundColor(Theme.textPrimary)
                .frame(width: 36, alignment: .leading)

            Image(systemName: "arrow.right")
                .font(.system(size: 9))
                .foregroundColor(Theme.textSecondary)

            if let endCharge = session.endCharge {
                Text("\(endCharge)%")
                    .font(.system(size: Theme.fontSizeSubheadline, weight: .medium, design: .rounded))
                    .foregroundColor(Theme.accentGreen)
                    .frame(width: 36, alignment: .leading)
            } else {
                Text("In progress")
                    .font(.system(size: Theme.fontSizeCaption))
                    .foregroundColor(Theme.accentOrange)
            }

            Spacer()

            Text(session.durationString)
                .font(.system(size: Theme.fontSizeCaption))
                .foregroundColor(Theme.textSecondary)

            Text(formattedDate)
                .font(.system(size: Theme.fontSizeCaption2))
                .foregroundColor(Theme.textSecondary)
                .frame(width: 50, alignment: .trailing)
        }
        .padding(.vertical, Theme.spacingSM)
        .padding(.horizontal, Theme.spacing8)
        .background(Color.black.opacity(0.03))
        .cornerRadius(Theme.cornerRadiusSM)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: session.startedAt)
    }
}
