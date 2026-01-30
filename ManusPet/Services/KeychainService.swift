import Foundation
import Security

// MARK: - Keychain Service

class KeychainService {
    // MARK: - Singleton
    
    static let shared = KeychainService()
    
    // MARK: - Properties
    
    private let serviceName = Constants.Keychain.serviceName
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Manus API Key
    
    func saveManusAPIKey(_ apiKey: String) {
        save(key: Constants.Keychain.apiKeyAccount, value: apiKey)
    }
    
    func getManusAPIKey() -> String? {
        return get(key: Constants.Keychain.apiKeyAccount)
    }
    
    func deleteManusAPIKey() {
        delete(key: Constants.Keychain.apiKeyAccount)
    }
    
    // MARK: - Generic Keychain Operations
    
    func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        // 先删除已存在的项
        delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }
    
    func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    func deleteAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}
