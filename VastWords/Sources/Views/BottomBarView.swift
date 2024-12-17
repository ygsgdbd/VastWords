import SwiftUI

struct BottomBarView: View {
    @EnvironmentObject private var viewModel: WordListViewModel
    
    private let repositoryURL = URL(string: "https://github.com/rainbow911/VastWords")!
    
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
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                    Text("清空全部")
                }
            }
            .buttonStyle(.plain)
            .font(Typography.caption)
            .tint(.red)
            .foregroundStyle(.red)
            
            Button {
                NSWorkspace.shared.open(repositoryURL)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "link")
                    Text("代码仓库")
                }
            }
            .buttonStyle(.plain)
            .font(Typography.caption)
            .foregroundColor(.secondary)
            
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
        .environmentObject(WordListViewModel(repository: .shared))
} 
