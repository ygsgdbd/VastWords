import SwiftUI
import SwiftUIX

struct ContentView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    
    var body: some View {
        VStack(spacing: 16) {
            Text("VastWords")
                .font(.title)
            
            Divider()
            
            Text("正在监听剪贴板...")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("已处理 \(clipboardManager.lastProcessedChangeCount) 次变更")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 300)
        .padding()
    }
}

#Preview {
    ContentView(clipboardManager: ClipboardManager())
} 
