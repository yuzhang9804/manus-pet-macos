import Foundation

// MARK: - App Settings

struct AppSettings: Codable {
    var pollingInterval: TimeInterval
    var showNotifications: Bool
    var launchAtLogin: Bool
    var petScale: CGFloat
    var petOpacity: CGFloat
    
    static let `default` = AppSettings(
        pollingInterval: 5.0,
        showNotifications: true,
        launchAtLogin: false,
        petScale: 1.0,
        petOpacity: 1.0
    )
    
    // MARK: - Persistence
    
    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "appSettings"),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "appSettings")
        }
    }
}
