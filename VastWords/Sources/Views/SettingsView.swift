import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: WordListViewModel
    
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: Spacing.large) {
            GridRow {
                // 左侧标题和副标题
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("导出所有")
                        .font(Typography.title)
                    
                    Text("支持导出词库数据")
                        .font(Typography.subtitle)
                        .foregroundStyle(.secondary)
                }
                .gridCellColumns(1)
                
                // 右侧功能区域
                HStack(spacing: Spacing.medium) {
                    Button(action: {
                        viewModel.exportToTxt()
                    }) {
                        Text("导出 TXT")
                            .font(Typography.button)
                    }
                    .buttonStyle(.borderless)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .gridCellColumns(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.extraLarge)
    }
}

#Preview {
    SettingsView()
        .environmentObject(WordListViewModel())
        .frame(width: 300)
} 
