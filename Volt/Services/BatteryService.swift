import Foundation
import IOKit

// MARK: - SMC Keys

private let SMC_KEY_BATTERY_INFO     = "BATP"
private let SMC_KEY_CURRENT_CHARGE   = "BCLT"
private let SMC_KEY_MAX_CAPACITY     = "MPAC"
private let SMC_KEY_DESIGN_CAPACITY  = "DCAP"
private let SMC_KEY_CYCLE_COUNT      = "CYC0"
private let SMC_KEY_TEMPERATURE      = "TB0T"
private let SMC_KEY_CHARGING_STATUS  = "CH0B"

// MARK: - SMC Data Types

private enum SMCDataType: UInt32 {
    case uint8  = 0x75_69_6e_74  // "uint"
    case uint16 = 0x75_69_6e_31  // "uin1"
    case uint32 = 0x75_69_6e_32  // "uin2"
    case flt    = 0x666c74       // "flt"
    case flag   = 0x666c_61_67  // "flag"
    case sp78   = 0x7370_3738   // "sp78" (signed fixed-point 7.8)
    case ch8    = 0x6368_38     // "ch8" (char[8])

    init?(string: String) {
        guard string.count == 4 else { return nil }
        var val: UInt32 = 0
        for ch in string.utf8 {
            val = (val << 8) | UInt32(ch)
        }
        self.init(rawValue: val)
    }
}

// MARK: - SMC Structs

private struct SMCKeyData {
    var key: UInt32 = 0
    var vers: SMCVersion = SMCVersion()
    var pLimitData: SMCPLimitData = SMCPLimitData()
    var keyInfo: SMCKeyInfo = SMCKeyInfo()
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
                UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

private struct SMCVersion {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    var release: UInt16 = 0
}

private struct SMCPLimitData {
    var version: UInt16 = 0
    var length: UInt16 = 0
    var cpuPLimit: UInt32 = 0
    var gpuPLimit: UInt32 = 0
    var memPLimit: UInt32 = 0
}

private struct SMCKeyInfo {
    var dataSize: UInt32 = 0
    var dataType: UInt32 = 0
    var dataAttributes: UInt8 = 0
}

// MARK: - SMC Commands

private enum SMCCommand: UInt8 {
    case readBytes     = 5
    case writeBytes    = 6
    case readIndex     = 8
    case readKeyInfo   = 9
    case readPlimit    = 11
    case readVers      = 12
}

// MARK: - BatteryService

final class BatteryService {
    private var connection: io_connect_t = 0

    init() {
        openConnection()
    }

    deinit {
        closeConnection()
    }

    // MARK: - Public API

    func readBatteryInfo() -> BatteryInfo {
        guard connection != 0 else { return .empty }

        let charge = readInt(key: SMC_KEY_CURRENT_CHARGE, size: 2) ?? -1
        let maxCap = readInt(key: SMC_KEY_MAX_CAPACITY, size: 2) ?? 0
        let designCap = readInt(key: SMC_KEY_DESIGN_CAPACITY, size: 2) ?? 0
        let cycleCount = readInt(key: SMC_KEY_CYCLE_COUNT, size: 2) ?? 0
        let tempRaw = readInt(key: SMC_KEY_TEMPERATURE, size: 2) ?? 0
        let isCharging = readFlag(key: SMC_KEY_CHARGING_STATUS) ?? false
        let isPluggedIn = charge >= 0 && (isCharging || maxCap > 0)

        // SP78 temperature: signed 7.8 fixed-point → divide by 256
        let temperature = Double(tempRaw) / 256.0

        // Health: maxCap / designCap * 100
        let healthPercent: Int
        if designCap > 0 {
            healthPercent = min(100, Int((Double(maxCap) / Double(designCap)) * 100))
        } else {
            healthPercent = 0
        }

        // Charge percentage
        let chargePercent: Int
        if maxCap > 0 {
            chargePercent = min(100, Int((Double(charge) / Double(maxCap)) * 100))
        } else {
            chargePercent = 0
        }

        return BatteryInfo(
            charge: charge >= 0 ? chargePercent : 0,
            isCharging: isCharging,
            isPluggedIn: isPluggedIn,
            currentCapacity: charge >= 0 ? charge : 0,
            maxCapacity: maxCap,
            designCapacity: designCap,
            cycleCount: cycleCount,
            temperature: temperature,
            healthPercent: healthPercent
        )
    }

    // MARK: - SMC Low-Level

    private func openConnection() {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("AppleSMC")
        )
        guard service != 0 else { return }

        let result = IOServiceOpen(service, mach_task_self_, 0, &connection)
        IOObjectRelease(service)

        if result != kIOReturnSuccess {
            connection = 0
        }
    }

    private func closeConnection() {
        if connection != 0 {
            IOServiceClose(connection)
            connection = 0
        }
    }

    private func stringToUInt32(_ str: String) -> UInt32 {
        var result: UInt32 = 0
        for ch in str.utf8.prefix(4) {
            result = (result << 8) | UInt32(ch)
        }
        return result
    }

    private func readBytes(key: String) -> [UInt8]? {
        guard connection != 0 else { return nil }

        var inputStruct = SMCKeyData()
        var outputStruct = SMCKeyData()

        inputStruct.key = stringToUInt32(key)
        inputStruct.data8 = SMCCommand.readKeyInfo.rawValue

        var outputSize = MemoryLayout<SMCKeyData>.size
        let result = IOConnectCallStructMethod(
            connection,
            2,  // kSMCHandleYPCMethod
            &inputStruct,
            MemoryLayout<SMCKeyData>.size,
            &outputStruct,
            &outputSize
        )

        guard result == kIOReturnSuccess else { return nil }

        var keyInfo = SMCKeyInfo()
        keyInfo.dataSize = outputStruct.keyInfo.dataSize
        keyInfo.dataType = outputStruct.keyInfo.dataType
        keyInfo.dataAttributes = outputStruct.keyInfo.dataAttributes

        inputStruct.keyInfo = keyInfo
        inputStruct.data8 = SMCCommand.readBytes.rawValue

        outputSize = MemoryLayout<SMCKeyData>.size
        let readResult = IOConnectCallStructMethod(
            connection,
            2,
            &inputStruct,
            MemoryLayout<SMCKeyData>.size,
            &outputStruct,
            &outputSize
        )

        guard readResult == kIOReturnSuccess else { return nil }

        let count = Int(keyInfo.dataSize)
        guard count > 0 && count <= 32 else { return nil }

        var bytes = [UInt8](repeating: 0, count: count)
        withUnsafeMutableBytes(of: &outputStruct.bytes) { ptr in
            for i in 0..<count {
                bytes[i] = ptr[i]
            }
        }
        return bytes
    }

    private func readInt(key: String, size: Int) -> Int? {
        guard let bytes = readBytes(key: key), bytes.count >= size else { return nil }

        switch size {
        case 1:
            return Int(bytes[0])
        case 2:
            // Big-endian
            return Int(bytes[0]) << 8 | Int(bytes[1])
        case 4:
            return Int(bytes[0]) << 24 | Int(bytes[1]) << 16 | Int(bytes[2]) << 8 | Int(bytes[3])
        default:
            return nil
        }
    }

    private func readFlag(key: String) -> Bool? {
        guard let bytes = readBytes(key: key), !bytes.isEmpty else { return nil }
        return bytes[0] != 0
    }
}
