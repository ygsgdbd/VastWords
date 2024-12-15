import Foundation
import AppKit
import CoreServices

/// 系统词典服务
final class SystemDictionaryService {
    static let shared = SystemDictionaryService()
    
    /// 缓存词典查询结果
    private let cache: NSCache<NSString, NSString> = {
        let cache = NSCache<NSString, NSString>()
        cache.name = "com.vastwords.dictionary.cache"
        cache.countLimit = 1000 // 最多缓存1000个单词
        return cache
    }()
    
    private init() {}
    
    /// 查询单词释义
    /// - Parameter word: 要查询的单词
    /// - Returns: 单词释义，如果没有找到则返回 nil
    func lookup(_ word: String) async -> String? {
        // 先从缓存中查找
        if let cached = cache.object(forKey: word as NSString) {
            return cached as String
        }
        
        // 缓存未命中，从系统词典查询
        guard let definition = DCSCopyTextDefinition(nil, word as CFString, CFRangeMake(0, word.count)) else {
            return nil
        }
        
        let result = definition.takeRetainedValue() as String
        
        // 缓存查询结果
        cache.setObject(result as NSString, forKey: word as NSString)
        
        return result
    }
    
    /// 在词典应用中查看单词
    func lookupInDictionary(_ word: String) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "dict://\(word)")!
        workspace.open(url)
    }
    
    /// 清除缓存
    func clearCache() {
        cache.removeAllObjects()
    }
} 