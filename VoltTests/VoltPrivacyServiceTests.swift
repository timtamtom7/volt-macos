import XCTest
@testable import Volt

final class VoltPrivacyServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        VoltPrivacyService.shared.deleteAPIKey()
    }

    override func tearDown() {
        VoltPrivacyService.shared.deleteAPIKey()
        super.tearDown()
    }

    func testSaveAndRetrieveAPIKey() throws {
        let testKey = "test-api-key-12345"

        try VoltPrivacyService.shared.saveAPIKey(testKey)
        let retrievedKey = try VoltPrivacyService.shared.retrieveAPIKey()

        XCTAssertEqual(retrievedKey, testKey)
    }

    func testRetrieveNonExistentAPIKey() throws {
        let retrievedKey = try VoltPrivacyService.shared.retrieveAPIKey()
        XCTAssertNil(retrievedKey)
    }

    func testDeleteAPIKey() throws {
        let testKey = "test-api-key-to-delete"

        try VoltPrivacyService.shared.saveAPIKey(testKey)
        var retrievedKey = try VoltPrivacyService.shared.retrieveAPIKey()
        XCTAssertEqual(retrievedKey, testKey)

        VoltPrivacyService.shared.deleteAPIKey()
        retrievedKey = try VoltPrivacyService.shared.retrieveAPIKey()
        XCTAssertNil(retrievedKey)
    }

    func testUpdateAPIKey() throws {
        let firstKey = "first-api-key"
        let secondKey = "second-api-key"

        try VoltPrivacyService.shared.saveAPIKey(firstKey)
        try VoltPrivacyService.shared.saveAPIKey(secondKey)

        let retrievedKey = try VoltPrivacyService.shared.retrieveAPIKey()
        XCTAssertEqual(retrievedKey, secondKey)
    }

    func testEncryptionDecryption() throws {
        let originalData = "Sensitive battery data".data(using: .utf8)!

        let encryptedData = try VoltPrivacyService.shared.encrypt(originalData)
        let decryptedData = try VoltPrivacyService.shared.decrypt(encryptedData)

        XCTAssertNotEqual(encryptedData, originalData)
        XCTAssertEqual(decryptedData, originalData)
    }

    func testWipeAllData() throws {
        let testKey = "api-key-before-wipe"
        try VoltPrivacyService.shared.saveAPIKey(testKey)

        VoltPrivacyService.shared.wipeAllData()

        let retrievedKey = try VoltPrivacyService.shared.retrieveAPIKey()
        XCTAssertNil(retrievedKey)
    }
}
