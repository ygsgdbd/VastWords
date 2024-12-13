import Foundation
import NaturalLanguage
import AppKit

final class TextProcessor {
    static let shared = TextProcessor()
    
    private let tagger: NLTagger
    private let spellChecker: NSSpellChecker
    private let repository = WordRepository.shared
    
    // 常用简单词汇集合，这些词通常不需要特别学习
    private let commonWords: Set<String> = [
        "the", "be", "to", "of", "and", "a", "in", "that", "have", "i",
        "it", "for", "not", "on", "with", "he", "as", "you", "do", "at",
        "this", "but", "his", "by", "from", "they", "we", "say", "her", "she",
        "or", "an", "will", "my", "one", "all", "would", "there", "their"
    ]
    
    // 编程相关词汇，这些词在编程上下文中很常见
    private let programmingWords: Set<String> = [
        "var", "let", "func", "class", "struct", "enum", "protocol",
        "interface", "method", "function", "variable", "const", "static",
        "public", "private", "protected", "import", "export", "default",
        "return", "true", "false", "null", "nil", "undefined", "async",
        "await", "try", "catch", "throw", "throws", "error"
    ]
    
    private init() {
        print("TextProcessor: 初始化")
        tagger = NLTagger(tagSchemes: [
            .tokenType,
            .language,
            .lexicalClass,
            .lemma,
            .nameType
        ])
        
        spellChecker = NSSpellChecker.shared
        spellChecker.setLanguage("en")
    }
    
    private func isValidWord(_ word: String) -> Bool {
        // 单词长度检查（避免太短的单词）
        guard word.count > 2 else { return false }
        
        // 过滤常用简单词
        guard !commonWords.contains(word.lowercased()) else { return false }
        
        // 过滤编程相关词汇
        guard !programmingWords.contains(word.lowercased()) else { return false }
        
        // 检查是否包含数字
        guard !word.contains(where: { $0.isNumber }) else { return false }
        
        return true
    }
    
    func process(_ text: String) {
        print("\n=== 开始处理文本 ===")
        
        // 设置分词选项
        let options: NLTagger.Options = [
            .omitPunctuation,
            .omitWhitespace,
            .joinNames,
            .omitOther
        ]
        
        // 检测语言
        tagger.string = text
        guard let dominantLanguage = tagger.dominantLanguage,
              dominantLanguage.rawValue.starts(with: "en") else {
            print("⚠️ 不是英文文本")
            return
        }
        
        // 分词并处理
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                            unit: .word,
                            scheme: .lexicalClass,
                            options: options) { tag, tokenRange in
            let word = String(text[tokenRange]).trimmingCharacters(in: .whitespaces)
            
            // 处理可能的复合词
            let wordsToCheck: [String]
            if word.contains("-") || word.contains("_") {
                wordsToCheck = splitByDelimiters(word)
                print("📝 分隔符单词: \(word)")
            } else if word.contains(where: { $0.isUppercase }) && !word.allSatisfy({ $0.isUppercase }) {
                wordsToCheck = splitCamelCase(word)
                print("📝 驼峰命名: \(word)")
            } else {
                wordsToCheck = [word]
            }
            
            // 处理每个子单词
            for subWord in wordsToCheck {
                guard isValidWord(subWord) else { continue }
                
                // 获取词形还原结果
                let lemmatizer = NLTagger(tagSchemes: [.lemma])
                lemmatizer.string = subWord
                let lemma = lemmatizer.tag(at: subWord.startIndex, unit: .word, scheme: .lemma).0?.rawValue ?? subWord
                
                // 进行拼写检查
                let misspelledRange = spellChecker.checkSpelling(of: subWord, startingAt: 0)
                
                if misspelledRange.location == NSNotFound {
                    // 更新统计信息
                    var stats = repository.get(lemma) ?? WordStats()
                    stats.count += 1
                    stats.lastSeenDate = Date()
                    repository.save(stats, for: lemma)
                    
                    // 打印单词信息
                    print("\n✅ 单词: \(subWord)")
                    if lemma != subWord {
                        print("   原形: \(lemma)")
                    }
                    if let partOfSpeech = tag?.rawValue {
                        print("   词性: \(partOfSpeech)")
                    }
                    print("   出现次数: \(stats.count)")
                } else {
                    // 获取拼写建议
                    if let guesses = spellChecker.guesses(forWordRange: NSRange(location: 0, length: subWord.utf16.count),
                                                        in: subWord,
                                                        language: "en",
                                                        inSpellDocumentWithTag: 0) {
                        print("\n❌ 可能拼写错误: \(subWord)")
                        print("   建议拼写: \(guesses.joined(separator: ", "))")
                    }
                }
            }
            
            return true
        }
        
        print("\n=== 处理完成 ===")
    }
    
    private func splitCamelCase(_ word: String) -> [String] {
        guard !word.isEmpty else { return [] }
        var words: [String] = []
        var currentWord = String(word.first!)
        
        for char in word.dropFirst() {
            if char.isUppercase {
                words.append(currentWord)
                currentWord = String(char)
            } else {
                currentWord.append(char)
            }
        }
        words.append(currentWord)
        return words
    }
    
    private func splitByDelimiters(_ word: String) -> [String] {
        return word.components(separatedBy: CharacterSet(charactersIn: "-_"))
            .filter { !$0.isEmpty }
    }
} 