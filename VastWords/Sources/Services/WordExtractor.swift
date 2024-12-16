import Foundation
import AppKit
import NaturalLanguage

/// 单词提取工具
actor WordExtractor {
    static let shared = WordExtractor()
    
    /// 英文字母集合
    private let englishLetters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz")
    
    /// 最小单词长度
    private let minimumWordLength = 2
    
    /// 最大单词长度
    private let maximumWordLength = 45
    
    /// 单次处理的最大文本长度
    private let maxBatchLength = 10000
    
    /// 缓存大小限制
    private let maxCacheSize = 1000
    
    /// 要忽略的常见单词（仅过滤基础功能词）
    private let commonWords: Set<String> = [
        // 冠词
        "a", "an", "the",
        
        // 基础代词
        "i", "you", "he", "she", "it", "we", "they",
        "me", "him", "her", "us", "them",
        "my", "your", "his", "its", "our", "their",
        "this", "that", "these", "those",
        
        // 基础介词
        "in", "on", "at", "to", "for", "of", "with",
        "by", "from", "up", "about", "into", "over",
        
        // 基础连词
        "and", "but", "or", "if", "so",
        
        // 助动词
        "am", "is", "are", "was", "were",
        "have", "has", "had",
        "do", "does", "did",
        
        // 其他功能词
        "not", "yes", "no", "ok", "okay"
    ]
    
    /// 结果缓存
    private var cache = NSCache<NSString, NSSet>()
    
    private let tagger: NSLinguisticTagger
    private let options: NSLinguisticTagger.Options
    
    private init() {
        self.tagger = NSLinguisticTagger(tagSchemes: [.tokenType, .lemma, .language], options: 0)
        self.options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        // 设置缓存限制
        cache.countLimit = maxCacheSize
    }
    
    /// 从文本中提取英文单词
    /// - Parameter text: 要处理的文本
    /// - Returns: 提取的单词数组（已词形还原）
    func extract(from text: String) async -> Set<String> {
        guard !text.isEmpty else { return [] }
        
        // 检查缓存
        if let cached = cache.object(forKey: text as NSString) {
            return cached as! Set<String>
        }
        
        var words = Set<String>()
        
        // 如果是单个单词，直接处理
        if !text.contains(" ") {
            if let word = processWord(text) {
                words.insert(word)
            }
            cache.setObject(words as NSSet, forKey: text as NSString)
            return words
        }
        
        // 检查语言
        tagger.string = text
        let language = tagger.dominantLanguage
        guard language == "en" || language == nil else { return [] }
        
        // 分批并发处理长文本
        let textLength = text.utf16.count
        let batchCount = (textLength + maxBatchLength - 1) / maxBatchLength
        
        await withTaskGroup(of: Set<String>.self) { group in
            for i in 0..<batchCount {
                group.addTask { [self] in
                    let start = i * maxBatchLength
                    let length = min(maxBatchLength, textLength - start)
                    let range = NSRange(location: start, length: length)
                    
                    var batchWords = Set<String>()
                    let localTagger = NSLinguisticTagger(tagSchemes: [.tokenType, .lemma, .language], options: 0)
                    localTagger.string = text
                    
                    // 分词并获取词形还原
                    let semaphore = DispatchSemaphore(value: 0)
                    var tempWords = [(String, String?)]()
                    
                    localTagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { tag, tokenRange, stop in
                        guard let wordRange = Range(tokenRange, in: text) else { return }
                        let word = String(text[wordRange])
                        tempWords.append((word, tag?.rawValue))
                    }
                    
                    // 处理提取的单词
                    for (word, lemma) in tempWords {
                        if let processedWord = processWord(word) {
                            if let lemma = lemma?.lowercased(), !lemma.isEmpty {
                                batchWords.insert(lemma)
                            } else {
                                batchWords.insert(processedWord)
                            }
                        }
                    }
                    
                    return batchWords
                }
            }
            
            // 合并所有批次的结果
            for await batchWords in group {
                words.formUnion(batchWords)
            }
        }
        
        // 缓存结果
        cache.setObject(words as NSSet, forKey: text as NSString)
        return words
    }
    
    /// 处理单个单词
    /// - Parameter word: 原始单词
    /// - Returns: 处理后的单词，如果不符合要求则返回 nil
    nonisolated private func processWord(_ word: String) -> String? {
        let processed = word.trimmingCharacters(in: .whitespaces).lowercased()
        
        // 检查单词是否符合要求
        guard !processed.isEmpty,
              processed.count >= minimumWordLength,
              processed.count <= maximumWordLength,
              processed.unicodeScalars.allSatisfy({ englishLetters.contains($0) }),
              !commonWords.contains(processed) else {
            return nil
        }
        
        return processed
    }
    
    /// 清除缓存
    func clearCache() {
        cache.removeAllObjects()
    }
} 
