import Foundation
import SwiftUI
import Combine
import Defaults
import ServiceManagement
import SwifterSwift

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
            // 在属性观察器中创建新任务来处理异步操作
            Task {
                await refreshList()
            }
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
                    try await updateLaunchAtLogin(launchAtLogin)
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
    /// 所有单词总数（不受筛选影响）
    private(set) var allWordsCount: Int = 0
    /// 第一个单词的时间
    @MainActor
    var firstWordDate: Date? {
        do {
            return try repository.getAll().last?.createdAt
        } catch {
            print("⚠️ Failed to get first word date: \(error)")
            return nil
        }
    }
    
    /// 获取相对时间描述
    @MainActor
    var relativeTimeDescription: String? {
        guard let date = firstWordDate else { return nil }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    /// 导出单词列表到文本文件
    func exportToTxt(starredOnly: Bool = false) {
        Task { @MainActor in
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
    }
    
    init(repository: WordRepository) {
        self.repository = repository
        
        // 从系统获取实际的开机启动状态
        let isEnabled = SMAppService.mainApp.status == .enabled
        self.launchAtLogin = isEnabled
        Defaults[.launchAtLogin] = isEnabled
        
        // 从 Defaults 读取星标筛选状态
        self.showStarredOnly = Defaults[.showStarredOnly]
        
        setupBindings()
    }
    
    private func setupBindings() {
        // 监听搜索文本变化
        $searchText
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                // 在闭包中创建新任务来处理异步操作
                guard let self = self else { return }
                Task {
                    await self.refreshList()
                }
            }
            .store(in: &cancellables)
        
        // 监听是否显示清除按钮
        $searchText
            .map { !$0.isEmpty }
            .assign(to: \.showsClearButton, on: self)
            .store(in: &cancellables)
    }
    
    /// 刷新列表，考虑搜索和星标状态
    private func refreshList() async {
        if searchText.isEmpty {
            if showStarredOnly {
                await loadStarredWords()
            } else {
                await loadWords()
            }
        } else {
            await search(searchText)
        }
    }
    
    /// 加载最近12小时的统计数据
    func loadStatistics() async {
        do {
            let now = Date()
            let calendar = Calendar.current
            
            // 创建最近24小时的时间点
            let hours = (0...23).map { hourOffset in
                calendar.date(byAdding: .hour, value: -hourOffset, to: now)!
            }.reversed()
            
            // 获取每个小时的单词数量
            hourlyStatistics = try await withThrowingTaskGroup(of: HourlyStatistics.self) { group in
                for hour in hours {
                    group.addTask { @MainActor in
                        let startOfHour = calendar.startOfHour(for: hour)
                        let endOfHour = calendar.date(byAdding: .hour, value: 1, to: startOfHour)!
                        let count = try self.repository.getWordCount(from: startOfHour, to: endOfHour)
                        return HourlyStatistics(hour: startOfHour, count: count)
                    }
                }
                
                var statistics: [HourlyStatistics] = []
                for try await stat in group {
                    statistics.append(stat)
                }
                return statistics.sorted { $0.hour < $1.hour }
            }
            
            print("📊 Total statistics loaded: \(hourlyStatistics.count) hours")
        } catch {
            print("⚠️ Failed to load statistics: \(error)")
            hourlyStatistics = []
        }
    }
    
    /// 加载所有单词
    func loadWords() async {
        do {
            // 获取数据
            let words = try repository.getAll()
            
            // 并发处理定义查询
            items = try await words.concurrentMap { word in
                let definition = await SystemDictionaryService.shared.lookup(word.text)
                return word.toListItem(definition: definition)
            }
        } catch {
            print("⚠️ Failed to load words: \(error)")
        }
    }
    
    /// 加载星标单词
    private func loadStarredWords() async {
        do {
            // 获取数据
            let words = try repository.getStarred()
            
            items = try await words.concurrentMap { word in
                let definition = await SystemDictionaryService.shared.lookup(word.text)
                return word.toListItem(definition: definition)
            }
        } catch {
            print("⚠️ Failed to load starred words: \(error)")
        }
    }
    
    /// 更新单词星级
    func updateStars(for wordId: String, stars: Int) {
        Task { @MainActor in
            do {
                try repository.updateStars(for: wordId, stars: stars)
                await refreshList()
                await loadStatistics()
            } catch {
                print("⚠️ Failed to update stars: \(error)")
            }
        }
    }
    
    /// 删除单词
    func remove(_ word: String) {
        Task { @MainActor in
            do {
                try repository.remove(word)
                await refreshList()
                await loadStatistics()
            } catch {
                print("⚠️ Failed to remove word: \(error)")
            }
        }
    }
    
    /// 清空所有单词
    func removeAll() {
        Task { @MainActor in
            do {
                try repository.removeAll()
                showStarredOnly = false
                await loadWords()
                await loadStatistics()
            } catch {
                print("⚠️ Failed to remove all words: \(error)")
            }
        }
    }
    
    /// 搜索单词
    private func search(_ query: String) async {
        do {
            // 获取和过滤数据
            var words = try repository.search(query)
            if self.showStarredOnly {
                words = words.filter { $0.stars > 0 }
            }
            
            items = try await words.concurrentMap { word in
                let definition = await SystemDictionaryService.shared.lookup(word.text)
                return word.toListItem(definition: definition)
            }
        } catch {
            print("⚠️ Failed to search words: \(error)")
        }
    }
    
    /// 清除搜索文本
    func clearSearch() {
        searchText = ""
    }
    
    /// 更新开机启动状态
    private func updateLaunchAtLogin(_ enabled: Bool) async throws {
        if enabled {
            if SMAppService.mainApp.status == .enabled {
                return  // 已经启用，不需要重复操作
            }
            try SMAppService.mainApp.register()
        } else {
            if SMAppService.mainApp.status == .notRegistered {
                return  // 已经禁用，不需要重复操作
            }
            try await SMAppService.mainApp.unregister()
        }
    }
}

private extension Calendar {
    func startOfHour(for date: Date) -> Date {
        let components = dateComponents([.year, .month, .day, .hour], from: date)
        return self.date(from: components) ?? date
    }
}

// 添加 Word 的扩展方法
private extension Word {
    func toListItem(definition: String?) -> WordListItem {
        WordListItem(
            id: text,
            text: text,
            count: count,
            stars: stars,
            createdAt: createdAt,
            updatedAt: updatedAt,
            definition: definition
        )
    }
}

// 添加数组的异步映射扩展
private extension Array {
    func concurrentMap<T>(_ transform: @escaping (Element) async throws -> T) async throws -> [T] {
        try await withThrowingTaskGroup(of: (Int, T).self) { group in
            // 添加所有任务到组
            for (index, element) in enumerated() {
                group.addTask {
                    let result = try await transform(element)
                    return (index, result)
                }
            }
            
            // 收集结果并保持顺序
            var results = [(Int, T)]()
            for try await result in group {
                results.append(result)
            }
            
            return results
                .sorted { $0.0 < $1.0 }
                .map { $0.1 }
        }
    }
} 
