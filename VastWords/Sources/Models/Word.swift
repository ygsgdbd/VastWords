import Foundation
import CoreStore

// MARK: - Word 模型
final class Word: CoreStoreObject {
    // MARK: - 属性
    @Field.Stored("text")
    var text: String = ""
    
    @Field.Stored("count")
    var count: Int = 0
    
    @Field.Stored("stars")
    var stars: Int = 0
    
    @Field.Stored("createdAt")
    var createdAt: Date = .init()
    
    @Field.Stored("updatedAt")
    var updatedAt: Date = .init()
    
    // MARK: - 配置
    public class var uniqueConstraints: [[String]] {
        return [
            ["text"] // 单词文本必须唯一
        ]
    }
} 