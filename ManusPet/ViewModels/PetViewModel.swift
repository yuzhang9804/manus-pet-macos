import Foundation
import SwiftUI
import Combine

// MARK: - Pet ViewModel

class PetViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentSprite: Sprite?
    @Published var currentState: PetState = .idle
    @Published var scale: CGFloat = 1.0
    @Published var opacity: CGFloat = 1.0
    @Published var showStatusBubble: Bool = false
    @Published var statusMessage: String = ""
    
    // MARK: - Animator
    
    let animator = SpriteAnimator()
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var statusBubbleTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // 当精灵变化时重新加载动画
        $currentSprite
            .compactMap { $0 }
            .sink { [weak self] sprite in
                self?.loadSprite(sprite)
            }
            .store(in: &cancellables)
        
        // 当状态变化时切换动画
        $currentState
            .sink { [weak self] state in
                self?.playAnimationForState(state)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func setState(_ state: PetState) {
        guard state != currentState else { return }
        currentState = state
        showStatus(state.displayName)
    }
    
    func startAnimation() {
        if let sprite = currentSprite {
            animator.playAnimation(for: currentState, config: sprite.config)
        }
    }
    
    func stopAnimation() {
        animator.stopAnimation()
    }
    
    func showStatus(_ message: String, duration: TimeInterval = 2.0) {
        statusMessage = message
        withAnimation(.easeInOut(duration: 0.2)) {
            showStatusBubble = true
        }
        
        statusBubbleTimer?.invalidate()
        statusBubbleTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            withAnimation(.easeInOut(duration: 0.2)) {
                self?.showStatusBubble = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadSprite(_ sprite: Sprite) {
        // 优先从本地路径加载
        if let localPath = sprite.localImagePath {
            let url = URL(fileURLWithPath: localPath)
            animator.loadSpriteSheet(
                from: url,
                frameWidth: sprite.config.frameWidth,
                frameHeight: sprite.config.frameHeight
            ) { [weak self] success in
                if success {
                    self?.playAnimationForState(self?.currentState ?? .idle)
                }
            }
        }
        // 从远程 URL 加载
        else if let imageURL = sprite.imageURL {
            animator.loadSpriteSheet(
                from: imageURL,
                frameWidth: sprite.config.frameWidth,
                frameHeight: sprite.config.frameHeight
            ) { [weak self] success in
                if success {
                    self?.playAnimationForState(self?.currentState ?? .idle)
                }
            }
        }
    }
    
    private func playAnimationForState(_ state: PetState) {
        guard let sprite = currentSprite else { return }
        animator.playAnimation(for: state, config: sprite.config)
    }
}
