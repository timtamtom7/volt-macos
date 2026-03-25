import Foundation

final class VoltSyncManager: ObservableObject {
    static let shared = VoltSyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSynced: Date?

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case offline
        case error(String)
    }

    private let store = NSUbiquitousKeyValueStore.default
    private var observers: [NSObjectProtocol] = []

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        let notification = NSUbiquitousKeyValueStore.didChangeExternallyNotification
        let observer = NotificationCenter.default.addObserver(
            forName: notification,
            object: store,
            queue: .main
        ) { [weak self] notification in
            self?.handleExternalChange(notification)
        }
        observers.append(observer)
    }

    // MARK: - Sync Data

    struct SyncPayload: Codable {
        var chargeLimit: Int
        var limitEnabled: Bool
        var profiles: [BatteryProfile]
        var settings: VoltSettings
        var schedules: [ChargingSchedule]

        struct VoltSettings: Codable {
            var notifyFullyCharged: Bool
            var notifyLowBattery: Bool
            var notifyHighTemp: Bool
            var lowBatteryThreshold: Int
            var highTempThreshold: Double
        }
    }

    func sync() {
        guard isICloudAvailable else {
            syncStatus = .offline
            return
        }

        syncStatus = .syncing

        do {
            let payload = buildPayload()
            let data = try JSONEncoder().encode(payload)
            store.set(data, forKey: "volt.sync.data")
            store.synchronize()

            syncStatus = .synced
            lastSynced = Date()
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    func pullFromCloud() {
        guard isICloudAvailable else { return }

        guard let data = store.data(forKey: "volt.sync.data"),
              let payload = try? JSONDecoder().decode(SyncPayload.self, from: data) else {
            return
        }

        applyPayload(payload)
    }

    private func buildPayload() -> SyncPayload {
        let settings = SyncPayload.VoltSettings(
            notifyFullyCharged: UserDefaults.standard.object(forKey: "notifyFullyCharged") as? Bool ?? true,
            notifyLowBattery: UserDefaults.standard.object(forKey: "notifyLowBattery") as? Bool ?? true,
            notifyHighTemp: UserDefaults.standard.object(forKey: "notifyHighTemp") as? Bool ?? true,
            lowBatteryThreshold: UserDefaults.standard.object(forKey: "lowBatteryThreshold") as? Int ?? 20,
            highTempThreshold: UserDefaults.standard.object(forKey: "highTempThreshold") as? Double ?? 40.0
        )

        return SyncPayload(
            chargeLimit: UserDefaults.standard.object(forKey: "volt_charge_limit") as? Int ?? 80,
            limitEnabled: UserDefaults.standard.object(forKey: "volt_limit_enabled") as? Bool ?? false,
            profiles: BatteryProfile.allProfiles(),
            settings: settings,
            schedules: (try? VoltDatabaseService.shared.fetchSchedules()) ?? []
        )
    }

    private func applyPayload(_ payload: SyncPayload) {
        UserDefaults.standard.set(payload.chargeLimit, forKey: "volt_charge_limit")
        UserDefaults.standard.set(payload.limitEnabled, forKey: "volt_limit_enabled")
        UserDefaults.standard.set(payload.settings.notifyFullyCharged, forKey: "notifyFullyCharged")
        UserDefaults.standard.set(payload.settings.notifyLowBattery, forKey: "notifyLowBattery")
        UserDefaults.standard.set(payload.settings.notifyHighTemp, forKey: "notifyHighTemp")
        UserDefaults.standard.set(payload.settings.lowBatteryThreshold, forKey: "lowBatteryThreshold")
        UserDefaults.standard.set(payload.settings.highTempThreshold, forKey: "highTempThreshold")
    }

    private func handleExternalChange(_ notification: Notification) {
        pullFromCloud()
        syncStatus = .synced
        lastSynced = Date()
    }

    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func syncNow() {
        sync()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
