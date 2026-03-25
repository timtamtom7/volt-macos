import Foundation
import SQLite

final class VoltDatabaseService {
    static let shared = VoltDatabaseService()

    private var db: Connection?

    // MARK: - Table Definitions

    private let sessions = Table("charging_sessions")
    private let snapshots = Table("battery_snapshots")
    private let dailyStats = Table("daily_stats")
    private let schedules = Table("charging_schedules")

    // Sessions columns
    private let sId = Expression<String>("id")
    private let sBatteryId = Expression<String>("battery_id")
    private let sStartCharge = Expression<Int>("start_charge")
    private let sEndCharge = Expression<Int?>("end_charge")
    private let sStartedAt = Expression<Date>("started_at")
    private let sEndedAt = Expression<Date?>("ended_at")
    private let sScheduleName = Expression<String?>("schedule_name")

    // Snapshot columns
    private let shId = Expression<String>("id")
    private let shBatteryId = Expression<String>("battery_id")
    private let shCharge = Expression<Int>("charge")
    private let shIsCharging = Expression<Bool>("is_charging")
    private let shIsPluggedIn = Expression<Bool>("is_plugged_in")
    private let shTemperature = Expression<Double>("temperature")
    private let shCycleCount = Expression<Int>("cycle_count")
    private let shHealthPercent = Expression<Int>("health_percent")
    private let shTimestamp = Expression<Date>("timestamp")

    // Daily stats columns
    private let dId = Expression<String>("id")
    private let dDate = Expression<Date>("date")
    private let dMaxCharge = Expression<Int>("max_charge")
    private let dMinCharge = Expression<Int>("min_charge")
    private let dAvgCharge = Expression<Int>("avg_charge")
    private let dSessionsCount = Expression<Int>("sessions_count")
    private let dTotalChargeTime = Expression<Int>("total_charge_time")
    private let dBatteryId = Expression<String>("battery_id")

    // Schedule columns
    private let scId = Expression<String>("id")
    private let scName = Expression<String>("name")
    private let scStartHour = Expression<Int>("start_hour")
    private let scStartMinute = Expression<Int>("start_minute")
    private let scEndHour = Expression<Int>("end_hour")
    private let scEndMinute = Expression<Int>("end_minute")
    private let scDays = Expression<String>("days")
    private let scChargeLimit = Expression<Int>("charge_limit")
    private let scIsEnabled = Expression<Bool>("is_enabled")

    // MARK: - Init

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        do {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let voltDir = appSupport.appendingPathComponent("Volt", isDirectory: true)

            if !FileManager.default.fileExists(atPath: voltDir.path) {
                try FileManager.default.createDirectory(at: voltDir, withIntermediateDirectories: true)
            }

            let dbPath = voltDir.appendingPathComponent("volt_data.db").path
            db = try Connection(dbPath)

            try createTables()
        } catch {
            print("Volt DB setup error: \(error)")
        }
    }

    private func createTables() throws {
        guard let db = db else { return }

        try db.run(sessions.create(ifNotExists: true) { t in
            t.column(sId, primaryKey: true)
            t.column(sBatteryId)
            t.column(sStartCharge)
            t.column(sEndCharge)
            t.column(sStartedAt)
            t.column(sEndedAt)
            t.column(sScheduleName)
        })

        try db.run(snapshots.create(ifNotExists: true) { t in
            t.column(shId, primaryKey: true)
            t.column(shBatteryId)
            t.column(shCharge)
            t.column(shIsCharging)
            t.column(shIsPluggedIn)
            t.column(shTemperature)
            t.column(shCycleCount)
            t.column(shHealthPercent)
            t.column(shTimestamp)
        })

        try db.run(dailyStats.create(ifNotExists: true) { t in
            t.column(dId, primaryKey: true)
            t.column(dDate)
            t.column(dMaxCharge)
            t.column(dMinCharge)
            t.column(dAvgCharge)
            t.column(dSessionsCount)
            t.column(dTotalChargeTime)
            t.column(dBatteryId)
        })

        try db.run(schedules.create(ifNotExists: true) { t in
            t.column(scId, primaryKey: true)
            t.column(scName)
            t.column(scStartHour)
            t.column(scStartMinute)
            t.column(scEndHour)
            t.column(scEndMinute)
            t.column(scDays)
            t.column(scChargeLimit)
            t.column(scIsEnabled)
        })
    }

    // MARK: - Charging Sessions

    func startSession(_ session: ChargingSession) throws {
        guard let db = db else { return }
        try db.run(sessions.insert(
            sId <- session.id.uuidString,
            sBatteryId <- session.batteryId,
            sStartCharge <- session.startCharge,
            sEndCharge <- session.endCharge,
            sStartedAt <- session.startedAt,
            sEndedAt <- session.endedAt,
            sScheduleName <- session.scheduleName
        ))
    }

    func endSession(_ sessionId: UUID, endCharge: Int) throws {
        guard let db = db else { return }
        let row = sessions.filter(sId == sessionId.uuidString)
        try db.run(row.update(
            sEndCharge <- endCharge,
            sEndedAt <- Date()
        ))
    }

    func fetchActiveSession(for batteryId: String) throws -> ChargingSession? {
        guard let db = db else { return nil }
        let query = sessions.filter(sBatteryId == batteryId && sEndedAt == nil)
        if let row = try db.pluck(query) {
            return sessionFromRow(row)
        }
        return nil
    }

    func fetchSessions(limit: Int = 30) throws -> [ChargingSession] {
        guard let db = db else { return [] }
        var result: [ChargingSession] = []
        let query = sessions.order(sStartedAt.desc).limit(limit)
        for row in try db.prepare(query) {
            result.append(sessionFromRow(row))
        }
        return result
    }

    func fetchSessions(forDay date: Date) throws -> [ChargingSession] {
        guard let db = db else { return [] }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        var result: [ChargingSession] = []
        let query = sessions
            .filter(sStartedAt >= start && sStartedAt < end)
            .order(sStartedAt.desc)

        for row in try db.prepare(query) {
            result.append(sessionFromRow(row))
        }
        return result
    }

    private func sessionFromRow(_ row: Row) -> ChargingSession {
        ChargingSession(
            id: UUID(uuidString: row[sId]) ?? UUID(),
            batteryId: row[sBatteryId],
            startCharge: row[sStartCharge],
            endCharge: row[sEndCharge],
            startedAt: row[sStartedAt],
            endedAt: row[sEndedAt],
            scheduleName: row[sScheduleName]
        )
    }

    // MARK: - Snapshots

    func saveSnapshot(_ snapshot: BatterySnapshot) throws {
        guard let db = db else { return }
        try db.run(snapshots.insert(or: .replace,
            shId <- snapshot.id.uuidString,
            shBatteryId <- snapshot.batteryId,
            shCharge <- snapshot.charge,
            shIsCharging <- snapshot.isCharging,
            shIsPluggedIn <- snapshot.isPluggedIn,
            shTemperature <- snapshot.temperature,
            shCycleCount <- snapshot.cycleCount,
            shHealthPercent <- snapshot.healthPercent,
            shTimestamp <- snapshot.timestamp
        ))

        // Also update daily stats
        try updateDailyStats(for: snapshot)
    }

    func fetchSnapshots(limit: Int = 100) throws -> [BatterySnapshot] {
        guard let db = db else { return [] }
        var result: [BatterySnapshot] = []
        let query = snapshots.order(shTimestamp.desc).limit(limit)
        for row in try db.prepare(query) {
            result.append(snapshotFromRow(row))
        }
        return result
    }

    func fetchSnapshotsGroupedByDay(days: Int = 7) throws -> [Date: [BatterySnapshot]] {
        let snapshots = try fetchSnapshots(limit: days * 24)  // rough estimate
        let calendar = Calendar.current
        var grouped: [Date: [BatterySnapshot]] = [:]
        for snapshot in snapshots {
            let day = calendar.startOfDay(for: snapshot.timestamp)
            grouped[day, default: []].append(snapshot)
        }
        return grouped
    }

    private func snapshotFromRow(_ row: Row) -> BatterySnapshot {
        BatterySnapshot(
            id: UUID(uuidString: row[shId]) ?? UUID(),
            batteryId: row[shBatteryId],
            charge: row[shCharge],
            isCharging: row[shIsCharging],
            isPluggedIn: row[shIsPluggedIn],
            temperature: row[shTemperature],
            cycleCount: row[shCycleCount],
            healthPercent: row[shHealthPercent],
            timestamp: row[shTimestamp]
        )
    }

    // MARK: - Daily Stats

    private func updateDailyStats(for snapshot: BatterySnapshot) throws {
        guard let db = db else { return }
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: snapshot.timestamp)

        // Check if we already have stats for this day
        let query = dailyStats.filter(dDate == day && dBatteryId == snapshot.batteryId)

        if let existing = try db.pluck(query) {
            // Update with new snapshot data
            let currentMax = existing[dMaxCharge]
            let currentMin = existing[dMinCharge]
            // We can't easily recalculate avg without all snapshots, so just update max/min
            let newMax = max(currentMax, snapshot.charge)
            let newMin = min(currentMin, snapshot.charge)
            try db.run(query.update(
                dMaxCharge <- newMax,
                dMinCharge <- newMin
            ))
        } else {
            // Create new daily stat
            let stats = DailyBatteryStats(
                date: day,
                maxCharge: snapshot.charge,
                minCharge: snapshot.charge,
                avgCharge: snapshot.charge,
                sessionsCount: 0,
                totalChargeTime: 0,
                batteryId: snapshot.batteryId
            )
            try db.run(dailyStats.insert(
                dId <- stats.id.uuidString,
                dDate <- stats.date,
                dMaxCharge <- stats.maxCharge,
                dMinCharge <- stats.minCharge,
                dAvgCharge <- stats.avgCharge,
                dSessionsCount <- stats.sessionsCount,
                dTotalChargeTime <- stats.totalChargeTime,
                dBatteryId <- stats.batteryId
            ))
        }
    }

    func fetchDailyStats(days: Int = 7) throws -> [DailyBatteryStats] {
        guard let db = db else { return [] }
        var result: [DailyBatteryStats] = []
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -days, to: Date())!

        let query = dailyStats
            .filter(dDate >= start)
            .order(dDate.desc)

        for row in try db.prepare(query) {
            result.append(DailyBatteryStats(
                id: UUID(uuidString: row[dId]) ?? UUID(),
                date: row[dDate],
                maxCharge: row[dMaxCharge],
                minCharge: row[dMinCharge],
                avgCharge: row[dAvgCharge],
                sessionsCount: row[dSessionsCount],
                totalChargeTime: row[dTotalChargeTime],
                batteryId: row[dBatteryId]
            ))
        }
        return result
    }

    // MARK: - Schedules

    func saveSchedule(_ schedule: ChargingSchedule) throws {
        guard let db = db else { return }
        let daysJson = (try? JSONEncoder().encode(Array(schedule.days)).base64EncodedString()) ?? "[]"
        try db.run(schedules.insert(or: .replace,
            scId <- schedule.id.uuidString,
            scName <- schedule.name,
            scStartHour <- schedule.startHour,
            scStartMinute <- schedule.startMinute,
            scEndHour <- schedule.endHour,
            scEndMinute <- schedule.endMinute,
            scDays <- daysJson,
            scChargeLimit <- schedule.chargeLimit,
            scIsEnabled <- schedule.isEnabled
        ))
    }

    func fetchSchedules() throws -> [ChargingSchedule] {
        guard let db = db else { return [] }
        var result: [ChargingSchedule] = []
        for row in try db.prepare(schedules) {
            let daysData = Data(base64Encoded: row[scDays]) ?? Data()
            let daysArray = (try? JSONDecoder().decode([Int].self, from: daysData)) ?? []
            let schedule = ChargingSchedule(
                id: UUID(uuidString: row[scId]) ?? UUID(),
                name: row[scName],
                startHour: row[scStartHour],
                startMinute: row[scStartMinute],
                endHour: row[scEndHour],
                endMinute: row[scEndMinute],
                days: Set(daysArray),
                chargeLimit: row[scChargeLimit],
                isEnabled: row[scIsEnabled]
            )
            result.append(schedule)
        }
        return result
    }

    func deleteSchedule(_ scheduleId: UUID) throws {
        guard let db = db else { return }
        let row = schedules.filter(scId == scheduleId.uuidString)
        try db.run(row.delete())
    }
}
