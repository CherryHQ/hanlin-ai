//
//  FileContentExtraction.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 8/2/25.
//

import Foundation
import PDFKit       // 用于处理 PDF 文件
import ZIPFoundation // 用于解压 DOCX、PPTX 文件
import CoreXLSX     // 用于解析 XLSX 文件

/// 使用 XMLParser 解析 XML 结构（用于 DOCX、PPTX）
class XMLContentParser: NSObject, XMLParserDelegate {
    var parsedText = ""
    
    // 遇到文本节点时追加内容
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        parsedText.append(string)
    }
    
    // 捕获解析错误以便调试
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        // 可选择记录日志或其它处理
    }
}

/// 从压缩包中解析指定 XML 文件的内容
func extractXMLContent(from archive: Archive, xmlPath: String) throws -> String {
    guard let entry = archive.first(where: { $0.path.lowercased() == xmlPath.lowercased() }) else {
        return "无法在压缩包中找到 \(xmlPath) 文件"
    }
    
    var xmlData = Data()
    do {
        // 显式忽略 extract 方法的返回值（CRC32）
        _ = try archive.extract(entry, consumer: { data in
            xmlData.append(data)
        })
    } catch {
        return "解压 \(xmlPath) 文件失败：\(error.localizedDescription)"
    }
    
    let parser = XMLParser(data: xmlData)
    parser.shouldResolveExternalEntities = false
    let xmlDelegate = XMLContentParser()
    parser.delegate = xmlDelegate
    
    if parser.parse() {
        return xmlDelegate.parsedText.trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
        return "XMLParser解析 \(xmlPath) 失败：\(parser.parserError?.localizedDescription ?? "未知错误")"
    }
}

/// 提取 XLSX 文件的文本内容
func extractXLSXContent(from fileURL: URL) throws -> String {
    guard let file = XLSXFile(filepath: fileURL.path) else {
        return "无法打开 XLSX 文件"
    }
    
    var extractedText = ""
    
    // 解析 SharedStrings
    guard let sharedStrings = try file.parseSharedStrings() else {
        return "无法解析 SharedStrings"
    }
    
    // 遍历所有工作表路径
    let worksheetPaths = try file.parseWorksheetPaths()
    for path in worksheetPaths {
        let worksheet = try file.parseWorksheet(at: path)
        if let rows = worksheet.data?.rows {
            for row in rows {
                for cell in row.cells {
                    if let value = cell.stringValue(sharedStrings) {
                        extractedText.append(value + "\t")
                    }
                }
                extractedText.append("\n")
            }
        }
    }
    
    return extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// 从 PPTX 文件中提取幻灯片文本内容，并按照幻灯片顺序排序
func extractPPTXContent(from fileURL: URL) throws -> String {
    let archive = try Archive(url: fileURL, accessMode: .read)
    
    // 筛选幻灯片 XML 文件
    let slideEntries = archive.filter { entry in
        let lowerPath = entry.path.lowercased()
        return lowerPath.hasPrefix("ppt/slides/slide") && lowerPath.hasSuffix(".xml")
    }
    
    if slideEntries.isEmpty {
        return "无法在 PPTX 文件中找到任何幻灯片"
    }
    
    // 根据文件名中的数字部分排序（如 slide1.xml, slide2.xml, …）
    let sortedSlideEntries = slideEntries.sorted { (entry1, entry2) -> Bool in
        func slideNumber(from path: String) -> Int {
            let fileName = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent // 例如 "slide1"
            let numberString = fileName.replacingOccurrences(of: "slide", with: "")
            return Int(numberString) ?? 0
        }
        return slideNumber(from: entry1.path) < slideNumber(from: entry2.path)
    }
    
    var extractedText = ""
    for entry in sortedSlideEntries {
        let slideText = try extractXMLContent(from: archive, xmlPath: entry.path)
        if !slideText.isEmpty {
            extractedText.append(slideText + "\n")
        }
    }
    
    return extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// 截断过长的内容以防止内存问题和 UI 崩溃
/// - Parameters:
///   - content: 原始内容
///   - maxLength: 最大字符长度（默认 100,000 字符）
/// - Returns: 截断后的内容（如果超长会添加提示信息）
func truncateContent(_ content: String, maxLength: Int = 100_000) -> String {
    if content.count <= maxLength {
        return content
    }

    let truncated = String(content.prefix(maxLength))
    let warningMessage = "\n\n⚠️ 内容已截断（原文件约 \(content.count.formatted()) 字符，已截取前 \(maxLength.formatted()) 字符）"
    return truncated + warningMessage
}

/// 根据传入文件的 URL 异步提取文本内容
/// 支持的格式包括：.pdf, .docx, .xlsx, .pptx 以及纯文本格式（例如：.csv, .py, .txt, .md, .json, .log, .html）
func extractContent(from fileURL: URL) async throws -> String {
    // 尝试访问安全范围资源
    var didAccess = false
    if fileURL.startAccessingSecurityScopedResource() {
        didAccess = true
    }
    defer {
        if didAccess {
            fileURL.stopAccessingSecurityScopedResource()
        }
    }
    
    // 检查文件是否存在
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
        return "文件不存在: \(fileURL.path)"
    }
    
    let fileExtension = fileURL.pathExtension.lowercased()
    
    switch fileExtension {
    // 纯文本文件：CSV、PY、TXT、MD、JSON、LOG、HTML
    case "csv", "py", "txt", "md", "json", "log", "html":
        let content = try await Task.detached {
            return try String(contentsOf: fileURL, encoding: .utf8)
        }.value
        return truncateContent(content)

    case "pdf":
        if let pdfDocument = PDFDocument(url: fileURL),
           let content = pdfDocument.string, !content.isEmpty {
            return truncateContent(content)
        } else {
            return "PDF 文件为空或无法提取文本"
        }

    case "docx":
        let content = try await Task.detached {
            let archive = try Archive(url: fileURL, accessMode: .read)
            return try extractXMLContent(from: archive, xmlPath: "word/document.xml")
        }.value
        return truncateContent(content)

    case "xlsx":
        let content = try await Task.detached {
            return try extractXLSXContent(from: fileURL)
        }.value
        return truncateContent(content)

    case "pptx":
        let content = try await Task.detached {
            return try extractPPTXContent(from: fileURL)
        }.value
        return truncateContent(content)

    default:
        return "不支持的文件类型：\(fileExtension)"
    }
}
