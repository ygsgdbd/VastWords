import Foundation
import AppKit
import Combine

extension Notification.Name {
    static let wordsDidSave = Notification.Name("wordsDidSave")
}

@MainActor
final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published private(set) var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    private var cancellables = Set<AnyCancellable>()
    private var isProcessing = false
    
    private let repository: WordRepository
    private let extractor: WordExtractor
    private let dictionaryService: SystemDictionaryService
    
    private let processingQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.qualityOfService = .utility  // 使用较低优先级
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    
    init(
        repository: WordRepository = .shared,
        extractor: WordExtractor = .shared,
        dictionaryService: SystemDictionaryService = .shared
    ) {
        print("📋 ClipboardManager: 初始化")
        self.repository = repository
        self.extractor = extractor
        self.dictionaryService = dictionaryService
        self.lastChangeCount = pasteboard.changeCount
    }
    
    func startMonitoring() {
        print("📋 ClipboardManager: 开始监听剪贴板")
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .receive(on: processingQueue)  // 在后台队列处理
            .sink { [weak self] _ in
                self?.checkForChanges()
            }
            .store(in: &cancellables)
    }
    
    func stopMonitoring() {
        print("📋 ClipboardManager: 停止监听剪贴板")
        cancellables.removeAll()
    }
    
    private func checkForChanges() {
        guard !isProcessing,
              pasteboard.changeCount != lastChangeCount else { return }
        
        isProcessing = true
        
        Task(priority: .utility) { [weak self] in
            guard let self = self else { return }
            
            print("📋 ClipboardManager: 检测到剪贴板变化 [\(self.lastChangeCount) -> \(self.pasteboard.changeCount)]")
            await MainActor.run { self.lastChangeCount = self.pasteboard.changeCount }
            
            defer { 
                Task { @MainActor in
                    self.isProcessing = false
                }
            }
            
            var text: String?
            
            do {
                // 分别处理文本和图片，避免并行处理可能导致的问题
                // 首先尝试获取文本
                if let pasteboardText = pasteboard.string(forType: .string) {
                    print("📋 ClipboardManager: 获取到文本内容")
                    text = pasteboardText
                } else {
                    // 如果没有文本，尝试OCR
                    print("📋 ClipboardManager: 尝试从图片提取文本")
                    do {
                        text = try await OCRService.shared.extractTextFromClipboard()
                        if let text = text {
                            print("📋 ClipboardManager: OCR提取成功")
                        }
                    } catch OCRError.noImageInClipboard {
                        print("📋 ClipboardManager: 剪贴板中没有图片")
                    } catch OCRError.invalidImage {
                        print("📋 ClipboardManager: 图片格式无效")
                    } catch {
                        print("📋 ClipboardManager: OCR处理失败: \(error)")
                    }
                }
            } catch {
                print("📋 ClipboardManager: 处理剪贴板内容时出错: \(error)")
                return
            }
            
            guard let text = text else {
                print("📋 ClipboardManager: 剪贴板内容既不是文本也不是图片")
                return
            }
            
            // 提取单词
            let words = await extractor.extract(from: text)
            guard !words.isEmpty else {
                print("📋 ClipboardManager: 未提取到有效单词")
                return
            }
            
            print("📋 ClipboardManager: 提取到 \(words.count) 个单词: \(words)")
            
            // 并行验证单词
            var validWords = Set<String>()
            await withTaskGroup(of: (String, Bool).self) { group in
                for word in words {
                    group.addTask(priority: .utility) {
                        let isValid = await self.dictionaryService.lookup(word) != nil
                        return (word, isValid)
                    }
                }
                
                for await (word, isValid) in group {
                    if isValid {
                        print("📋 ClipboardManager: 单词 '\(word)' 验证通过")
                        validWords.insert(word)
                    } else {
                        print("📋 ClipboardManager: 单词 '\(word)' 未找到释义，跳过")
                    }
                }
            }
            
            guard !validWords.isEmpty else {
                print("📋 ClipboardManager: 没有找到有效单词")
                return
            }
            
            do {
                try repository.batchSave(validWords)
                print("📋 ClipboardManager: 保存 \(validWords.count) 个有效单词成功")
                await MainActor.run {
                    NotificationCenter.default.post(name: .wordsDidSave, object: nil)
                }
            } catch {
                print("⚠️ ClipboardManager: 保存单词失败: \(error)")
            }
        }
    }
    
    deinit {
        print("📋 ClipboardManager: 释放")
        cancellables.removeAll()
    }
} 
