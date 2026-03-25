import Foundation
import AppKit

final class ChargingExportService {
    static let shared = ChargingExportService()

    private init() {}

    // MARK: - CSV Export

    func exportSessionsToCSV(sessions: [ChargingSession]) -> URL? {
        var csvLines: [String] = []
        csvLines.append("session_id,start_time,end_time,duration_minutes,start_charge,end_charge,charge_added,schedule")

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for session in sessions {
            let startTime = dateFormatter.string(from: session.startedAt)
            let endTime = session.endedAt.map { dateFormatter.string(from: $0) } ?? ""
            let duration = session.duration.map { Int($0 / 60) } ?? 0
            let chargeAdded = (session.endCharge ?? 0) - session.startCharge
            let schedule = session.scheduleName ?? ""

            let line = "\(session.id.uuidString),\(startTime),\(endTime),\(duration),\(session.startCharge),\(session.endCharge ?? 0),\(chargeAdded),\"\(schedule)\""
            csvLines.append(line)
        }

        let csvContent = csvLines.joined(separator: "\n")

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Volt-Sessions-\(formattedDate()).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }

    func exportDailyStatsToCSV(stats: [DailyBatteryStats]) -> URL? {
        var csvLines: [String] = []
        csvLines.append("date,max_charge,min_charge,avg_charge,sessions_count,total_charge_time_minutes")

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for stat in stats {
            let date = dateFormatter.string(from: stat.date)
            let line = "\(date),\(stat.maxCharge),\(stat.minCharge),\(stat.avgCharge),\(stat.sessionsCount),\(stat.totalChargeTime)"
            csvLines.append(line)
        }

        let csvContent = csvLines.joined(separator: "\n")

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Volt-DailyStats-\(formattedDate()).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }

    func exportBatterySnapshotsToCSV(snapshots: [BatterySnapshot]) -> URL? {
        var csvLines: [String] = []
        csvLines.append("timestamp,charge,is_charging,is_plugged_in,temperature_celsius,cycle_count,health_percent")

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        for snapshot in snapshots {
            let time = dateFormatter.string(from: snapshot.timestamp)
            let line = "\(time),\(snapshot.charge),\(snapshot.isCharging),\(snapshot.isPluggedIn),\(String(format: "%.1f", snapshot.temperature)),\(snapshot.cycleCount),\(snapshot.healthPercent)"
            csvLines.append(line)
        }

        let csvContent = csvLines.joined(separator: "\n")

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Volt-Snapshots-\(formattedDate()).csv"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("Failed to write CSV: \(error)")
            return nil
        }
    }

    // MARK: - JSON Export

    func exportAllData(sessions: [ChargingSession], stats: [DailyBatteryStats]) -> URL? {
        let exportData = ChargingExport(
            exportDate: Date(),
            appVersion: "R7",
            sessions: sessions,
            dailyStats: stats
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(exportData)

            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "Volt-Export-\(formattedDate()).json"
            let fileURL = tempDir.appendingPathComponent(fileName)

            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to export JSON: \(error)")
            return nil
        }
    }

    // MARK: - Share

    func shareExport(at url: URL) {
        let picker = NSSharingServicePicker(items: [url])
        if let contentView = NSApp.keyWindow?.contentView {
            picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
        }
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct ChargingExport: Codable {
    let exportDate: Date
    let appVersion: String
    let sessions: [ChargingSession]
    let dailyStats: [DailyBatteryStats]
}
