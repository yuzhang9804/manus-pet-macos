import SwiftUI
import AppKit

// MARK: - Pet View

struct PetView: View {
    @EnvironmentObject var viewModel: PetViewModel
    
    var body: some View {
        ZStack {
            // 透明背景
            Color.clear
            
            // 精灵动画
            if let frame = viewModel.animator.currentFrame {
                Image(nsImage: frame)
                    .resizable()
                    .interpolation(.none) // 像素风格，不模糊
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .scaleEffect(viewModel.scale)
                    .opacity(viewModel.opacity)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.currentState)
            } else {
                // 默认占位图
                DefaultPetView()
                    .frame(width: 150, height: 150)
                    .scaleEffect(viewModel.scale)
                    .opacity(viewModel.opacity)
            }
            
            // 状态指示器
            VStack {
                Spacer()
                
                if viewModel.showStatusBubble {
                    StatusBubble(status: viewModel.statusMessage)
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .padding(.bottom, 20)
        }
        .frame(width: 200, height: 200)
        .onAppear {
            viewModel.startAnimation()
        }
        .onDisappear {
            viewModel.stopAnimation()
        }
    }
}

// MARK: - Default Pet View (当没有加载精灵时显示)

struct DefaultPetView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 身体
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 1.0, green: 0.8, blue: 0.9),
                            Color(red: 0.95, green: 0.6, blue: 0.75)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: .pink.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // 耳朵
            HStack(spacing: 60) {
                Ear()
                    .rotationEffect(.degrees(-15))
                Ear()
                    .rotationEffect(.degrees(15))
            }
            .offset(y: -50)
            
            // 脸部
            VStack(spacing: 8) {
                // 眼睛
                HStack(spacing: 25) {
                    Eye()
                    Eye()
                }
                
                // 嘴巴
                Mouth()
            }
            .offset(y: 5)
            
            // 腮红
            HStack(spacing: 50) {
                Circle()
                    .fill(Color.pink.opacity(0.4))
                    .frame(width: 15, height: 15)
                Circle()
                    .fill(Color.pink.opacity(0.4))
                    .frame(width: 15, height: 15)
            }
            .offset(y: 15)
        }
        .scaleEffect(isAnimating ? 1.02 : 1.0)
        .animation(
            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Ear Component

struct Ear: View {
    var body: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.75, blue: 0.85),
                        Color(red: 0.95, green: 0.55, blue: 0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 25, height: 40)
            .overlay(
                Ellipse()
                    .fill(Color.pink.opacity(0.5))
                    .frame(width: 12, height: 25)
                    .offset(y: 5)
            )
    }
}

// MARK: - Eye Component

struct Eye: View {
    var body: some View {
        ZStack {
            // 眼白
            Ellipse()
                .fill(Color.white)
                .frame(width: 18, height: 20)
            
            // 瞳孔
            Circle()
                .fill(Color(red: 0.2, green: 0.15, blue: 0.15))
                .frame(width: 10, height: 10)
                .offset(y: 2)
            
            // 高光
            Circle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
                .offset(x: 2, y: -1)
        }
    }
}

// MARK: - Mouth Component

struct Mouth: View {
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addQuadCurve(
                to: CGPoint(x: 12, y: 0),
                control: CGPoint(x: 6, y: 6)
            )
        }
        .stroke(Color(red: 0.4, green: 0.3, blue: 0.3), lineWidth: 2)
        .frame(width: 12, height: 6)
    }
}

// MARK: - Status Bubble

struct StatusBubble: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
    }
}

// MARK: - Preview

#Preview {
    PetView()
        .environmentObject(PetViewModel())
        .frame(width: 200, height: 200)
        .background(Color.gray.opacity(0.3))
}
