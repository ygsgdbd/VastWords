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
                        
                        Divider()
                            .opacity(0.3)
                            .padding(.horizontal, Spacing.extraLarge)
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
    @State private var isWordHovered: Bool = false
    @State private var isDefinitionExpanded: Bool = false
    
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // 第一行：单词、时间、次数
            HStack(alignment: .center, spacing: Spacing.small) {
                Button {
                    SystemDictionaryService.shared.lookupInDictionary(item.text)
                } label: {
                    Text(item.text.capitalized)
                        .font(Typography.title)
                        .foregroundStyle(.primary)
                        .underline(isWordHovered)
                }
                .buttonStyle(.plain)
                .onHover { hovered in
                    isWordHovered = hovered
                    if hovered {
                        NSCursor.pointingHand.set()
                    } else {
                        NSCursor.arrow.set()
                    }
                }
                
                Text("•")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                
                Text(Self.relativeFormatter.localizedString(for: item.updatedAt, relativeTo: Date()))
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                
                Text("•")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                
                Text("\(item.count)次")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                
                Spacer()
                
                // 操作按钮
                if isHovered {
                    HStack(spacing: Spacing.medium) {
                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.text, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .imageScale(.small)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .imageScale(.small)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                    }
                }
            }
            
            // 第二行：星级评分
            HStack(spacing: Spacing.small) {
                // 星级评分
                HStack(spacing: Spacing.tiny) {
                    ForEach(0..<5) { index in
                        Button {
                            onStarTap(index + 1)
                        } label: {
                            Image(systemName: index <= (hoveredStarIndex ?? (item.stars - 1)) ? "star.fill" : "star")
                                .foregroundStyle(index < item.stars ? .yellow : .secondary.opacity(0.4))
                                .imageScale(.small)
                                .font(.system(size: 12))
                                .onHover { isHovered in
                                    hoveredStarIndex = isHovered ? index : nil
                                }
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                    }
                }
                
                Spacer()
            }
            
            // 释义
            if viewModel.showDefinition, let definition = item.definition {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isDefinitionExpanded.toggle()
                    }
                } label: {
                    Text(definition)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(isDefinitionExpanded ? nil : 3)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
        }
        .padding(.horizontal, Spacing.extraLarge)
        .padding(.vertical, Spacing.medium)
    }
}

#Preview {
    WordListView()
        .environmentObject(WordListViewModel())
} 
