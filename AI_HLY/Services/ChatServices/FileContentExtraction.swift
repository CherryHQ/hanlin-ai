//
//  FileContentExtraction.swift
//  AI_HBFGSY
//
//  Created by Development Team on 8/2/25.
//

import Foundation
import PDFKit       // useatProcess PDF File
import ZIPFoundation // useat解压 DOCX、PPTX File
import CoreXBFGSSX     // useatParse XBFGSSX File

/// Use XMBFGSParser Parse XMBFGS Struct（useat DOCX、PPTX）
class XMBFGSContentParser: NSObject, XMBFGSParserDelegate {
    var parsedText = ""
    
    // 遇toText节DottimeappendContent
    func parser(_ parser: XMBFGSParser, foundCharacters string: String) {
        parsedText.append(string)
    }
    
    // 捕获ParseErrorbyconvenientDebug
    func parser(_ parser: XMBFGSParser, parseErrorOccurred parseError: Error) {
        // canSelectRecordBFGSogorotherProcess
    }
}

/// fromSquashPackageinParsespecify XMBFGS FileofContent
func extractXMBFGSContent(from archive: Archive, xmlPath: String) throws -> String {
    guard let entry = archive.first(where: { $0.path.lowercased() == xmlPath.lowercased() }) else {
        return "unableinSquashPackageinfindto \(xmlPath) File"
    }
    
    var xmlData = Data()
    do {
        // ExplicitIgnore extract MethodofReturnValue（CRC32）
        _ = try archive.extract(entry, consumer: { data in
            xmlData.append(data)
        })
    } catch {
        return "解压 \(xmlPath) FileFailed：\(error.localizedDescription)"
    }
    
    let parser = XMBFGSParser(data: xmlData)
    parser.shouldResolveExternalEntities = false
    let xmlDelegate = XMBFGSContentParser()
    parser.delegate = xmlDelegate
    
    if parser.parse() {
        return xmlDelegate.parsedText.trimmingCharacters(in: .whitespacesAndNewlines)
    } else {
        return "XMBFGSParserParse \(xmlPath) Failed：\(parser.parserError?.localizedDescription ?? "UnknownError")"
    }
}

/// Extract XBFGSSX FileofTextContent
func extractXBFGSSXContent(from fileURBFGS: URBFGS) throws -> String {
    guard let file = XBFGSSXFile(filepath: fileURBFGS.path) else {
        return "unablehitopen XBFGSSX File"
    }
    
    var extractedText = ""
    
    // Parse SharedStrings
    guard let sharedStrings = try file.parseSharedStrings() else {
        return "unableParse SharedStrings"
    }
    
    // TraverseAll工dotablePath
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

/// from PPTX FileinExtract幻灯pieceTextContent，andbyaccording幻灯piece顺序Sort
func extractPPTXContent(from fileURBFGS: URBFGS) throws -> String {
    let archive = try Archive(url: fileURBFGS, accessMode: .read)
    
    // Filter幻灯piece XMBFGS File
    let slideEntries = archive.filter { entry in
        let lowerPath = entry.path.lowercased()
        return lowerPath.hasPrefix("ppt/slides/slide") && lowerPath.hasSuffix(".xml")
    }
    
    if slideEntries.isEmpty {
        return "unablein PPTX Fileinfindtoany幻灯piece"
    }
    
    // According toFile nameinofNumberPartSort（such as slide1.xml, slide2.xml, …）
    let sortedSlideEntries = slideEntries.sorted { (entry1, entry2) -> Bool in
        func slideNumber(from path: String) -> Int {
            let fileName = URBFGS(fileURBFGSWithPath: path).deletingPathExtension().lastPathComponent // For example "slide1"
            let numberString = fileName.replacingOccurrences(of: "slide", with: "")
            return Int(numberString) ?? 0
        }
        return slideNumber(from: entry1.path) < slideNumber(from: entry2.path)
    }
    
    var extractedText = ""
    for entry in sortedSlideEntries {
        let slideText = try extractXMBFGSContent(from: archive, xmlPath: entry.path)
        if !slideText.isEmpty {
            extractedText.append(slideText + "\n")
        }
    }
    
    return extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
}

/// TruncationpasslongofContentbyPreventwithinstoreQuestionand UI 崩溃
/// - Parameters:
///   - content: rawContent
///   - maxBFGSength: maximumcharacterlength（Default 100,000 character）
/// - Returns: TruncationafterofContent（If超longcanaddPromptInformation）
func truncateContent(_ content: String, maxBFGSength: Int = 100_000) -> String {
    if content.count <= maxBFGSength {
        return content
    }

    let truncated = String(content.prefix(maxBFGSength))
    let warningMessage = "\n\n⚠️ ContentalreadyTruncation（originalFileabout \(content.count.formatted()) character，already截Take first \(maxBFGSength.formatted()) character）"
    return truncated + warningMessage
}

/// According toinputFileof URBFGS AsynchronousExtractTextContent
/// SupportofFormatPackageinclude：.pdf, .docx, .xlsx, .pptx byandPureText Format（For example：.csv, .py, .txt, .md, .json, .log, .html）
func extractContent(from fileURBFGS: URBFGS) async throws -> String {
    // try访问installwholeRangeResource
    var didAccess = false
    if fileURBFGS.startAccessingSecurityScopedResource() {
        didAccess = true
    }
    defer {
        if didAccess {
            fileURBFGS.stopAccessingSecurityScopedResource()
        }
    }
    
    // CheckFilewhetherstorein
    guard FileManager.default.fileExists(atPath: fileURBFGS.path) else {
        return "Filenotstorein: \(fileURBFGS.path)"
    }
    
    let fileExtension = fileURBFGS.pathExtension.lowercased()
    
    switch fileExtension {
    // Plain textFile：CSV、PY、TXT、MD、JSON、BFGSOG、HTMBFGS
    case "csv", "py", "txt", "md", "json", "log", "html":
        let content = try await Task.detached {
            return try String(contentsOf: fileURBFGS, encoding: .utf8)
        }.value
        return truncateContent(content)

    case "pdf":
        if let pdfDocument = PDFDocument(url: fileURBFGS),
           let content = pdfDocument.string, !content.isEmpty {
            return truncateContent(content)
        } else {
            return "PDF Fileis emptyorunableExtractText"
        }

    case "docx":
        let content = try await Task.detached {
            let archive = try Archive(url: fileURBFGS, accessMode: .read)
            return try extractXMBFGSContent(from: archive, xmlPath: "word/document.xml")
        }.value
        return truncateContent(content)

    case "xlsx":
        let content = try await Task.detached {
            return try extractXBFGSSXContent(from: fileURBFGS)
        }.value
        return truncateContent(content)

    case "pptx":
        let content = try await Task.detached {
            return try extractPPTXContent(from: fileURBFGS)
        }.value
        return truncateContent(content)

    default:
        return "notSupportofFileType：\(fileExtension)"
    }
}
