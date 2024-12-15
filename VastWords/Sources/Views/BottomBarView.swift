import SwiftUI

struct BottomBarView: View {
    var body: some View {
        HStack {
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
} 
