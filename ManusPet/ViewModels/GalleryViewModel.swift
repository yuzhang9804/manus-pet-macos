import Foundation
import Combine

// MARK: - Gallery ViewModel

@MainActor
class GalleryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var sprites: [Sprite] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var searchQuery: String = ""
    @Published var selectedCategory: SpriteCategory = .popular
    @Published var installedSpriteIds: Set<String> = []
    
    // MARK: - Computed Properties
    
    var filteredSprites: [Sprite] {
        if searchQuery.isEmpty {
            return sprites
        }
        return sprites.filter { sprite in
            sprite.name.localizedCaseInsensitiveContains(searchQuery) ||
            (sprite.description?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
            (sprite.author?.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
    }
    
    // MARK: - Private Properties
    
    private let galleryService = GalleryAPIService.shared
    private let spriteService = SpriteService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        loadInstalledSprites()
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // 当分类变化时重新加载
        $selectedCategory
            .dropFirst()
            .sink { [weak self] category in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.fetchSprites(category: category)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func fetchSprites(category: SpriteCategory = .popular) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedSprites = try await galleryService.fetchSprites(category: category)
            sprites = fetchedSprites
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func installSprite(_ sprite: Sprite) async throws {
        // 下载精灵包
        let localPath = try await spriteService.downloadSprite(sprite)
        
        installedSpriteIds.insert(sprite.id)
        saveInstalledSprites()
        
        // 通知精灵变化
        let installedSprite = sprite
        // 更新本地路径
        NotificationCenter.default.post(
            name: .spriteDidChange,
            object: nil,
            userInfo: ["sprite": installedSprite]
        )
    }
    
    func uninstallSprite(_ spriteId: String) {
        spriteService.deleteSprite(id: spriteId)
        installedSpriteIds.remove(spriteId)
        saveInstalledSprites()
    }
    
    func isInstalled(_ spriteId: String) -> Bool {
        installedSpriteIds.contains(spriteId)
    }
    
    func likeSprite(_ spriteId: String) async throws {
        try await galleryService.likeSprite(spriteId)
        
        // 更新本地数据
        if let index = sprites.firstIndex(where: { $0.id == spriteId }) {
            var sprite = sprites[index]
            sprite.likes = (sprite.likes ?? 0) + 1
            sprites[index] = sprite
        }
    }
    
    // MARK: - Private Methods
    
    private func loadInstalledSprites() {
        if let data = UserDefaults.standard.data(forKey: "installedSpriteIds"),
           let ids = try? JSONDecoder().decode(Set<String>.self, from: data) {
            installedSpriteIds = ids
        }
    }
    
    private func saveInstalledSprites() {
        if let data = try? JSONEncoder().encode(installedSpriteIds) {
            UserDefaults.standard.set(data, forKey: "installedSpriteIds")
        }
    }
}

// MARK: - Sprite Category

enum SpriteCategory: String, CaseIterable {
    case popular = "popular"
    case recent = "recent"
    case trending = "trending"
    case featured = "featured"
    
    var displayName: String {
        switch self {
        case .popular: return "热门"
        case .recent: return "最新"
        case .trending: return "流行"
        case .featured: return "精选"
        }
    }
}
