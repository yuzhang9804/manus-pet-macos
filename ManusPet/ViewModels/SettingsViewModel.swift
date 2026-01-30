import Foundation
import Combine

// MARK: - Settings ViewModel

class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var apiKey: String = "" {
        didSet {
            if apiKey != oldValue {
                saveAPIKey()
            }
        }
    }
    
    @Published var pollingInterval: Double = 5.0 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var showNotifications: Bool = true {
        didSet {
            saveSettings()
        }
    }
    
    @Published var launchAtLogin: Bool = false {
        didSet {
            saveSettings()
            updateLaunchAtLogin()
        }
    }
    
    @Published var petScale: Double = 1.0 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var petOpacity: Double = 1.0 {
        didSet {
            saveSettings()
        }
    }
    
    @Published var isAPIKeyValid: Bool = false
    @Published var isValidating: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    func validateAPIKey() async {
        guard !apiKey.isEmpty else {
            await MainActor.run {
                isAPIKeyValid = false
            }
            return
        }
        
        await MainActor.run {
            isValidating = true
        }
        
        do {
            // 尝试获取任务列表来验证 API Key
            let service = ManusAPIService.shared
            service.setAPIKey(apiKey)
            _ = try await service.listTasks()
            
            await MainActor.run {
                isAPIKeyValid = true
                isValidating = false
            }
        } catch {
            await MainActor.run {
                isAPIKeyValid = false
                isValidating = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        // 加载 API Key
        if let savedAPIKey = KeychainService.shared.getManusAPIKey() {
            apiKey = savedAPIKey
        }
        
        // 加载其他设置
        let settings = AppSettings.load()
        pollingInterval = settings.pollingInterval
        showNotifications = settings.showNotifications
        launchAtLogin = settings.launchAtLogin
        petScale = settings.petScale
        petOpacity = settings.petOpacity
    }
    
    private func saveSettings() {
        let settings = AppSettings(
            pollingInterval: pollingInterval,
            showNotifications: showNotifications,
            launchAtLogin: launchAtLogin,
            petScale: petScale,
            petOpacity: petOpacity
        )
        settings.save()
    }
    
    private func saveAPIKey() {
        KeychainService.shared.saveManusAPIKey(apiKey)
        
        // 通知 API Key 变化
        NotificationCenter.default.post(
            name: .apiKeyDidChange,
            object: nil,
            userInfo: ["apiKey": apiKey]
        )
    }
    
    private func updateLaunchAtLogin() {
        // 使用 SMLoginItemSetEnabled 或 ServiceManagement 框架
        // 这里简化处理，实际需要添加 Login Item
        #if DEBUG
        print("Launch at login: \(launchAtLogin)")
        #endif
    }
}
