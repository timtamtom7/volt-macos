import XCTest
@testable import Volt

final class ChargingSessionTests: XCTestCase {

    func testChargingSessionInitialization() {
        let session = ChargingSession(
            batteryId: "main",
            startCharge: 25
        )

        XCTAssertEqual(session.batteryId, "main")
        XCTAssertEqual(session.startCharge, 25)
        XCTAssertNil(session.endCharge)
        XCTAssertNil(session.endedAt)
        XCTAssertNotNil(session.id)
        XCTAssertNotNil(session.startedAt)
    }

    func testChargingSessionDurationString() {
        let session = ChargingSession(
            batteryId: "main",
            startCharge: 50
        )

        XCTAssertFalse(session.durationString.isEmpty)
    }

    func testChargingSessionWithEndCharge() {
        let session = ChargingSession(
            batteryId: "main",
            startCharge: 20,
            endCharge: 80,
            endedAt: Date()
        )

        XCTAssertEqual(session.endCharge, 80)
        XCTAssertNotNil(session.endedAt)
    }

    func testChargingSessionWithSchedule() {
        let schedule = ChargingSchedule(
            name: "Night Charge",
            startHour: 22,
            startMinute: 0,
            endHour: 6,
            endMinute: 0,
            days: [1, 2, 3, 4, 5],
            chargeLimit: 80
        )

        let session = ChargingSession(
            batteryId: "main",
            startCharge: 40,
            scheduleName: schedule.name
        )

        XCTAssertEqual(session.scheduleName, "Night Charge")
    }
}

final class ChargingScheduleTests: XCTestCase {

    func testChargingScheduleInitialization() {
        let schedule = ChargingSchedule(
            name: "Test Schedule",
            startHour: 8,
            startMinute: 30,
            endHour: 17,
            endMinute: 0,
            days: [1, 2, 3, 4, 5],
            chargeLimit: 80
        )

        XCTAssertEqual(schedule.name, "Test Schedule")
        XCTAssertEqual(schedule.startHour, 8)
        XCTAssertEqual(schedule.startMinute, 30)
        XCTAssertEqual(schedule.endHour, 17)
        XCTAssertEqual(schedule.endMinute, 0)
        XCTAssertEqual(schedule.chargeLimit, 80)
        XCTAssertEqual(schedule.days.count, 5)
        XCTAssertTrue(schedule.isEnabled)
    }

    func testChargingScheduleIsActiveNow() {
        let schedule = ChargingSchedule(
            name: "Test Schedule",
            startHour: 0,
            startMinute: 0,
            endHour: 23,
            endMinute: 59,
            days: Set(1...7),
            chargeLimit: 80,
            isEnabled: true
        )

        XCTAssertTrue(schedule.isActiveNow())
    }

    func testChargingScheduleDisabled() {
        let schedule = ChargingSchedule(
            name: "Test Schedule",
            startHour: 0,
            startMinute: 0,
            endHour: 23,
            endMinute: 59,
            days: Set(1...7),
            chargeLimit: 80,
            isEnabled: false
        )

        XCTAssertFalse(schedule.isActiveNow())
    }

    func testChargingScheduleTimeStrings() {
        let schedule = ChargingSchedule(
            name: "Morning Charge",
            startHour: 7,
            startMinute: 0,
            endHour: 9,
            endMinute: 0,
            days: [1, 2, 3, 4, 5],
            chargeLimit: 100
        )

        XCTAssertFalse(schedule.startTimeString.isEmpty)
        XCTAssertFalse(schedule.endTimeString.isEmpty)
    }
}