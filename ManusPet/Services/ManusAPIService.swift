import Foundation

// MARK: - Manus API Service

class ManusAPIService {
    // MARK: - Singleton
    
    static let shared = ManusAPIService()
    
    // MARK: - Properties
    
    private var apiKey: String = ""
    private let baseURL = Constants.API.manusBaseURL
    private let session: URLSession
    
    // MARK: - Initialization
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }
    
    // MARK: - Configuration
    
    func setAPIKey(_ key: String) {
        apiKey = key
    }
    
    // MARK: - API Methods
    
    /// 获取任务列表
    func listTasks(limit: Int = 20) async throws -> [ManusTask] {
        let url = URL(string: "\(baseURL)/tasks?limit=\(limit)")!
        let request = createRequest(url: url, method: "GET")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        let taskListResponse = try decoder.decode(TaskListResponse.self, from: data)
        
        return taskListResponse.data.map { $0.toManusTask() }
    }
    
    /// 获取单个任务详情
    func getTask(taskId: String) async throws -> ManusTask {
        let url = URL(string: "\(baseURL)/tasks/\(taskId)")!
        let request = createRequest(url: url, method: "GET")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        let taskResponse = try decoder.decode(ManusTaskResponse.self, from: data)
        
        return taskResponse.toManusTask()
    }
    
    /// 创建新任务
    func createTask(prompt: String, attachments: [TaskAttachment]? = nil, parentTaskId: String? = nil) async throws -> ManusTask {
        let url = URL(string: "\(baseURL)/tasks")!
        var request = createRequest(url: url, method: "POST")
        
        let createRequest = CreateTaskRequest(
            prompt: prompt,
            attachments: attachments,
            parentTaskId: parentTaskId
        )
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(createRequest)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        let taskResponse = try decoder.decode(ManusTaskResponse.self, from: data)
        
        return taskResponse.toManusTask()
    }
    
    /// 上传文件
    func uploadFile(data: Data, filename: String, mimeType: String) async throws -> String {
        let url = URL(string: "\(baseURL)/files")!
        var request = createRequest(url: url, method: "POST")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加文件数据
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (responseData, response) = try await session.data(for: request)
        try validateResponse(response)
        
        // 解析响应获取文件 URL
        struct FileUploadResponse: Codable {
            let url: String
        }
        
        let decoder = JSONDecoder()
        let uploadResponse = try decoder.decode(FileUploadResponse.self, from: responseData)
        
        return uploadResponse.url
    }
    
    // MARK: - Private Methods
    
    private func createRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ManusAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 401:
            throw ManusAPIError.unauthorized
        case 403:
            throw ManusAPIError.forbidden
        case 404:
            throw ManusAPIError.notFound
        case 429:
            throw ManusAPIError.rateLimited
        case 500..<600:
            throw ManusAPIError.serverError(httpResponse.statusCode)
        default:
            throw ManusAPIError.unknown(httpResponse.statusCode)
        }
    }
}

// MARK: - API Errors

enum ManusAPIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serverError(Int)
    case unknown(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "无效的服务器响应"
        case .unauthorized:
            return "API Key 无效或已过期"
        case .forbidden:
            return "没有权限访问此资源"
        case .notFound:
            return "请求的资源不存在"
        case .rateLimited:
            return "请求过于频繁，请稍后再试"
        case .serverError(let code):
            return "服务器错误 (\(code))"
        case .unknown(let code):
            return "未知错误 (\(code))"
        }
    }
}
