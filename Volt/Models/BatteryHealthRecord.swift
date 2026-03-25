import Foundation

struct BatteryHealthRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let healthPercent: Int
    let maxCapacity: Int
    let designCapacity: Int
    let cycleCount: Int

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        healthPercent: Int,
        maxCapacity: Int,
        designCapacity: Int,
        cycleCount: Int
    ) {
        self.id = id
        self.date = date
        self.healthPercent = healthPercent
        self.maxCapacity = maxCapacity
        self.designCapacity = designCapacity
        self.cycleCount = cycleCount
    }

    var capacityLoss: Int {
        max(0, 100 - healthPercent)
    }
}

struct HealthSnapshot {
    let current: BatteryInfo
    let previous: BatteryHealthRecord?

    var healthTrend: HealthTrend {
        guard let prev = previous else { return .stable }
        if healthPercent > prev.healthPercent + 2 { return .improving }
        if healthPercent < prev.healthPercent - 2 { return .degrading }
        return .stable
    }

    var healthPercent: Int { current.healthPercent }
    var cycleCount: Int { current.cycleCount }
}

enum HealthTrend {
    case improving
    case stable
    case degrading

    var icon: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "equal.circle.fill"
        case .degrading: return "arrow.down.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .improving: return "success"
        case .stable: return "accent"
        case .degrading: return "danger"
        }
    }

    var description: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .degrading: return "Degrading"
        }
    }
}
