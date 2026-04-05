import XCTest
import SwiftUI
@testable import Volt

final class ThemeTests: XCTestCase {

    func testHealthColorExcellent() {
        let color = Theme.healthColor(for: 0.95)
        XCTAssertEqual(color, Theme.primaryGreen)
    }

    func testHealthColorGood() {
        let color = Theme.healthColor(for: 0.65)
        XCTAssertEqual(color, Theme.warning)
    }

    func testHealthColorPoor() {
        let color = Theme.healthColor(for: 0.40)
        XCTAssertEqual(color, Theme.danger)
    }

    func testBatteryColorCharging() {
        let color = Theme.batteryColor(charge: 50, isCharging: true)
        XCTAssertEqual(color, Theme.primaryGreen)
    }

    func testBatteryColorHigh() {
        let color = Theme.batteryColor(charge: 85, isCharging: false)
        XCTAssertEqual(color, Theme.textPrimary)
    }

    func testBatteryColorMedium() {
        let color = Theme.batteryColor(charge: 45, isCharging: false)
        XCTAssertEqual(color, Theme.warning)
    }

    func testBatteryColorLow() {
        let color = Theme.batteryColor(charge: 15, isCharging: false)
        XCTAssertEqual(color, Theme.danger)
    }

    func testColorFromHex() {
        let red = Color(hex: "FF3B30")
        let green = Color(hex: "34C759")
        let blue = Color(hex: "007AFF")

        XCTAssertNotNil(red)
        XCTAssertNotNil(green)
        XCTAssertNotNil(blue)
    }

    func testColorFromHex3Digit() {
        let color = Color(hex: "FFF")
        XCTAssertNotNil(color)
    }

    func testColorFromHex8Digit() {
        let color = Color(hex: "FF3B30FF")
        XCTAssertNotNil(color)
    }

    func testSpacingValues() {
        XCTAssertEqual(Theme.spacing2, 2)
        XCTAssertEqual(Theme.spacing4, 4)
        XCTAssertEqual(Theme.spacing8, 8)
        XCTAssertEqual(Theme.spacing12, 12)
        XCTAssertEqual(Theme.spacing16, 16)
        XCTAssertEqual(Theme.spacing24, 24)
        XCTAssertEqual(Theme.spacing32, 32)
    }

    func testCornerRadiusValues() {
        XCTAssertEqual(Theme.cornerRadiusSM, 6)
        XCTAssertEqual(Theme.cornerRadiusMD, 8)
        XCTAssertEqual(Theme.cornerRadiusLG, 12)
    }

    func testFontSizes() {
        XCTAssertEqual(Theme.fontSizeCaption2, 10)
        XCTAssertEqual(Theme.fontSizeCaption, 11)
        XCTAssertEqual(Theme.fontSizeSubheadline, 12)
        XCTAssertEqual(Theme.fontSizeBody, 13)
        XCTAssertEqual(Theme.fontSizeHeadline, 14)
        XCTAssertEqual(Theme.fontSizeTitle3, 16)
        XCTAssertEqual(Theme.fontSizeTitle2, 18)
        XCTAssertEqual(Theme.fontSizeTitle1, 22)
        XCTAssertEqual(Theme.fontSizeLargeTitle, 28)
    }
}
