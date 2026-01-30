import Foundation

// MARK: - Gallery API Service

class GalleryAPIService {
    // MARK: - Singleton
    
    static let shared = GalleryAPIService()
    
    // MARK: - Properties
    
    private let baseURL = Constants.API.galleryBaseURL
    private let session: URLSession
    
    // MARK: - Initialization
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
    }
    
    // MARK: - API Methods
    
    /// 获取精灵列表
    func fetchSprites(category: SpriteCategory, page: Int = 1, limit: Int = 20) async throws -> [Sprite] {
        var components = URLComponents(string: "\(baseURL)/sprites")!
        components.queryItems = [
            URLQueryItem(name: "category", value: category.rawValue),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw GalleryAPIError.invalidURL
        }
        
        let request = createRequest(url: url, method: "GET")
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        struct SpritesResponse: Codable {
            let data: [GallerySpriteResponse]
            let total: Int
            let page: Int
            let limit: Int
        }
        
        let decoder = JSONDecoder()
        let spritesResponse = try decoder.decode(SpritesResponse.self, from: data)
        
        return spritesResponse.data.map { $0.toSprite() }
    }
    
    /// 搜索精灵
    func searchSprites(query: String, page: Int = 1, limit: Int = 20) async throws -> [Sprite] {
        var components = URLComponents(string: "\(baseURL)/sprites/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw GalleryAPIError.invalidURL
        }
        
        let request = createRequest(url: url, method: "GET")
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        struct SearchResponse: Codable {
            let data: [GallerySpriteResponse]
        }
        
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(SearchResponse.self, from: data)
        
        return searchResponse.data.map { $0.toSprite() }
    }
    
    /// 获取精灵详情
    func getSpriteDetail(id: String) async throws -> Sprite {
        let url = URL(string: "\(baseURL)/sprites/\(id)")!
        let request = createRequest(url: url, method: "GET")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        let decoder = JSONDecoder()
        let spriteResponse = try decoder.decode(GallerySpriteResponse.self, from: data)
        
        return spriteResponse.toSprite()
    }
    
    /// 点赞精灵
    func likeSprite(_ spriteId: String) async throws {
        let url = URL(string: "\(baseURL)/sprites/\(spriteId)/like")!
        var request = createRequest(url: url, method: "POST")
        
        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }
    
    /// 下载精灵 (增加下载计数)
    func downloadSprite(_ spriteId: String) async throws -> URL {
        let url = URL(string: "\(baseURL)/sprites/\(spriteId)/download")!
        let request = createRequest(url: url, method: "GET")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        struct DownloadResponse: Codable {
            let downloadUrl: String
        }
        
        let decoder = JSONDecoder()
        let downloadResponse = try decoder.decode(DownloadResponse.self, from: data)
        
        guard let downloadURL = URL(string: downloadResponse.downloadUrl) else {
            throw GalleryAPIError.invalidURL
        }
        
        return downloadURL
    }
    
    // MARK: - Private Methods
    
    private func createRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("ManusPet/1.0", forHTTPHeaderField: "User-Agent")
        return request
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GalleryAPIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200..<300:
            return
        case 404:
            throw GalleryAPIError.notFound
        case 500..<600:
            throw GalleryAPIError.serverError
        default:
            throw GalleryAPIError.unknown(httpResponse.statusCode)
        }
    }
}

// MARK: - Gallery API Errors

enum GalleryAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case notFound
    case serverError
    case unknown(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .invalidResponse:
            return "无效的服务器响应"
        case .notFound:
            return "精灵不存在"
        case .serverError:
            return "服务器错误"
        case .unknown(let code):
            return "未知错误 (\(code))"
        }
    }
}
