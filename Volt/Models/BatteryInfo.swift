import Foundation

struct BatteryInfo {
    let charge: Int           // 0–100
    let isCharging: Bool
    let isPluggedIn: Bool
    let currentCapacity: Int  // mAh, current charge
    let maxCapacity: Int      // mAh, current max
    let designCapacity: Int   // mAh, original design
    let cycleCount: Int
    let temperature: Double   // Celsius
    let healthPercent: Int    // 0–100

    static let empty = BatteryInfo(
        charge: 0,
        isCharging: false,
        isPluggedIn: false,
        currentCapacity: 0,
        maxCapacity: 0,
        designCapacity: 0,
        cycleCount: 0,
        temperature: 0,
        healthPercent: 0
    )

    var healthDescription: String {
        switch healthPercent {
        case 80...: return "Normal"
        case 60..<80: return "Service Recommended"
        default: return "Service Required"
        }
    }
}
