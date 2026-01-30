import SwiftUI

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    @EnvironmentObject var taskViewModel: TaskViewModel
    @EnvironmentObject var galleryViewModel: GalleryViewModel
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 通用设置
            GeneralSettingsTab()
                .environmentObject(viewModel)
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
                .tag(0)
            
            // API 设置
            APISettingsTab()
                .environmentObject(viewModel)
                .tabItem {
                    Label("API", systemImage: "key")
                }
                .tag(1)
            
            // 外观设置
            AppearanceSettingsTab()
                .environmentObject(viewModel)
                .tabItem {
                    Label("外观", systemImage: "paintbrush")
                }
                .tag(2)
            
            // 关于
            AboutTab()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
                .tag(3)
        }
        .frame(width: 450, height: 300)
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsTab: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section {
                Toggle("开机自启动", isOn: $viewModel.launchAtLogin)
                Toggle("显示通知", isOn: $viewModel.showNotifications)
            }
            
            Section {
                HStack {
                    Text("轮询间隔")
                    Spacer()
                    Picker("", selection: $viewModel.pollingInterval) {
                        Text("3 秒").tag(3.0)
                        Text("5 秒").tag(5.0)
                        Text("10 秒").tag(10.0)
                        Text("30 秒").tag(30.0)
                        Text("60 秒").tag(60.0)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - API Settings Tab

struct APISettingsTab: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    @State private var showAPIKey = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Manus API Key")
                        .font(.headline)
                    
                    HStack {
                        if showAPIKey {
                            TextField("输入 API Key", text: $viewModel.apiKey)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            SecureField("输入 API Key", text: $viewModel.apiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Button {
                            showAPIKey.toggle()
                        } label: {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    HStack {
                        if viewModel.isValidating {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("验证中...")
                                .foregroundColor(.secondary)
                        } else if viewModel.isAPIKeyValid {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("API Key 有效")
                                .foregroundColor(.green)
                        } else if !viewModel.apiKey.isEmpty {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                            Text("API Key 无效")
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        Button("验证") {
                            Task {
                                await viewModel.validateAPIKey()
                            }
                        }
                        .disabled(viewModel.apiKey.isEmpty || viewModel.isValidating)
                    }
                    .font(.caption)
                }
                
                Link("获取 API Key", destination: URL(string: "https://manus.im/settings/api")!)
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Appearance Settings Tab

struct AppearanceSettingsTab: View {
    @EnvironmentObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Text("宠物大小: \(Int(viewModel.petScale * 100))%")
                    Slider(value: $viewModel.petScale, in: 0.5...2.0, step: 0.1)
                }
                
                VStack(alignment: .leading) {
                    Text("透明度: \(Int(viewModel.petOpacity * 100))%")
                    Slider(value: $viewModel.petOpacity, in: 0.3...1.0, step: 0.1)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.pink)
            
            Text("Manus Pet")
                .font(.title)
                .fontWeight(.bold)
            
            Text("版本 1.0.0")
                .foregroundColor(.secondary)
            
            Text("一个可爱的桌面宠物，帮助你监控 Manus AI 任务状态")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            HStack(spacing: 20) {
                Link("官网", destination: URL(string: "https://manus.im")!)
                Link("GitHub", destination: URL(string: "https://github.com/manus-im")!)
                Link("反馈", destination: URL(string: "https://help.manus.im")!)
            }
            .font(.caption)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(SettingsViewModel())
        .environmentObject(TaskViewModel())
        .environmentObject(GalleryViewModel())
}
