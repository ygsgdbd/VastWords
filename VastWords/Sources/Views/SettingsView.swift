import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: WordListViewModel
    
    var body: some View {
        Grid(alignment: .leading) {
            // 导出设置
            GridRow {
                // 左侧标题和副标题
                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack(spacing: Spacing.small) {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 16)
                            .font(Typography.subtitle)
                        
                        Text("导出单词")
                            .font(Typography.subtitle)
                    }
                    
                    Text("将收集的单词导出为文本文件")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .gridCellColumns(1)
                
                // 右侧功能区域
                HStack(spacing: Spacing.medium) {
                    Button(action: {
                        viewModel.exportToTxt(starredOnly: true)
                    }) {
                        Text("星标（\(viewModel.starredCount)）")
                            .font(Typography.caption)
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: {
                        viewModel.exportToTxt()
                    }) {
                        Text("全部（\(viewModel.totalCount)）")
                            .font(Typography.caption)
                    }
                    .buttonStyle(.borderless)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .gridCellColumns(1)
            }
            
            Divider()
                .gridCellColumns(2)
            
            // 显示设置
            GridRow {
                // 左侧标题和副标题
                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack(spacing: Spacing.small) {
                        Image(systemName: "text.magnifyingglass")
                            .frame(width: 16)
                            .font(Typography.subtitle)
                        
                        Text("显示释义")
                            .font(Typography.subtitle)
                    }
                    
                    Text("在列表中显示系统词典释义")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .gridCellColumns(1)
                
                // 右侧功能区域
                HStack(spacing: Spacing.medium) {
                    Toggle(isOn: $viewModel.showDefinition) {
                        
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .gridCellColumns(1)
            }
            
            Divider()
                .gridCellColumns(2)
            
            // 启动设置
            GridRow {
                // 左侧标题和副标题
                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack(spacing: Spacing.small) {
                        Image(systemName: "power")
                            .frame(width: 16)
                            .font(Typography.subtitle)
                        
                        Text("开机启动")
                            .font(Typography.subtitle)
                    }
                    
                    Text("登录系统时自动启动应用")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
                .gridCellColumns(1)
                
                // 右侧功能区域
                HStack(spacing: Spacing.medium) {
                    Toggle(isOn: $viewModel.launchAtLogin) {
                        
                    }
                    .toggleStyle(.switch)
                    .controlSize(.mini)
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
