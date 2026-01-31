import SwiftUI
import AppKit

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    // MARK: - Properties
    
    var petWindow: PetWindow?
    var statusItem: NSStatusItem?
    
    // ViewModels - 延迟初始化以避免 MainActor 隔离问题
    var petViewModel: PetViewModel!
    var taskViewModel: TaskViewModel!
    var settingsViewModel: SettingsViewModel!
    var galleryViewModel: GalleryViewModel!
    
    // Services
    let manusAPIService = ManusAPIService.shared
    let spriteService = SpriteService.shared
    
    // Polling timer
    var taskPollingTimer: Timer?
    
    // MARK: - Application Lifecycle
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始化 ViewModels
        petViewModel = PetViewModel()
        taskViewModel = TaskViewModel()
        settingsViewModel = SettingsViewModel()
        galleryViewModel = GalleryViewModel()
        
        // 设置菜单栏图标
        setupStatusItem()
        
        // 创建宠物窗口
        setupPetWindow()
        
        // 加载用户设置
        loadSettings()
        
        // 开始任务轮询
        startTaskPolling()
        
        // 监听设置变化
        setupObservers()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        stopTaskPolling()
    }
    
    nonisolated func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // 关闭窗口不退出应用
    }
    
    // MARK: - Setup Methods
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Manus Pet")
            button.image?.isTemplate = true
        }
        
        let menu = NSMenu()
        
        // 显示/隐藏宠物
        menu.addItem(NSMenuItem(title: "显示宠物", action: #selector(togglePetWindow), keyEquivalent: "p"))
        
        menu.addItem(NSMenuItem.separator())
        
        // 任务列表
        menu.addItem(NSMenuItem(title: "任务列表", action: #selector(showTaskList), keyEquivalent: "t"))
        
        // 精灵画廊
        menu.addItem(NSMenuItem(title: "精灵画廊", action: #selector(showGallery), keyEquivalent: "g"))
        
        menu.addItem(NSMenuItem.separator())
        
        // 设置
        menu.addItem(NSMenuItem(title: "设置...", action: #selector(showSettings), keyEquivalent: ","))
        
        menu.addItem(NSMenuItem.separator())
        
        // 退出
        menu.addItem(NSMenuItem(title: "退出 Manus Pet", action: #selector(quitApp), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    private func setupPetWindow() {
        petWindow = PetWindow(petViewModel: petViewModel)
        petWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func loadSettings() {
        // 加载 API Key
        if let apiKey = KeychainService.shared.getManusAPIKey() {
            settingsViewModel.apiKey = apiKey
            manusAPIService.setAPIKey(apiKey)
        }
        
        // 加载当前精灵
        if let spriteId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currentSpriteId) {
            spriteService.loadSprite(id: spriteId) { [weak self] sprite in
                if let sprite = sprite {
                    Task { @MainActor in
                        self?.petViewModel.currentSprite = sprite
                    }
                }
            }
        } else {
            // 加载默认精灵
            petViewModel.currentSprite = spriteService.loadDefaultSprite()
        }
    }
    
    private func setupObservers() {
        // 监听 API Key 变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(apiKeyDidChange),
            name: .apiKeyDidChange,
            object: nil
        )
        
        // 监听精灵变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(spriteDidChange),
            name: .spriteDidChange,
            object: nil
        )
    }
    
    // MARK: - Task Polling
    
    private func startTaskPolling() {
        guard settingsViewModel.apiKey.isEmpty == false else { return }
        
        // 每 5 秒轮询一次
        taskPollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollTasks()
            }
        }
        
        // 立即执行一次
        pollTasks()
    }
    
    private func stopTaskPolling() {
        taskPollingTimer?.invalidate()
        taskPollingTimer = nil
    }
    
    private func pollTasks() {
        Task {
            do {
                let tasks = try await manusAPIService.listTasks()
                self.taskViewModel.updateTasks(tasks)
                self.updatePetStateBasedOnTasks(tasks)
            } catch {
                print("Failed to poll tasks: \(error)")
            }
        }
    }
    
    private func updatePetStateBasedOnTasks(_ tasks: [ManusTask]) {
        // 检查是否有正在运行的任务
        let runningTasks = tasks.filter { $0.status == .running }
        let recentCompletedTasks = tasks.filter { 
            $0.status == .completed && 
            $0.updatedAt.timeIntervalSinceNow > -10 // 10秒内完成的任务
        }
        let recentFailedTasks = tasks.filter { 
            $0.status == .failed && 
            $0.updatedAt.timeIntervalSinceNow > -10
        }
        
        if !runningTasks.isEmpty {
            petViewModel.setState(.thinking)
        } else if !recentCompletedTasks.isEmpty {
            petViewModel.setState(.happy)
            // 5秒后恢复 idle
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                if self?.petViewModel.currentState == .happy {
                    self?.petViewModel.setState(.idle)
                }
            }
        } else if !recentFailedTasks.isEmpty {
            petViewModel.setState(.sad)
            // 5秒后恢复 idle
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                if self?.petViewModel.currentState == .sad {
                    self?.petViewModel.setState(.idle)
                }
            }
        } else {
            if petViewModel.currentState == .thinking {
                petViewModel.setState(.idle)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func togglePetWindow() {
        if petWindow?.isVisible == true {
            petWindow?.orderOut(nil)
            statusItem?.menu?.item(at: 0)?.title = "显示宠物"
        } else {
            petWindow?.makeKeyAndOrderFront(nil)
            statusItem?.menu?.item(at: 0)?.title = "隐藏宠物"
        }
    }
    
    @objc private func showTaskList() {
        let taskListWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        taskListWindow.title = "任务列表"
        taskListWindow.center()
        taskListWindow.contentView = NSHostingView(rootView: 
            TaskListView()
                .environmentObject(taskViewModel)
        )
        taskListWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc private func showGallery() {
        let galleryWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        galleryWindow.title = "精灵画廊"
        galleryWindow.center()
        galleryWindow.contentView = NSHostingView(rootView: 
            GalleryView()
                .environmentObject(galleryViewModel)
                .environmentObject(petViewModel)
        )
        galleryWindow.makeKeyAndOrderFront(nil)
    }
    
    @objc private func showSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // MARK: - Notification Handlers
    
    @objc private func apiKeyDidChange(_ notification: Notification) {
        if let apiKey = notification.userInfo?["apiKey"] as? String {
            manusAPIService.setAPIKey(apiKey)
            KeychainService.shared.saveManusAPIKey(apiKey)
            
            // 重新开始轮询
            stopTaskPolling()
            startTaskPolling()
        }
    }
    
    @objc private func spriteDidChange(_ notification: Notification) {
        if let sprite = notification.userInfo?["sprite"] as? Sprite {
            petViewModel.currentSprite = sprite
            UserDefaults.standard.set(sprite.id, forKey: Constants.UserDefaultsKeys.currentSpriteId)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let apiKeyDidChange = Notification.Name("apiKeyDidChange")
    static let spriteDidChange = Notification.Name("spriteDidChange")
}
