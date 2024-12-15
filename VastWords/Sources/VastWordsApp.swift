import SwiftUI
import SwiftUIX

@main
struct VastWordsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = WordListViewModel()
    
    init() {
        // 启动剪贴板监听
        ClipboardManager.shared.startMonitoring()
    }
    
    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(viewModel)
        } label: {
            Image(systemName: "character.textbox")
        }
        .menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 禁用主窗口
        NSApp.setActivationPolicy(.accessory)
    }
} 
