import SwiftUI
import AppKit

// MARK: - Pet Window

class PetWindow: NSWindow {
    private var petViewModel: PetViewModel
    private var initialMouseLocation: NSPoint?
    private var initialWindowOrigin: NSPoint?
    
    init(petViewModel: PetViewModel) {
        self.petViewModel = petViewModel
        
        // 窗口大小
        let windowSize = NSSize(width: 200, height: 200)
        
        // 获取屏幕尺寸，设置初始位置
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let windowOrigin = NSPoint(
            x: screenFrame.maxX - windowSize.width - 50,
            y: screenFrame.minY + 50
        )
        
        super.init(
            contentRect: NSRect(origin: windowOrigin, size: windowSize),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupContentView()
        loadSavedPosition()
    }
    
    // MARK: - Setup
    
    private func setupWindow() {
        // 透明背景
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        
        // 窗口层级
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        // 允许鼠标事件
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        
        // 不显示在 Dock 和任务切换器中
        // (已在 Info.plist 中设置 LSUIElement = YES)
    }
    
    private func setupContentView() {
        let petView = PetView()
            .environmentObject(petViewModel)
        
        contentView = NSHostingView(rootView: petView)
        contentView?.wantsLayer = true
        contentView?.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    private func loadSavedPosition() {
        if let positionData = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.petWindowPosition),
           let position = try? JSONDecoder().decode(PetPosition.self, from: positionData) {
            setFrameOrigin(NSPoint(x: position.x, y: position.y))
        }
    }
    
    private func savePosition() {
        let position = PetPosition(x: frame.origin.x, y: frame.origin.y)
        if let data = try? JSONEncoder().encode(position) {
            UserDefaults.standard.set(data, forKey: Constants.UserDefaultsKeys.petWindowPosition)
        }
    }
    
    // MARK: - Mouse Events (拖拽移动)
    
    override func mouseDown(with event: NSEvent) {
        initialMouseLocation = NSEvent.mouseLocation
        initialWindowOrigin = frame.origin
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let initialMouse = initialMouseLocation,
              let initialOrigin = initialWindowOrigin else { return }
        
        let currentMouse = NSEvent.mouseLocation
        let deltaX = currentMouse.x - initialMouse.x
        let deltaY = currentMouse.y - initialMouse.y
        
        let newOrigin = NSPoint(
            x: initialOrigin.x + deltaX,
            y: initialOrigin.y + deltaY
        )
        
        setFrameOrigin(newOrigin)
    }
    
    override func mouseUp(with event: NSEvent) {
        initialMouseLocation = nil
        initialWindowOrigin = nil
        savePosition()
    }
    
    // MARK: - Right Click Menu
    
    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        
        // 动画状态切换
        let stateMenu = NSMenu()
        for state in PetState.allCases {
            let item = NSMenuItem(
                title: state.displayName,
                action: #selector(changeState(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = state
            if state == petViewModel.currentState {
                item.state = .on
            }
            stateMenu.addItem(item)
        }
        let stateItem = NSMenuItem(title: "切换状态", action: nil, keyEquivalent: "")
        stateItem.submenu = stateMenu
        menu.addItem(stateItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // 精灵画廊
        menu.addItem(NSMenuItem(title: "精灵画廊", action: #selector(openGallery), keyEquivalent: ""))
        
        // 任务列表
        menu.addItem(NSMenuItem(title: "任务列表", action: #selector(openTaskList), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // 设置
        menu.addItem(NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
        // 退出
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: ""))
        
        NSMenu.popUpContextMenu(menu, with: event, for: contentView!)
    }
    
    // MARK: - Actions
    
    @objc private func changeState(_ sender: NSMenuItem) {
        if let state = sender.representedObject as? PetState {
            petViewModel.setState(state)
        }
    }
    
    @objc private func openGallery() {
        NotificationCenter.default.post(name: .openGallery, object: nil)
    }
    
    @objc private func openTaskList() {
        NotificationCenter.default.post(name: .openTaskList, object: nil)
    }
    
    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openGallery = Notification.Name("openGallery")
    static let openTaskList = Notification.Name("openTaskList")
}
