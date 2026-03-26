import Foundation
import CryptoKit

/// R19: Privacy and Security Service for Volt
/// AES-256 encryption, Keychain integration
public final class VoltPrivacyService {
    
    public static let shared = VoltPrivacyService()
    
    private let keychainService = "com.volt.macos.encryption"
    private let keychainAccount = "battery-history-key"
    
    private init() {}
    
    public func getOrCreateEncryptionKey() throws -> SymmetricKey {
        if let existingKey = try? retrieveKeyFromKeychain() {
            return existingKey
        }
        let newKey = SymmetricKey(size: .bits256)
        try storeKeyInKeychain(newKey)
        return newKey
    }
    
    public func encrypt(_ data: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.seal(data, using: key)
        guard let combined = sealedBox.combined else {
            throw VoltPrivacyError.encryptionFailed
        }
        return combined
    }
    
    public func decrypt(_ encryptedData: Data) throws -> Data {
        let key = try getOrCreateEncryptionKey()
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    private func storeKeyInKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw VoltPrivacyError.keychainStoreFailed(status)
        }
    }
    
    private func retrieveKeyFromKeychain() throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let keyData = result as? Data else {
            throw VoltPrivacyError.keychainRetrieveFailed(status)
        }
        return SymmetricKey(data: keyData)
    }
    
    public func wipeAllData() {
        if let bundleId = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleId)
        }
        let keychainQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        SecItemDelete(keychainQuery as CFDictionary)
    }
    
    public static var privacyManifest: [String: Any] {
        [
            "NSPrivacyTracking": false,
            "NSPrivacyTrackingDomains": [],
            "NSPrivacyCollectedDataTypes": [],
            "NSPrivacyAccessedDataTypes": [
                [
                    "NSPrivacyAccessedDataType": "NSPrivacyAccessedDataTypeUserDefaults",
                    "NSPrivacyAccessedDataTypeReasons": ["CA92.1"]
                ]
            ]
        ]
    }
}

public enum VoltPrivacyError: Error {
    case encryptionFailed, decryptionFailed
    case keychainStoreFailed(OSStatus), keychainRetrieveFailed(OSStatus)
}
