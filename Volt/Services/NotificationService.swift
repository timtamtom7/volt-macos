import Foundation
import UserNotifications
import AppKit

final class VoltNotificationService {
    static let shared = VoltNotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Authorization

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Volt notification auth error: \(error)")
            }
            // R20 audit: always invoke completion, even on error, so callers don't hang
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    // MARK: - Battery Notifications

    func sendFullyChargedNotification() {
        sendNotification(
            title: "Volt",
            body: "Battery is fully charged! You can unplug now.",
            identifier: "fully_charged"
        )
    }

    func sendChargingLimitReachedNotification(limit: Int) {
        sendNotification(
            title: "Volt",
            body: "Charging limit of \(limit)% reached.",
            identifier: "limit_reached"
        )
    }

    func sendHighTemperatureNotification(temperature: Double) {
        sendNotification(
            title: "Battery Warning",
            body: String(format: "Battery temperature is high (%.1f°C). Consider letting it cool down.", temperature),
            identifier: "high_temperature"
        )
    }

    func sendLowBatteryNotification(charge: Int) {
        sendNotification(
            title: "Low Battery",
            body: "Battery at \(charge)%. Consider plugging in.",
            identifier: "low_battery"
        )
    }

    func sendChargingResumedNotification(charge: Int) {
        sendNotification(
            title: "Volt",
            body: "Charging resumed at \(charge)%",
            identifier: "charging_resumed"
        )
    }

    func sendChargingStartedNotification(charge: Int) {
        sendNotification(
            title: "Volt",
            body: "Charging started at \(charge)%",
            identifier: "charging_started"
        )
    }

    func sendChargingEndedNotification(charge: Int, duration: String) {
        sendNotification(
            title: "Volt",
            body: "Charging session ended at \(charge)%. Duration: \(duration)",
            identifier: "charging_ended"
        )
    }

    // MARK: - Private

    private func sendNotification(title: String, body: String, identifier: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.add(request) { error in
            if let error = error {
                print("Volt notification error: \(error)")
            }
        }
    }

    // MARK: - Permission Check

    func checkAuthorizationStatus(completion: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
}
