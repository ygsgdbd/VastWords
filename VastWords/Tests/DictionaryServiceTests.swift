import XCTest
@testable import VastWords

final class DictionaryServiceTests: XCTestCase {
    var service: DictionaryService!
    
    override func setUp() {
        super.setUp()
        service = DictionaryService.shared
    }
    
    override func tearDown() {
        service.clearCache()
        service = nil
        super.tearDown()
    }
    
    func testLookupValidWord() {
        // 测试查询一个有效的单词
        let definition = service.lookup("hello")
        XCTAssertNotNil(definition, "应该能找到 'hello' 的释义")
        XCTAssertFalse(definition!.isEmpty, "释义不应该为空")
    }
    
    func testLookupInvalidWord() {
        // 测试查询一个无效的单词
        let definition = service.lookup("asdfghjkl")
        XCTAssertNil(definition, "无效单词应该返回 nil")
    }
    
    func testCaching() {
        // 第一次查询
        let firstResult = service.lookup("test")
        XCTAssertNotNil(firstResult, "应该能找到 'test' 的释义")
        
        // 第二次查询应该使用缓存
        let secondResult = service.lookup("test")
        XCTAssertEqual(firstResult, secondResult, "缓存的结果应该相同")
    }
    
    func testCacheClear() {
        // 先查询一个单词
        let firstResult = service.lookup("test")
        XCTAssertNotNil(firstResult)
        
        // 清除缓存
        service.clearCache()
        
        // 再次查询同一个单词
        let secondResult = service.lookup("test")
        XCTAssertNotNil(secondResult)
        // 结果应该相同，但是是重新查询的
        XCTAssertEqual(firstResult, secondResult)
    }
} 