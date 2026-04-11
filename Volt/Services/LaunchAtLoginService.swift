import Foundation
import ServiceManagement

final class LaunchAtLoginService {
    static let shared = LaunchAtLoginService()

    private let loginItemsKey = "LaunchAtLoginEnabled"

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: loginItemsKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: loginItemsKey)
            updateLoginItemStatus(enabled: newValue)
        }
    }

    private init() {}

    private func updateLoginItemStatus(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Volt: Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        } else {
            let success = SMLoginItemSetEnabled("com.volt.app" as CFString, enabled)
            if !success {
                print("Volt: Failed to \(enabled ? "enable" : "disable") launch at login")
            }
        }
    }

    func checkStatus() {
        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            switch status {
            case .enabled:
                UserDefaults.standard.set(true, forKey: loginItemsKey)
            case .notRegistered, .requiresApproval:
                UserDefaults.standard.set(false, forKey: loginItemsKey)
            @unknown default:
                UserDefaults.standard.set(false, forKey: loginItemsKey)
            }
        }
    }
}
