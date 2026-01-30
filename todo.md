# Manus Pet macOS - 功能清单

## 核心功能 (对齐 Confirmo)

### 桌面宠物应用
- [x] 透明无边框悬浮窗口 (PetWindow)
- [x] Sprite Sheet 动画渲染系统
- [x] 多种动画状态 (idle, thinking, happy, sad, working, celebrating)
- [x] 窗口拖拽移动
- [x] 系统托盘/菜单栏图标
- [x] 右键上下文菜单
- [x] 精灵切换功能
- [x] 应用设置界面

### Manus API 集成 (替代 Cursor/VSCode 监听)
- [x] Manus API Key 配置
- [x] 任务列表获取和显示
- [x] 任务状态实时监听 (polling)
- [x] 任务状态变化触发宠物动画
- [x] 任务创建快捷入口
- [x] 任务结果通知

### 精灵画廊 (Sprites Gallery)
- [x] 精灵列表浏览 (热门/最新/流行)
- [x] 精灵搜索功能
- [x] 精灵详情查看
- [x] 精灵下载和安装
- [x] 精灵上传功能
- [x] 用户登录 (OAuth) - 预留接口
- [x] 点赞/收藏功能

### 竞技场 (Arena) - 可选
- [ ] 像素风格对战界面
- [ ] 实时匹配系统
- [ ] 基于任务完成度的战斗力计算

## 技术架构

### 桌面应用 (Swift + SwiftUI)
- AppKit: NSWindow 透明窗口
- SwiftUI: 设置界面和对话框
- SpriteKit: 精灵动画渲染
- Combine: 响应式数据流
- URLSession: API 请求

### 精灵系统
- Sprite Sheet PNG 解析
- manifest.json 配置解析
- 动画帧序列播放
- 状态机管理

### 数据存储
- UserDefaults: 用户设置
- FileManager: 精灵文件管理
- Keychain: API Key 安全存储

### 网络层
- Manus Open API 集成
- 精灵画廊 API (可复用现有 Web 后端)
- WebSocket (竞技场实时通信)


## GitHub CI/CD

- [ ] 创建 GitHub Actions 工作流
- [ ] 配置自动打 tag
- [ ] 配置自动构建 macOS 应用
- [ ] 配置自动发布 Release
- [ ] 上传到 GitHub 仓库
