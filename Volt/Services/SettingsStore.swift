import Foundation
import SQLite

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

    // MARK: - Private

    private let batteryService: BatteryService
    private var pollTimer: Timer?
    private var db: Connection?

    private let settingsTable = Table("settings")
    private let keyCol = Expression<String>("key")
    private let valueCol = Expression<String>("value")

    // Keys
    private static let kChargeLimit  = "charge_limit"
    private static let kLimitEnabled = "limit_enabled"

    // MARK: - Init

    init(batteryService: BatteryService) {
        self.batteryService = batteryService
        setupDatabase()
    }

    // MARK: - Database Setup

    private func setupDatabase() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let voltDir = appSupport.appendingPathComponent("Volt", isDirectory: true)

        do {
            try fileManager.createDirectory(at: voltDir, withIntermediateDirectories: true)
            let dbPath = voltDir.appendingPathComponent("volt.db").path
            db = try Connection(dbPath)

            try db?.run(settingsTable.create(ifNotExists: true) { t in
                t.column(keyCol, primaryKey: true)
                t.column(valueCol)
            })
        } catch {
            print("Volt DB error: \(error)")
        }
    }

    // MARK: - Settings Persistence

    func loadSettings() {
        guard let db = db else { return }

        do {
            let limitRow = try db.pluck(settingsTable.filter(keyCol == Self.kChargeLimit))
            if let raw = limitRow {
                chargeLimit = Int(raw[valueCol]) ?? 80
            }

            let enabledRow = try db.pluck(settingsTable.filter(keyCol == Self.kLimitEnabled))
            if let raw = enabledRow {
                limitEnabled = (Int(raw[valueCol]) ?? 0) == 1
            }
        } catch {
            // Defaults
        }
    }

    private func saveLimit(_ value: Int) {
        guard let db = db else { return }
        let clamped = min(100, max(50, value))
        do {
            try db.run(settingsTable.insert(or: .replace,
                keyCol <- Self.kChargeLimit,
                valueCol <- String(clamped)
            ))
        } catch {
            print("Volt save limit error: \(error)")
        }
    }

    private func saveLimitEnabled(_ enabled: Bool) {
        guard let db = db else { return }
        do {
            try db.run(settingsTable.insert(or: .replace,
                keyCol <- Self.kLimitEnabled,
                valueCol <- enabled ? "1" : "0"
            ))
        } catch {
            print("Volt save enabled error: \(error)")
        }
    }

    // MARK: - Battery Polling

    func refreshBatteryInfo() {
        isLoading = true
        readError = nil

        let info = batteryService.readBatteryInfo()
        if info.charge == 0 && info.maxCapacity == 0 && info.designCapacity == 0 {
            readError = "Unable to read battery info.\nCheck System Settings → Privacy & Security → Accessibility."
        }

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
}
