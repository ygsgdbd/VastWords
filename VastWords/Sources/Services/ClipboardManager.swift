import Foundation
import AppKit
import Combine

extension Notification.Name {
    static let wordsDidSave = Notification.Name("wordsDidSave")
}

@MainActor
final class ClipboardManager {
    static let shared = ClipboardManager()
    
    /// 剪贴板检查间隔（纳秒）
    private let checkInterval: UInt64 = 500_000_000  // 0.5秒
    
    private var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    private var cancellables = Set<AnyCancellable>()
    
    private let repository: WordRepository
    private let extractor: WordExtractor
    private let dictionaryService: SystemDictionaryService
    
    private var monitoringTask: Task<Void, Never>?
    
    private init() {
        print("📋 ClipboardManager: 初始化")
        self.repository = WordRepository.shared
        self.extractor = WordExtractor.shared
        self.dictionaryService = SystemDictionaryService.shared
        self.lastChangeCount = pasteboard.changeCount
    }
    
    func startMonitoring() {
        print("📋 ClipboardManager: 开始监听剪贴板（检查间隔：\(Double(checkInterval) / 1_000_000_000)��）")
        
        // 取消之前的监听任务
        monitoringTask?.cancel()
        
        // 创建新的监听任务
        monitoringTask = Task(priority: .background) { @MainActor in
            while !Task.isCancelled {
                // 检查剪贴板是否有变化
                let currentCount = pasteboard.changeCount
                if currentCount != lastChangeCount {
                    lastChangeCount = currentCount
                    await processClipboard()
                }
                
                // 等待指定时间再检查
                try? await Task.sleep(nanoseconds: checkInterval)
            }
        }
    }
    
    func stopMonitoring() {
        print("📋 ClipboardManager: 停止监听剪贴板")
        monitoringTask?.cancel()
        monitoringTask = nil
    }
    
    private func processClipboard() async {
        guard let text = pasteboard.string(forType: .string) else { return }
        
        do {
            // 提取单词
            let words = await extractor.extract(from: text)
            guard !words.isEmpty else { return }
            
            print("📋 ClipboardManager: 发现 \(words.count) 个单词")
            
            // 验证单词是否有效
            var validWords = Set<String>()
            
            await withThrowingTaskGroup(of: (String, Bool).self, body: { group in
                for word in words {
                    group.addTask(priority: .background) {
                        let definition = await self.dictionaryService.lookup(word)
                        return (word, definition != nil)
                    }
                }
                
                do {
                    for try await (word, isValid) in group {
                        if isValid {
                            validWords.insert(word)
                        }
                    }
                } catch {
                    print("⚠️ ClipboardManager: 单词验证失败: \(error)")
                }
            })
            
            guard !validWords.isEmpty else { return }
            
            // 保存单词
            try repository.batchSave(validWords)
            print("📋 ClipboardManager: 保存 \(validWords.count) 个有效单词成功")
            NotificationCenter.default.post(name: .wordsDidSave, object: nil)
        } catch {
            print("⚠️ ClipboardManager: 处理失败: \(error)")
        }
    }
} 
