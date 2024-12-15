import XCTest
@testable import VastWords

final class WordExtractorTests: XCTestCase {
    var extractor: WordExtractor!
    
    override func setUp() {
        super.setUp()
        extractor = WordExtractor.shared
    }
    
    override func tearDown() {
        extractor = nil
        super.tearDown()
    }
    
    // MARK: - 基本功能测试
    
    func testExtractEmptyText() {
        let result = extractor.extract(from: "")
        XCTAssertTrue(result.isEmpty, "空文本应该返回空集合")
    }
    
    func testExtractSingleWord() {
        let result = extractor.extract(from: "hello")
        XCTAssertEqual(result, ["hello"], "应该正确提取单个单词")
    }
    
    func testExtractMultipleWords() {
        let result = extractor.extract(from: "hello world")
        XCTAssertEqual(result, ["hello", "world"], "应该正确提取多个单词")
    }
    
    // MARK: - 词形还原测试
    
    func testLemmatization() {
        let result = extractor.extract(from: "running runs ran")
        XCTAssertEqual(result, ["run"], "应该将所有动词形式还原为原形")
        
        let result2 = extractor.extract(from: "mice mouse")
        XCTAssertEqual(result2, ["mouse"], "应该将复数形式还原为单数")
    }
    
    // MARK: - 语言检测测试
    
    func testNonEnglishText() {
        let result = extractor.extract(from: "你好世界")
        XCTAssertTrue(result.isEmpty, "非英文文本应该返回空集合")
        
        let result2 = extractor.extract(from: "Bonjour le monde")
        XCTAssertTrue(result2.isEmpty, "法语文本应该返回空集合")
    }
    
    func testMixedLanguageText() {
        let result = extractor.extract(from: "hello 世界 world")
        XCTAssertEqual(result, ["hello", "world"], "应该只提取英文单词")
    }
    
    // MARK: - 特殊情况测试
    
    func testPunctuation() {
        let result = extractor.extract(from: "hello, world! How are you?")
        XCTAssertEqual(result, ["hello", "world", "how", "be", "you"], "应该正确处理标点符号")
    }
    
    func testWhitespace() {
        let result = extractor.extract(from: "  hello   world  ")
        XCTAssertEqual(result, ["hello", "world"], "应该正确处理空白字符")
    }
    
    func testCase() {
        let result = extractor.extract(from: "Hello WORLD")
        XCTAssertEqual(result, ["hello", "world"], "应该将所有单词转换为小写")
    }
    
    // MARK: - 复杂文本测试
    
    func testComplexText() {
        let text = """
        Hello, World! This is a complex text with multiple sentences.
        It includes numbers like 123 and special characters @#$.
        Some words are UPPERCASE, some are lowercase, and some are Mixed.
        """
        
        let result = extractor.extract(from: text)
        let expectedWords = [
            "hello", "world", "this", "be", "complex", "text", "with", "multiple",
            "sentence", "it", "include", "number", "like", "and", "special",
            "character", "some", "word", "uppercase", "lowercase", "mixed"
        ]
        
        for word in expectedWords {
            XCTAssertTrue(result.contains(word), "复杂文本中应该包含单词: \(word)")
        }
    }
} 