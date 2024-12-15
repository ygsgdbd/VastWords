import Foundation
import AppKit
import SwiftUI
import Combine

@MainActor
final class ClipboardManager: ObservableObject {
    static let shared = ClipboardManager()
    
    @Published private(set) var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    private var cancellables = Set<AnyCancellable>()
    
    private let repository: WordRepository
    private let extractor: WordExtractor
    
    init(
        repository: WordRepository = .shared,
        extractor: WordExtractor = .shared
    ) {
        print("📋 ClipboardManager: 初始化")
        self.repository = repository
        self.extractor = extractor
        self.lastChangeCount = pasteboard.changeCount
    }
    
    func startMonitoring() {
        print("📋 ClipboardManager: 开始监听剪贴板")
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
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
        guard pasteboard.changeCount != lastChangeCount else { return }
        print("📋 ClipboardManager: 检测到剪贴板变化 [\(lastChangeCount) -> \(pasteboard.changeCount)]")
        
        guard let text = pasteboard.string(forType: .string) else {
            print("📋 ClipboardManager: 剪贴板内容不是文本")
            return
        }
        
        lastChangeCount = pasteboard.changeCount
        print("📋 ClipboardManager: 获取到文本 [\(text.prefix(50))...]")
        
        let words = extractor.extract(from: text)
        guard !words.isEmpty else {
            print("📋 ClipboardManager: 未提取到有效单词")
            return
        }
        
        print("📋 ClipboardManager: 提取到 \(words.count) 个单词: \(words)")
        
        do {
            try repository.batchSave(words)
            print("📋 ClipboardManager: 保存单词成功")
        } catch {
            print("⚠️ ClipboardManager: 保存单词失败: \(error)")
        }
    }
    
    deinit {
        print("📋 ClipboardManager: 释放")
        cancellables.removeAll()
    }
} 
