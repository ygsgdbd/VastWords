import Foundation
import SwiftUI
import Combine
import Defaults
import ServiceManagement

extension Defaults.Keys {
    static let showStarredOnly = Key<Bool>("showStarredOnly", default: false)
    static let launchAtLogin = Key<Bool>("launchAtLogin", default: false)
}

/// 单词列表项
struct WordListItem: Identifiable {
    let id: String
    let text: String
    let count: Int
    let stars: Int
    let createdAt: Date
    let updatedAt: Date
    let definition: String?
}

/// 单词列表视图模型
@MainActor
final class WordListViewModel: ObservableObject {
    /// 单词仓库
    private let repository: WordRepository
    
    /// 开机启动的 Helper Bundle ID
    private let launchHelperBundleId = "com.vastwords.LaunchHelper"
    
    /// 单词列表
    @Published private(set) var items: [WordListItem] = []
    /// 搜索文本
    @Published var searchText: String = ""
    /// 是否显示搜索清除按钮
    @Published private(set) var showsClearButton = false
    /// 是否只显示星标单词
    @Published var showStarredOnly = false {
        didSet {
            Defaults[.showStarredOnly] = showStarredOnly
            refreshList()
        }
    }
    /// 是否显示释义
    @Published var showDefinition = true
    /// 是否开机启动
    @Published var launchAtLogin = false {
        didSet {
            // 避免重复触发
            guard oldValue != launchAtLogin else { return }
            
            Task { @MainActor in
                do {
                    if launchAtLogin {
                        if SMAppService.mainApp.status == .enabled {
                            return  // 已经启用，不需要重复操作
                        }
                        try await SMAppService.mainApp.register()
                    } else {
                        if SMAppService.mainApp.status == .notRegistered {
                            return  // 已经禁用，不需要重复操作
                        }
                        try await SMAppService.mainApp.unregister()
                    }
                    // 操作成功后才保存状态
                    Defaults[.launchAtLogin] = launchAtLogin
                } catch {
                    print("⚠️ Failed to \(launchAtLogin ? "enable" : "disable") launch at login: \(error)")
                    // 如果设置失败，直接设置属性值，避免触发 didSet
                    self.launchAtLogin = oldValue
                }
            }
        }
    }
    /// 最近12小时的统计数据
    @Published private(set) var hourlyStatistics: [HourlyStatistics] = []
    
    /// 单词总数
    var totalCount: Int { items.count }
    /// 星标单词数量
    var starredCount: Int { items.filter { $0.stars > 0 }.count }
    /// 第一个单词的时间
    var firstWordDate: Date? { items.last?.createdAt }
    
    /// 获取相对时间描述
    var relativeTimeDescription: String? {
        guard let date = firstWordDate else { return nil }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
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
        
        // 从系统获取实际的开机启动状态
        let isEnabled = (try? SMAppService.mainApp.status == .enabled) ?? false
        self.launchAtLogin = isEnabled  // 先设置属性
        Defaults[.launchAtLogin] = isEnabled  // 再保存状态
        
        // 从 Defaults 读取星标筛选状态
        self.showStarredOnly = Defaults[.showStarredOnly]
        
        setupBindings()
        loadWords()
        loadStatistics()
        
        // 监听单词保存通知
        NotificationCenter.default.publisher(for: .wordsDidSave)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.loadWords()
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
                self?.refreshList()
            }
            .store(in: &cancellables)
        
        // 监是否显示清除按钮
        $searchText
            .map { !$0.isEmpty }
            .assign(to: \.showsClearButton, on: self)
            .store(in: &cancellables)
    }
    
    /// 刷新列表，考虑搜索和星标状态
    private func refreshList() {
        if searchText.isEmpty {
            if showStarredOnly {
                loadStarredWords()
            } else {
                loadWords()
            }
        } else {
            search(searchText)
        }
    }
    
    /// 加载最近12小时的统计数据
    private func loadStatistics() {
        do {
            let now = Date()
            let calendar = Calendar.current
            
            // 创建最近24小时的时间点
            let hours = (0...23).map { hourOffset in
                calendar.date(byAdding: .hour, value: -hourOffset, to: now)!
            }.reversed()
            
            // 获取每个小时的单词数量
            hourlyStatistics = try hours.map { hour in
                let startOfHour = calendar.startOfHour(for: hour)
                let endOfHour = calendar.date(byAdding: .hour, value: 1, to: startOfHour)!
                let count = try repository.getWordCount(from: startOfHour, to: endOfHour)
                print("📊 Statistics for \(startOfHour): \(count) words")
                return HourlyStatistics(hour: startOfHour, count: count)
            }
            
            print("📊 Total statistics loaded: \(hourlyStatistics.count) hours")
        } catch {
            print("⚠️ Failed to load statistics: \(error)")
            hourlyStatistics = []
        }
    }
    
    /// 加载所有单词
    func loadWords() {
        Task {
            do {
                let words = try repository.getAll()
                var newItems: [WordListItem] = []
                
                for word in words {
                    let definition = await SystemDictionaryService.shared.lookup(word.text)
                    newItems.append(WordListItem(
                        id: word.text,
                        text: word.text,
                        count: word.count,
                        stars: word.stars,
                        createdAt: word.createdAt,
                        updatedAt: word.updatedAt,
                        definition: definition
                    ))
                }
                
                items = newItems
            } catch {
                print("⚠️ Failed to load words: \(error)")
            }
        }
    }
    
    /// 加载星标单词
    private func loadStarredWords() {
        Task {
            do {
                let words = try repository.getStarred()
                var newItems: [WordListItem] = []
                
                for word in words {
                    let definition = await SystemDictionaryService.shared.lookup(word.text)
                    newItems.append(WordListItem(
                        id: word.text,
                        text: word.text,
                        count: word.count,
                        stars: word.stars,
                        createdAt: word.createdAt,
                        updatedAt: word.updatedAt,
                        definition: definition
                    ))
                }
                
                items = newItems
            } catch {
                print("⚠️ Failed to load starred words: \(error)")
            }
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
        Task {
            do {
                var words = try repository.search(query)
                
                // 果开启了星标筛选，显示星标单词
                if showStarredOnly {
                    words = words.filter { $0.stars > 0 }
                }
                
                var newItems: [WordListItem] = []
                
                for word in words {
                    let definition = await SystemDictionaryService.shared.lookup(word.text)
                    newItems.append(WordListItem(
                        id: word.text,
                        text: word.text,
                        count: word.count,
                        stars: word.stars,
                        createdAt: word.createdAt,
                        updatedAt: word.updatedAt,
                        definition: definition
                    ))
                }
                
                items = newItems
            } catch {
                print("⚠️ Failed to search words: \(error)")
            }
        }
    }
    
    /// 清除搜索文本
    func clearSearch() {
        searchText = ""
    }
}

private extension Calendar {
    func startOfHour(for date: Date) -> Date {
        let components = dateComponents([.year, .month, .day, .hour], from: date)
        return self.date(from: components) ?? date
    }
} 
