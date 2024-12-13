import Foundation
import AppKit
import Combine

class ClipboardManager: ObservableObject {
    @Published var lastProcessedChangeCount: Int = NSPasteboard.general.changeCount
    private let pasteboard: NSPasteboard
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("ClipboardManager: 初始化")
        self.pasteboard = NSPasteboard.general
        setupPasteboardObserver()
    }
    
    private func setupPasteboardObserver() {
        print("ClipboardManager: 设置观察者")
        // 使用 Timer.publish 来检查剪贴板变化
        Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkClipboard()
            }
            .store(in: &cancellables)
        
        // 初始检查一次
        checkClipboard()
    }
    
    private func checkClipboard() {
        let currentCount = pasteboard.changeCount
        print("ClipboardManager: 检查剪贴板 - 当前计数: \(currentCount), 上次计数: \(lastProcessedChangeCount)")
        
        guard currentCount != lastProcessedChangeCount else { return }
        lastProcessedChangeCount = currentCount
        
        // 获取剪贴板内容
        guard let items = pasteboard.pasteboardItems else {
            print("ClipboardManager: 没有剪贴板内容")
            return
        }
        
        print("ClipboardManager: 发现 \(items.count) 个剪贴板项目")
        
        // 只处理文本内容
        for item in items {
            if let text = item.string(forType: .string) {
                print("ClipboardManager: 发现文本内容: \(text)")
                TextProcessor.shared.process(text)
                return
            }
        }
    }
    
    deinit {
        print("ClipboardManager: 释放")
        cancellables.removeAll()
    }
} 
