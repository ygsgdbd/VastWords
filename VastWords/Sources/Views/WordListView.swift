import SwiftUI
import SwiftUIX

/// 单词列表视图
struct WordListView: View {
    @EnvironmentObject private var viewModel: WordListViewModel
    @State private var hoveredWordId: String?
    
    var body: some View {
        VStack(spacing: Spacing.none) {
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .imageScale(.small)
                
                TextField("搜索", text: $viewModel.searchText)
                    .font(Typography.body)
                    .textFieldStyle(.plain)
                
                if viewModel.showsClearButton {
                    Button(action: viewModel.clearSearch) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .imageScale(.small)
                    }
                    .buttonStyle(.plain)
                }
                
                // 星标筛选
                Toggle(isOn: $viewModel.showStarredOnly) {
                    Text("星标")
                        .font(Typography.subtitle)
                        .foregroundStyle(.secondary)
                }
                .toggleStyle(.switch)
                .controlSize(.mini)
            }
            .padding(.horizontal, Spacing.extraLarge)
            .padding(.vertical, Spacing.medium)
            
            Divider()
            
            // 单词列表
            ScrollView {
                LazyVStack(spacing: Spacing.none) {
                    ForEach(viewModel.items) { item in
                        WordRowView(
                            item: item,
                            isHovered: hoveredWordId == item.id,
                            onStarTap: { stars in
                                viewModel.updateStars(for: item.id, stars: stars)
                            },
                            onDelete: {
                                viewModel.remove(item.text)
                            }
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(hoveredWordId == item.id ? Color.gray.opacity(0.1) : Color.clear)
                        )
                        .onHover { isHovered in
                            hoveredWordId = isHovered ? item.id : nil
                        }
                        .onTapGesture {
                            SystemDictionaryService.shared.lookupInDictionary(item.text)
                        }
                        
                        Divider()
                            .opacity(0.2)
                    }
                }
            }
            .scrollIndicators(.visible)
        }
    }
}

/// 单词行视图
struct WordRowView: View {
    @EnvironmentObject private var viewModel: WordListViewModel
    let item: WordListItem
    let isHovered: Bool
    let onStarTap: (Int) -> Void
    let onDelete: () -> Void
    
    @State private var hoveredStarIndex: Int?
    
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // 第一行：单词和出现次数
            HStack(alignment: .center, spacing: Spacing.small) {
                Text(item.text.capitalized)
                    .font(Typography.title)
                    .foregroundStyle(.primary)
                    .onTapGesture {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(item.text, forType: .string)
                    }
                
                Text("•")
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                
                Text(Self.relativeFormatter.localizedString(for: item.updatedAt, relativeTo: Date()))
                    .font(Typography.subtitle)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(item.count)次")
                    .font(Typography.subtitle)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            
            // 第二行：星级评分和删除按钮
            HStack {
                // 星级评分
                HStack(spacing: Spacing.tiny) {
                    ForEach(0..<5) { index in
                        Image(systemName: index <= (hoveredStarIndex ?? (item.stars - 1)) ? "star.fill" : "star")
                            .foregroundStyle(index < item.stars ? .yellow : .secondary.opacity(0.4))
                            .imageScale(.small)
                            .onHover { isHovered in
                                hoveredStarIndex = isHovered ? index : nil
                            }
                            .onTapGesture {
                                onStarTap(index + 1)
                            }
                            .contentShape(Rectangle())
                    }
                }
                
                Spacer()
                
                // 删除按钮
                if isHovered {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .imageScale(.small)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, Spacing.tiny)
            
            // 第三行：释义
            if viewModel.showDefinition, let definition = item.definition {
                Text(definition)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .onTapGesture {
                        SystemDictionaryService.shared.lookupInDictionary(item.text)
                    }
            }
        }
        .padding(.horizontal, Spacing.extraLarge)
        .padding(.vertical, Spacing.large)
    }
}

#Preview {
    WordListView()
        .environmentObject(WordListViewModel())
} 
