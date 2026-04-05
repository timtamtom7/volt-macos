import XCTest
import SQLite
@testable import Volt

final class VoltDatabaseServiceTests: XCTestCase {

    private var dbService: VoltDatabaseService!
    private var testDBPath: URL!

    override func setUp() {
        super.setUp()
        let tempDir = FileManager.default.temporaryDirectory
        testDBPath = tempDir.appendingPathComponent("volt_test_\(UUID().uuidString).db")
        
        UserDefaults.standard.set(testDBPath.path, forKey: "volt_test_db_path")
    }

    override func tearDown() {
        super.tearDown()
        try? FileManager.default.removeItem(at: testDBPath)
    }

    func testDatabaseInitialization() {
        XCTAssertNotNil(VoltDatabaseService.shared)
    }

    func testSaveAndFetchChargingSession() throws {
        let session = ChargingSession(
            batteryId: "test_battery",
            startCharge: 25,
            endCharge: 80,
            endedAt: Date()
        )

        try VoltDatabaseService.shared.startSession(session)
        
        let sessions = try VoltDatabaseService.shared.fetchSessions(limit: 10)
        XCTAssertFalse(sessions.isEmpty)
        
        if let savedSession = sessions.first {
            XCTAssertEqual(savedSession.batteryId, "test_battery")
            XCTAssertEqual(savedSession.startCharge, 25)
        }
    }

    func testEndSession() throws {
        let session = ChargingSession(
            batteryId: "test_battery",
            startCharge: 50
        )

        try VoltDatabaseService.shared.startSession(session)
        
        let sessions = try VoltDatabaseService.shared.fetchRecentSessions(limit: 1)
        guard let startedSession = sessions.first else {
            XCTFail("Session should have been created")
            return
        }

        try VoltDatabaseService.shared.endSession(startedSession.id, endCharge: 100)
        
        let updatedSessions = try VoltDatabaseService.shared.fetchRecentSessions(limit: 1)
        if let updatedSession = updatedSessions.first {
            XCTAssertEqual(updatedSession.endCharge, 100)
            XCTAssertNotNil(updatedSession.endedAt)
        }
    }

    func testFetchDailyStats() throws {
        let stats = try VoltDatabaseService.shared.fetchDailyStats(days: 7)
        XCTAssertNotNil(stats)
    }

    func testSaveSchedule() throws {
        let schedule = ChargingSchedule(
            name: "Test Schedule",
            startHour: 8,
            startMinute: 0,
            endHour: 17,
            endMinute: 0,
            days: Set([1, 2, 3, 4, 5]),
            chargeLimit: 80
        )

        try VoltDatabaseService.shared.saveSchedule(schedule)
        
        let schedules = try VoltDatabaseService.shared.fetchSchedules()
        XCTAssertFalse(schedules.isEmpty)
        
        if let savedSchedule = schedules.first(where: { $0.name == "Test Schedule" }) {
            XCTAssertEqual(savedSchedule.chargeLimit, 80)
            XCTAssertEqual(savedSchedule.startHour, 8)
        }
    }

    func testDeleteSchedule() throws {
        let schedule = ChargingSchedule(
            name: "Delete Test Schedule",
            startHour: 9,
            startMinute: 0,
            endHour: 18,
            endMinute: 0,
            days: Set([1, 2, 3]),
            chargeLimit: 85
        )

        try VoltDatabaseService.shared.saveSchedule(schedule)
        
        let schedulesBeforeDelete = try VoltDatabaseService.shared.fetchSchedules()
        guard let scheduleToDelete = schedulesBeforeDelete.first(where: { $0.name == "Delete Test Schedule" }) else {
            XCTFail("Schedule should have been saved")
            return
        }

        try VoltDatabaseService.shared.deleteSchedule(scheduleToDelete.id)
        
        let schedulesAfterDelete = try VoltDatabaseService.shared.fetchSchedules()
        XCTAssertFalse(schedulesAfterDelete.contains(where: { $0.id == scheduleToDelete.id }))
    }

    func testSaveBatterySnapshot() throws {
        let snapshot = BatterySnapshot(from: BatteryInfo.empty)
        
        try VoltDatabaseService.shared.saveSnapshot(snapshot)
        
        let snapshots = try VoltDatabaseService.shared.fetchSnapshots(limit: 10)
        XCTAssertFalse(snapshots.isEmpty)
    }

    func testHealthRecords() throws {
        let record = BatteryHealthRecord(
            healthPercent: 90,
            maxCapacity: 5500,
            designCapacity: 6000,
            cycleCount: 100
        )

        try VoltDatabaseService.shared.saveHealthRecord(record)
        
        let records = try VoltDatabaseService.shared.fetchHealthRecords(limit: 10)
        XCTAssertFalse(records.isEmpty)
    }
}
