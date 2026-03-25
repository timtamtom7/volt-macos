import Foundation

final class HealthTrackingService {
    static let shared = HealthTrackingService()
    private let userDefaults = UserDefaults.standard
    private let recordsKey = "batteryHealthRecords"
    private let lastSnapshotKey = "lastHealthSnapshot"

    private init() {}

    // MARK: - Records

    func fetchAllRecords() -> [BatteryHealthRecord] {
        guard let data = userDefaults.data(forKey: recordsKey) else { return [] }
        do {
            return try JSONDecoder().decode([BatteryHealthRecord].self, from: data)
        } catch {
            print("Failed to decode health records: \(error)")
            return []
        }
    }

    func saveRecord(_ record: BatteryHealthRecord) {
        var records = fetchAllRecords()
        records.append(record)
        saveRecords(records)
    }

    func deleteOldRecords(olderThan days: Int = 365) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        var records = fetchAllRecords()
        records.removeAll { $0.date < cutoff }
        saveRecords(records)
    }

    private func saveRecords(_ records: [BatteryHealthRecord]) {
        do {
            let data = try JSONEncoder().encode(records)
            userDefaults.set(data, forKey: recordsKey)
        } catch {
            print("Failed to encode health records: \(error)")
        }
    }

    // MARK: - Snapshot

    func getLatestSnapshot() -> BatteryHealthRecord? {
        fetchAllRecords().last
    }

    func takeSnapshotIfNeeded(from batteryInfo: BatteryInfo) {
        let lastSnapshot = getLatestSnapshot()
        let shouldSnapshot: Bool

        if let last = lastSnapshot {
            // Snapshot once per day or if cycle count changed
            let calendar = Calendar.current
            let lastSnapshotDay = calendar.startOfDay(for: last.date)
            let today = calendar.startOfDay(for: Date())

            if lastSnapshotDay < today {
                shouldSnapshot = true
            } else if last.cycleCount != batteryInfo.cycleCount {
                shouldSnapshot = true
            } else {
                shouldSnapshot = false
            }
        } else {
            shouldSnapshot = true
        }

        if shouldSnapshot {
            let record = BatteryHealthRecord(
                healthPercent: batteryInfo.healthPercent,
                maxCapacity: batteryInfo.maxCapacity,
                designCapacity: batteryInfo.designCapacity,
                cycleCount: batteryInfo.cycleCount
            )
            saveRecord(record)
        }
    }

    // MARK: - Health Trend

    func getHealthTrend(days: Int = 30) -> [BatteryHealthRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return fetchAllRecords().filter { $0.date >= cutoff }
    }

    func averageHealthChangePerMonth() -> Double {
        let records = fetchAllRecords()
        guard records.count >= 2 else { return 0 }

        let sorted = records.sorted { $0.date < $1.date }
        let first = sorted.first!
        let last = sorted.last!

        let months = max(1, Calendar.current.dateComponents([.month], from: first.date, to: last.date).month ?? 1)
        let healthDiff = Double(last.healthPercent - first.healthPercent)

        return healthDiff / Double(months)
    }

    func estimatedFullCyclesRemaining(currentCycles: Int) -> Int {
        // Most MacBook batteries are rated for 1000 cycles before health drops significantly
        let ratedCycles = 1000
        return max(0, ratedCycles - currentCycles)
    }

    func estimatedHealthAtCycles(_ targetCycles: Int, currentCycles: Int, currentHealth: Int) -> Int {
        let cycleDiff = targetCycles - currentCycles
        // Rough estimate: ~0.5% health loss per 10 cycles after 500 cycles
        let healthLoss = max(0, Double(max(0, cycleDiff)) * 0.05)
        return max(0, currentHealth - Int(healthLoss))
    }

    // MARK: - Health Alerts

    func checkHealthAlerts(batteryInfo: BatteryInfo) -> [HealthAlert] {
        var alerts: [HealthAlert] = []

        if batteryInfo.healthPercent < 60 {
            alerts.append(HealthAlert(
                type: .critical,
                title: "Battery Service Required",
                message: "Your battery health is significantly degraded. Consider scheduling a service appointment."
            ))
        } else if batteryInfo.healthPercent < 80 {
            alerts.append(HealthAlert(
                type: .warning,
                title: "Battery Service Recommended",
                message: "Your battery health is below optimal. You may want to plan for a battery replacement."
            ))
        }

        let snapshot = getLatestSnapshot()
        if let last = snapshot, last.healthPercent - batteryInfo.healthPercent > 5 {
            alerts.append(HealthAlert(
                type: .info,
                title: "Health Drop Detected",
                message: "Your battery health has dropped more than 5% since the last check."
            ))
        }

        return alerts
    }
}

struct HealthAlert: Identifiable {
    let id = UUID()
    let type: AlertType
    let title: String
    let message: String

    enum AlertType {
        case info
        case warning
        case critical
    }
}
