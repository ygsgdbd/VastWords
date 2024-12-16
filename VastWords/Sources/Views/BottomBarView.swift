import SwiftUI

struct BottomBarView: View {
    @EnvironmentObject private var viewModel: WordListViewModel
    
    var body: some View {
        HStack {
            Button {
                let alert = NSAlert()
                alert.messageText = "清空全部单词"
                alert.informativeText = "确定要清空所有单词吗？此操作不可恢复。"
                alert.alertStyle = .warning
                alert.addButton(withTitle: "清空")
                alert.addButton(withTitle: "取消")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    viewModel.removeAll()
                }
            } label: {
                Text("清空全部")
            }
            .buttonStyle(.plain)
            .font(Typography.caption)
            .tint(.red)
            .foregroundStyle(.red)
            
            Spacer()
            
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("退出")
                    + Text(" (⌘Q)")
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
            .font(Typography.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, Spacing.extraLarge)
        .padding(.vertical, Spacing.large)
    }
}

#Preview {
    BottomBarView()
        .environmentObject(WordListViewModel())
} 
