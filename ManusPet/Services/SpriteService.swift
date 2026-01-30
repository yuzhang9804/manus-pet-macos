import Foundation
import AppKit

// MARK: - Sprite Service

class SpriteService {
    // MARK: - Singleton
    
    static let shared = SpriteService()
    
    // MARK: - Properties
    
    private let fileManager = FileManager.default
    private var spritesDirectory: URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let spritesDir = appSupport.appendingPathComponent("ManusPet/Sprites")
        
        if !fileManager.fileExists(atPath: spritesDir.path) {
            try? fileManager.createDirectory(at: spritesDir, withIntermediateDirectories: true)
        }
        
        return spritesDir
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// 加载默认精灵
    func loadDefaultSprite() -> Sprite {
        // 创建默认精灵配置
        let config = SpriteConfig(
            frameWidth: 64,
            frameHeight: 64,
            animations: [
                "idle": AnimationConfig(frames: Array(0..<8), frameRate: 4, loop: true),
                "thinking": AnimationConfig(frames: Array(8..<16), frameRate: 6, loop: true),
                "happy": AnimationConfig(frames: Array(16..<24), frameRate: 8, loop: true),
                "sad": AnimationConfig(frames: Array(24..<32), frameRate: 4, loop: true),
                "working": AnimationConfig(frames: Array(32..<40), frameRate: 6, loop: true),
                "celebrating": AnimationConfig(frames: Array(40..<48), frameRate: 10, loop: false),
                "sleeping": AnimationConfig(frames: Array(48..<56), frameRate: 2, loop: true)
            ]
        )
        
        return Sprite(
            id: "default",
            name: "默认精灵",
            description: "Manus Pet 默认精灵",
            author: "Manus",
            version: "1.0",
            imageURL: nil,
            localImagePath: nil,
            config: config
        )
    }
    
    /// 加载精灵
    func loadSprite(id: String, completion: @escaping (Sprite?) -> Void) {
        let spriteDir = spritesDirectory.appendingPathComponent(id)
        let manifestURL = spriteDir.appendingPathComponent("manifest.json")
        
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            completion(nil)
            return
        }
        
        do {
            let data = try Data(contentsOf: manifestURL)
            let manifest = try JSONDecoder().decode(SpriteManifest.self, from: data)
            
            let imagePath = spriteDir.appendingPathComponent("sprite.png").path
            let sprite = manifest.toSprite(localImagePath: imagePath)
            
            completion(sprite)
        } catch {
            print("Failed to load sprite: \(error)")
            completion(nil)
        }
    }
    
    /// 下载并安装精灵
    func downloadSprite(_ sprite: Sprite) async throws -> String {
        guard let imageURL = sprite.imageURL else {
            throw SpriteError.invalidURL
        }
        
        let spriteDir = spritesDirectory.appendingPathComponent(sprite.id)
        
        // 创建目录
        try fileManager.createDirectory(at: spriteDir, withIntermediateDirectories: true)
        
        // 下载精灵图
        let (data, _) = try await URLSession.shared.data(from: imageURL)
        
        let imagePath = spriteDir.appendingPathComponent("sprite.png")
        try data.write(to: imagePath)
        
        // 保存 manifest
        let manifest = SpriteManifest(
            id: sprite.id,
            name: sprite.name,
            description: sprite.description,
            author: sprite.author,
            version: sprite.version,
            frameWidth: sprite.config.frameWidth,
            frameHeight: sprite.config.frameHeight,
            frameCount: 56, // 默认 8x7
            animations: sprite.config.animations
        )
        
        let manifestData = try JSONEncoder().encode(manifest)
        let manifestPath = spriteDir.appendingPathComponent("manifest.json")
        try manifestData.write(to: manifestPath)
        
        return imagePath.path
    }
    
    /// 从 ZIP 文件安装精灵（使用系统 unzip 命令）
    func installSpriteFromZip(at url: URL) async throws -> Sprite {
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        defer {
            try? fileManager.removeItem(at: tempDir)
        }
        
        // 创建临时目录
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        // 使用 Process 调用系统 unzip 命令
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-q", url.path, "-d", tempDir.path]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw SpriteError.installFailed
        }
        
        // 读取 manifest
        let manifestURL = tempDir.appendingPathComponent("manifest.json")
        let manifestData = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(SpriteManifest.self, from: manifestData)
        
        // 移动到精灵目录
        let spriteDir = spritesDirectory.appendingPathComponent(manifest.id)
        
        if fileManager.fileExists(atPath: spriteDir.path) {
            try fileManager.removeItem(at: spriteDir)
        }
        
        try fileManager.moveItem(at: tempDir, to: spriteDir)
        
        let imagePath = spriteDir.appendingPathComponent("sprite.png").path
        return manifest.toSprite(localImagePath: imagePath)
    }
    
    /// 获取所有已安装的精灵
    func getInstalledSprites() -> [Sprite] {
        var sprites: [Sprite] = []
        
        guard let contents = try? fileManager.contentsOfDirectory(
            at: spritesDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return sprites
        }
        
        for dir in contents {
            let manifestURL = dir.appendingPathComponent("manifest.json")
            
            guard let data = try? Data(contentsOf: manifestURL),
                  let manifest = try? JSONDecoder().decode(SpriteManifest.self, from: data) else {
                continue
            }
            
            let imagePath = dir.appendingPathComponent("sprite.png").path
            sprites.append(manifest.toSprite(localImagePath: imagePath))
        }
        
        return sprites
    }
    
    /// 删除精灵
    func deleteSprite(id: String) {
        let spriteDir = spritesDirectory.appendingPathComponent(id)
        try? fileManager.removeItem(at: spriteDir)
    }
}

// MARK: - Sprite Errors

enum SpriteError: LocalizedError {
    case invalidURL
    case downloadFailed
    case invalidManifest
    case installFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的精灵 URL"
        case .downloadFailed:
            return "下载精灵失败"
        case .invalidManifest:
            return "无效的精灵配置文件"
        case .installFailed:
            return "安装精灵失败"
        }
    }
}
