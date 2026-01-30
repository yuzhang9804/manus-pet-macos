import SwiftUI

// MARK: - Task List View

struct TaskListView: View {
    @EnvironmentObject var viewModel: TaskViewModel
    @State private var selectedFilter: TaskFilter = .all
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                // 筛选器
                Picker("筛选", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
                
                Spacer()
                
                // 刷新按钮
                Button {
                    Task {
                        await viewModel.fetchTasks()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 任务列表
            if viewModel.isLoading && viewModel.tasks.isEmpty {
                VStack {
                    Spacer()
                    ProgressView("加载中...")
                    Spacer()
                }
            } else if filteredTasks.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("暂无任务")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(filteredTasks) { task in
                    TaskRowView(task: task)
                        .onTapGesture {
                            viewModel.selectedTask = task
                        }
                }
                .listStyle(.inset)
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
                await viewModel.fetchTasks()
            }
        }
        .sheet(item: $viewModel.selectedTask) { task in
            TaskDetailView(task: task)
        }
    }
    
    private var filteredTasks: [ManusTask] {
        switch selectedFilter {
        case .all:
            return viewModel.tasks
        case .running:
            return viewModel.runningTasks
        case .completed:
            return viewModel.completedTasks
        case .failed:
            return viewModel.failedTasks
        }
    }
}

// MARK: - Task Filter

enum TaskFilter: String, CaseIterable {
    case all
    case running
    case completed
    case failed
    
    var displayName: String {
        switch self {
        case .all: return "全部"
        case .running: return "运行中"
        case .completed: return "已完成"
        case .failed: return "失败"
        }
    }
}

// MARK: - Task Row View

struct TaskRowView: View {
    let task: ManusTask
    
    var body: some View {
        HStack(spacing: 12) {
            // 状态指示器
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                // 任务提示
                Text(task.prompt)
                    .lineLimit(2)
                    .font(.body)
                
                // 时间和状态
                HStack {
                    Text(task.displayStatus)
                        .font(.caption)
                        .foregroundColor(statusColor)
                    
                    Spacer()
                    
                    Text(timeAgo(from: task.updatedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch task.status {
        case .pending:
            return .orange
        case .running:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        case .cancelled:
            return .gray
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Task Detail View

struct TaskDetailView: View {
    let task: ManusTask
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 头部
            HStack {
                Text("任务详情")
                    .font(.headline)
                Spacer()
                Button("关闭") {
                    dismiss()
                }
            }
            
            Divider()
            
            // 状态
            HStack {
                Text("状态:")
                    .foregroundColor(.secondary)
                Text(task.displayStatus)
                    .foregroundColor(statusColor)
                    .fontWeight(.medium)
            }
            
            // 提示
            VStack(alignment: .leading, spacing: 4) {
                Text("提示:")
                    .foregroundColor(.secondary)
                Text(task.prompt)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
            }
            
            // 输出
            if let outputText = task.outputText {
                VStack(alignment: .leading, spacing: 4) {
                    Text("输出:")
                        .foregroundColor(.secondary)
                    ScrollView {
                        Text(outputText)
                            .font(.system(.body, design: .monospaced))
                    }
                    .frame(maxHeight: 200)
                    .padding(8)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                }
            }
            
            // 错误
            if let error = task.error {
                VStack(alignment: .leading, spacing: 4) {
                    Text("错误:")
                        .foregroundColor(.secondary)
                    Text(error)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            
            // 时间
            HStack {
                Text("创建时间:")
                    .foregroundColor(.secondary)
                Text(formatDate(task.createdAt))
            }
            
            HStack {
                Text("更新时间:")
                    .foregroundColor(.secondary)
                Text(formatDate(task.updatedAt))
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 500, height: 400)
    }
    
    private var statusColor: Color {
        switch task.status {
        case .pending: return .orange
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - ManusTask Identifiable Extension

extension ManusTask: Hashable {
    static func == (lhs: ManusTask, rhs: ManusTask) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Preview

#Preview {
    TaskListView()
        .environmentObject(TaskViewModel())
        .frame(width: 400, height: 500)
}
