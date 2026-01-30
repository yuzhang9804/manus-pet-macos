import Foundation
import AppKit

// MARK: - Sprite Model

struct Sprite: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let author: String?
    let version: String
    let imageURL: URL?
    let localImagePath: String?
    let config: SpriteConfig
    
    // Gallery metadata
    var likes: Int?
    var downloads: Int?
    var createdAt: Date?
    
    // Computed property for display
    var displayName: String {
        name.isEmpty ? "Unknown Sprite" : name
    }
}

// MARK: - Sprite Configuration

struct SpriteConfig: Codable {
    let frameWidth: Int
    let frameHeight: Int
    let animations: [String: AnimationConfig]
    
    init(frameWidth: Int = 64, frameHeight: Int = 64, animations: [String: AnimationConfig] = [:]) {
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.animations = animations
    }
}

// MARK: - Animation Configuration

struct AnimationConfig: Codable {
    let frames: [Int]
    let frameRate: Double
    let loop: Bool
    
    init(frames: [Int], frameRate: Double = 8.0, loop: Bool = true) {
        self.frames = frames
        self.frameRate = frameRate
        self.loop = loop
    }
}

// MARK: - Sprite Manifest (for loading from ZIP)

struct SpriteManifest: Codable {
    let id: String
    let name: String
    let description: String?
    let author: String?
    let version: String
    let frameWidth: Int
    let frameHeight: Int
    let frameCount: Int
    let animations: [String: AnimationConfig]?
    
    func toSprite(imageURL: URL? = nil, localImagePath: String? = nil) -> Sprite {
        let config = SpriteConfig(
            frameWidth: frameWidth,
            frameHeight: frameHeight,
            animations: animations ?? defaultAnimations()
        )
        
        return Sprite(
            id: id,
            name: name,
            description: description,
            author: author,
            version: version,
            imageURL: imageURL,
            localImagePath: localImagePath,
            config: config
        )
    }
    
    private func defaultAnimations() -> [String: AnimationConfig] {
        // 默认动画配置 (假设 8x7 网格布局)
        return [
            "idle": AnimationConfig(frames: Array(0..<8), frameRate: 4, loop: true),
            "thinking": AnimationConfig(frames: Array(8..<16), frameRate: 6, loop: true),
            "happy": AnimationConfig(frames: Array(16..<24), frameRate: 8, loop: true),
            "sad": AnimationConfig(frames: Array(24..<32), frameRate: 4, loop: true),
            "working": AnimationConfig(frames: Array(32..<40), frameRate: 6, loop: true),
            "celebrating": AnimationConfig(frames: Array(40..<48), frameRate: 10, loop: false),
            "sleeping": AnimationConfig(frames: Array(48..<56), frameRate: 2, loop: true)
        ]
    }
}

// MARK: - Gallery Sprite Response

struct GallerySpriteResponse: Codable {
    let id: String
    let name: String
    let description: String?
    let authorId: String?
    let authorName: String?
    let imageUrl: String
    let thumbnailUrl: String?
    let config: SpriteConfig
    let likes: Int
    let downloads: Int
    let createdAt: String
    let updatedAt: String
    
    func toSprite() -> Sprite {
        return Sprite(
            id: id,
            name: name,
            description: description,
            author: authorName,
            version: "1.0",
            imageURL: URL(string: imageUrl),
            localImagePath: nil,
            config: config,
            likes: likes,
            downloads: downloads,
            createdAt: ISO8601DateFormatter().date(from: createdAt)
        )
    }
}
