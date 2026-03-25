import AppIntents
import Foundation

// MARK: - App Shortcuts Provider

struct VoltShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetBatteryStatusIntent(),
            phrases: [
                "Get \(.applicationName) battery status",
                "What's my battery status in \(.applicationName)",
                "Battery info in \(.applicationName)"
            ],
            shortTitle: "Battery Status",
            systemImageName: "battery.100"
        )

        AppShortcut(
            intent: SetChargeLimitIntent(),
            phrases: [
                "Set \(.applicationName) limit to \(\.$limit)%",
                "Change \(.applicationName) charge limit"
            ],
            shortTitle: "Set Limit",
            systemImageName: "bolt.fill"
        )
    }
}

// MARK: - Battery Profile Entity

struct BatteryProfileEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Battery Profile")

    static var defaultQuery = BatteryProfileQuery()

    var id: UUID
    var name: String
    var chargeLimit: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name) (\(chargeLimit)%)")
    }

    init(from profile: BatteryProfile) {
        self.id = profile.id
        self.name = profile.name
        self.chargeLimit = profile.chargeLimit
    }

    init(id: UUID, name: String, chargeLimit: Int) {
        self.id = id
        self.name = name
        self.chargeLimit = chargeLimit
    }
}

struct BatteryProfileQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [BatteryProfileEntity] {
        BatteryProfile.allProfiles()
            .filter { identifiers.contains($0.id) }
            .map { BatteryProfileEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [BatteryProfileEntity] {
        BatteryProfile.allProfiles().map { BatteryProfileEntity(from: $0) }
    }

    func defaultResult() async -> BatteryProfileEntity? {
        try? await suggestedEntities().first
    }
}

// MARK: - Get Battery Status Intent

struct GetBatteryStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Battery Status"
    static var description = IntentDescription("Get the current battery status from Volt")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let info = await VoltState.shared.store.currentCharge

        let status: String
        if info.isCharging {
            status = "Charging at \(info.charge)%"
        } else if info.isPluggedIn {
            status = "Plugged in at \(info.charge)%"
        } else {
            status = "On battery at \(info.charge)%"
        }

        let healthText = "Health: \(info.healthPercent)% (\(info.healthDescription))"
        let tempText = "Temperature: \(String(format: "%.1f", info.temperature))°C"
        let cyclesText = "Cycles: \(info.cycleCount)"

        return .result(dialog: "\(status). \(healthText). \(tempText). \(cyclesText)")
    }
}

// MARK: - Switch Profile Intent

struct SwitchProfileIntent: AppIntent {
    static var title: LocalizedStringResource = "Switch Volt Profile"
    static var description = IntentDescription("Switch to a battery profile in Volt")

    @Parameter(title: "Profile")
    var profile: BatteryProfileEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Switch to \(\.$profile)")
    }

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            VoltState.shared.store.chargeLimit = profile.chargeLimit
            VoltState.shared.store.limitEnabled = true
        }

        return .result(dialog: "Switched to \(profile.name) profile (limit: \(profile.chargeLimit)%)")
    }
}

// MARK: - Set Charge Limit Intent

struct SetChargeLimitIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Charge Limit"
    static var description = IntentDescription("Set the charge limit in Volt")

    @Parameter(title: "Limit")
    var limit: ChargeLimitEnum

    static var parameterSummary: some ParameterSummary {
        Summary("Set Volt limit to \(\.$limit)")
    }

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            VoltState.shared.store.chargeLimit = limit.rawValue
            VoltState.shared.store.limitEnabled = true
        }

        return .result(dialog: "Charge limit set to \(limit.rawValue)%")
    }
}

enum ChargeLimitEnum: Int, AppEnum {
    case fifty = 50
    case sixty = 60
    case seventy = 70
    case eighty = 80
    case ninety = 90
    case hundred = 100

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Charge Limit")

    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .fifty: "50%",
        .sixty: "60%",
        .seventy: "70%",
        .eighty: "80%",
        .ninety: "90%",
        .hundred: "100%"
    ]
}

// MARK: - Battery Profile Model

struct BatteryProfile: Codable, Identifiable {
    let id: UUID
    let name: String
    let chargeLimit: Int
    let limitEnabled: Bool

    init(id: UUID = UUID(), name: String, chargeLimit: Int, limitEnabled: Bool = true) {
        self.id = id
        self.name = name
        self.chargeLimit = chargeLimit
        self.limitEnabled = limitEnabled
    }

    static func allProfiles() -> [BatteryProfile] {
        [
            BatteryProfile(name: "Home", chargeLimit: 80, limitEnabled: true),
            BatteryProfile(name: "Work", chargeLimit: 100, limitEnabled: false),
            BatteryProfile(name: "Travel", chargeLimit: 100, limitEnabled: false),
            BatteryProfile(name: "Storage", chargeLimit: 50, limitEnabled: true)
        ]
    }
}
