import Foundation

// MARK: - Manus Task Model

struct ManusTask: Identifiable, Codable {
    let id: String
    let prompt: String
    let status: Constants.TaskStatus
    let createdAt: Date
    let updatedAt: Date
    let output: [TaskOutput]?
    let error: String?
    
    // Computed properties
    var isRunning: Bool {
        status == .running
    }
    
    var isCompleted: Bool {
        status == .completed
    }
    
    var isFailed: Bool {
        status == .failed
    }
    
    var displayStatus: String {
        status.displayName
    }
    
    var outputText: String? {
        output?
            .flatMap { $0.content }
            .compactMap { content -> String? in
                if case .outputText(let text) = content {
                    return text
                }
                return nil
            }
            .joined(separator: "\n")
    }
}

// MARK: - Task Output

struct TaskOutput: Codable {
    let type: String
    let content: [TaskContent]
}

// MARK: - Task Content

enum TaskContent: Codable {
    case outputText(String)
    case outputFile(TaskFile)
    case other
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
        case file
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "output_text":
            let text = try container.decode(String.self, forKey: .text)
            self = .outputText(text)
        case "output_file":
            let file = try container.decode(TaskFile.self, forKey: .file)
            self = .outputFile(file)
        default:
            self = .other
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .outputText(let text):
            try container.encode("output_text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .outputFile(let file):
            try container.encode("output_file", forKey: .type)
            try container.encode(file, forKey: .file)
        case .other:
            try container.encode("other", forKey: .type)
        }
    }
}

// MARK: - Task File

struct TaskFile: Codable {
    let name: String
    let url: String
    let mimeType: String?
    let size: Int?
}

// MARK: - API Response Models

struct TaskListResponse: Codable {
    let data: [ManusTaskResponse]
    let hasMore: Bool?
    
    enum CodingKeys: String, CodingKey {
        case data
        case hasMore = "has_more"
    }
}

struct ManusTaskResponse: Codable {
    let id: String
    let prompt: String
    let status: String
    let createdAt: Int
    let updatedAt: Int
    let output: [TaskOutputResponse]?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case prompt
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case output
        case error
    }
    
    func toManusTask() -> ManusTask {
        let taskStatus = Constants.TaskStatus(rawValue: status) ?? .pending
        
        return ManusTask(
            id: id,
            prompt: prompt,
            status: taskStatus,
            createdAt: Date(timeIntervalSince1970: TimeInterval(createdAt) / 1000),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(updatedAt) / 1000),
            output: output?.map { $0.toTaskOutput() },
            error: error
        )
    }
}

struct TaskOutputResponse: Codable {
    let type: String
    let content: [TaskContentResponse]
    
    func toTaskOutput() -> TaskOutput {
        return TaskOutput(
            type: type,
            content: content.map { $0.toTaskContent() }
        )
    }
}

struct TaskContentResponse: Codable {
    let type: String
    let text: String?
    let file: TaskFileResponse?
    
    func toTaskContent() -> TaskContent {
        switch type {
        case "output_text":
            return .outputText(text ?? "")
        case "output_file":
            if let file = file {
                return .outputFile(TaskFile(
                    name: file.name,
                    url: file.url,
                    mimeType: file.mimeType,
                    size: file.size
                ))
            }
            return .other
        default:
            return .other
        }
    }
}

struct TaskFileResponse: Codable {
    let name: String
    let url: String
    let mimeType: String?
    let size: Int?
    
    enum CodingKeys: String, CodingKey {
        case name
        case url
        case mimeType = "mime_type"
        case size
    }
}

// MARK: - Create Task Request

struct CreateTaskRequest: Codable {
    let prompt: String
    let attachments: [TaskAttachment]?
    let parentTaskId: String?
    
    enum CodingKeys: String, CodingKey {
        case prompt
        case attachments
        case parentTaskId = "parent_task_id"
    }
}

struct TaskAttachment: Codable {
    let name: String
    let url: String
    let mimeType: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case url
        case mimeType = "mime_type"
    }
}
