import Foundation
import AppKit

/// 金山词典 API 响应模型
struct IcibaResponse: Codable {
    let message: [IcibaWord]
    let status: Int
}

struct IcibaWord: Codable {
    let key: String
    let paraphrase: String
    let value: Int
}

/// 词典服务
final class DictionaryService {
    static let shared = DictionaryService()
    
    /// URLSession 配置
    private let session: URLSession
    
    private init() {
        // 配置 URLCache
        let cache = URLCache(memoryCapacity: 10 * 1024 * 1024,  // 10MB 内存缓存
                           diskCapacity: 50 * 1024 * 1024)       // 50MB 磁盘缓存
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        
        self.session = URLSession(configuration: config)
    }
    
    /// 查询单词释义
    /// - Parameter word: 要查询的单词
    /// - Returns: 单词释义，如果没有找到则返回 nil
    func lookup(_ word: String) async -> String? {
        // 构建请求 URL
        guard let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://dict-mobile.iciba.com/interface/index.php?c=word&m=getsuggest&nums=1&is_need_mean=0&word=\(encodedWord)") else {
            return nil
        }
        
        do {
            let (data, _) = try await session.data(from: url)
            let response = try JSONDecoder().decode(IcibaResponse.self, from: data)
            
            // 处理响应
            if let firstWord = response.message.first {
                return firstWord.paraphrase
            }
        } catch {
            print("词典查询错误: \(error)")
        }
        
        return nil
    }
    
    /// 清除缓存
    func clearCache() {
        session.configuration.urlCache?.removeAllCachedResponses()
    }
    
    /// 在词典应用中查看单词
    func lookupInDictionary(_ word: String) {
        let workspace = NSWorkspace.shared
        let url = URL(string: "dict://\(word)")!
        workspace.open(url)
    }
}
