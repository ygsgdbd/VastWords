import Foundation
import SwiftUI
import Combine

/// 单词列表项
struct WordListItem: Identifiable {
    let id: String
    let text: String
    let count: Int
    let stars: Int
    let createdAt: Date
    let updatedAt: Date
}

/// 单词列表视图模型
@MainActor
final class WordListViewModel: ObservableObject {
    /// 单词仓库
    private let repository: WordRepository
    
    /// 单词列表
    @Published private(set) var items: [WordListItem] = []
    /// 搜索文本
    @Published var searchText: String = ""
    /// 是否显示搜索清除按钮
    @Published private(set) var showsClearButton = false
    /// 是否只显示星标单词
    @Published var showStarredOnly = false
    /// 最近12小时的统计数据
    @Published private(set) var hourlyStatistics: [HourlyStatistics] = []
    
    /// 单词总数
    var totalCount: Int { items.count }
    /// 第一个单词的时间
    var firstWordDate: Date? { items.last?.createdAt }
    
    private var cancellables = Set<AnyCancellable>()
    
    /// 导出单词列表到文本文件
    func exportToTxt(starredOnly: Bool = false) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.plainText]
        savePanel.nameFieldStringValue = "words\(starredOnly ? "_starred" : "")_\(timestamp).txt"
        savePanel.title = "导出\(starredOnly ? "星标" : "")单词列表"
        savePanel.message = "选择保存位置"
        savePanel.prompt = "导出"
        
        guard savePanel.runModal() == .OK,
              let url = savePanel.url else {
            return
        }
        
        do {
            // 获取单词并按时间倒序排序
            let words = try (starredOnly ? repository.getStarred() : repository.getAll())
                .sorted { $0.updatedAt > $1.updatedAt }
                .map { $0.text }
                .joined(separator: "\n")
            
            try words.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("⚠️ Failed to export words: \(error)")
        }
    }
    
    init(repository: WordRepository = .shared) {
        self.repository = repository
        setupBindings()
        loadWords()
        loadStatistics()
        
        // 每分钟更新一次统计数据
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.loadStatistics()
            }
            .store(in: &cancellables)
    }
    
    private func setupBindings() {
        // 监听搜索文本变化
        $searchText
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if query.isEmpty {
                    self?.loadWords()
                } else {
                    self?.search(query)
                }
            }
            .store(in: &cancellables)
        
        // 监听是否显示清除按钮
        $searchText
            .map { !$0.isEmpty }
            .assign(to: \.showsClearButton, on: self)
            .store(in: &cancellables)
            
        // 监听星标筛选变化
        $showStarredOnly
            .sink { [weak self] showStarred in
                if showStarred {
                    self?.loadStarredWords()
                } else {
                    self?.loadWords()
                }
            }
            .store(in: &cancellables)
    }
    
    /// 加载最近12小时的统计数据
    private func loadStatistics() {
        do {
            let now = Date()
            let calendar = Calendar.current
            
            // 创建最近12小时的时间点
            let hours = (0...11).map { hourOffset in
                calendar.date(byAdding: .hour, value: -hourOffset, to: now)!
            }.reversed()
            
            // 获取每个小时的单词数量
            hourlyStatistics = try hours.map { hour in
                let startOfHour = calendar.startOfHour(for: hour)
                let endOfHour = calendar.date(byAdding: .hour, value: 1, to: startOfHour)!
                let count = try repository.getWordCount(from: startOfHour, to: endOfHour)
                return HourlyStatistics(hour: startOfHour, count: count)
            }
        } catch {
            print("⚠️ Failed to load statistics: \(error)")
        }
    }
    
    /// 清除搜索文本
    func clearSearch() {
        searchText = ""
    }
    
    /// 加载所有单词
    func loadWords() {
        do {
            let words = try repository.getAll()
            items = words.map { word in
                WordListItem(
                    id: word.text,
                    text: word.text,
                    count: word.count,
                    stars: word.stars,
                    createdAt: word.createdAt,
                    updatedAt: word.updatedAt
                )
            }
        } catch {
            print("⚠️ Failed to load words: \(error)")
        }
    }
    
    /// 加载星标单词
    private func loadStarredWords() {
        do {
            let words = try repository.getStarred()
            items = words.map { word in
                WordListItem(
                    id: word.text,
                    text: word.text,
                    count: word.count,
                    stars: word.stars,
                    createdAt: word.createdAt,
                    updatedAt: word.updatedAt
                )
            }
        } catch {
            print("⚠️ Failed to load starred words: \(error)")
        }
    }
    
    /// 更新单词星级
    func updateStars(for wordId: String, stars: Int) {
        do {
            try repository.updateStars(for: wordId, stars: stars)
            if showStarredOnly {
                loadStarredWords()
            } else {
                loadWords()
            }
        } catch {
            print("⚠️ Failed to update stars: \(error)")
        }
    }
    
    /// 删除单词
    func remove(_ word: String) {
        do {
            try repository.remove(word)
            if showStarredOnly {
                loadStarredWords()
            } else {
                loadWords()
            }
            loadStatistics()
        } catch {
            print("⚠️ Failed to remove word: \(error)")
        }
    }
    
    /// 清空所有单词
    func removeAll() {
        do {
            try repository.removeAll()
            showStarredOnly = false
            loadWords()
            loadStatistics()
        } catch {
            print("⚠️ Failed to remove all words: \(error)")
        }
    }
    
    /// 搜索单词
    private func search(_ query: String) {
        do {
            let words = try repository.search(query)
            items = words.map { word in
                WordListItem(
                    id: word.text,
                    text: word.text,
                    count: word.count,
                    stars: word.stars,
                    createdAt: word.createdAt,
                    updatedAt: word.updatedAt
                )
            }
        } catch {
            print("⚠️ Failed to search words: \(error)")
        }
    }
}

private extension Calendar {
    func startOfHour(for date: Date) -> Date {
        let components = dateComponents([.year, .month, .day, .hour], from: date)
        return self.date(from: components) ?? date
    }
} 