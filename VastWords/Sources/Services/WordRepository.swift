import Foundation

final class WordRepository {
    static let shared = WordRepository()
    private static let suiteName = "top.ygsgdbd.vastwords.words.v1"
    
    private let defaults = UserDefaults(suiteName: WordRepository.suiteName)!
    private var words: [String: WordStats] = [:]
    
    private init() {
        let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let preferencesDir = libraryDir.appendingPathComponent("Preferences")
        let plistPath = preferencesDir.appendingPathComponent("\(WordRepository.suiteName).plist")
        print("🗂️ UserDefaults path: \(plistPath.path)")
        loadWords()
    }
    
    private func loadWords() {
        for key in defaults.dictionaryRepresentation().keys {
            if let data = defaults.data(forKey: key),
               let stats = try? JSONDecoder().decode(WordStats.self, from: data) {
                words[key] = stats
            }
        }
    }
    
    func save(_ stats: WordStats, for word: String) {
        words[word] = stats
        if let data = try? JSONEncoder().encode(stats) {
            defaults.set(data, forKey: word)
        }
    }
    
    func get(_ word: String) -> WordStats? {
        return words[word]
    }
    
    func getAll() -> [String: WordStats] {
        return words
    }
    
    func remove(_ word: String) {
        words.removeValue(forKey: word)
        defaults.removeObject(forKey: word)
    }
    
    func removeAll() {
        words.removeAll()
        defaults.removePersistentDomain(forName: WordRepository.suiteName)
    }
} 