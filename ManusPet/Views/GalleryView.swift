import SwiftUI

// MARK: - Gallery View

struct GalleryView: View {
    @EnvironmentObject var viewModel: GalleryViewModel
    @EnvironmentObject var petViewModel: PetViewModel
    
    @State private var selectedSprite: Sprite?
    @State private var isInstalling = false
    @State private var installError: String?
    
    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("搜索精灵...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(8)
                .frame(maxWidth: 250)
                
                Spacer()
                
                // 分类选择
                Picker("分类", selection: $viewModel.selectedCategory) {
                    ForEach(SpriteCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
                
                // 刷新按钮
                Button {
                    Task {
                        await viewModel.fetchSprites(category: viewModel.selectedCategory)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 精灵网格
            if viewModel.isLoading && viewModel.sprites.isEmpty {
                VStack {
                    Spacer()
                    ProgressView("加载中...")
                    Spacer()
                }
            } else if viewModel.filteredSprites.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("暂无精灵")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(viewModel.filteredSprites) { sprite in
                            SpriteCard(
                                sprite: sprite,
                                isInstalled: viewModel.isInstalled(sprite.id)
                            ) {
                                selectedSprite = sprite
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // 错误提示
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchSprites(category: viewModel.selectedCategory)
            }
        }
        .sheet(item: $selectedSprite) { sprite in
            SpriteDetailSheet(
                sprite: sprite,
                isInstalled: viewModel.isInstalled(sprite.id),
                isInstalling: $isInstalling,
                installError: $installError
            ) {
                // 安装精灵
                Task {
                    isInstalling = true
                    installError = nil
                    do {
                        try await viewModel.installSprite(sprite)
                    } catch {
                        installError = error.localizedDescription
                    }
                    isInstalling = false
                }
            } onUse: {
                // 使用精灵
                NotificationCenter.default.post(
                    name: .spriteDidChange,
                    object: nil,
                    userInfo: ["sprite": sprite]
                )
                selectedSprite = nil
            }
        }
    }
}

// MARK: - Sprite Card

struct SpriteCard: View {
    let sprite: Sprite
    let isInstalled: Bool
    let onTap: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        VStack(spacing: 8) {
            // 精灵预览
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(height: 120)
                
                if let imageURL = sprite.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 80)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 30))
                                .foregroundColor(.secondary)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 30))
                        .foregroundColor(.pink)
                }
                
                // 已安装标记
                if isInstalled {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .padding(6)
                        }
                        Spacer()
                    }
                }
            }
            
            // 精灵信息
            VStack(alignment: .leading, spacing: 4) {
                Text(sprite.displayName)
                    .font(.headline)
                    .lineLimit(1)
                
                if let author = sprite.author {
                    Text("by \(author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                        Text("\(sprite.likes ?? 0)")
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(.blue)
                        Text("\(sprite.downloads ?? 0)")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(color: .black.opacity(isHovering ? 0.15 : 0.05), radius: isHovering ? 8 : 4)
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Sprite Detail Sheet

struct SpriteDetailSheet: View {
    let sprite: Sprite
    let isInstalled: Bool
    @Binding var isInstalling: Bool
    @Binding var installError: String?
    let onInstall: () -> Void
    let onUse: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // 头部
            HStack {
                Text(sprite.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("关闭") {
                    dismiss()
                }
            }
            
            // 精灵预览
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .frame(height: 200)
                
                if let imageURL = sprite.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .interpolation(.none)
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 150)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            
            // 精灵信息
            VStack(alignment: .leading, spacing: 8) {
                if let author = sprite.author {
                    HStack {
                        Text("作者:")
                            .foregroundColor(.secondary)
                        Text(author)
                    }
                }
                
                if let description = sprite.description {
                    Text(description)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                        Text("\(sprite.likes ?? 0) 喜欢")
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(.blue)
                        Text("\(sprite.downloads ?? 0) 下载")
                    }
                }
            }
            
            // 错误提示
            if let error = installError {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
            
            Spacer()
            
            // 操作按钮
            HStack {
                if isInstalled {
                    Button("使用此精灵") {
                        onUse()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        onInstall()
                    } label: {
                        if isInstalling {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Text("安装精灵")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isInstalling)
                }
            }
        }
        .padding()
        .frame(width: 400, height: 450)
    }
}

// MARK: - Sprite Identifiable Extension

extension Sprite: Hashable {
    static func == (lhs: Sprite, rhs: Sprite) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview

#Preview {
    GalleryView()
        .environmentObject(GalleryViewModel())
        .environmentObject(PetViewModel())
        .frame(width: 800, height: 600)
}
