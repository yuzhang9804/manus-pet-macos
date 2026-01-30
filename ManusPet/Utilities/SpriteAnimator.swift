import Foundation
import AppKit
import Combine

// MARK: - Sprite Animator

class SpriteAnimator: ObservableObject {
    // MARK: - Published Properties
    
    @Published var currentFrame: NSImage?
    @Published var isPlaying: Bool = false
    
    // MARK: - Private Properties
    
    private var spriteSheet: NSImage?
    private var frameWidth: Int = 64
    private var frameHeight: Int = 64
    private var currentAnimation: AnimationConfig?
    private var currentFrameIndex: Int = 0
    private var animationTimer: Timer?
    private var allFrames: [NSImage] = []
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// 加载精灵图
    func loadSpriteSheet(from image: NSImage, frameWidth: Int, frameHeight: Int) {
        self.spriteSheet = image
        self.frameWidth = frameWidth
        self.frameHeight = frameHeight
        self.allFrames = extractAllFrames()
        
        // 显示第一帧
        if !allFrames.isEmpty {
            currentFrame = allFrames[0]
        }
    }
    
    /// 加载精灵图从 URL
    func loadSpriteSheet(from url: URL, frameWidth: Int, frameHeight: Int, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let image = NSImage(contentsOf: url) else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            DispatchQueue.main.async {
                self?.loadSpriteSheet(from: image, frameWidth: frameWidth, frameHeight: frameHeight)
                completion(true)
            }
        }
    }
    
    /// 播放指定动画
    func playAnimation(_ config: AnimationConfig) {
        stopAnimation()
        
        currentAnimation = config
        currentFrameIndex = 0
        isPlaying = true
        
        let interval = 1.0 / config.frameRate
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.advanceFrame()
        }
        
        // 立即显示第一帧
        updateCurrentFrame()
    }
    
    /// 播放指定状态的动画
    func playAnimation(for state: PetState, config: SpriteConfig) {
        if let animConfig = config.animations[state.animationKey] {
            playAnimation(animConfig)
        } else {
            // 使用默认动画
            let defaultConfig = AnimationConfig(
                frames: Array(0..<8),
                frameRate: 8.0,
                loop: true
            )
            playAnimation(defaultConfig)
        }
    }
    
    /// 停止动画
    func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        isPlaying = false
    }
    
    /// 暂停动画
    func pauseAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        isPlaying = false
    }
    
    /// 恢复动画
    func resumeAnimation() {
        guard let config = currentAnimation else { return }
        
        isPlaying = true
        let interval = 1.0 / config.frameRate
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.advanceFrame()
        }
    }
    
    // MARK: - Private Methods
    
    private func extractAllFrames() -> [NSImage] {
        guard let spriteSheet = spriteSheet else { return [] }
        
        var frames: [NSImage] = []
        
        let sheetWidth = Int(spriteSheet.size.width)
        let sheetHeight = Int(spriteSheet.size.height)
        
        let cols = sheetWidth / frameWidth
        let rows = sheetHeight / frameHeight
        
        for row in 0..<rows {
            for col in 0..<cols {
                let rect = NSRect(
                    x: col * frameWidth,
                    y: (rows - 1 - row) * frameHeight, // 翻转 Y 坐标
                    width: frameWidth,
                    height: frameHeight
                )
                
                if let frame = extractFrame(from: spriteSheet, rect: rect) {
                    frames.append(frame)
                }
            }
        }
        
        return frames
    }
    
    private func extractFrame(from image: NSImage, rect: NSRect) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        // 转换坐标系 (NSImage 使用左下角原点，CGImage 使用左上角)
        let cgRect = CGRect(
            x: rect.origin.x,
            y: CGFloat(cgImage.height) - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
        
        guard let croppedCGImage = cgImage.cropping(to: cgRect) else {
            return nil
        }
        
        return NSImage(cgImage: croppedCGImage, size: rect.size)
    }
    
    private func advanceFrame() {
        guard let config = currentAnimation else { return }
        
        currentFrameIndex += 1
        
        if currentFrameIndex >= config.frames.count {
            if config.loop {
                currentFrameIndex = 0
            } else {
                stopAnimation()
                return
            }
        }
        
        updateCurrentFrame()
    }
    
    private func updateCurrentFrame() {
        guard let config = currentAnimation,
              currentFrameIndex < config.frames.count else { return }
        
        let frameIndex = config.frames[currentFrameIndex]
        
        if frameIndex < allFrames.count {
            currentFrame = allFrames[frameIndex]
        }
    }
}

// MARK: - NSImage Extension

extension NSImage {
    /// 从 NSImage 获取 CGImage
    func cgImage(forProposedRect proposedRect: UnsafeMutablePointer<NSRect>?, context: NSGraphicsContext?, hints: [NSImageRep.HintKey : Any]?) -> CGImage? {
        var rect = proposedRect?.pointee ?? NSRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: context, hints: hints)
    }
}
