import Foundation

enum Constants {
    // MARK: - API
    enum API {
        static let manusBaseURL = "https://api.manus.im/v1"
        static let galleryBaseURL = "https://api.sprites.manus.pet"
    }
    
    // MARK: - UserDefaults Keys
    enum UserDefaultsKeys {
        static let currentSpriteId = "currentSpriteId"
        static let petWindowPosition = "petWindowPosition"
        static let pollingInterval = "pollingInterval"
        static let showNotifications = "showNotifications"
    }
    
    // MARK: - Keychain
    enum Keychain {
        static let serviceName = "im.manus.pet"
        static let apiKeyAccount = "ManusAPIKey"
    }
    
    // MARK: - Sprite
    enum Sprite {
        static let defaultFrameWidth = 64
        static let defaultFrameHeight = 64
        static let defaultFrameRate = 8.0
        static let spritesDirectory = "Sprites"
    }
    
    // MARK: - Animation States
    enum AnimationState: String, CaseIterable {
        case idle = "idle"
        case thinking = "thinking"
        case happy = "happy"
        case sad = "sad"
        case working = "working"
        case celebrating = "celebrating"
        case sleeping = "sleeping"
        
        var displayName: String {
            switch self {
            case .idle: return "待机"
            case .thinking: return "思考中"
            case .happy: return "开心"
            case .sad: return "沮丧"
            case .working: return "工作中"
            case .celebrating: return "庆祝"
            case .sleeping: return "休息"
            }
        }
    }
    
    // MARK: - Task Status
    enum TaskStatus: String, Codable {
        case pending = "pending"
        case running = "running"
        case completed = "completed"
        case failed = "failed"
        case cancelled = "cancelled"
        
        var displayName: String {
            switch self {
            case .pending: return "等待中"
            case .running: return "运行中"
            case .completed: return "已完成"
            case .failed: return "失败"
            case .cancelled: return "已取消"
            }
        }
        
        var color: String {
            switch self {
            case .pending: return "orange"
            case .running: return "blue"
            case .completed: return "green"
            case .failed: return "red"
            case .cancelled: return "gray"
            }
        }
    }
}
