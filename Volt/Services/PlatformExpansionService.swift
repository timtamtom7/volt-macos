import Foundation

/// R20: Platform Expansion Services for Volt
/// Android companion, Windows integration, Vision Pro, open-source core

public struct VoltIntegration: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var category: String
    public var isEnabled: Bool
    public var lastSyncAt: Date?
    
    public init(id: UUID = UUID(), name: String, category: String, isEnabled: Bool = false, lastSyncAt: Date? = nil) {
        self.id = id; self.name = name; self.category = category; self.isEnabled = isEnabled; self.lastSyncAt = lastSyncAt
    }
}

/// R20: Integration registry
public final class VoltIntegrationRegistry: ObservableObject {
    public static let shared = VoltIntegrationRegistry()
    @Published public private(set) var integrations: [VoltIntegration] = []
    
    private init() {
        integrations = [
            VoltIntegration(name: "HomeKit", category: "Smart Home"),
            VoltIntegration(name: "IFTTT", category: "Automation"),
            VoltIntegration(name: "Zapier", category: "Automation"),
            VoltIntegration(name: "Make", category: "Automation"),
        ]
    }
    
    public func enable(_ id: UUID) {
        if let index = integrations.firstIndex(where: { $0.id == id }) {
            integrations[index].isEnabled = true
        }
    }
    
    public func disable(_ id: UUID) {
        if let index = integrations.firstIndex(where: { $0.id == id }) {
            integrations[index].isEnabled = false
        }
    }
}

/// R20: Vision Pro spatial service
@available(visionOS 1.0, macOS 14.0, *)
public final class VoltVisionProService: ObservableObject {
    public static let shared = VoltVisionProService()
    private init() {}
    
    public func openBatteryDashboard() {
        // R20: Implement spatial window for Vision Pro
    }
    
    public func show3DHealthChart() {
        // R20: Implement 3D visualization
    }
}

/// R20: Open source core info
public struct VoltOpenSourceInfo {
    public static let repositoryURL = "https://github.com/volt-app/volt-core"
    public static let license = "MIT"
    public static let version = "1.0.0"
}
