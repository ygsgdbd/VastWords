import Foundation
import NaturalLanguage
import SwifterSwift

/// 单词提取工具
final class WordExtractor {
    static let shared = WordExtractor()
    
    private init() {
        print("📝 WordExtractor: 初始化")
    }
    
    /// 从文本中提取英文单词
    /// - Parameter text: 要处理的文本
    /// - Returns: 提取的单词数组（已词形还原）
    func extract(from text: String) -> Set<String> {
        guard !text.isEmpty else {
            print("📝 WordExtractor: 输入文本为空")
            return []
        }
        
        print("📝 WordExtractor: 开始处理文本 [\(text.prefix(50))...]")
        
        var words = Set<String>()
        let tagger = NSLinguisticTagger(tagSchemes: [.tokenType, .lemma, .language], options: 0)
        tagger.string = text
        
        // 对于单个单词或短语，不进行语言检测
        if !text.contains(" ") {
            let word = text.trimmingCharacters(in: .whitespaces).lowercased()
            if isValidEnglishWord(word) {
                print("📝 WordExtractor: 单个单词模式，提取到: \(word)")
                words.insert(word)
                return words
            } else {
                print("📝 WordExtractor: 单个单词模式，但不是有效的英文单词: \(word)")
                return []
            }
        }
        
        // 检查是否包含英文（只对多个单词的文本进行检查）
        if let language = tagger.dominantLanguage {
            print("📝 WordExtractor: 检测到语言: \(language)")
            if language != "en" {
                print("📝 WordExtractor: 不是英文文本，跳过处理")
                return []
            }
        } else {
            print("📝 WordExtractor: 无法检测语言")
            return []
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        
        print("📝 WordExtractor: 开始分词和词形还原")
        
        // 分词并获取词形还原
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma, options: options) { tag, tokenRange, stop in
            guard let wordRange = Range(tokenRange, in: text) else { return }
            
            let word = text[wordRange].trimmingCharacters(in: .whitespaces).lowercased()
            guard isValidEnglishWord(word) else {
                print("📝 WordExtractor: 跳过无效单词: \(word)")
                return
            }
            
            // 使用词形还原或原始单词
            if let lemma = tag?.rawValue.lowercased(), !lemma.isEmpty {
                print("📝 WordExtractor: 词形还原 \(word) -> \(lemma)")
                words.insert(lemma)
            } else {
                print("📝 WordExtractor: 使用原始单词: \(word)")
                words.insert(word)
            }
        }
        
        print("📝 WordExtractor: 提取完成，共 \(words.count) 个单词: \(words)")
        return words
    }
    
    /// 检查是否是有效的英文单词
    private func isValidEnglishWord(_ word: String) -> Bool {
        guard !word.isEmpty,
              !word.contains("'"),
              word.rangeOfCharacter(from: .letters) != nil,
              word.allSatisfy({ $0.isLetter }) else {
            return false
        }
        
        let englishLetters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        return word.unicodeScalars.allSatisfy { englishLetters.contains($0) }
    }
} 
