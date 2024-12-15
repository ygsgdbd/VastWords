import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: WordListViewModel
    
    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: Spacing.large) {
            GridRow {
                // 左侧标题和副标题
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("导出")
                        .font(Typography.subtitle)
                    
                    Text("支持导出词库数据")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .gridCellColumns(1)
                
                // 右侧功能区域
                HStack(spacing: Spacing.medium) {
                    Button(action: {
                        viewModel.exportToTxt(starredOnly: true)
                    }) {
                        Text("导出星标")
                            .font(Typography.caption)
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: {
                        viewModel.exportToTxt()
                    }) {
                        Text("导出全部")
                            .font(Typography.caption)
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
