import XCTest
@testable import Volt

final class BatteryHealthRecordTests: XCTestCase {

    func testBatteryHealthRecordInitialization() {
        let record = BatteryHealthRecord(
            date: Date(),
            healthPercent: 90,
            maxCapacity: 5500,
            designCapacity: 6000,
            cycleCount: 100
        )

        XCTAssertEqual(record.healthPercent, 90)
        XCTAssertEqual(record.maxCapacity, 5500)
        XCTAssertEqual(record.designCapacity, 6000)
        XCTAssertEqual(record.cycleCount, 100)
        XCTAssertNotNil(record.id)
    }

    func testCapacityLoss() {
        let healthyRecord = BatteryHealthRecord(
            healthPercent: 95,
            maxCapacity: 5700,
            designCapacity: 6000,
            cycleCount: 50
        )
        XCTAssertEqual(healthyRecord.capacityLoss, 5)

        let degradedRecord = BatteryHealthRecord(
            healthPercent: 75,
            maxCapacity: 4500,
            designCapacity: 6000,
            cycleCount: 500
        )
        XCTAssertEqual(degradedRecord.capacityLoss, 25)
    }

    func testHealthSnapshotTrendImproving() {
        let previousRecord = BatteryHealthRecord(
            date: Date().addingTimeInterval(-86400),
            healthPercent: 82,
            maxCapacity: 4900,
            designCapacity: 6000,
            cycleCount: 300
        )

        let currentInfo = BatteryInfo(
            charge: 85,
            isCharging: false,
            isPluggedIn: true,
            currentCapacity: 5100,
            maxCapacity: 5100,
            designCapacity: 6000,
            cycleCount: 310,
            temperature: 32.0,
            healthPercent: 85
        )

        let snapshot = HealthSnapshot(current: currentInfo, previous: previousRecord)
        XCTAssertEqual(snapshot.healthTrend, .improving)
    }

    func testHealthSnapshotTrendDegrading() {
        let previousRecord = BatteryHealthRecord(
            date: Date().addingTimeInterval(-86400),
            healthPercent: 88,
            maxCapacity: 5300,
            designCapacity: 6000,
            cycleCount: 300
        )

        let currentInfo = BatteryInfo(
            charge: 75,
            isCharging: false,
            isPluggedIn: false,
            currentCapacity: 4800,
            maxCapacity: 4800,
            designCapacity: 6000,
            cycleCount: 350,
            temperature: 35.0,
            healthPercent: 80
        )

        let snapshot = HealthSnapshot(current: currentInfo, previous: previousRecord)
        XCTAssertEqual(snapshot.healthTrend, .degrading)
    }

    func testHealthSnapshotTrendStable() {
        let previousRecord = BatteryHealthRecord(
            date: Date().addingTimeInterval(-86400),
            healthPercent: 85,
            maxCapacity: 5100,
            designCapacity: 6000,
            cycleCount: 300
        )

        let currentInfo = BatteryInfo(
            charge: 80,
            isCharging: false,
            isPluggedIn: true,
            currentCapacity: 5050,
            maxCapacity: 5050,
            designCapacity: 6000,
            cycleCount: 310,
            temperature: 33.0,
            healthPercent: 84
        )

        let snapshot = HealthSnapshot(current: currentInfo, previous: previousRecord)
        XCTAssertEqual(snapshot.healthTrend, .stable)
    }

    func testHealthTrendIcons() {
        XCTAssertEqual(HealthTrend.improving.icon, "arrow.up.circle.fill")
        XCTAssertEqual(HealthTrend.stable.icon, "equal.circle.fill")
        XCTAssertEqual(HealthTrend.degrading.icon, "arrow.down.circle.fill")
    }

    func testHealthTrendColors() {
        XCTAssertEqual(HealthTrend.improving.color, "success")
        XCTAssertEqual(HealthTrend.stable.color, "accent")
        XCTAssertEqual(HealthTrend.degrading.color, "danger")
    }

    func testHealthTrendDescriptions() {
        XCTAssertEqual(HealthTrend.improving.description, "Improving")
        XCTAssertEqual(HealthTrend.stable.description, "Stable")
        XCTAssertEqual(HealthTrend.degrading.description, "Degrading")
    }
}
