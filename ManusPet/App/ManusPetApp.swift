import SwiftUI

@main
struct ManusPetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 使用 Settings scene 来提供设置窗口
        Settings {
            SettingsView()
                .environmentObject(appDelegate.settingsViewModel)
                .environmentObject(appDelegate.taskViewModel)
                .environmentObject(appDelegate.galleryViewModel)
        }
    }
}
