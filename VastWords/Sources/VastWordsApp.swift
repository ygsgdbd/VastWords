import SwiftUI
import SwiftUIX

@main
struct VastWordsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var clipboardManager = ClipboardManager()
    
    var body: some Scene {
        MenuBarExtra {
            ContentView(clipboardManager: clipboardManager)
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