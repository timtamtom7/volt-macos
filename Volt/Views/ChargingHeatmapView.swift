import SwiftUI

struct ChargingHeatmapView: View {
    @EnvironmentObject var voltStore: VoltStore
    @Binding var isPresented: Bool

    @State private var selectedYear: Int

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self._selectedYear = State(initialValue: Calendar.current.component(.year, from: Date()))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Charging Heatmap")
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
                    // Year selector
                    yearSelector

                    // Month grid
                    monthGrid

                    // Legend
                    legendView
                }
                .padding(16)
            }
        }
        .frame(width: 500, height: 520)
        .background(Theme.background)
    }

    private var yearSelector: some View {
        HStack {
            Button(action: { selectedYear -= 1 }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Theme.primaryBlue)
            }
            .buttonStyle(.plain)

            Text("\(selectedYear)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)
                .frame(width: 60)

            Button(action: { if selectedYear < Calendar.current.component(.year, from: Date()) { selectedYear += 1 } }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(selectedYear < Calendar.current.component(.year, from: Date()) ? Theme.primaryBlue : Theme.textSecondary)
            }
            .buttonStyle(.plain)
            .disabled(selectedYear >= Calendar.current.component(.year, from: Date()))

            Spacer()
        }
    }

    private var monthGrid: some View {
        let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let calendar = Calendar.current
        let currentYear = selectedYear
        let currentMonth = calendar.component(.month, from: Date())
        let currentDay = calendar.component(.day, from: Date())

        return VStack(spacing: 4) {
            // Month labels
            HStack(spacing: 2) {
                ForEach(months, id: \.self) { month in
                    Text(month)
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day rows (weeks)
            ForEach(0..<5, id: \.self) { week in
                HStack(spacing: 2) {
                    ForEach(1...12, id: \.self) { month in
                        let intensity = chargingIntensity(for: month, week: week)
                        let isCurrentMonth = month == currentMonth && currentYear == calendar.component(.year, from: Date())
                        let isFuture = currentYear > calendar.component(.year, from: Date()) || (currentYear == calendar.component(.year, from: Date()) && month > currentMonth)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(isFuture ? Theme.secondaryBg : heatmapColor(intensity: intensity))
                            .frame(height: 20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(isCurrentMonth ? Theme.primaryBlue : Color.clear, lineWidth: 1)
                            )
                    }
                }
            }
        }
        .padding(12)
        .background(Theme.secondaryBg)
        .cornerRadius(10)
    }

    private var legendView: some View {
        HStack(spacing: 16) {
            Text("Less")
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)

            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(heatmapColor(intensity: level))
                        .frame(width: 16, height: 16)
                }
            }

            Text("More")
                .font(.system(size: 10))
                .foregroundColor(Theme.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 12)
    }

    private func chargingIntensity(for month: Int, week: Int) -> Int {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = selectedYear
        components.month = month
        components.day = 1

        guard let monthStart = calendar.date(from: components),
              let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return 0
        }

        let dayOfWeek = calendar.component(.weekday, from: monthStart)
        let adjustedWeek = week

        var totalChargeTime = 0
        for day in monthRange {
            let dayIndex = calendar.component(.weekday, from: calendar.date(byAdding: .day, value: day - 1, to: monthStart)!) - 1
            if dayIndex / 7 == adjustedWeek {
                totalChargeTime += getChargingMinutes(for: month, day: day)
            }
        }

        if totalChargeTime == 0 { return 0 }
        if totalChargeTime < 30 { return 1 }
        if totalChargeTime < 60 { return 2 }
        if totalChargeTime < 120 { return 3 }
        return 4
    }

    private func getChargingMinutes(for month: Int, day: Int) -> Int {
        let calendar = Calendar.current
        let sessions = voltStore.recentSessions

        var targetComponents = DateComponents()
        targetComponents.year = selectedYear
        targetComponents.month = month
        targetComponents.day = day

        guard let targetDate = calendar.date(from: targetComponents) else { return 0 }

        var totalMinutes = 0
        for session in sessions {
            let sessionComponents = calendar.dateComponents([.year, .month, .day], from: session.startedAt)
            if sessionComponents.year == selectedYear &&
               sessionComponents.month == month &&
               sessionComponents.day == day {
                if let duration = session.duration {
                    totalMinutes += Int(duration / 60)
                }
            }
        }

        return totalMinutes
    }

    private func heatmapColor(intensity: Int) -> Color {
        switch intensity {
        case 0: return Theme.secondaryBg
        case 1: return Theme.accentGreen.opacity(0.3)
        case 2: return Theme.accentGreen.opacity(0.5)
        case 3: return Theme.accentGreen.opacity(0.7)
        default: return Theme.accentGreen
        }
    }
}
