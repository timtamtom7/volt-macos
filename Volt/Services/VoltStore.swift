import Foundation
import Combine

@MainActor
final class VoltStore: ObservableObject {
    // MARK: - Published Battery State

    @Published private(set) var currentCharge: BatteryInfo = .empty
    @Published private(set) var isLoading = true
    @Published private(set) var readError: String?

    // MARK: - Settings

    @Published var chargeLimit: Int = 80 {
        didSet { saveLimit(chargeLimit) }
    }
    @Published var limitEnabled: Bool = false {
        didSet { saveLimitEnabled(limitEnabled) }
    }

    // MARK: - R2: Notification Settings

    @Published var notifyFullyCharged: Bool = true {
        didSet { UserDefaults.standard.set(notifyFullyCharged, forKey: "notifyFullyCharged") }
    }
    @Published var notifyLowBattery: Bool = true {
        didSet { UserDefaults.standard.set(notifyLowBattery, forKey: "notifyLowBattery") }
    }
    @Published var notifyHighTemp: Bool = true {
        didSet { UserDefaults.standard.set(notifyHighTemp, forKey: "notifyHighTemp") }
    }
    @Published var lowBatteryThreshold: Int = 20 {
        didSet { UserDefaults.standard.set(lowBatteryThreshold, forKey: "lowBatteryThreshold") }
    }
    @Published var highTempThreshold: Double = 40.0 {
        didSet { UserDefaults.standard.set(highTempThreshold, forKey: "highTempThreshold") }
    }

    // MARK: - R2: History

    @Published private(set) var recentSessions: [ChargingSession] = []
    @Published private(set) var weeklyHistory: [DailyBatteryStats] = []

    // MARK: - R3: Schedules

    @Published var schedules: [ChargingSchedule] = []

    // MARK: - R2: Active Session Tracking

    private var activeSessionId: UUID?
    private var wasCharging = false
    private var wasFullyChargedNotified = false
    private var wasLowBatteryNotified = false

    // MARK: - Private

    private let batteryService: BatteryService
    private let db = VoltDatabaseService.shared
    private let notifications = VoltNotificationService.shared
    private var pollTimer: Timer?
    private var snapshotTimer: Timer?
    private var scheduleCheckTimer: Timer?

    // MARK: - Init

    init(batteryService: BatteryService) {
        self.batteryService = batteryService
        loadSettings()
        loadSchedules()
        loadHistory()
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        notifyFullyCharged = UserDefaults.standard.object(forKey: "notifyFullyCharged") as? Bool ?? true
        notifyLowBattery = UserDefaults.standard.object(forKey: "notifyLowBattery") as? Bool ?? true
        notifyHighTemp = UserDefaults.standard.object(forKey: "notifyHighTemp") as? Bool ?? true
        lowBatteryThreshold = UserDefaults.standard.object(forKey: "lowBatteryThreshold") as? Int ?? 20
        highTempThreshold = UserDefaults.standard.object(forKey: "highTempThreshold") as? Double ?? 40.0
    }

    private func saveLimit(_ value: Int) {
        // Already saved in SQLite via SettingsStore pattern
        UserDefaults.standard.set(value, forKey: "volt_charge_limit")
    }

    private func saveLimitEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "volt_limit_enabled")
    }

    // MARK: - Battery Polling

    func refreshBatteryInfo() {
        isLoading = true
        readError = nil

        let info = batteryService.readBatteryInfo()
        if info.charge == 0 && info.maxCapacity == 0 && info.designCapacity == 0 {
            readError = "Unable to read battery info."
        }

        // R2: Track charging state changes
        trackChargingSession(info: info)

        // R2: Check notification conditions
        checkNotificationConditions(info: info)

        currentCharge = info
        isLoading = false
    }

    func startPolling(interval: TimeInterval = 30) {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshBatteryInfo()
            }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - R2: Charging Session Tracking

    private func trackChargingSession(info: BatteryInfo) {
        if info.isCharging && !wasCharging {
            // Charging started
            let session = ChargingSession(
                batteryId: "main",
                startCharge: info.charge
            )
            activeSessionId = session.id
            wasCharging = true
            try? db.startSession(session)
            if notifyFullyCharged {
                notifications.sendChargingStartedNotification(charge: info.charge)
            }
        } else if !info.isCharging && wasCharging {
            // Charging ended
            if let sessionId = activeSessionId {
                try? db.endSession(sessionId, endCharge: info.charge)
                activeSessionId = nil
                loadHistory()
                if let sessions = try? db.fetchRecentSessions(limit: 5) {
                    recentSessions = sessions
                }
            }
            wasCharging = false
        }
        wasCharging = info.isCharging
    }

    private func checkNotificationConditions(info: BatteryInfo) {
        // Fully charged notification
        if info.charge == 100 && !wasFullyChargedNotified && notifyFullyCharged {
            wasFullyChargedNotified = true
            notifications.sendFullyChargedNotification()
        } else if info.charge < 99 {
            wasFullyChargedNotified = false
        }

        // Low battery notification
        if info.charge <= lowBatteryThreshold && !info.isPluggedIn && !wasLowBatteryNotified && notifyLowBattery {
            wasLowBatteryNotified = true
            notifications.sendLowBatteryNotification(charge: info.charge)
        } else if info.charge > lowBatteryThreshold + 5 {
            wasLowBatteryNotified = false
        }

        // High temperature notification
        if info.temperature >= highTempThreshold && notifyHighTemp {
            notifications.sendHighTemperatureNotification(temperature: info.temperature)
        }
    }

    // MARK: - R2: History

    private func loadHistory() {
        do {
            recentSessions = try db.fetchSessions(limit: 30)
            weeklyHistory = try db.fetchDailyStats(days: 7)
        } catch {
            print("Failed to load history: \(error)")
        }
    }

    func saveSnapshot() {
        let snapshot = BatterySnapshot(from: currentCharge)
        try? db.saveSnapshot(snapshot)
    }

    // MARK: - R3: Schedules

    private func loadSchedules() {
        do {
            schedules = try db.fetchSchedules()
        } catch {
            print("Failed to load schedules: \(error)")
        }
    }

    func addSchedule(_ schedule: ChargingSchedule) {
        do {
            try db.saveSchedule(schedule)
            schedules.append(schedule)
        } catch {
            print("Failed to add schedule: \(error)")
        }
    }

    func toggleSchedule(_ schedule: ChargingSchedule) {
        var updated = schedule
        updated.isEnabled.toggle()
        do {
            try db.saveSchedule(updated)
            if let idx = schedules.firstIndex(where: { $0.id == schedule.id }) {
                schedules[idx] = updated
            }
        } catch {
            print("Failed to toggle schedule: \(error)")
        }
    }

    func deleteSchedule(_ scheduleId: UUID) {
        do {
            try db.deleteSchedule(scheduleId)
            schedules.removeAll { $0.id == scheduleId }
        } catch {
            print("Failed to delete schedule: \(error)")
        }
    }

    func startScheduleCheckTimer() {
        scheduleCheckTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkSchedules()
            }
        }
    }

    private func checkSchedules() {
        for schedule in schedules where schedule.isEnabled && schedule.isActiveNow() {
            // If within schedule window and not yet at limit, notify
            if !limitEnabled || currentCharge.charge < schedule.chargeLimit {
                // Could trigger a notification to remind user to plug in
            }
        }
    }

    // MARK: - Limit Logic

    var limitStatusText: String {
        if limitEnabled {
            return "Limit: \(chargeLimit)%"
        } else {
            return "Limit: Off"
        }
    }

    var isAtLimit: Bool {
        currentCharge.charge >= chargeLimit
    }

    // MARK: - Export

    func exportSessionsCSV() -> URL? {
        var csv = "Start Charge,End Charge,Started At,Ended At,Duration,Schedule\n"
        for session in recentSessions {
            let start = "\(session.startCharge)%"
            let end = session.endCharge.map { "\($0)%" } ?? "In Progress"
            let formatter = ISO8601DateFormatter()
            let started = formatter.string(from: session.startedAt)
            let ended = session.endedAt.map { formatter.string(from: $0) } ?? ""
            let duration = session.durationString
            let schedule = session.scheduleName ?? ""
            csv += "\(start),\(end),\(started),\(ended),\(duration),\(schedule)\n"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("volt_sessions.csv")
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }
}

// MARK: - VoltDatabaseService Extension

extension VoltDatabaseService {
    func fetchRecentSessions(limit: Int) throws -> [ChargingSession] {
        return try fetchSessions(limit: limit)
    }
}
