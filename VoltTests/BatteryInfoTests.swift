import XCTest
@testable import Volt

final class BatteryInfoTests: XCTestCase {

    func testEmptyBatteryInfo() {
        let info = BatteryInfo.empty
        XCTAssertEqual(info.charge, 0)
        XCTAssertEqual(info.healthPercent, 0)
        XCTAssertEqual(info.cycleCount, 0)
        XCTAssertFalse(info.isCharging)
        XCTAssertFalse(info.isPluggedIn)
    }

    func testBatteryInfoInitialization() {
        let info = BatteryInfo(
            charge: 85,
            isCharging: true,
            isPluggedIn: true,
            currentCapacity: 5000,
            maxCapacity: 6000,
            designCapacity: 7000,
            cycleCount: 150,
            temperature: 32.5,
            healthPercent: 86
        )

        XCTAssertEqual(info.charge, 85)
        XCTAssertTrue(info.isCharging)
        XCTAssertTrue(info.isPluggedIn)
        XCTAssertEqual(info.currentCapacity, 5000)
        XCTAssertEqual(info.maxCapacity, 6000)
        XCTAssertEqual(info.designCapacity, 7000)
        XCTAssertEqual(info.cycleCount, 150)
        XCTAssertEqual(info.temperature, 32.5)
        XCTAssertEqual(info.healthPercent, 86)
    }

    func testHealthDescriptionNormal() {
        let info = BatteryInfo(
            charge: 100,
            isCharging: false,
            isPluggedIn: false,
            currentCapacity: 5500,
            maxCapacity: 6000,
            designCapacity: 7000,
            cycleCount: 50,
            temperature: 30.0,
            healthPercent: 95
        )
        XCTAssertEqual(info.healthDescription, "Normal")
    }

    func testHealthDescriptionServiceRecommended() {
        let info = BatteryInfo(
            charge: 80,
            isCharging: false,
            isPluggedIn: true,
            currentCapacity: 5200,
            maxCapacity: 6000,
            designCapacity: 7000,
            cycleCount: 200,
            temperature: 35.0,
            healthPercent: 70
        )
        XCTAssertEqual(info.healthDescription, "Service Recommended")
    }

    func testHealthDescriptionServiceRequired() {
        let info = BatteryInfo(
            charge: 75,
            isCharging: false,
            isPluggedIn: false,
            currentCapacity: 4500,
            maxCapacity: 6000,
            designCapacity: 7000,
            cycleCount: 400,
            temperature: 38.0,
            healthPercent: 59
        )
        XCTAssertEqual(info.healthDescription, "Service Required")
    }

    func testHealthDescriptionServiceRequiredLow() {
        let info = BatteryInfo(
            charge: 60,
            isCharging: false,
            isPluggedIn: false,
            currentCapacity: 3000,
            maxCapacity: 6000,
            designCapacity: 7000,
            cycleCount: 800,
            temperature: 40.0,
            healthPercent: 45
        )
        XCTAssertEqual(info.healthDescription, "Service Required")
    }

    func testHealthDescriptionServiceRequiredCritical() {
        let info = BatteryInfo(
            charge: 50,
            isCharging: false,
            isPluggedIn: false,
            currentCapacity: 2000,
            maxCapacity: 6000,
            designCapacity: 7000,
            cycleCount: 1000,
            temperature: 45.0,
            healthPercent: 30
        )
        XCTAssertEqual(info.healthDescription, "Service Required")
    }
}
