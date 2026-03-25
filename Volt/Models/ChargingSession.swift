import Foundation

// MARK: - Charging Session

struct ChargingSession: Identifiable, Codable {
    let id: UUID
    let batteryId: String
    let startCharge: Int
    let endCharge: Int?
    let startedAt: Date
    var endedAt: Date?
    let scheduleName: String?

    init(
        id: UUID = UUID(),
        batteryId: String = "main",
        startCharge: Int,
        endCharge: Int? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        scheduleName: String? = nil
    ) {
        self.id = id
        self.batteryId = batteryId
        self.startCharge = startCharge
        self.endCharge = endCharge
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.scheduleName = scheduleName
    }

    var duration: TimeInterval? {
        guard let endedAt = endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
    }

    var durationString: String {
        guard let duration = duration else { return "In progress" }
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes)m"
        }
        let hours = minutes / 60
        let remainingMins = minutes % 60
        return "\(hours)h \(remainingMins)m"
    }
}

// MARK: - Battery Snapshot

struct BatterySnapshot: Identifiable, Codable {
    let id: UUID
    let batteryId: String
    let charge: Int
    let isCharging: Bool
    let isPluggedIn: Bool
    let temperature: Double
    let cycleCount: Int
    let healthPercent: Int
    let timestamp: Date

    init(
        id: UUID = UUID(),
        batteryId: String = "main",
        charge: Int,
        isCharging: Bool,
        isPluggedIn: Bool,
        temperature: Double,
        cycleCount: Int,
        healthPercent: Int,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.batteryId = batteryId
        self.charge = charge
        self.isCharging = isCharging
        self.isPluggedIn = isPluggedIn
        self.temperature = temperature
        self.cycleCount = cycleCount
        self.healthPercent = healthPercent
        self.timestamp = timestamp
    }

    init(from info: BatteryInfo, batteryId: String = "main") {
        self.id = UUID()
        self.batteryId = batteryId
        self.charge = info.charge
        self.isCharging = info.isCharging
        self.isPluggedIn = info.isPluggedIn
        self.temperature = info.temperature
        self.cycleCount = info.cycleCount
        self.healthPercent = info.healthPercent
        self.timestamp = Date()
    }
}

// MARK: - Charging Schedule

struct ChargingSchedule: Identifiable, Codable {
    let id: UUID
    var name: String
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var days: Set<Int>  // 1=Sunday, 7=Saturday
    var chargeLimit: Int
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        name: String,
        startHour: Int = 23,
        startMinute: Int = 0,
        endHour: Int = 7,
        endMinute: Int = 0,
        days: Set<Int> = [1, 2, 3, 4, 5, 6, 7],
        chargeLimit: Int = 80,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.startHour = startHour
        self.startMinute = startMinute
        self.endHour = endHour
        self.endMinute = endMinute
        self.days = days
        self.chargeLimit = chargeLimit
        self.isEnabled = isEnabled
    }

    var startTimeString: String {
        let hour12 = startHour % 12 == 0 ? 12 : startHour % 12
        let ampm = startHour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour12, startMinute, ampm)
    }

    var endTimeString: String {
        let hour12 = endHour % 12 == 0 ? 12 : endHour % 12
        let ampm = endHour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", hour12, endMinute, ampm)
    }

    var daysString: String {
        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let sorted = days.sorted()
        return sorted.compactMap { dayNames[$0 - 1] }.joined(separator: ", ")
    }

    func isActiveNow() -> Bool {
        guard isEnabled else { return false }

        let now = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: now)

        guard days.contains(weekday) else { return false }

        let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)
        let startMinutes = startHour * 60 + startMinute
        var endMinutes = endHour * 60 + endMinute

        // Handle overnight schedules (end < start means it ends the next day)
        if endMinutes <= startMinutes {
            return nowMinutes >= startMinutes || nowMinutes <= endMinutes
        }

        return nowMinutes >= startMinutes && nowMinutes <= endMinutes
    }
}

// MARK: - Daily Stats

struct DailyBatteryStats: Identifiable, Codable {
    let id: UUID
    let date: Date
    let maxCharge: Int
    let minCharge: Int
    let avgCharge: Int
    let sessionsCount: Int
    let totalChargeTime: Int  // minutes
    let batteryId: String

    init(
        id: UUID = UUID(),
        date: Date,
        maxCharge: Int,
        minCharge: Int,
        avgCharge: Int,
        sessionsCount: Int,
        totalChargeTime: Int,
        batteryId: String = "main"
    ) {
        self.id = id
        self.date = date
        self.maxCharge = maxCharge
        self.minCharge = minCharge
        self.avgCharge = avgCharge
        self.sessionsCount = sessionsCount
        self.totalChargeTime = totalChargeTime
        self.batteryId = batteryId
    }
}
