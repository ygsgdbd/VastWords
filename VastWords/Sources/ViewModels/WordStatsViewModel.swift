import Foundation
import SwiftUI

class WordStatsViewModel: ObservableObject {
    @Published var totalWordCount: Int = 0
    @Published var topWords: [(word: String, stats: WordStats)] = []
    
    private let repository = WordRepository.shared
    
    init() {
        updateStats()
    }
    
    func updateStats() {
        let allStats = repository.getAll()
        totalWordCount = allStats.count
        
        // 获取出现频率最高的单词
        topWords = allStats.sorted { $0.value.count > $1.value.count }
            .prefix(10)
            .map { ($0.key, $0.value) }
    }
    
    // 获取格式化的日期字符串
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // 获取单词的详细信息
    func getWordDetails(word: String, stats: WordStats) -> String {
        return """
            出现次数：\(stats.count)
            最后见到：\(formatDate(stats.lastSeenDate))
            """
    }
    
    // 删除���词
    func removeWord(_ word: String) {
        repository.remove(word)
        updateStats()
    }
    
    // 清除所有数据
    func clearAllStats() {
        repository.removeAll()
        updateStats()
    }
    
    // 获取单词的使用趋势
    func getWordTrend(for word: String) -> String {
        guard let stats = repository.get(word) else {
            return "无数据"
        }
        
        let daysSinceFirstSeen = Calendar.current.dateComponents([.day], 
            from: stats.lastSeenDate, 
            to: Date()
        ).day ?? 0
        
        if daysSinceFirstSeen == 0 {
            return "今天新学习"
        } else if stats.count == 1 {
            return "仅见过一次"
        } else {
            let frequency = Double(stats.count) / Double(daysSinceFirstSeen + 1)
            return String(format: "平均每天见到 %.1f 次", frequency)
        }
    }
} 