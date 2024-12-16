import Foundation
import Vision
import AppKit

/// OCR 相关错误
enum OCRError: Error {
    case noImageInClipboard
    case invalidImage
    case recognitionFailed(Error)
}

actor OCRService {
    static let shared = OCRService()
    
    private init() {}
    
    /// 从剪贴板图片中提取文本
    /// - Returns: 提取的文本
    /// - Throws: OCRError
    func extractTextFromClipboard() async throws -> String? {
        guard let image = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage else {
            throw OCRError.noImageInClipboard
        }
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.invalidImage
        }
        
        return try await extractText(from: cgImage)
    }
    
    /// 从图片中提取文本
    /// - Parameter cgImage: 要处理的图片
    /// - Returns: 提取的文本
    /// - Throws: OCRError
    private func extractText(from cgImage: CGImage) async throws -> String? {
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLanguages = ["en"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
            guard let observations = request.results else { return nil }
            
            return observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
        } catch {
            throw OCRError.recognitionFailed(error)
        }
    }
} 