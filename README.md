# Manus Pet

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS%2013+-blue" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

**Manus Pet** 是一个可爱的 macOS 原生桌面宠物应用，专为 Manus AI 用户设计。它可以实时监控你的 Manus 任务状态，并通过可爱的宠物动画给你反馈。

## 功能特性

### 桌面宠物
- **透明悬浮窗口**：宠物始终显示在桌面上，不干扰其他应用
- **Sprite 动画系统**：支持多种动画状态（待机、思考、开心、沮丧等）
- **拖拽移动**：可以将宠物拖动到屏幕任意位置
- **右键菜单**：快速访问设置、任务列表、精灵画廊等功能

### Manus API 集成
- **任务状态监控**：实时轮询 Manus API，获取任务状态更新
- **动画反馈**：任务运行时宠物显示"思考"动画，完成时显示"开心"，失败时显示"沮丧"
- **系统通知**：任务状态变化时发送系统通知
- **任务列表**：查看所有任务的详细信息和状态

### 精灵画廊
- **社区精灵**：浏览和下载社区创建的精灵角色
- **精灵安装**：一键安装喜欢的精灵
- **搜索和筛选**：按热门、最新、流行等分类浏览

## 系统要求

- macOS 13.0 (Ventura) 或更高版本
- Xcode 15.0 或更高版本（用于编译）

## 安装

### 从源码编译

1. 克隆仓库：
```bash
git clone https://github.com/your-username/manus-pet-macos.git
cd manus-pet-macos
```

2. 打开 Xcode 项目：
```bash
open ManusPet.xcodeproj
```

3. 选择目标设备为 "My Mac"，然后点击运行（⌘R）

### 配置 API Key

1. 启动应用后，点击菜单栏图标
2. 选择"设置..."
3. 在 API 标签页中输入你的 Manus API Key
4. 点击"验证"确认 API Key 有效

你可以在 [Manus 设置页面](https://manus.im/settings/api) 获取 API Key。

## 项目结构

```
ManusPet/
├── App/
│   ├── ManusPetApp.swift      # 应用入口
│   └── AppDelegate.swift      # 应用生命周期管理
├── Views/
│   ├── PetWindow.swift        # 透明宠物窗口
│   ├── PetView.swift          # 宠物视图
│   ├── SettingsView.swift     # 设置界面
│   ├── TaskListView.swift     # 任务列表
│   └── GalleryView.swift      # 精灵画廊
├── ViewModels/
│   ├── PetViewModel.swift     # 宠物状态管理
│   ├── TaskViewModel.swift    # 任务数据管理
│   ├── SettingsViewModel.swift # 设置管理
│   └── GalleryViewModel.swift # 画廊数据管理
├── Models/
│   ├── Sprite.swift           # 精灵数据模型
│   ├── ManusTask.swift        # 任务数据模型
│   ├── PetState.swift         # 宠物状态枚举
│   └── AppSettings.swift      # 应用设置模型
├── Services/
│   ├── ManusAPIService.swift  # Manus API 服务
│   ├── SpriteService.swift    # 精灵管理服务
│   ├── GalleryAPIService.swift # 画廊 API 服务
│   └── KeychainService.swift  # 钥匙串服务
├── Utilities/
│   ├── SpriteAnimator.swift   # 精灵动画器
│   └── Constants.swift        # 常量定义
└── Resources/
    └── Assets.xcassets        # 资源文件
```

## 技术栈

| 组件 | 技术 |
|------|------|
| UI 框架 | SwiftUI + AppKit |
| 动画系统 | Core Graphics + Timer |
| 网络请求 | URLSession |
| 数据存储 | UserDefaults + Keychain |
| 架构模式 | MVVM |

## 精灵格式

Manus Pet 使用与 Confirmo 兼容的精灵格式：

### manifest.json
```json
{
  "id": "unique-sprite-id",
  "name": "精灵名称",
  "description": "精灵描述",
  "author": "作者名",
  "version": "1.0",
  "frameWidth": 64,
  "frameHeight": 64,
  "frameCount": 56,
  "animations": {
    "idle": { "frames": [0,1,2,3,4,5,6,7], "frameRate": 4, "loop": true },
    "thinking": { "frames": [8,9,10,11,12,13,14,15], "frameRate": 6, "loop": true },
    "happy": { "frames": [16,17,18,19,20,21,22,23], "frameRate": 8, "loop": true },
    "sad": { "frames": [24,25,26,27,28,29,30,31], "frameRate": 4, "loop": true }
  }
}
```

### sprite.png
- 精灵图（Sprite Sheet）
- 默认布局：8x7 网格，每帧 64x64 像素
- 背景使用纯色（如品红色 #FF00FF）便于透明处理

## 开发计划

- [x] 桌面宠物基础功能
- [x] Manus API 集成
- [x] 精灵画廊
- [ ] 竞技场功能
- [ ] 自定义精灵创建工具
- [ ] 多语言支持

## 贡献

欢迎提交 Issue 和 Pull Request！

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 致谢

- 灵感来源：[Confirmo](https://confirmo.love/)
- API 提供：[Manus AI](https://manus.im/)
