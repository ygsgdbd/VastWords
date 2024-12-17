import Foundation
import CoreStore

@MainActor
final class WordRepository {
    static let shared = WordRepository()
    
    private let dataStack: DataStack
    
    private init() {
        dataStack = DataStack(
            CoreStoreSchema(
                modelVersion: "V1",
                entities: [
                    Entity<Word>("Word")
                ]
            )
        )
        
        do {
            try dataStack.addStorageAndWait(
                SQLiteStore(
                    fileName: "words.sqlite",
                    localStorageOptions: .allowSynchronousLightweightMigration
                )
            )
        } catch {
            print("⚠️ Failed to add storage: \(error)")
        }
    }
    
    /// 保存或更新单词
    func save(_ word: String, count: Int = 1, stars: Int = 0) throws {
        try dataStack.perform { transaction in
            if let existingWord = try transaction.fetchOne(
                From<Word>()
                    .where(Where<Word>("text == %@", word))
            ) {
                existingWord.count += count
                existingWord.updatedAt = Date()
            } else {
                let newWord = transaction.create(Into<Word>())
                newWord.text = word
                newWord.count = count
                newWord.stars = stars
                newWord.createdAt = Date()
                newWord.updatedAt = Date()
            }
        }
    }
    
    /// 更新单词星级（不更新时间）
    func updateStars(for word: String, stars: Int) throws {
        try dataStack.perform { transaction in
            if let existingWord = try transaction.fetchOne(
                From<Word>()
                    .where(Where<Word>("text == %@", word))
            ) {
                existingWord.stars = stars
            }
        }
    }
    
    /// 获取单词
    func get(_ word: String) throws -> Word? {
        return try dataStack.fetchOne(
            From<Word>()
                .where(Where<Word>("text == %@", word))
        )
    }
    
    /// 获取所有单词
    func getAll() throws -> [Word] {
        return try dataStack.fetchAll(
            From<Word>()
                .orderBy(.init(NSSortDescriptor(key: "updatedAt", ascending: false)))
        )
    }
    
    /// 获取星标单词
    func getStarred() throws -> [Word] {
        return try dataStack.fetchAll(
            From<Word>()
                .where(Where<Word>("stars > 0"))
                .orderBy(.init(NSSortDescriptor(key: "updatedAt", ascending: false)))
        )
    }
    
    /// 获取指定时间范围内的单词数量
    func getWordCount(from startDate: Date, to endDate: Date) throws -> Int {
        return try dataStack.fetchCount(
            From<Word>()
                .where(Where<Word>("updatedAt >= %@ AND updatedAt < %@", startDate, endDate))
        )
    }
    
    /// 搜索单词
    func search(_ query: String) throws -> [Word] {
        // 将查询转换为小写并移除多余空格
        let normalizedQuery = query.trimmingCharacters(in: .whitespaces).lowercased()
        
        // 如果查询为空，返回所有单词
        guard !normalizedQuery.isEmpty else {
            return try getAll()
        }
        
        // 构建模糊搜索条件
        let conditions = [
            Where<Word>("text == %@", normalizedQuery),
            Where<Word>("text BEGINSWITH[cd] %@", normalizedQuery),
            Where<Word>("text CONTAINS[cd] %@", normalizedQuery),
            Where<Word>("text LIKE[cd] %@", "*\(normalizedQuery)*")
        ]
        
        // 组合所有搜索条件
        let combinedCondition = conditions.reduce(Where<Word>("FALSEPREDICATE")) { $0 || $1 }
        
        // 执行搜索并按相关性排序
        return try dataStack.fetchAll(
            From<Word>()
                .where(combinedCondition)
                .orderBy(.init(NSSortDescriptor(key: "updatedAt", ascending: false)))
        )
    }
    
    /// 删除单词
    func remove(_ word: String) throws {
        try dataStack.perform { transaction in
            if let existingWord = try transaction.fetchOne(
                From<Word>()
                    .where(Where<Word>("text == %@", word))
            ) {
                try transaction.delete(existingWord)
            }
        }
    }
    
    /// 删除所有单词
    func removeAll() throws {
        try dataStack.perform { transaction in
            try transaction.deleteAll(From<Word>())
        }
    }
    
    /// 批量保存单词
    func batchSave(_ words: Set<String>) throws {
        try dataStack.perform { transaction in
            for word in words {
                if let existingWord = try transaction.fetchOne(
                    From<Word>()
                        .where(Where<Word>("text == %@", word))
                ) {
                    existingWord.count += 1
                    existingWord.updatedAt = Date()
                } else {
                    let newWord = transaction.create(Into<Word>())
                    newWord.text = word
                    newWord.count = 1
                    newWord.createdAt = Date()
                    newWord.updatedAt = Date()
                }
            }
        }
    }
} 
