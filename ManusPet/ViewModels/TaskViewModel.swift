import Foundation
import Combine

// MARK: - Task ViewModel

class TaskViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var tasks: [ManusTask] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedTask: ManusTask?
    
    // MARK: - Computed Properties
    
    var runningTasks: [ManusTask] {
        tasks.filter { $0.status == .running }
    }
    
    var completedTasks: [ManusTask] {
        tasks.filter { $0.status == .completed }
    }
    
    var failedTasks: [ManusTask] {
        tasks.filter { $0.status == .failed }
    }
    
    var pendingTasks: [ManusTask] {
        tasks.filter { $0.status == .pending }
    }
    
    // MARK: - Private Properties
    
    private let apiService = ManusAPIService.shared
    private var cancellables = Set<AnyCancellable>()
    private var previousTaskStatuses: [String: Constants.TaskStatus] = [:]
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    func updateTasks(_ newTasks: [ManusTask]) {
        // 检测状态变化
        for task in newTasks {
            if let previousStatus = previousTaskStatuses[task.id],
               previousStatus != task.status {
                // 状态发生变化，发送通知
                notifyTaskStatusChange(task: task, from: previousStatus, to: task.status)
            }
            previousTaskStatuses[task.id] = task.status
        }
        
        tasks = newTasks.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func fetchTasks() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let fetchedTasks = try await apiService.listTasks()
            await MainActor.run {
                updateTasks(fetchedTasks)
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    func createTask(prompt: String, attachments: [TaskAttachment]? = nil) async throws -> ManusTask {
        let task = try await apiService.createTask(prompt: prompt, attachments: attachments)
        
        await MainActor.run {
            tasks.insert(task, at: 0)
            previousTaskStatuses[task.id] = task.status
        }
        
        return task
    }
    
    func cancelTask(_ taskId: String) async throws {
        // Manus API 可能不支持取消，这里预留接口
        // try await apiService.cancelTask(taskId)
    }
    
    func refreshTask(_ taskId: String) async {
        do {
            let task = try await apiService.getTask(taskId: taskId)
            await MainActor.run {
                if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                    let previousStatus = tasks[index].status
                    tasks[index] = task
                    
                    if previousStatus != task.status {
                        notifyTaskStatusChange(task: task, from: previousStatus, to: task.status)
                    }
                }
            }
        } catch {
            print("Failed to refresh task: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func notifyTaskStatusChange(task: ManusTask, from: Constants.TaskStatus, to: Constants.TaskStatus) {
        NotificationCenter.default.post(
            name: .taskStatusDidChange,
            object: nil,
            userInfo: [
                "task": task,
                "fromStatus": from,
                "toStatus": to
            ]
        )
        
        // 发送系统通知
        if AppSettings.load().showNotifications {
            sendSystemNotification(for: task, newStatus: to)
        }
    }
    
    private func sendSystemNotification(for task: ManusTask, newStatus: Constants.TaskStatus) {
        let notification = NSUserNotification()
        notification.title = "Manus 任务状态更新"
        
        switch newStatus {
        case .completed:
            notification.subtitle = "任务已完成"
            notification.informativeText = task.prompt.prefix(100).description
        case .failed:
            notification.subtitle = "任务失败"
            notification.informativeText = task.error ?? task.prompt.prefix(100).description
        case .running:
            notification.subtitle = "任务开始运行"
            notification.informativeText = task.prompt.prefix(100).description
        default:
            return
        }
        
        NSUserNotificationCenter.default.deliver(notification)
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let taskStatusDidChange = Notification.Name("taskStatusDidChange")
}
