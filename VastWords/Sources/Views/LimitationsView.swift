import SwiftUI

/// 使用限制说明视图
struct LimitationsView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
            Text("文本长度上限 10,000 字符，单词长度 2-45 字符")
        }
        .foregroundColor(.primary)
        .padding(.vertical, 8)
    }
}

#Preview {
    LimitationsView()
} 
