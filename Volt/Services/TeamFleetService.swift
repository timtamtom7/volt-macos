import Foundation
import Combine

// MARK: - Team Fleet Service

@MainActor
final class TeamFleetService: ObservableObject {
    static let shared = TeamFleetService()

    @Published var currentFleet: TeamFleet?
    @Published var fleetDevices: [FleetDevice] = []
    @Published var isMDMEnrolled: Bool = false
    @Published var mdmConfiguration: MDMConfiguration?

    private let fleetKey = "volt_fleet"
    private let devicesKey = "volt_fleet_devices"
    private let mdmKey = "volt_mdm_config"

    private init() {
        loadFleetData()
    }

    // MARK: - Fleet Management

    func createFleet(name: String, adminEmail: String) -> TeamFleet {
        let fleet = TeamFleet(name: name, adminEmail: adminEmail)
        currentFleet = fleet
        saveFleetData()
        return fleet
    }

    func joinFleet(inviteCode: String) async -> Bool {
        // In production, this would verify against server
        // Simulated for now
        return false
    }

    func leaveFleet() {
        currentFleet = nil
        fleetDevices = []
        saveFleetData()
    }

    func refreshFleetDevices() async {
        // In production, this would fetch from server
        // For now, simulate with current device
        let device = FleetDevice(
            deviceName: Host.current().localizedName ?? "My Mac",
            deviceModel: getMacModel(),
            batteryHealthPercent: BatteryService().readBatteryInfo().healthPercent,
            cycleCount: BatteryService().readBatteryInfo().cycleCount
        )
        fleetDevices = [device]
        updateFleetSummary()
    }

    // MARK: - MDM

    func enrollMDM(organizationName: String, token: String, serverURL: String) -> Bool {
        var config = MDMConfiguration(
            organizationName: organizationName,
            enrollmentToken: token,
            serverURL: serverURL,
            isEnrolled: true
        )
        // In production, validate token with server
        mdmConfiguration = config
        isMDMEnrolled = true
        saveMDMData()
        return true
    }

    func unenrollMDM() {
        mdmConfiguration = nil
        isMDMEnrolled = false
        saveMDMData()
    }

    func isSettingLocked(_ setting: String) -> Bool {
        guard let config = mdmConfiguration else { return false }
        return config.lockedSettings.contains(setting)
    }

    // MARK: - Profile Sharing

    func exportProfile(_ profile: PowerProfile) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(profile) else { return nil }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(profile.name.replacingOccurrences(of: " ", with: "_")).voltprofile"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }

    func importProfile(from url: URL) -> PowerProfile? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(PowerProfile.self, from: data)
    }

    // MARK: - Fleet Summary

    func getFleetSummary() -> FleetSummary {
        guard !fleetDevices.isEmpty else {
            return FleetSummary(
                totalDevices: 0,
                averageHealth: 100,
                devicesNeedingService: 0,
                totalCycles: 0,
                averageCyclesPerDevice: 0
            )
        }

        let totalHealth = fleetDevices.reduce(0) { $0 + $1.batteryHealthPercent }
        let totalCycles = fleetDevices.reduce(0) { $0 + $1.cycleCount }
        let devicesNeedingService = fleetDevices.filter { $0.batteryHealthPercent < 80 }.count

        return FleetSummary(
            totalDevices: fleetDevices.count,
            averageHealth: totalHealth / fleetDevices.count,
            devicesNeedingService: devicesNeedingService,
            totalCycles: totalCycles,
            averageCyclesPerDevice: totalCycles / fleetDevices.count
        )
    }

    func exportFleetReportCSV() -> URL? {
        let summary = getFleetSummary()
        let csv = """
        Metric,Value
        Total Devices,\(summary.totalDevices)
        Average Health,\(summary.averageHealth)%
        Devices Needing Service,\(summary.devicesNeedingService)
        Total Cycles,\(summary.totalCycles)
        Average Cycles/Device,\(summary.averageCyclesPerDevice)
        """

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Volt_Fleet_Report.csv")

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            return nil
        }
    }

    // MARK: - Private Helpers

    private func getMacModel() -> String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }

    private func updateFleetSummary() {
        guard var fleet = currentFleet else { return }
        let summary = getFleetSummary()
        fleet.averageHealthPercent = summary.averageHealth
        fleet.devicesBelowThreshold = summary.devicesNeedingService
        fleet.deviceCount = summary.totalDevices
        currentFleet = fleet
        saveFleetData()
    }

    // MARK: - Persistence

    private func saveFleetData() {
        if let fleet = currentFleet,
           let data = try? JSONEncoder().encode(fleet) {
            UserDefaults.standard.set(data, forKey: fleetKey)
        }
        if let devices = try? JSONEncoder().encode(fleetDevices) {
            UserDefaults.standard.set(devices, forKey: devicesKey)
        }
    }

    private func loadFleetData() {
        if let data = UserDefaults.standard.data(forKey: fleetKey),
           let fleet = try? JSONDecoder().decode(TeamFleet.self, from: data) {
            currentFleet = fleet
        }
        if let data = UserDefaults.standard.data(forKey: devicesKey),
           let devices = try? JSONDecoder().decode([FleetDevice].self, from: data) {
            fleetDevices = devices
        }
    }

    private func saveMDMData() {
        if let config = mdmConfiguration,
           let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: mdmKey)
        }
    }

    private func loadMDMData() {
        if let data = UserDefaults.standard.data(forKey: mdmKey),
           let config = try? JSONDecoder().decode(MDMConfiguration.self, from: data) {
            mdmConfiguration = config
            isMDMEnrolled = config.isEnrolled
        }
    }
}
