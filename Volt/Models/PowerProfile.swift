import Foundation

// MARK: - Power Profile

struct PowerProfile: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var profileDescription: String
    var settings: PowerSettings
    var authorName: String
    var authorEmail: String?
    var rating: Double
    var downloadCount: Int
    var isOfficial: Bool
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        profileDescription: String = "",
        settings: PowerSettings = PowerSettings(),
        authorName: String,
        authorEmail: String? = nil,
        rating: Double = 0,
        downloadCount: Int = 0,
        isOfficial: Bool = false,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.profileDescription = profileDescription
        self.settings = settings
        self.authorName = authorName
        self.authorEmail = authorEmail
        self.rating = rating
        self.downloadCount = downloadCount
        self.isOfficial = isOfficial
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Power Settings

struct PowerSettings: Codable, Equatable {
    var displayBrightness: Int?        // 0-100
    var keyboardBrightness: Int?       // 0-100
    var lowPowerModeEnabled: Bool
    var sleepTimeout: Int?             // minutes
    var diskSleepTimeout: Int?         // minutes
    var displaySleepTimeout: Int?      // minutes
    var wakeOnLAN: Bool?
    var powerNap: Bool?
    var allowBluetoothWake: Bool?
    var chargeLimit: Int?              // 0-100, stop charging at this level
    var optimizedCharging: Bool

    init(
        displayBrightness: Int? = nil,
        keyboardBrightness: Int? = nil,
        lowPowerModeEnabled: Bool = false,
        sleepTimeout: Int? = nil,
        diskSleepTimeout: Int? = nil,
        displaySleepTimeout: Int? = nil,
        wakeOnLAN: Bool? = nil,
        powerNap: Bool? = nil,
        allowBluetoothWake: Bool? = nil,
        chargeLimit: Int? = nil,
        optimizedCharging: Bool = false
    ) {
        self.displayBrightness = displayBrightness
        self.keyboardBrightness = keyboardBrightness
        self.lowPowerModeEnabled = lowPowerModeEnabled
        self.sleepTimeout = sleepTimeout
        self.diskSleepTimeout = diskSleepTimeout
        self.displaySleepTimeout = displaySleepTimeout
        self.wakeOnLAN = wakeOnLAN
        self.powerNap = powerNap
        self.allowBluetoothWake = allowBluetoothWake
        self.chargeLimit = chargeLimit
        self.optimizedCharging = optimizedCharging
    }
}

// MARK: - Profile Rating

struct ProfileRating: Identifiable, Codable {
    let id: UUID
    let profileId: UUID
    let userId: String
    var rating: Int              // 1-5
    var review: String?
    var createdAt: Date

    init(id: UUID = UUID(), profileId: UUID, userId: String, rating: Int, review: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.profileId = profileId
        self.userId = userId
        self.rating = rating
        self.review = review
        self.createdAt = createdAt
    }
}

// MARK: - Team Fleet

struct TeamFleet: Identifiable, Codable {
    let id: UUID
    var name: String
    var adminEmail: String
    var deviceCount: Int
    var averageHealthPercent: Int
    var devicesBelowThreshold: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        adminEmail: String,
        deviceCount: Int = 0,
        averageHealthPercent: Int = 100,
        devicesBelowThreshold: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.adminEmail = adminEmail
        self.deviceCount = deviceCount
        self.averageHealthPercent = averageHealthPercent
        self.devicesBelowThreshold = devicesBelowThreshold
        self.createdAt = createdAt
    }
}

// MARK: - Fleet Device

struct FleetDevice: Identifiable, Codable {
    let id: UUID
    var deviceName: String
    var deviceModel: String
    var batteryHealthPercent: Int
    var cycleCount: Int
    var lastSeen: Date
    var isBelowThreshold: Bool
    var powerMode: String

    init(
        id: UUID = UUID(),
        deviceName: String,
        deviceModel: String,
        batteryHealthPercent: Int,
        cycleCount: Int,
        lastSeen: Date = Date(),
        isBelowThreshold: Bool = false,
        powerMode: String = "Auto"
    ) {
        self.id = id
        self.deviceName = deviceName
        self.deviceModel = deviceModel
        self.batteryHealthPercent = batteryHealthPercent
        self.cycleCount = cycleCount
        self.lastSeen = lastSeen
        self.isBelowThreshold = isBelowThreshold
        self.powerMode = powerMode
    }
}

// MARK: - MDM Configuration

struct MDMConfiguration: Codable {
    var organizationName: String
    var enrollmentToken: String?
    var serverURL: String?
    var managedSettings: ManagedSettings
    var lockedSettings: [String]
    var isEnrolled: Bool

    init(
        organizationName: String = "",
        enrollmentToken: String? = nil,
        serverURL: String? = nil,
        managedSettings: ManagedSettings = ManagedSettings(),
        lockedSettings: [String] = [],
        isEnrolled: Bool = false
    ) {
        self.organizationName = organizationName
        self.enrollmentToken = enrollmentToken
        self.serverURL = serverURL
        self.managedSettings = managedSettings
        self.lockedSettings = lockedSettings
        self.isEnrolled = isEnrolled
    }
}

struct ManagedSettings: Codable {
    var forceLowPowerMode: Bool
    var disableSleepMode: Bool
    var allowedPowerModes: [String]
    var quietHoursStart: String?
    var quietHoursEnd: String?

    init(
        forceLowPowerMode: Bool = false,
        disableSleepMode: Bool = false,
        allowedPowerModes: [String] = [],
        quietHoursStart: String? = nil,
        quietHoursEnd: String? = nil
    ) {
        self.forceLowPowerMode = forceLowPowerMode
        self.disableSleepMode = disableSleepMode
        self.allowedPowerModes = allowedPowerModes
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
    }
}

// MARK: - Fleet Summary

struct FleetSummary {
    var totalDevices: Int
    var averageHealth: Int
    var devicesNeedingService: Int
    var totalCycles: Int
    var averageCyclesPerDevice: Int

    var healthStatus: String {
        switch averageHealth {
        case 90...: return "Excellent"
        case 80..<90: return "Good"
        case 60..<80: return "Fair"
        default: return "Needs Attention"
        }
    }
}
