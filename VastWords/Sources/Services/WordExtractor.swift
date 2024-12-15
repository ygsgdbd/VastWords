import Foundation
import NaturalLanguage

/// 单词提取工具
final class WordExtractor {
    static let shared = WordExtractor()
    
    private let englishLetters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz")
    
    private init() {}
    
    /// 从文本中提取英文单词
    /// - Parameter text: 要处理的文本
    /// - Returns: 提取的单词数组（已词形还原）
    func extract(from text: String) -> Set<String> {
        guard !text.isEmpty else { return [] }
        
        var words = Set<String>()
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType, .lemma], options: 0)
        tagger.string = text
        
        // 如果是单个单词，直接处理
        if !text.contains(" ") {
            let word = text.trimmingCharacters(in: .whitespaces).lowercased()
            if !word.isEmpty && word.unicodeScalars.allSatisfy({ englishLetters.contains($0) }) {
                words.insert(word)
            }
            return words
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace]
        
        // 分词并获取词形还原
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { tag, tokenRange, stop in
            guard let wordRange = Range(tokenRange, in: text) else { return }
            
            let word = text[wordRange].trimmingCharacters(in: .whitespaces).lowercased()
            guard !word.isEmpty && word.unicodeScalars.allSatisfy({ self.englishLetters.contains($0) }) else { return }
            
            // 使用词形还原或原始单词
            if let lemma = tag?.rawValue.lowercased(), !lemma.isEmpty {
                words.insert(lemma)
            } else {
                words.insert(word)
            }
        }
        
        return words
    }
} 
