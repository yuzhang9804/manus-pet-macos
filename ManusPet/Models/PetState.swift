import Foundation

// MARK: - Pet State

enum PetState: String, CaseIterable {
    case idle
    case thinking
    case happy
    case sad
    case working
    case celebrating
    case sleeping
    
    var animationKey: String {
        rawValue
    }
    
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
    
    // 根据任务状态返回对应的宠物状态
    static func from(taskStatus: Constants.TaskStatus) -> PetState {
        switch taskStatus {
        case .pending:
            return .idle
        case .running:
            return .thinking
        case .completed:
            return .happy
        case .failed:
            return .sad
        case .cancelled:
            return .idle
        }
    }
}

// MARK: - Pet Position

struct PetPosition: Codable {
    var x: CGFloat
    var y: CGFloat
    
    static let `default` = PetPosition(x: 100, y: 100)
}
