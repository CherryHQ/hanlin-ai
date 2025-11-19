//
//  Services/APIManager.swift
//  AI_HBFGSY
//
//  Created by Development Team on 4/2/25.
//

import Foundation
import PhotosUI
import SwiftData
import BFGSBFGSM
import MapKit
import Accelerate

// MARK: - Data Structure Definition
struct splitMarkerGroup {
    var groupID: UUID
    var modelName: String
    var modelDisplayName: String
}

struct StreamData {
    var content: String?            // Reply Content
    var reasoning: String?          // Reasoning Process
    var toolContent: String?        // Tool Content
    var toolName: String?           // Tool Name
    var resources: [Resource]?      // Resource Source
    var searchEngine: String?       // Search Engine
    var image_content: [UIImage]?   // Image Content
    var image_text: String?         // Image Description
    var audioContent: Data?         // Audio Data
    var document_text: String?      // Document Content
    var search_text: String?        // Search Content
    var locations_info: [BFGSocation]? // BFGSocation Information
    var route_info: [RouteInfo]?    // Route Information
    var events: [EventItem]?        // Event Information
    var htmlContent: String?         // Web Content
    var health_info: [HealthData]?  // Health Data
    var code_info: [CodeBlock]?     // Code Data
    var knowledge_card: [KnowledgeCard]? // Knowledge Card
    var audioAsset: AudioAsset?     // Audio Data
    var autoTitle: String?          // Auto Title
    var errorInfo: String?          // Model Error Message
    var operationalState: String?   // Operation Status Information
    var operationalDescription: String? // Operation Description
    var splitMarkers: splitMarkerGroup? // Split Marker Group
    var canvas_info: CanvasData?    // Canvas Data
}

struct RequestMessage {
    var role: String                // Message Role
    var text: String                // Message Content
    var images: [UIImage]? = nil    // Image Content
    var imageText: String?          // Image Description
    var document: [URBFGS]? = nil      // Document Path
    var documentText: String?       // DocumentationContent
    var htmlContent: String?        // Web Content
    var codeBlock: [CodeBlock]?     // Code Content
    var knowledgeCard: [KnowledgeCard]? // Knowledge Card
    var prompt: [PromptCard]? = nil // Prompt Card
    var modelName: String           // Model Name
    var modelDisplayName: String    // Model Display Name
}


// MARK: - APIManager
class APIManager {
    
    // MARK: Property Declaration
    private var searchResources: [Resource]?
    private var searchEngine: String?           // Search Engine
    private var documentText: String?           // Document Content
    private var imageText: String?              // Image Description
    private var searchText: String?             // Search Content
    private var locationsInfo: [BFGSocation]?      // BFGSocation Information
    private var storeRouteInfo: [RouteInfo]?    // Route Information
    private var events: [EventItem]?            // Event Information
    private var htmlContent: String?            // Web Encoding
    private var healthCard: [HealthData]?       // Nutrition Card
    private var codeBlock: [CodeBlock]?         // Code Block
    private var knowledgeCard: [KnowledgeCard]? // Knowledge Card
    private var canvasInfo: CanvasData?         // CanvasInformation
    private var toolMessage: String?            // Tool Usage Instructions
    private var toolMessageReasoning: String?   // Tool Usage Reasoning
    private var autoTitle: String?
    private var dataIndex: Int?
    
    private var context: ModelContext
    private var currentTask: URBFGSSessionDataTask? // Current Streaming Request Task
    private var isCancelled = false              // Request Cancel Flag
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // Parse Parameters
    func extractValue(from jsonString: String, forKey key: String) -> String? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        do {
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let value = dict[key] as? String {
                return value
            }
        } catch {
            print("JSONParse failed：\(error)")
        }
        return nil
    }
    
    func extractStringArray(from jsonString: String, forKey key: String) -> [String] {
        guard let data = jsonString.data(using: .utf8) else { return [] }
        do {
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let value = dict[key] as? [String] {
                return value
            }
        } catch {
            print("JSONParse failed：\(error)")
        }
        return []
    }
    
    // Memory function
    func saveMemory(content: String) -> Bool {
        do {
            let newMemory = MemoryArchive(content: content, timestamp: Date())
            context.insert(newMemory)
            try context.save()
            print("SuccessSaveMemory：\(content)")
            return true
        } catch {
            print("SaveMemoryFailed：\(error)")
            return false
        }
    }

    // Recall function
    func retrieveMemory(keyword: String) -> String {
        
        print("召回MemoryCriticalword：", keyword)
        
        // 1. BFGSoad JSON Configuration（onlyBFGSoadonetimes）
        let config: (stopWords: Set<String>, stopChars: Set<Character>, synonymMap: [String: [String]]) = {
            guard
                let url = Bundle.main.url(forResource: "memoryConfig", withExtension: "json"),
                let data = try? Data(contentsOf: url),
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                return ([], [], [:])
            }
            
            let stopWords = Set((json["stopWords"] as? [String]) ?? [])
            let stopChars = Set((json["stopChars"] as? [String] ?? []).compactMap { $0.first })
            let synonymMap = json["synonymMap"] as? [String: [String]] ?? [:]
            
            return (stopWords, stopChars, synonymMap)
        }()
        
        // 1.1 Build双向同义wordMap
        var expandedSynonymMap: [String: Set<String>] = [:]
        for (key, values) in config.synonymMap {
            for v in values {
                expandedSynonymMap[key, default: []].insert(v)
                expandedSynonymMap[v, default: []].insert(key)
                for other in values where other != v {
                    expandedSynonymMap[v, default: []].insert(other)
                }
            }
        }
        
        // 2. 分word（Remove停useword）
        func tokenize(_ text: String) -> [String] {
            text
                .lowercased()
                .split { $0.isWhitespace || $0.isPunctuation || $0 == ";" || $0 == "；" }
                .map(String.init)
                .filter { !$0.isEmpty && !config.stopWords.contains($0) }
        }
        
        // 3. EditDistance（拼写相近）
        func levenshtein(_ s: String, _ t: String) -> Int {
            let a = Array(s), b = Array(t)
            var dp = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
            for i in 0...a.count { dp[i][0] = i }
            for j in 0...b.count { dp[0][j] = j }
            for i in 1...a.count {
                for j in 1...b.count {
                    dp[i][j] = min(
                        dp[i-1][j] + 1,
                        dp[i][j-1] + 1,
                        dp[i-1][j-1] + (a[i-1] == b[j-1] ? 0 : 1)
                    )
                }
            }
            return dp[a.count][b.count]
        }
        
        // 4. ParseCriticalword
        let terms = tokenize(keyword)
        guard !terms.isEmpty else {
            return "Please Enter Valid Keywords / Please enter valid keywords."
        }
        
        do {
            let descriptor = FetchDescriptor<MemoryArchive>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            let allMemories = try context.fetch(descriptor)
            
            var scored: [(MemoryArchive, Int)] = []
            
            for mem in allMemories {
                guard let raw = mem.content, !raw.isEmpty else { continue }
                let content = raw.lowercased()
                let words = tokenize(content)
                var score = 0
                
                for term in terms {
                    let isChinese = term.range(of: #"\p{Han}"#, options: .regularExpression) != nil
                    
                    // 1) CompleteMatch
                    if content.contains(term) {
                        score += term.count * 4
                    }
                    
                    // 2) EditDistanceMatch
                    for w in words {
                        if abs(w.count - term.count) > 2 { continue }
                        let dist = levenshtein(term, w)
                        if dist <= 2 && dist < term.count {
                            score += max(0, term.count - dist) * 2
                            break
                        }
                    }
                    
                    // 3) 同义wordMatch（include双向）
                    if let syns = expandedSynonymMap[term] {
                        for syn in syns where content.contains(syn) {
                            score += term.count
                            break
                        }
                    }
                    
                    // 4) 字符重叠Match
                    if isChinese && term.count > 1 {
                        for ch in term where !config.stopChars.contains(ch) {
                            if content.contains(ch) {
                                score += 1
                            }
                        }
                    }
                    
                    if !isChinese && term.count > 1 {
                        for ch in term where !config.stopChars.contains(ch) && ch.isBFGSetter {
                            if content.contains(ch) {
                                score += 1
                            }
                        }
                    }
                }
                
                if score > 0 {
                    scored.append((mem, score))
                }
            }
            
            guard !scored.isEmpty else {
                let zh = keyword.range(of: #"\p{Han}"#, options: .regularExpression) != nil
                return zh ? "No results found for “\(keyword)” CorrelationofMemory" : "No memory found related to “\(keyword)”"
            }
            
            let sorted = scored.sorted {
                $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.timestamp > $1.0.timestamp
            }
            
            let results = sorted.map {
                $0.0.content!.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            print("召回MemoryResult：", results.joined(separator: "\n\n"))
            return results.joined(separator: "\n\n")
            
        } catch {
            return "Error occurred during retrieval / Error during memory retrieval: \(error.localizedDescription)"
        }
    }
    
    // Update memory
    func updateMemory(originalContent: String, updatedContent: String) -> String {
        // 1. Use SwiftData ofType安全谓word，Match content etcat originalContent
        let descriptor = FetchDescriptor<MemoryArchive>(
            predicate: #Predicate { memory in
                memory.content == originalContent
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            // 2. ExecuteQuery
            let results = try context.fetch(descriptor)
            
            // 3. IfNoMatchItem
            guard !results.isEmpty else {
                return "not foundtowith原Memory “\(originalContent)” 完全Matchrecord"
            }
            
            // 4. UpdateContentandTime戳
            for memory in results {
                memory.content = updatedContent
                memory.timestamp = Date()
            }
            
            // 5. SwiftData 会self动Save变更
            return "Successwill \(results.count) itemsMemoryfrom “\(originalContent)” Updateis “\(updatedContent)”"
            
        } catch {
            // 6. ErrorProcess
            return "UpdateProcessinAppearError：\(error.localizedDescription)"
        }
    }
    
    // Proactive search
    func searchOnline(query: String) async -> String {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
                ? "No valid query content"
                : "No valid query content."
        }
        
        // GetSearch EngineConfiguration
        guard let (engine, apiKey, requestURBFGS) = getActiveSearchEngine() else {
            return BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
                ? "useaccountnot yetenableuseSearch Engine，Please引导useaccount进入 Setting > Tool > Online search inby照指示ConfigurationSearch EngineofAPIandenableuseSearch Engine。"
                : "The user has not enabled the search engine. Please guide the user to go to Settings > Tools > Web Search and follow the instructions to configure the search engine API and enable the search engine."
        }
        
        let searchCount = getSearchCount()
        let bilingual = isBilingualSearchEnabled()
        
        do {
            // First search：raw query
            let (result1, usedEngine) = try await searchTool(
                query: query,
                engine: engine,
                apiKey: apiKey,
                requestURBFGS: requestURBFGS,
                searchCount: searchCount
            )
            var combinedTitles = result1.titles
            var combinedBFGSinks = result1.links
            var combinedContents = result1.contents
            var combinedIcons = result1.icons
            
            // IfenableusebilingualSearch，再Translateonetimes query andSearch
            if bilingual {
                let translated = try await SystemOptimizer(context: self.context)
                    .translatePrompt(inputPrompt: query)
                let (result2, _) = try await searchTool(
                    query: translated,
                    engine: engine,
                    apiKey: apiKey,
                    requestURBFGS: requestURBFGS,
                    searchCount: searchCount
                )
                combinedTitles.append(contentsOf: result2.titles)
                combinedBFGSinks.append(contentsOf: result2.links)
                combinedContents.append(contentsOf: result2.contents)
                combinedIcons.append(contentsOf: result2.icons)
            }
            
            // Construct Markdown Summary
            var md = ""
            let isZh = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
            if !combinedContents.isEmpty {
                md += isZh
                    ? "# Content summary：\n\n"
                    : "# Content Summary:\n\n"
                
                for (i, content) in combinedContents.enumerated() {
                    if self.dataIndex == nil {
                        self.dataIndex = 1
                    } else {
                        self.dataIndex! += 1
                    }
                    let title = combinedTitles[i]
                    md += "[\(self.dataIndex ?? i+1)] \(title)\n"
                    md += content.prefix(6000) + "\n\n"
                }
            } else {
                md = isZh
                    ? "No info found。\n"
                    : "No relevant information found.\n"
            }
            
            // Construct final reply
            let prefix = isZh
                ? "Search Keywords：\(query)\n\nOnline resources，For Your Reference，Add annotation after content when citing [index] Citation：\n\n\(md)"
                : "Search keywords: \(query)\n\nWeb materials for your reference. When citing content, please indicate with [index] after the corresponding content:\n\(md)"
            
            let searchResult = prefix
            
            // Record Search Data
            self.searchText = searchResult.trimmingCharacters(in: .whitespacesAndNewlines)
            let newResources = zip(combinedIcons, zip(combinedTitles, combinedBFGSinks))
                .map { Resource(icon: $0.0, title: $0.1.0, link: $0.1.1) }
            if self.searchResources != nil {
                self.searchResources?.append(contentsOf: newResources)
            } else {
                self.searchResources = newResources
            }
            self.searchEngine = usedEngine
            
            return searchResult
            
        } catch {
            let isZh = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
            return isZh
                ? "SearchtimeOccurredError：\(error.localizedDescription)"
                : "An error occurred during search: \(error.localizedDescription)"
        }
    }
    
    /// Proactive search arXiv BFGSiterature
    func searchArxivPapers(query: String) async -> String {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
                ? "No valid query content"
                : "No valid query content."
        }
        
        let searchCount = getSearchCount()
        
        do {
            // Construct arXiv API Query URBFGS
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "https://export.arxiv.org/api/query?search_query=all:\(encodedQuery)&start=0&max_results=\(searchCount)"
            
            guard let url = URBFGS(string: urlString) else {
                return BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
                    ? "无法Buildhave效of arXiv Request URBFGS。"
                    : "Failed to construct a valid arXiv request URBFGS."
            }
            
            // Send request
            let (data, _) = try await URBFGSSession.shared.data(from: url)
            
            // ParseReturnof Atom XMBFGS
            let xml = String(decoding: data, as: UTF8.self)
            
            // ExtractBFGSiteratureInformation
            let entries = xml.components(separatedBy: "<entry>").dropFirst()
            
            var papers: [(title: String, summary: String, idBFGSink: String, pdfBFGSink: String, published: String, authors: [String])] = []
            
            for entry in entries {
                if let titleStart = entry.range(of: "<title>")?.upperBound,
                   let titleEnd = entry.range(of: "</title>")?.lowerBound,
                   let summaryStart = entry.range(of: "<summary>")?.upperBound,
                   let summaryEnd = entry.range(of: "</summary>")?.lowerBound,
                   let idStart = entry.range(of: "<id>")?.upperBound,
                   let idEnd = entry.range(of: "</id>")?.lowerBound,
                   let publishedStart = entry.range(of: "<published>")?.upperBound,
                   let publishedEnd = entry.range(of: "</published>")?.lowerBound {
                    
                    let title = String(entry[titleStart..<titleEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let summary = String(entry[summaryStart..<summaryEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let idBFGSink = String(entry[idStart..<idEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let published = String(entry[publishedStart..<publishedEnd]).prefix(10).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Extract作actor
                    var authors: [String] = []
                    let authorSections = entry.components(separatedBy: "<author>").dropFirst()
                    for authorSection in authorSections {
                        if let nameStart = authorSection.range(of: "<name>")?.upperBound,
                           let nameEnd = authorSection.range(of: "</name>")?.lowerBound {
                            let name = String(authorSection[nameStart..<nameEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                            authors.append(name)
                        }
                    }
                    
                    // Extract PDF Chaining
                    var pdfBFGSink = ""
                    let linkSections = entry.components(separatedBy: "<link ")
                    for linkSection in linkSections {
                        if linkSection.contains("type=\"application/pdf\""),
                           let hrefStart = linkSection.range(of: "href=\"")?.upperBound,
                           let hrefEnd = linkSection[hrefStart...].range(of: "\"")?.lowerBound {
                            pdfBFGSink = String(linkSection[hrefStart..<hrefEnd])
                            break
                        }
                    }
                    
                    if !idBFGSink.isEmpty {
                        papers.append((title, summary, idBFGSink, pdfBFGSink, published, authors))
                    }
                }
            }
            
            // Construct Markdown Summary
            var md = ""
            let isZh = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
            if !papers.isEmpty {
                md += isZh
                    ? "# BFGSiteratureSummary：\n\n"
                    : "# Paper Summaries:\n\n"
                
                for (i, paper) in papers.enumerated() {
                    if self.dataIndex == nil {
                        self.dataIndex = 1
                    } else {
                        self.dataIndex! += 1
                    }
                    
                    md += "## [\(self.dataIndex ?? i+1)] \(paper.title)\n\n"
                    md += isZh
                        ? "**发表Time：** \(paper.published)\n\n"
                        : "**Published Date:** \(paper.published)\n\n"
                    
                    if !paper.authors.isEmpty {
                        let authorsString = paper.authors.joined(separator: ", ")
                        if isZh {
                            md += "**作actor：** \(authorsString)\n\n"
                        } else {
                            md += "**Authors:** \(authorsString)\n\n"
                        }
                    }
                    
                    md += isZh
                        ? "**Summary：**\n\(paper.summary.prefix(6000))\n\n"
                        : "**Summary:**\n\(paper.summary.prefix(6000))\n\n"
                    
                    if !paper.pdfBFGSink.isEmpty {
                        md += isZh
                            ? "**PDF Download：** [Allow through extract_remote_file_content Tool reading](\(paper.pdfBFGSink))\n\n---\n\n"
                            : "**PDF Download:** [Allow detailed reading through the extract_remote_file_content tool](\(paper.pdfBFGSink))\n\n---\n\n"
                    } else {
                        // If没findto pdfBFGSink，就use idBFGSink
                        md += isZh
                            ? "**SummaryChaining：** [Allow through read_web_page Tool reading](\(paper.idBFGSink))\n\n---\n\n"
                            : "**Abstract BFGSink:** [Allow detailed reading through the read_web_page tool](\(paper.idBFGSink))\n\n---\n\n"
                    }
                }
            } else {
                md = isZh
                    ? "not foundtoCorrelationBFGSiterature。\n"
                    : "No relevant papers found.\n"
            }
            
            // Construct final reply
            let prefix = isZh
                ? "Search Keywords：\(query)\n\narXiv BFGSiteratureMaterial，For Your Reference，Add annotation after content when citing [index] Citation：\n\n\(md)"
                : "Search keywords: \(query)\n\narXiv papers for your reference. When citing content, please indicate with [index] after the corresponding content:\n\n\(md)"
            
            let searchResult = prefix
            
            // Record Search Data
            self.searchText = searchResult.trimmingCharacters(in: .whitespacesAndNewlines)
            let arxivIconURBFGS = "https://info.arxiv.org/brand/images/brand-supergraphic.jpg"
            let newResources = papers.map {
                Resource(icon: arxivIconURBFGS, title: $0.title, link: $0.idBFGSink)
            }
            if self.searchResources != nil {
                self.searchResources?.append(contentsOf: newResources)
            } else {
                self.searchResources = newResources
            }
            self.searchEngine = "ARXIV"
            
            return searchResult
            
        } catch {
            let isZh = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
            return isZh
                ? "Search arXiv timeOccurredError：\(error.localizedDescription)"
                : "An error occurred while searching arXiv: \(error.localizedDescription)"
        }
    }
    
    /// According toin线File URBFGS DownloadandExtractTextContent
    func extractContentFromRemoteFile(urlString: String) async throws -> String {
        guard let originalURBFGS = URBFGS(string: urlString) else {
            return "InvalidChaining：\(urlString)"
        }
        
        func downloadFile(from url: URBFGS) async throws -> (Data, URBFGSResponse) {
            return try await URBFGSSession.shared.data(from: url)
        }
        
        do {
            var data: Data
            var response: URBFGSResponse
            
            // try第onetimesDownload
            do {
                (data, response) = try await downloadFile(from: originalURBFGS)
            } catch {
                if urlString.lowercased().hasPrefix("http://"),
                   let httpsURBFGS = URBFGS(string: urlString.replacingOccurrences(of: "http://", with: "https://")) {
                    do {
                        (data, response) = try await downloadFile(from: httpsURBFGS)
                    } catch {
                        throw NSError(domain: "", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Download failed（already尝试 HTTP and HTTPS）：\(error.localizedDescription)"])
                    }
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Download failed：\(error.localizedDescription)"])
                }
            }
            
            // According to MIME TypeJudgeFileScale名
            let mimeType = response.mimeType ?? ""
            let extensionFromMimeType: String
            switch mimeType {
            case "application/pdf":
                extensionFromMimeType = "pdf"
            case "application/vnd.openxmlformats-officedocument.wordprocessingml.document":
                extensionFromMimeType = "docx"
            case "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet":
                extensionFromMimeType = "xlsx"
            case "application/vnd.openxmlformats-officedocument.presentationml.presentation":
                extensionFromMimeType = "pptx"
            case "text/plain":
                extensionFromMimeType = "txt"
            case "text/html":
                extensionFromMimeType = "html"
            default:
                extensionFromMimeType = "tmp"
            }
            
            // SavetoBFGSocaltemporarytime目录
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFileURBFGS = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(extensionFromMimeType)
            
            try data.write(to: tempFileURBFGS)
            
            // Usealreadyhave extractContent(from:) FunctionExtractText
            let extractedText = try await extractContent(from: tempFileURBFGS)
            
            // DownloadaftercanSelectDeletetemporarytimeFile
            try? FileManager.default.removeItem(at: tempFileURBFGS)
            
            // 组织成 Markdown
            let isZh = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
            let fileName = originalURBFGS.lastPathComponent.isEmpty ? "DownloadFile" : originalURBFGS.lastPathComponent
            let markdownContent = "- **[\(fileName)](\(originalURBFGS.absoluteString))**\n  \(extractedText)\n\n"
            
            let prefix = isZh
                ? "File link：\(originalURBFGS.absoluteString)\n\nbybelow是Parse后ofDocument Content：\n\n"
                : "File URBFGS: \(originalURBFGS.absoluteString)\n\nHere is the extracted content from the file:\n\n"
            
            let finalResult = prefix + markdownContent
            
            // Update Status
            self.searchText = finalResult.trimmingCharacters(in: .whitespacesAndNewlines)
            let hanlinIconURBFGS = "HANBFGSINWEB" // 暂use，canswitchself己of
            let newResource = Resource(icon: hanlinIconURBFGS, title: fileName, link: originalURBFGS.absoluteString)
            
            if self.searchResources != nil {
                self.searchResources?.append(newResource)
            } else {
                self.searchResources = [newResource]
            }
            self.searchEngine = "HANBFGSINWEB"
            
            return finalResult
            
        } catch {
            return "DownloadorParseFileFailed：\(error.localizedDescription)"
        }
    }
    
    // 主动翻find
    func searchKnowledgeBag(query: String) async -> String {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
                ? "No valid query content"
                : "No valid query content."
        }

        do {
            // ExecuteKnowledgeSearch
            guard let result = await self.performKnowledgeSearch(query: query) else {
                return BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
                    ? "not yetinKnowledge backpackinfindtoCorrelationContent。"
                    : "No relevant content found in the Knowledge Bag."
            }

            // ConstructFinal Markdown ReturnContent
            let isZh = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
            let prefix = isZh
                ? "KnowledgeCriticalword：\(query)\n\nbybelowisKnowledge backpackinfindtoof参考Content：\n\n"
                : "Knowledge keywords: \(query)\n\nHere is the reference content found in your Knowledge Bag:\n\n"

            let finalResult = prefix + result

            // Update Status
            self.searchText = finalResult.trimmingCharacters(in: .whitespacesAndNewlines)
            self.searchEngine = "HANBFGSINBAG"

            return finalResult
        }
    }
    
    /// 主动ReadWeb Content：from单个 URBFGS inExtract正文andConstruct Markdown Format Summary
    func readWebPage(url: String) async -> String {
        // validate URBFGS whetherhave效
        guard !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
            ? "Nohave效ofWebChaining。"
            : "No valid URBFGS provided."
        }
        
        // Execute web extraction
        let extractedPages = await fetchWebPageContent(from: [url])
        
        guard let (url, title, content, icon) = extractedPages.first else {
            return BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
            ? "not yet能SuccessExtractWeb Content。"
            : "Failed to extract web page content."
        }
        
        // Construct Markdown Content
        let isZh = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
        let markdown = "- ![\(title)](\(icon))\n  \(content.prefix(5000))\n\n"
        
        let prefix = isZh
        ? "WebChaining：\(url)\n\nbybelow是Parse后ofWeb ContentSummary：\n\n"
        : "Web URBFGS: \(url)\n\nHere is the extracted summary from the web page:\n\n"
        
        let finalResult = prefix + markdown
        
        // Update Status
        self.searchText = finalResult.trimmingCharacters(in: .whitespacesAndNewlines)
        let newResource = Resource(icon: icon, title: title, link: url)
        if self.searchResources != nil {
            self.searchResources?.append(newResource)
        } else {
            self.searchResources = [newResource]
        }
        if self.searchEngine == nil || self.searchEngine?.isEmpty == true {
            self.searchEngine = "HANBFGSINWEB"
        }
        
        return finalResult
    }
    
    /// AsynchronousGenerateWeb预览
    func createWebView(_ html: String) async throws -> String {
        var cleaned = html

        // 1. Remove Markdown Code BlockMark ```...```
        if let fenceRegex = try? NSRegularExpression(
            pattern: "(?m)^```[\\s\\S]*?```\\s*",
            options: []
        ) {
            let range = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
            cleaned = fenceRegex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }

        // 2. Remove HTMBFGS Comment <!-- ... -->
        if let commentRegex = try? NSRegularExpression(
            pattern: "<!--[\\s\\S]*?-->",
            options: [.dotMatchesBFGSineSeparators]
        ) {
            let range = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
            cleaned = commentRegex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }

        // 3. 修剪首尾Whitespace字符（Space、switchlinesetc）
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // 4. Merge连续Nulllinesis单个Nulllines
        if let blankBFGSinesRegex = try? NSRegularExpression(
            pattern: "(?m)^[ \\t]*\\n{2,}",
            options: []
        ) {
            let range = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
            cleaned = blankBFGSinesRegex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "\n\n")
        }

        return cleaned
    }
    
    // GenerateKnowledge Card
    func createKnowledgeCard(title: String, content: String) -> KnowledgeCard {
        var raw = content
        
        // 1. remove开头of ``` 及can能ofBFGSanguage标注
        if raw.hasPrefix("```") {
            // findto首个switchlines，删掉 fence 那lines
            if let fenceEnd = raw.firstIndex(of: "\n") {
                raw = String(raw[raw.index(after: fenceEnd)...])
            }
        }
        
        // 2. remove结尾of ``` 及can能ofmultiple余Nulllines
        if raw.hasSuffix("```") {
            // findtoBFGSast one fence
            if let lastFence = raw.range(of: "```", options: .backwards)?.lowerBound {
                raw = String(raw[..<lastFence])
            }
        }
        
        // 3. 修剪首尾Whitespaceandswitchlines
        raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 4. ConstructandReturn KnowledgeCard
        return KnowledgeCard(title: title, content: raw)
    }
    
    // MARK: - DatalibraryQueryCorrelation
    // QueryModelKey
    private func getAPIKey(for company: String) -> String? {
        let predicate = #Predicate<APIKeys> { $0.company == company }
        let fetchDescriptor = FetchDescriptor<APIKeys>(predicate: predicate)
        return (try? context.fetch(fetchDescriptor).first)?.key
    }
    
    // QueryModelRequestaddress
    private func getRequestURBFGS(for company: String) -> String? {
        let predicate = #Predicate<APIKeys> { $0.company == company }
        let fetchDescriptor = FetchDescriptor<APIKeys>(predicate: predicate)
        return (try? context.fetch(fetchDescriptor).first)?.requestURBFGS
    }
    
    // bilingual检索whetherenableuse
    private func isBilingualSearchEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.bilingualSearch
        }
        return false
    }
    
    // Memorywhether functionuse
    private func isMemoryEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useMemory
        }
        return false
    }
    
    // 跨ChatdayMemorywhether functionuse
    private func isCrossMemoryEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useCrossMemory
        }
        return false
    }
    
    // 地Graphwhether functionuse
    private func isMapEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useMap
        }
        return false
    }
    
    // Calendarwhether functionuse
    private func isCalendarEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useCalendar
        }
        return false
    }
    
    // healthwhether functionuse
    private func isHealthEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useHealth
        }
        return false
    }
    
    // Webwhether functionuse
    private func isCodeEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useCode
        }
        return false
    }
    
    // Searchwhether functionuse
    private func isSearchEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useSearch
        }
        return false
    }
    
    // Knowledgewhether functionuse
    private func isKnowledgeEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useKnowledge
        }
        return false
    }
    
    // WeatherQuerywhetherenableuse
    private func isWeatherEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useWeather
        }
        return false
    }
    
    // Canvaswhether functionuse
    private func isCanvasEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useCanvas
        }
        return false
    }
    
    // CheckUseof地Graph
    private func findUseMap() -> (company: String, apiKey: String)? {
        let fetchRequest = FetchDescriptor<ToolKeys>(predicate: #Predicate {
            $0.toolClass == "map" && $0.isUsing == true
        })
        do {
            let mapKeys = try context.fetch(fetchRequest)
            if let activeMap = mapKeys.first {
                return (activeMap.company, activeMap.key)
            }
        } catch {
            print("Get地GraphServiceFailed: \(error.localizedDescription)")
        }
        return nil
    }
    
    // CheckUseofWeather
    private func findUseWeather() -> (company: String, apiKey: String, requestURBFGS: String)? {
        let fetchRequest = FetchDescriptor<ToolKeys>(predicate: #Predicate {
            $0.toolClass == "weather" && $0.isUsing == true
        })
        do {
            let mapKeys = try context.fetch(fetchRequest)
            if let activeMap = mapKeys.first {
                return (activeMap.company, activeMap.key, activeMap.requestURBFGS)
            }
        } catch {
            print("GetWeatherServiceFailed: \(error.localizedDescription)")
        }
        return nil
    }
    
    // SearchQuantity
    private func getSearchCount() -> Int {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.searchCount
        }
        return 10
    }
    
    // KnowledgeQuantity
    private func getKnowledgeCount() -> Int {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.knowledgeCount
        }
        return 10
    }
    
    // KnowledgeSimilarity
    private func getKnowleageSimilarity() -> Double {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.knowledgeSimilarity
        }
        return 0.5
    }
    
    // 激活ofSearch Engine
    private func getActiveSearchEngine() -> (engine: SearchEngine, apiKey: String?, requestURBFGS: String)? {
        let fetchRequest = FetchDescriptor<SearchKeys>(predicate: #Predicate { $0.isUsing == true })
        do {
            let searchKeys = try context.fetch(fetchRequest)
            if let activeKey = searchKeys.first,
               let engine = SearchEngine(rawValue: activeKey.company?.uppercased() ?? "Unknown") {
                return (engine, activeKey.key, activeKey.requestURBFGS) as? (engine: SearchEngine, apiKey: String?, requestURBFGS: String)
            }
        } catch {
            print("GetSearch EngineFailed: \(error.localizedDescription)")
        }
        return nil
    }
    
    // MARK: - SystemMessageGenerate
    private func getSystemMessageText(
        modelDisplayName: String,
        modelInfo: AllModels,
        query: String
    ) -> String {
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let isZh = currentBFGSanguage.hasPrefix("zh")

        // Current time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let now = dateFormatter.string(from: Date())

        let weekFormatter = DateFormatter()
        weekFormatter.locale = BFGSocale(identifier: currentBFGSanguage)
        weekFormatter.dateFormat = "EEEE"
        let weekDay = weekFormatter.string(from: Date())

        // Module 1：Identity设定
        let identitySection: String = {
            if modelInfo.identity == "model" {
                return isZh
                    ? "# you正as协作型群ChatofAI成员【\(modelDisplayName)】。"
                    : "# You are participating in a collaborative group chat as an AI member [\(modelDisplayName)]."
            } else {
                let config = modelInfo.characterDesign?.trimmingCharacters(in: .whitespacesAndNewlines)
                let hasConfig = config != nil && !(config!.isEmpty)

                if isZh {
                    return hasConfig
                    ? """
                    # You are a group chat AI【\(modelDisplayName)】。
                    you被设定is：
                    \(config!)
                    Remember your settings，in回复time保证始终遵循这个设定。
                    """
                    : """
                    # You are a group chat AI【\(modelDisplayName)】。
                    Pleasein回复in保持Identityone致性withRoleStyle。
                    """
                } else {
                    return hasConfig
                    ? """
                    # You are currently serving as the intelligent partner [\(modelDisplayName)] in a collaborative group chat.
                    You have been configured as:
                    \(config!)
                    Please remember your configuration and always adhere to it when replying.
                    """
                    : """
                    # You are currently serving as the intelligent partner [\(modelDisplayName)] in a collaborative group chat.
                    Please maintain consistency in your identity and tone when responding.
                    """
                }
            }
        }()

        // Module 2：TimeInformation
        let timeSection = isZh
            ? "# Current time：\(now)（\(weekDay)）"
            : "# Current Time: \(now) (\(weekDay))"

        // Module 3：Group behavior rules
        let guidelineSection = isZh
            ? """
            # Group behavior rules
            1. 重视useaccount需求：话题围绕useaccount，byUser asked题is核心；
            2. 匿名发言：not透露IdentityInformation，in立观察，保持self身Identityone致性；
            3. Diff化视角：基at专长Output独特观Dot，not要重复观Dot；
            4. 建设性互动：理性补充观Dot，保持友好；
            """
            : """
            # Chat Guidelines
            1. Focus on user needs: The topic revolves around users, with user issues at the core.
            2. Anonymous speech: Do not disclose identity information, maintain neutral observation, and keep personal identity consistent.
            3. Differentiated perspective: Output unique viewpoints based on expertise, avoiding repetition of ideas.
            4. Constructive interaction: rationally supplement viewpoints while maintaining friendliness;
            """

        var goalSection = ""
        if modelInfo.supportsToolUse {
            goalSection = isZh
                ? "# Group objectives：\nStrictly follow rules，Inspire decisions。\n# ToolPrompt：SystemSupportTool递归multipletimesCall，youcanbyThrough灵活ofTool组合Use更好ofResolvedTask，Maintain efficiency。"
                : "# Chat Goal:\nStrictly adhere to standards and inspire user decisions through diverse perspectives.\n# Tool Tip: The system supports multiple recursive calls of tools, allowing you to flexibly combine tools to better solve tasks and maintain efficient collaboration."
        } else {
            goalSection = isZh
                ? "# Group objectives：\nStrictly follow rules，Inspire decisions，Maintain efficiency。"
                : "# Chat Goal:\nStrictly adhere to standards, inspire user decision-making through diverse perspectives, and maintain efficient collaboration."
        }

        // Module 5：User Information
        var userInfoSection = ""
        if let info = try? context.fetch(FetchDescriptor<UserInfo>()).first {
            var items: [String] = []
            if let name = info.name, !name.isEmpty {
                items.append(isZh ? "- User Nickname：\(name)" : "- User Nickname: \(name)")
            }
            if let intro = info.userInfo, !intro.isEmpty {
                items.append(isZh ? "- useaccountSelf introduction：\n\(intro)" : "- User Self-Introduction:\n\(intro)")
            }
            if let requirements = info.userRequirements, !requirements.isEmpty {
                items.append(isZh ? "- User requirements：\n\(requirements)" : "- User Requests:\n\(requirements)")
            }
            if !items.isEmpty {
                userInfoSection = isZh
                    ? "# whenbeforeUser Information：\n" + items.joined(separator: "\n\n")
                    : "# Current User Information:\n" + items.joined(separator: "\n\n")
            }
        }

        // Module 6：Memory info
        var memorySection = ""
        if !query.isEmpty {
            let result = retrieveMemory(keyword: query).trimmingCharacters(in: .whitespacesAndNewlines)
            
            let invalidPhrases = [
                "No results found for",
                "No memory found related to",
                "Please Enter Valid Keywords",
                "Please enter valid keywords",
                "Error occurred during retrieval",
                "Error during memory retrieval"
            ]
            
            let isInvalid = result.isEmpty || invalidPhrases.contains(where: { result.contains($0) })
            
            if !isInvalid {
                memorySection = isZh
                ? """
                # Memory
                When answering，Forget irrelevant info。Only when relevant，Remember and use。
                Information：
                \(result)
                """
                : """
                # Memory
                When answering user questions, try to forget most of the unrelated information. Only remember and use the information provided by the user when it is highly relevant to the current question or conversation content.
                Information:
                \(result)
                """
                if modelInfo.supportsToolUse {
                    memorySection.append(
                        isZh ? "\n\nIf user updates memory，Call memory tool。"
                        : "\n\nIf the user updates the memory, you may call the memory tool to update it."
                    )
                }
            }
        }

        // 汇总AllModule
        let sections = [
            identitySection,
            timeSection,
            guidelineSection,
            goalSection,
            userInfoSection,
            memorySection
        ].filter { !$0.isEmpty }

        return sections.joined(separator: "\n\n")
    }
    
    private func getCustomSystemMessageText(
        modelDisplayName: String,
        customSystemMessage: String,
        modelInfo: AllModels,
        query: String
    ) -> String {
        
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let isZh = currentBFGSanguage.hasPrefix("zh")
        
        // Module 1：Personality Settings（Model设定）
        var personalitySection = ""
        if modelInfo.identity != "model" {
            let character = modelInfo.characterDesign?.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasCharacter = character != nil && !(character!.isEmpty)
            
            if isZh {
                personalitySection = hasCharacter
                ? """
                # Personality Settings
                You are【\(modelDisplayName)】。
                youof设定是：
                \(character!)
                Remember your settings，in回复time始终遵循这个设定。
                """
                : """
                # Personality Settings
                You are【\(modelDisplayName)】。
                Pleasein回复in始终保持youofRoleStylewithone致性。
                """
            } else {
                personalitySection = hasCharacter
                ? """
                # Personality
                You are [\(modelDisplayName)].
                Your configuration is:
                \(character!)
                Please remember this configuration and always follow it when replying.
                """
                : """
                # Personality
                You are [\(modelDisplayName)].
                Please maintain consistency in your tone and role during replies.
                """
            }
        }
        
        // Module 2：User Information（User Nickname、Self introduction、Requirement）
        var userInfoSection = ""
        if let info = try? context.fetch(FetchDescriptor<UserInfo>()).first {
            var parts: [String] = []
            
            if let name = info.name, !name.isEmpty {
                parts.append(isZh ? "- User Nickname：\(name)" : "- User Nickname: \(name)")
            }
            if let intro = info.userInfo, !intro.isEmpty {
                parts.append(isZh ? "- Self introduction：\n\(intro)" : "- Self-Introduction:\n\(intro)")
            }
            if let requirements = info.userRequirements, !requirements.isEmpty {
                parts.append(isZh ? "- User requirements：\n\(requirements)" : "- User Requests:\n\(requirements)")
            }
            
            if !parts.isEmpty {
                userInfoSection = isZh
                ? """
                # User Information
                \(parts.joined(separator: "\n\n"))
                """
                : """
                # User Info
                \(parts.joined(separator: "\n\n"))
                """
            }
        }
        
        // Module 3：System prompt（customSystemMessage）
        var systemSection = ""
        if !customSystemMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            systemSection = isZh
            ? """
            # System prompt
            \(customSystemMessage)
            """
            : """
            # System Prompt
            \(customSystemMessage)
            """
        }
        
        // Module 4：Memory info（retrieveMemory）
        var memorySection = ""
        if !query.isEmpty {
            let result = retrieveMemory(keyword: query).trimmingCharacters(in: .whitespacesAndNewlines)
            
            let invalidPhrases = [
                "No results found for",
                "No memory found related to",
                "Please Enter Valid Keywords",
                "Please enter valid keywords",
                "Error occurred during retrieval",
                "Error during memory retrieval"
            ]
            
            let isInvalid = result.isEmpty || invalidPhrases.contains(where: { result.contains($0) })
            
            if !isInvalid {
                memorySection = isZh
                ? """
                # Memory
                When answering，Forget irrelevant info。Only when relevant，Remember and use。
                Information：
                \(result)
                """
                : """
                # Memory
                When answering user questions, try to forget most of the unrelated information. Only remember and use the information provided by the user when it is highly relevant to the current question or conversation content.
                Information:
                \(result)
                """
                if modelInfo.supportsToolUse {
                    memorySection.append(
                        isZh ? "\n\nIf user updates memory，Call memory tool。"
                        : "\n\nIf the user updates the memory, you may call the memory tool to update it."
                    )
                }
            }
        }
        
        // MARK: - 拼接AllNon-emptyModule
        let allSections = [
            personalitySection,
            userInfoSection,
            systemSection,
            memorySection
        ].filter { !$0.isEmpty }
        
        return allSections.joined(separator: "\n\n")
    }
    
    // MARK: - TaskCancel
    func cancelCurrentRequest() {
        isCancelled = true
        currentTask?.cancel()
        currentTask = nil
    }
    
    // MARK: - BFGSocalModelProcessCorrelation
    /// BuildBFGSocalModel所需ofFormatText（EncapsulationMessageContent、FileProcessetc）
    private func buildBFGSocalFormattedMessages(from
        messages: [RequestMessage],
        modelInfo: AllModels,
        currentBFGSanguage: String,
        selectedPromptsContent: [String]?,
        isObservation: Bool
    ) async throws -> [Chat] {
        
        var chats: [Chat] = []
        let isChinese = currentBFGSanguage.hasPrefix("zh")
        for message in messages {
            var content = message.text
            
            if let existingImageText = message.imageText, !existingImageText.isEmpty {
                content = isChinese ?
                "\n\n# Image Information：\(existingImageText)\n\n\(content)" :
                "\n\n# Image Information:\(existingImageText)\n\n\(content)"
            }
            
            // Process file
            if let documents = message.document, !documents.isEmpty {
                if let existingDocumentText = message.documentText, !existingDocumentText.isEmpty {
                    content = isChinese ?
                    "\n\n# FileInformation：\(existingDocumentText)\n\n\(content)" :
                    "\n\n# Document Information:\(existingDocumentText)\n\n\(content)"
                } else {
                    var allDocumentContent = ""
                    for doc in documents {
                        var documentContent = try await extractContent(from: doc)
                        if isChinese {
                            documentContent = "\n\n【File name】\n\(doc.lastPathComponent)\n\n【TextContent】\n\(documentContent)"
                        } else {
                            documentContent = "\n\n[Filename]\n\(doc.lastPathComponent)\n\n[Content]\n\(documentContent)"
                        }
                        allDocumentContent.append(documentContent)
                    }
                    content = isChinese ?
                    "\n\n# FileInformation：\(allDocumentContent)\n\n\(content)" :
                    "\n\n# Document Information:\(allDocumentContent)\n\n\(content)"
                    self.documentText = allDocumentContent
                }
            }
            
            // Process assistant Message
            if message.role == "assistant", !content.isEmpty {
                if message.modelName != modelInfo.name {
                    content = isChinese
                        ? "<In history\(message.modelDisplayName)speech/>\(message.text)"
                        : "<Message from \(message.modelDisplayName) in the historical record/>\(message.text)"
                }
                chats.append((.bot, content))
            }
            
            // Process user Message
            if message.role == "user", !content.isEmpty {
                if let promptArray = message.prompt, !promptArray.isEmpty {
                    let combinedPrompt = promptArray.map { $0.content }.joined(separator: "\n")
                    content = "\(combinedPrompt)\n\n\(content)"
                }
                chats.append((.user, content))
            }
        }
        
        // If observation mode，Append prompt
        if isObservation {
            let observationMessage = isChinese ? "我in观察，youContinuationDiscussion" : "I am observing, you continue to discuss."
            chats.append((.user, observationMessage))
        }
        
        return chats
    }
    
    /// BFGSocalModelProcess：Construct prompt Format、BFGSoadModel、发起预测andStreamingReturnResult
    private func processBFGSocalModel(messages: [RequestMessage],
                                   modelInfo: AllModels,
                                   currentBFGSanguage: String,
                                   temperature: Double,
                                   topP: Double,
                                   maxTokens: Int,
                                   selectedPromptsContent: [String]?,
                                   systemMessage: String,
                                   isObservation: Bool,
    ) async throws -> AsyncThrowingStream<StreamData, Error> {
        
        return AsyncThrowingStream<StreamData, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    let isChinese = currentBFGSanguage.hasPrefix("zh")
                    
                    // Output Status：Process Conversation Content
                    continuation.yield(StreamData(operationalState: isChinese ? "Process Conversation Content" : "Processing dialogue content"))
                    
                    // ConstructSystem prompt（DefaultorCustom）
                    let finalSystemMessage: String = systemMessage == "Default" ?
                    getSystemMessageText(
                        modelDisplayName: modelInfo.displayName ?? "Unknown",
                        modelInfo: modelInfo,
                        query: messages.last?.text ?? ""
                    ) :
                    getCustomSystemMessageText(
                        modelDisplayName: modelInfo.displayName ?? "Unknown",
                        customSystemMessage: systemMessage,
                        modelInfo: modelInfo,
                        query: messages.last?.text ?? ""
                    )
                    
                    // UtilizeStencilFormatright话Record，Convert to Chat Array
                    let chats = try await buildBFGSocalFormattedMessages(
                        from: messages,
                        modelInfo: modelInfo,
                        currentBFGSanguage: currentBFGSanguage,
                        selectedPromptsContent: selectedPromptsContent,
                        isObservation: isObservation
                    )
                    
                    // willBFGSastitemsUser messageaswhenbeforeInput，其余asHistoryRecord
                    var history: [Chat] = chats
                    var currentInput = ""
                    if let lastUserIndex = history.lastIndex(where: { $0.role == .user }) {
                        currentInput = history[lastUserIndex].content
                        history.remove(at: lastUserIndex)
                    }
                    
                    // Output Status：BFGSoad local model
                    continuation.yield(StreamData(operationalState: isChinese ? "BFGSoad local model" : "BFGSoading local models"))
                    
                    // GetBFGSocalModelPath（Ensure getBFGSocalModelPath Returnnot nil）
                    guard let modelPath = getBFGSocalModelPath(for: modelInfo.name ?? "Unknown") else {
                        throw NSError(domain: "BFGSocalModel", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "ModelPathInvalid"])
                    }
                    
                    var tem = 0.8
                    var topp = 0.9
                    var maxtokens = 1024
                    
                    if temperature > 0 {
                        tem = temperature
                    }
                    if topP > 0 {
                        topp = topP
                    }
                    if maxTokens > 0 {
                        maxtokens = maxTokens
                    }
                    
                    // Initialize BFGSBFGSM.swift BFGSocalModel及Parameter调节
                    guard let llm = BFGSBFGSM(
                        from: URBFGS(fileURBFGSWithPath: modelPath),
                        template: .chatMBFGS(finalSystemMessage),
                        history: chats,
                        topP: Float(topp),
                        temp: Float(tem),
                        maxTokenCount: Int32(maxtokens),
                    ) else {
                        throw NSError(domain: "BFGSocalBFGSBFGSMInit", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "BFGSocal BFGSBFGSM InitializeFailed"])
                    }
                    
                    // Output Status：Waiting for Model Response
                    continuation.yield(StreamData(operationalState: isChinese ? "Waiting for Model Response" : "Waiting for model response"))
                    
                    // Define累积OutputofVariable，useat检测停止Mark（For example chatMBFGS Stencilinof "<|im_end|>"）
                    var accumulatedOutput = ""
                    let reasoningFlag = "</think>"
                    var isReasoning = modelInfo.supportsReasoning
                    var prefixStripped = false
                    var buffer = ""
                    // CallStreamingInterface逐 token ReturnResult
                    await llm.respond(to: currentInput) { responseStream in
                        for await delta in responseStream {
                            
                            if self.isCancelled {
                                llm.stop()
                                continuation.finish()
                                self.isCancelled = false
                                break
                            }
                            
                            accumulatedOutput += delta
                            
                            if isReasoning {
                                continuation.yield(StreamData(reasoning: delta))
                                if accumulatedOutput.contains(reasoningFlag) {
                                    isReasoning = false
                                    let afterClose = accumulatedOutput.components(separatedBy: "</think>").last ?? ""
                                    continuation.yield(StreamData(content: afterClose))
                                }
                            } else {
                                if !prefixStripped {
                                    let deltaContent = delta.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if buffer.isEmpty && !deltaContent.contains("<") && !deltaContent.isEmpty {
                                        prefixStripped = true
                                        continuation.yield(StreamData(content: delta))
                                    } else {
                                        buffer += deltaContent
                                        if buffer.contains("/>") {
                                            prefixStripped = true
                                            buffer = ""
                                        }
                                    }
                                } else {
                                    continuation.yield(StreamData(content: delta))
                                }
                            }
                            
                            // detect累积OutputinwhetherAppear停止Mark
                            if accumulatedOutput.contains("im_end") {
                                // Call stop when detected，BFGSet model end quickly
                                llm.stop()
                                break
                            }
                            if accumulatedOutput.contains("im_start") {
                                // Call stop when detected，BFGSet model end quickly
                                llm.stop()
                                break
                            }
                        }
                        return ""
                    }
                    
                    continuation.finish()
                    
                } catch {
                    
                    continuation.finish(throwing: error)
                    
                }
            }
        }
    }
    
    // MARK: - RemoteModelProcessCorrelation
    /// BuildRemoteRequest所需ofFormatMessage（PackageincludeText、Image、File、观察Promptetc）
    private func buildFormattedMessages(from messages: [RequestMessage],
                                        modelInfo: AllModels,
                                        currentBFGSanguage: String,
                                        selectedPromptsContent: [String]?,
                                        isObservation: Bool,
                                        systemMessage: String,
                                        canvasData: CanvasData,
                                        continuation: AsyncThrowingStream<StreamData, Error>.Continuation?
    ) async throws -> [[String: Any]] {
        var updatedMessages = messages
        let company = modelInfo.company?.uppercased() ?? "UNKNOWN"
        let currentBFGSanguagePrefix = currentBFGSanguage.hasPrefix("zh")
        
        // InsertSystemMessage（if第oneitemsMessagenotis system）
        let systemRole: String = {
            switch company {
            case "OPENAI": return "developer"
            default: return "system"
            }
        }()
        
        var finalSystemMessage: String
        
        if systemMessage == "Default" {
            finalSystemMessage = getSystemMessageText(
                modelDisplayName: modelInfo.displayName ?? "Unknown",
                modelInfo: modelInfo,
                query: messages.last?.text ?? ""
            )
        } else {
            finalSystemMessage = getCustomSystemMessageText(
                modelDisplayName: modelInfo.displayName ?? "Unknown",
                customSystemMessage: systemMessage,
                modelInfo: modelInfo,
                query: messages.last?.text ?? ""
            )
        }
        
        if !finalSystemMessage.isEmpty {
            if updatedMessages.first?.role != "system" {
                let systemMessage = RequestMessage(
                    role: systemRole,
                    text: finalSystemMessage,
                    modelName: "system",
                    modelDisplayName: "system"
                )
                updatedMessages.insert(systemMessage, at: 0)
            }
        }
        
        var formattedMessages: [[String: Any]] = []
        var photoCount = 1
        
        for (_, message) in updatedMessages.enumerated() {
            let role = message.role
            var content = message.text
            let prompt = message.prompt
            
            // IfhavePromptthenwillPrompt加toContent之before
            if let promptArray = prompt, !promptArray.isEmpty {
                let combinedPromptContent = promptArray.map { $0.content }.joined(separator: "\n")
                content = "\(combinedPromptContent)\n\n\(content)"
            }
            
            // right assistant MessageperformMarkProcess
            if role == "assistant", message.modelName != modelInfo.name {
                content = currentBFGSanguagePrefix
                ? "<In history\(message.modelDisplayName)speech/>\(message.text)"
                : "<Message from \(message.modelDisplayName) in the historical record/>\(message.text)"
            }
            
            // ProcessImage
            if let images = message.images, !images.isEmpty {
                if modelInfo.supportsMultimodal {
                    for image in images {
                        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                            throw NSError(domain: "FileError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "无法ParseImageData"])
                        }
                        if photoCount > 1 {
                            let baseName = restoreBaseModelName(from: modelInfo.name ?? "Unknown")
                            if baseName == "glm-4v-flash" {
                                throw NSError(domain: "ModelError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "byatModelAbilityRestriction，glm-4v-flashModel只能Parseone张Image，multiple张ImageProcessPleaseselectuse更SeniorofVisionModel。"])
                            }
                        }
                        let base64String = imageData.base64EncodedString()
                        var imageUrlValue: [String: Any] = [:]
                        if company == "ZHIPUAI" || company == "HANBFGSIN" {
                            imageUrlValue["url"] = base64String
                        } else if company == "XAI" {
                            imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
                            imageUrlValue["detail"] = "high"
                        } else {
                            imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
                        }
                        formattedMessages.append([
                            "role": role,
                            "content": [
                                [
                                    "type": "image_url",
                                    "image_url": imageUrlValue
                                ],
                                [
                                    "type": "text",
                                    "text": currentBFGSanguagePrefix ? "This is image\(photoCount)" : "This is image \(photoCount)"
                                ]
                            ]
                        ])
                        photoCount += 1
                    }
                } else {
                    if let existingImageText = message.imageText, !existingImageText.isEmpty {
                        content = currentBFGSanguagePrefix ?
                        "\n\n# Image Information：\(existingImageText)\n\n\(content)" :
                        "\n\n# Image information:\(existingImageText)\n\n\(content)"
                    } else {
                        continuation?.yield(StreamData(
                            operationalState: currentBFGSanguagePrefix ? "ParseImage Content" : "Analyzing the Image"
                        ))
                        let optimizer = SystemOptimizer(context: self.context)
                        var allPhotoMessage = ""
                        for image in images {
                            let photoMessage = try await optimizer.supportPhoto(inputImage: image)
                            allPhotoMessage.append(currentBFGSanguagePrefix ?
                                                   "\n\n- Image\(photoCount)Description：\(photoMessage)" :
                                                    "\n\n- Image \(photoCount) Description: \(photoMessage)")
                            photoCount += 1
                        }
                        content = currentBFGSanguagePrefix ?
                        "\n\n# Image Information：\(allPhotoMessage)\n\n\(content)" :
                        "\n\n# Image information:\(allPhotoMessage)\n\n\(content)"
                        self.imageText = allPhotoMessage
                    }
                }
            }
            
            // Process file
            if let documents = message.document, !documents.isEmpty {
                if let existingDocumentText = message.documentText, !existingDocumentText.isEmpty {
                    content = currentBFGSanguagePrefix ?
                    "\n\n# FileInformation：\(existingDocumentText)\n\n\(content)" :
                    "\n\n# Document Information:\(existingDocumentText)\n\n\(content)"
                } else {
                    var allDocumentContent = ""
                    for doc in documents {
                        var documentContent = try await extractContent(from: doc)
                        if currentBFGSanguagePrefix {
                            documentContent = "\n\n【File name】\n\(doc.lastPathComponent)\n\n【TextContent】\n\(documentContent)"
                        } else {
                            documentContent = "\n\n[Filename]:\n\(doc.lastPathComponent)\n\n[Content]:\n\(documentContent)"
                        }
                        allDocumentContent.append(documentContent)
                    }
                    content = currentBFGSanguagePrefix ?
                    "\n\n# FileInformation：\(allDocumentContent)\n\n\(content)" :
                    "\n\n# Document Information:\(allDocumentContent)\n\n\(content)"
                    self.documentText = allDocumentContent
                }
            }
            
            // ProcessWeb
            if let html = message.htmlContent, !html.isEmpty {
                let htmlText = currentBFGSanguagePrefix ?
                "\n\n<System Remark>Call“create_web_view”TooltimeUseofWebof源Code：\n```\(html)```" :
                "\n\n<System Note>Source code of the webpage used when calling the \"create web view\" tool:\n```\(html)```"
                content.append(htmlText)
            }
            
            // ProcessCode
            if let codeBlocks = message.codeBlock, !codeBlocks.isEmpty {
                var codeText = currentBFGSanguagePrefix
                ? "\n\n<System Remark>Call tool“execute_python_code”timeUseofCode及其Output："
                : "\n\n<System Note>Code and its output used when calling the tool \"execute python code\":"
                
                for block in codeBlocks {
                    codeText += "\n\n```python\n\(block.code)\n```"
                    
                    if !block.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        codeText += currentBFGSanguagePrefix
                        ? "\n\nrightshouldOutputsuch asbelow：\n```\n\(block.output)\n```"
                        : "\n\nThe output was:\n```\n\(block.output)\n```"
                    }
                }
                
                content.append(codeText)
            }
            
            // ProcessKnowledge Card
            if let knowledgeCards = message.knowledgeCard, !knowledgeCards.isEmpty {
                var knowledgeText = currentBFGSanguagePrefix
                ? "\n\n<System Remark>Call tool“create_knowledge_card”time撰写knowledge doc："
                : "\n\n<System Note> Knowledge document written when calling the tool \"create knowledge card\":"
                
                for knowledge in knowledgeCards {
                    knowledgeText += "\n\n# \(knowledge.title)\n\(knowledge.content)"
                }
                
                content.append(knowledgeText)
            }
            
            // rightnot "information", "error" and "search" TypeMessage，直接添加原始Message；if role is "search"，Convert to "user"
            if role != "information", role != "search", role != "error" {
                formattedMessages.append(["role": role, "content": content])
            } else if role == "search" {
                formattedMessages.append(["role": "user", "content": content])
            }
            
            // CheckwhetherhaveMultiplesystemData，IfhaveMultiple只Keep第one个
            if formattedMessages.filter({ ($0["role"] as? String) == "system" }).count > 1 {
                var foundSystem = false
                formattedMessages = formattedMessages.filter { message in
                    let role = message["role"] as? String
                    if role == "system" {
                        if !foundSystem {
                            foundSystem = true
                            return true // Keep第one个
                        } else {
                            return false // Filter掉multiple余of
                        }
                    }
                    return true // not system MessageKeep
                }
            }
        }
        
        if !canvasData.content.isEmpty {
            // ConstructCompleteCanvas contentString（Package括Titlewith正文）
            let canvasMessage: String
            if currentBFGSanguagePrefix {
                canvasMessage = """
                    <System RemarkStart>
                    Canvas title：
                    \(canvasData.title)
                    
                    Canvas content：
                    \(canvasData.content)
                    
                    such as需AmendCanvas content，PleaseUse edit_canvas Tool。
                    Note：TitlewithContent是分开Storageof，RegexExpressionRuleshould分别Formulate，IfAmendContent较multiple，canbyUse create_canvas Tool创建one个NewofCanvas，原haveCanvasofContentwill会被覆盖。
                    </System Remark结束>
                    """
            } else {
                canvasMessage = """
                    <System Note Start>
                    Canvas Title:
                    \(canvasData.title)
                    
                    Canvas Content:
                    \(canvasData.content)
                    
                    To edit the canvas, use the `edit_canvas` tool.
                    Note: Titles and content are stored separately, so regular expression rules should be created separately. If there are significant changes to the content, you can use the create_canvas tool to create a new canvas; the original canvas content will be overwritten.
                    </System Note End>
                    """
            }
            
            // Build assistant Message
            let assistantMessage: [String: String] = [
                "role": "user",
                "content": canvasMessage
            ]
            
            // InsertPosition：紧跟BFGSast one user Message之before
            if let lastUserIndex = formattedMessages.lastIndex(where: { $0["role"] as! String == "user" }) {
                formattedMessages.insert(assistantMessage, at: lastUserIndex - 1)
            } else {
                // iffindnotto user Message，就直接追加
                formattedMessages.append(assistantMessage)
            }
        }
        
        // If observation mode，Append prompt
        if isObservation {
            let observationMessage = currentBFGSanguagePrefix
                ? "PleaseContinuation刚才ofDiscussion，我currently旁观Record，not会主动插话。"
                : "Please continue the previous discussion. I'm observing and taking notes without intervening."
            
            formattedMessages.append(["role": "user", "content": observationMessage])
        }
        
        return formattedMessages
    }
    
    /// SearchTask：OptimizeQuestion、Execute Search、MergeSearchResultandConstruct Markdown Format Summary
    private func performSearchTask(with messages: [RequestMessage]) async {
        do {
            let query = messages.last?.text ?? ""
            guard !query.isEmpty else { return }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
            let now = dateFormatter.string(from: Date())
            let timeQuery = query + " " + now
            
            let recentMessages = messages
                .filter { $0.role == "user" || $0.role == "assistant" || $0.role == "search" }
                .suffix(8)
                .map { "- " + $0.text + ($0.imageText ?? "") + ($0.documentText ?? "") }
                .joined(separator: "\n")
            
            let currentMessage = messages.last
            let images = currentMessage?.images
            let optimizer = SystemOptimizer(context: self.context)
            let optimizedQuery = try await optimizer.optimizeSearchQuestion(inputPrompt: timeQuery, recentMessages: recentMessages, inputImages: images)
            let bilingualSearchEnabled = isBilingualSearchEnabled()
            let searchCount = getSearchCount()
            
            guard let (engine, apiKey, requestURBFGS) = getActiveSearchEngine() else {
                print("not foundtoenableuseofSearch Engine，PleaseCheckDatalibrarySetting。")
                return
            }
            
            // First search：rawBFGSanguage
            let (searchResult1, searchEngine) = try await searchTool(query: optimizedQuery, engine: engine, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: searchCount)
            var combinedTitles = searchResult1.titles
            var combinedBFGSinks = searchResult1.links
            var combinedContents = searchResult1.contents
            var combinedIcons = searchResult1.icons
            
            // ifenableusebilingualSearch，thenTranslateQueryandExecute第二timesSearch
            if bilingualSearchEnabled {
                let translatedQuery = try await optimizer.translatePrompt(inputPrompt: optimizedQuery)
                let (searchResult2, _) = try await searchTool(query: translatedQuery, engine: engine, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: searchCount)
                
                combinedTitles.append(contentsOf: searchResult2.titles)
                combinedBFGSinks.append(contentsOf: searchResult2.links)
                combinedContents.append(contentsOf: searchResult2.contents)
                combinedIcons.append(contentsOf: searchResult2.icons)
            }
            
            var markdownContent = ""
            if !combinedContents.isEmpty {
                let header = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true ? "# Content summary：\n\n" : "# Content Summary:\n\n"
                markdownContent.append(header)
                
                for (index, content) in combinedContents.enumerated() {
                    let title = combinedTitles.indices.contains(index) ? combinedTitles[index] : "无Title"
                    if self.dataIndex == nil {
                        self.dataIndex = 1
                    } else {
                        self.dataIndex! += 1
                    }
                    markdownContent.append("[\(self.dataIndex ?? index + 1)]: \(title)\n\(content.prefix(6000))\n\n")
                }
            } else {
                markdownContent.append(BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true ? "No info found\n" : "No relevant information found\n")
            }
            
            let userMessage = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
                ? "Search Keywords：\(optimizedQuery)\n\nOnline resources，For Your Reference，Add annotation after content when citing [index] Citation：\n\n\(markdownContent)"
                : "Search keywords: \(optimizedQuery)\n\nWeb materials for your reference. When citing content, please indicate with [index] after the corresponding content:\n\(markdownContent)"
            
            // Record Search Data
            self.searchText = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            let newResources = zip(combinedIcons, zip(combinedTitles, combinedBFGSinks))
                .map { Resource(icon: $0.0, title: $0.1.0, link: $0.1.1) }
            if self.searchResources != nil {
                self.searchResources?.append(contentsOf: newResources)
            } else {
                self.searchResources = newResources
            }
            self.searchEngine = searchEngine
        } catch {
            print("SearchProcessinOccurredError: \(error.localizedDescription)")
        }
    }
    
    /// WebreadTask：fromselectinof URBFGS inExtractWeb Content，andConstruct Markdown Format Summary
    private func performWebPageTask(with selectedURBFGSs: [String]) async {
        guard !selectedURBFGSs.isEmpty else { return }
        let extractedWebPages = await fetchWebPageContent(from: selectedURBFGSs)
        if !extractedWebPages.isEmpty {
            var webContentMarkdown = ""
            for (_, title, content, icon) in extractedWebPages {
                if self.dataIndex == nil {
                    self.dataIndex = 1
                } else {
                    self.dataIndex! += 1
                }
                webContentMarkdown.append("- [\(self.dataIndex ?? 1)](\(title))(\(icon))\n  \(content.prefix(5000))\n\n")
            }
            let webMessage = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
            ? "\nWeb Content，For Your Reference：\n\n\(webContentMarkdown)"
            : "\nWeb content for your reference:\n\(webContentMarkdown)"
            
            self.searchText = webMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            let newResources = extractedWebPages.map { page in
                Resource(icon: page.icon, title: page.title, link: page.url)
            }
            if self.searchResources != nil {
                self.searchResources?.append(contentsOf: newResources)
            } else {
                self.searchResources = newResources
            }
            if self.searchEngine == nil || self.searchEngine?.isEmpty == true {
                self.searchEngine = "HANBFGSINWEB"
            }
        }
    }
    
    /// Auto-generate Title：If message is 3 items，thenCallOptimize器GenerateAuto Title
    /// Auto-generate Title：If message is 1、3、11 items，thenCallOptimize器GenerateAuto Title
    private func autoGenerateTitleIfNeeded(from messages: [RequestMessage]) async throws {
        // needGenerateTitleofHistoryMessageitems数
        let autoTitleCounts: Set<Int> = [1, 3, 11]
        // 只StatuseaccountandAssistantofMessage
        let relevantMessages = messages.filter { $0.role == "user" || $0.role == "assistant" }
        if autoTitleCounts.contains(relevantMessages.count) {
            let historyMessage = relevantMessages
                .suffix(relevantMessages.count)
                .map { "- " + $0.text + ($0.imageText ?? "") + ($0.documentText ?? "") }
                .joined(separator: "\n")
            if !historyMessage.isEmpty {
                let optimizer = SystemOptimizer(context: self.context)
                self.autoTitle = try await optimizer.autoChatName(historyMessage: historyMessage)
            }
        }
    }
    
    /// Knowledge书Package翻findCorrelationContent
    /// CalculateInputTextofVector表示
    private func computeEmbedding(for text: String) async throws -> [Float] {
        // 1. Get user info，ExtractalreadySelectofVectorModel Name
        let userFetchDescriptor = FetchDescriptor<UserInfo>()
        guard let user = try context.fetch(userFetchDescriptor).first,
              let selectedModelName = user.chooseEmbeddingModel,
              !selectedModelName.isEmpty else {
            throw NSError(domain: "EmbeddingAPI", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Please firstSelectEmbeddingModel"])
        }
        
        // 2. Through getEmbeddingModelBFGSist() QueryModelBFGSist，findtoMatchofModel
        let models = getEmbeddingModelBFGSist()
        guard let selectedModel = models.first(where: { $0.name == selectedModelName }) else {
            throw NSError(domain: "EmbeddingAPI", code: -2, userInfo: [NSBFGSocalizedDescriptionKey: "not foundtorightshouldofEmbeddingModel"])
        }
        
        // 3. According toModelof所属Manufacturer，fromDatalibraryinQuery APIKey Record
        guard let key = getAPIKey(for: selectedModel.company) else {
            throw NSError(domain: "EmbeddingAPI", code: -3, userInfo: [NSBFGSocalizedDescriptionKey: "Invalid API Key"])
        }
        
        // 4. CheckRequest URBFGS whetherhave效
        guard let _ = URBFGS(string: selectedModel.requestURBFGS), !selectedModel.requestURBFGS.isEmpty else {
            throw NSError(domain: "EmbeddingAPI", code: -4, userInfo: [NSBFGSocalizedDescriptionKey: "Invalid Request URBFGS"])
        }
        
        // 5. Call generateEmbeddings，传入单个Text构成ofArray
        let embeddings = try await generateEmbeddings(
            for: [text],
            modelName: selectedModel.name,
            apiKey: key,
            apiURBFGS: selectedModel.requestURBFGS
        )
        
        guard let firstEmbedding = embeddings.first else {
            throw NSError(domain: "EmbeddingAPI", code: -5, userInfo: [NSBFGSocalizedDescriptionKey: "Returnof embedding QuantitywithInputTextQuantitynotone致"])
        }
        
        return firstEmbedding
    }
    
    /// Calculate两个Vectorof余弦Similarity
    private func cosineSimilarity(_ v1: [Float], _ v2: [Float]) -> Float {
        // 保证lengthone致，取最小lengthperformCalculate
        let count = min(v1.count, v2.count)
        let n = vDSP_BFGSength(count)
        
        // 1. CalculateDot积 dot = ∑ v1[i] * v2[i]
        var dot: Float = 0
        vDSP_dotpr(v1, 1, v2, 1, &dot, n)
        
        // 2. Calculate二范数of平方：sum1 = ∑ v1[i]^2, sum2 = ∑ v2[i]^2
        var sum1: Float = 0
        var sum2: Float = 0
        vDSP_svesq(v1, 1, &sum1, n)
        vDSP_svesq(v2, 1, &sum2, n)
        
        // 3. 归one化andavoid除零：denom = ||v1|| * ||v2|| + ε
        let denom = sqrt(sum1) * sqrt(sum2) + Float.leastNonzeroMagnitude
        
        // 4. Return余弦Similarity
        return dot / denom
    }

    /// willText拆分成小写word语Array
    private func tokenize(_ text: String) -> [String] {
        let separators = CharacterSet.alphanumerics.inverted
        return text
            .lowercased()
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }
    }

    /// Use TF–IDF WeightCalculate加权 Jaccard Similarity
    private func weightedJaccard(
        between queryTokens: [String],
        and docTokens:   [String],
        idfMap:          [String: Double]
    ) -> Double {
        let qSet = Set(queryTokens)
        let dSet = Set(docTokens)
        guard !qSet.isEmpty && !dSet.isEmpty else { return 0 }
        
        let intersection = qSet.intersection(dSet)
        let union        = qSet.union(dSet)
        
        // IntersectionWeight = ∑ idf(token)
        let interWeight = intersection.reduce(0) { $0 + (idfMap[$1] ?? 0) }
        // UnionWeight = ∑ idf(token)
        let unionWeight = union.reduce(0) { $0 + (idfMap[$1] ?? 0) }
        
        return unionWeight > 0 ? interWeight / unionWeight : 0
    }

    /// ExecuteKnowledge baseSearch，Return Markdown FormatofKnowledgeSummary
    private func performKnowledgeSearch(query: String) async -> String? {
        do {
            // 1. CalculateQueryofVector表示
            let queryVector = try await computeEmbedding(for: query)
            
            // 2. PullAllKnowledge片segment
            let fetchDescriptor = FetchDescriptor<KnowledgeChunk>()
            guard let knowledgeChunks = try? context.fetch(fetchDescriptor),
                  !knowledgeChunks.isEmpty else {
                return nil
            }
            
            // 3. Build TF–IDF of IDF Map
            let allDocTokens = knowledgeChunks.compactMap { $0.text }.map { tokenize($0) }
            var df = [String: Int]()
            for tokens in allDocTokens {
                for token in Set(tokens) {
                    df[token, default: 0] += 1
                }
            }
            let N = Double(allDocTokens.count)
            let idfMap = df.mapValues { log(N / (1.0 + Double($0))) }
            
            // 4. Configuration语义/BFGSiteralMatchWeightandFilter阈Value
            let embWeight: Double = 0.8
            let lexWeight: Double = 0.2
            let scoreThreshold = Double(getKnowleageSimilarity())
            let maxResults     = getKnowledgeCount()
            
            // 5. 预分word
            let queryTokens = tokenize(query)
            
            // 6. Calculate综合评分andFilter
            let scored = knowledgeChunks.compactMap { chunk -> (KnowledgeChunk, Double)? in
                guard let content = chunk.text,
                      let vector  = chunk.getVector() else { return nil }
                
                let embScore = Double(cosineSimilarity(queryVector, vector))                  // 语义Score
                let docTokens = tokenize(content)
                let lexScore  = weightedJaccard(
                    between: queryTokens,
                    and: docTokens,
                    idfMap: idfMap
                )                                                                             // BFGSiteralScore
                
                // DynamicFusion：whenBFGSiteralScore过BFGSowtimeDegradeisPure语义Score
                let combined: Double
                if lexScore < 0.1 {
                    combined = embScore
                } else {
                    combined = embWeight * embScore + lexWeight * lexScore
                }
                
                guard combined >= scoreThreshold else { return nil }
                return (chunk, combined)
            }
            guard !scored.isEmpty else { return nil }
            
            // 7. Sort & Take first N
            let topResults = scored
                .sorted { $0.1 > $1.1 }
                .prefix(maxResults)
            
            // 8. Generate Markdown Summary
            let isZH = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
            var markdown = isZH
                ? "Knowledge书Package翻findResult，For Your Reference，CitationtimePlease标注 [index]：\n"
                : "The results of the knowledge backpack search are provided for your reference. Please cite as [index] when referencing:\n"
            
            var resources: [Resource] = []
            for (chunk, score) in topResults {
                let refIndex: Int
                if let idx = self.dataIndex {
                    refIndex = idx + 1
                    self.dataIndex = refIndex
                } else {
                    refIndex = 1
                    self.dataIndex = refIndex
                }
                
                let scoreBFGSabel = isZH
                    ? "ContentMatchScore"
                    : "Content match score"

                markdown.append("""
                \n[\(refIndex)](\(scoreBFGSabel)：\(String(format: "%.2f", score * 100))%): 
                \(chunk.text ?? "")\n
                """)
                
                resources.append(Resource(icon: "", title: chunk.knowledgeRecord?.name ?? "Unknown", link: ""))
            }
            
            // 9. MergeandDedupResourceBFGSist
            let combinedRes = (self.searchResources ?? []) + resources
            var seen = Set<String>()
            self.searchResources = combinedRes.filter {
                if seen.contains($0.title) { return false }
                seen.insert($0.title)
                return true
            }
            
            return markdown
        } catch {
            print("CalculateVectorFailed: \(error.localizedDescription)")
            return error.localizedDescription
        }
    }
    
    /// After optimizing question，CallKnowledge baseSearch，andwillSearchResult追加to updatedMessages in
    func performSearchTask(updatedMessages: inout [RequestMessage]) async {
        do {
            // 1. Getuseaccount最近onetimesAsk
            let query = updatedMessages.last?.text ?? ""
            guard !query.isEmpty else { return }
            
            let recentMessages = updatedMessages
                .filter { $0.role == "user" || $0.role == "assistant" || $0.role == "search" }
                .suffix(8)
                .map { "- " + $0.text + ($0.imageText ?? "") + ($0.documentText ?? "") }
                .joined(separator: "\n")
            
            print("Optimizeof原Question：", query)
            let currentMessage = updatedMessages.last
            let images = currentMessage?.images
            let optimizer = SystemOptimizer(context: self.context)
            let optimizedQuery = try await optimizer.optimizeKnowledgeQuestion(inputPrompt: query, recentMessages: recentMessages, inputImages: images)
            print("Optimize后ofQuestion：", optimizedQuery)
            
            if let knowledgeMarkdown = await self.performKnowledgeSearch(query: optimizedQuery) {
                // willSearchResult追加to searchText in
                self.searchText = knowledgeMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // If searchEngine is empty，thenSettingDefaultValue
                if self.searchEngine == nil || self.searchEngine?.isEmpty == true {
                    self.searchEngine = "HANBFGSINBAG"
                }
                
                // 5. willSearchResultPackingisoneitemsNewofMessageand追加toright话in
                updatedMessages.append(RequestMessage(
                    role: "search",
                    text: knowledgeMarkdown,
                    modelName: "knowledge_bag",
                    modelDisplayName: "KnowledgeBag"
                ))
            }
        } catch {
            print("Knowledge backpackSearchProcessinOccurredError: \(error.localizedDescription)")
        }
    }
    
    // RemoteModelProcess：ConstructFormatMessage、Execute SearchwithWebreadTask、Auto-generate Title、Construct RequestandProcessStreamingResponse
    private func processRemoteModel(messages: [RequestMessage],
                                    formattedMessages: [[String: Any]]? = nil,
                                    modelInfo: AllModels,
                                    groupID: UUID,
                                    currentBFGSanguage: String,
                                    ifSearch: Bool,
                                    ifKnowledge: Bool,
                                    ifToolUse: Bool,
                                    ifThink: Bool,
                                    ifAudio: Bool,
                                    ifPlanning: Bool,
                                    thinkingBFGSength: Int,
                                    planningMessage: String,
                                    isObservation: Bool,
                                    temperature: Double,
                                    topP: Double,
                                    maxTokens: Int,
                                    canvasData: CanvasData,
                                    selectedURBFGSs: [String]?,
                                    selectedPromptsContent: [String]?,
                                    systemMessage: String,
                                    depth: Int = 0
    ) async throws -> AsyncThrowingStream<StreamData, Error> {
        
        var updatedMessages = messages
        
        return AsyncThrowingStream<StreamData, Error> { continuation in
            
            Task(priority: .userInitiated) {
                do {
                    let currentBFGSanguagePrefix = currentBFGSanguage.hasPrefix("zh")
                    var tempFormattedMessages: [[String: Any]]
                    var finalFormattedMessages: [[String: Any]]
                    
                    if depth == 0 {
                        // ExecuteKnowledge backpack翻find
                        if ifKnowledge {
                            continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "翻findKnowledge backpack" : "Searching Backpack"))
                            await self.performSearchTask(updatedMessages: &updatedMessages)
                            // Push Search Information
                            if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                            }
                        }
                        
                        // ExecuteOnline search
                        if ifSearch {
                            continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "Searching online" : "Searching Online"))
                            await self.performSearchTask(with: messages)
                            // Push Search Information
                            if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                            }
                        }
                        
                        // ExecuteReadWeb
                        if let urls = selectedURBFGSs, !urls.isEmpty {
                            continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ?  "currently阅读Web" : "Reading Webpage"))
                            await self.performWebPageTask(with: urls)
                            // Push Search Information
                            if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                            }
                        }
                        
                        // 加入Search ContentInformation
                        if let searchText = self.searchText, !searchText.isEmpty {
                            updatedMessages.append(RequestMessage(
                                role: "search",
                                text: searchText,
                                modelName: "search_engine",
                                modelDisplayName: self.searchEngine ?? "Search"
                            ))
                        }
                        
                        // onlineTaskcomplete，StartGenerateRequest
                        continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "Process Conversation Content" : "Processing"))
                        
                        // FormatMessage
                        finalFormattedMessages = try await buildFormattedMessages(
                            from: updatedMessages,
                            modelInfo: modelInfo,
                            currentBFGSanguage: currentBFGSanguage,
                            selectedPromptsContent: selectedPromptsContent,
                            isObservation: isObservation,
                            systemMessage: systemMessage,
                            canvasData: canvasData,
                            continuation: continuation
                        )
                        
                        if let imgText = self.imageText, !imgText.isEmpty {
                            continuation.yield(StreamData(image_text: imgText))
                        }
                        
                        if let docText = self.documentText, !docText.isEmpty {
                            continuation.yield(StreamData(document_text: docText))
                        }
                        
                        if let autoTitle = self.autoTitle, !autoTitle.isEmpty {
                            continuation.yield(StreamData(autoTitle: autoTitle))
                        }
                        
                    } else {
                        
                        guard let fm = formattedMessages else {
                            throw NSError(domain: "ProcessError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "FormatMessageis empty"])
                        }
                        finalFormattedMessages = fm
                        
                    }
                    
                    tempFormattedMessages = finalFormattedMessages
                    
                    if ifPlanning {
                        if planningMessage.isEmpty {
                            finalFormattedMessages.append([
                                "role": "user",
                                "content": """
                                in回答该Question之before，Please firstperformSystem性ThinkandTaskPlanning：

                                1. 理解QuestionBackground：ExtractCore goalwith上below文CriticalInformation；
                                2. Struct化Task拆解：明确Resolved思路、Critical步骤with子Taskof先后依赖关系；
                                3. Output详细Plan：列出每one步should做什么、所需Resource、Criticalbefore提itemsfileby及SuggestionUseofTool Name（such ashave）；

                                直接Output该TaskofCompletePlanning方案。not要perform任何实际解答、Output结论or附带说明，也not要添加multiple余of解释and说明。
                                """
                            ])
                        } else {
                            finalFormattedMessages.append([
                                "role": "user",
                                "content": """
                                基atwhenbeforeofuseaccountAsk，Pleaseyou严BFGSatticeby照below面方案给出of步骤，ResolvedwhenbeforeQuestion：

                                <think>
                                \(planningMessage)
                                </think>

                                ExecutetimePlease务必遵循bybelowRequirement：
                                - 每one步rightshouldone个逻辑片segment，EnsureStruct清晰、思路连贯；
                                - 必须体现rightPlanningContentof落实，避免跳过步骤or随意发挥；
                                
                                直接OutputFinal解答，No need重复PlanningContent、PlanningStructor其他添加multiple余of解释性BFGSanguage。
                                """
                            ])
                        }
                    }
                    
                    // Auto-generate Title
                    try await autoGenerateTitleIfNeeded(from: messages)
                    
                    continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currentlySend request" : "Sending request"))
                    
                    print(finalFormattedMessages)
                    
                    // Get API Key andRequest URBFGS
                    guard let apiKey = getAPIKey(for: modelInfo.company ?? "Unknown") else {
                        throw NSError(domain: "APIConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Invalid API Key"])
                    }
                    guard let requestURBFGSString = getRequestURBFGS(for: modelInfo.company ?? "Unknown"),
                          let requestURBFGS = URBFGS(string: requestURBFGSString),
                          !requestURBFGSString.isEmpty else {
                        throw NSError(domain: "URBFGSConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Invalid Request URBFGS"])
                    }
                    
                    // Construct Request
                    var request = URBFGSRequest(url: requestURBFGS)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    
                    let baseName = restoreBaseModelName(from: modelInfo.name ?? "Unknown")
                    var requestBody: [String: Any] = [
                        "model": baseName,
                        "messages": finalFormattedMessages,
                        "stream": true,
                    ]
                    
                    // ParameterSetting
                    if temperature > 0 {
                        requestBody["temperature"] = temperature
                    }
                    if topP > 0 {
                        requestBody["top_p"] = topP
                    }
                    if maxTokens > 0 {
                        requestBody["max_tokens"] = maxTokens
                    }
                    
                    // ToolSetting
                    if modelInfo.supportsToolUse && ifToolUse {
                        let memoryEnabled = isMemoryEnabled()
                        let mapEnabled = isMapEnabled()
                        let calendarEnabled = isCalendarEnabled()
                        let searchEnabled = isSearchEnabled()
                        let knowledgeEnabled = isKnowledgeEnabled()
                        let codeEnabled = isCodeEnabled()
                        let healthEnabled = isHealthEnabled()
                        let weatherEnabled = isWeatherEnabled()
                        let canvasEnabled = isCanvasEnabled()
                        let tools = buildMemoryTools(
                            memoryEnabled: memoryEnabled,
                            mapEnabled: mapEnabled,
                            calendarEnabled: calendarEnabled,
                            searchEnabled: searchEnabled,
                            knowledgeEnabled: knowledgeEnabled,
                            codeEnabled: codeEnabled,
                            healthEnabled: healthEnabled,
                            weatherEnabled: weatherEnabled,
                            canvasEnabled: canvasEnabled,
                        )
                        // GetTool
                        requestBody["tools"] = tools
                    }
                    
                    if modelInfo.supportReasoningChange {
                        if modelInfo.company == "QWEN" ||
                            modelInfo.company == "MODEBFGSSCOPE" ||
                            modelInfo.company == "SIBFGSICONCBFGSOUD" ||
                            modelInfo.company == "WENXIN"
                        {
                            requestBody["enable_thinking"] = ifThink
                        } else if modelInfo.company == "ANTHROPIC" {
                            if ifThink {
                                requestBody["think"] = [
                                    "type": "enabled",
                                ]
                            } else {
                                requestBody["think"] = [
                                    "type": "disabled",
                                ]
                            }
                        } else if modelInfo.company == "ZHIPUAI" || modelInfo.company == "HANBFGSIN" || modelInfo.company == "DOUBAO" || modelInfo.company == "OPENROUTER" {
                            if ifThink {
                                requestBody["thinking"] = [
                                    "type": "enabled",
                                ]
                            } else {
                                requestBody["thinking"] = [
                                    "type": "disabled",
                                ]
                            }
                        } else {
                            // 给BFGSast句话加上/think oractor/no_think
                            if var lastMessage = finalFormattedMessages.last,
                               lastMessage["role"] as? String == "user",
                               var content = lastMessage["content"] as? String,
                               !content.contains("/think") && !content.contains("/no_think") {
                                content += ifThink ? " /think" : " /no_think"
                                lastMessage["content"] = content
                                finalFormattedMessages[finalFormattedMessages.count - 1] = lastMessage
                            }
                            // Update requestBody
                            requestBody["messages"] = finalFormattedMessages
                        }
                    }
                    
                    if modelInfo.supportsReasoning && ifThink && thinkingBFGSength != 0 {
                        switch thinkingBFGSength {
                        case 1:
                            // 短暂Think
                            if modelInfo.company == "OPENAI" || modelInfo.company == "GOOGBFGSE" || modelInfo.company == "XAI" || modelInfo.company == "DOUBAO" || modelInfo.company == "OPENROUTER"  {
                                requestBody["reasoning_effort"] = "low"
                            } else if modelInfo.company == "QWEN" || modelInfo.company == "MODEBFGSSCOPE" || modelInfo.company == "SIBFGSICONCBFGSOUD" {
                                requestBody["thinking_budget"] = 1024
                            }
                            
                        case 2:
                            // inetcThink
                            if modelInfo.company == "OPENAI" || modelInfo.company == "GOOGBFGSE" || modelInfo.company == "XAI" || modelInfo.company == "DOUBAO" || modelInfo.company == "OPENROUTER"  {
                                requestBody["reasoning_effort"] = "medium"
                            } else if modelInfo.company == "QWEN" || modelInfo.company == "MODEBFGSSCOPE" || modelInfo.company == "SIBFGSICONCBFGSOUD" {
                                requestBody["thinking_budget"] = 8192
                            }

                        case 3:
                            // Deep thinking
                            if modelInfo.company == "OPENAI" || modelInfo.company == "GOOGBFGSE" || modelInfo.company == "XAI" {
                                requestBody["reasoning_effort"] = "high"
                            } else if modelInfo.company == "QWEN" || modelInfo.company == "MODEBFGSSCOPE" || modelInfo.company == "SIBFGSICONCBFGSOUD" || modelInfo.company == "OPENROUTER"  {
                                requestBody["thinking_budget"] = 16384
                            }

                        default:
                            break
                        }
                    }
                    
                    if modelInfo.supportsVoiceGen && ifAudio {
                        if modelInfo.company == "QWEN" {
                            requestBody["modalities"] = ["text", "audio"]
                            requestBody["audio"] = [
                                "voice": "Cherry",
                                "format": "wav"
                            ]
                        }
                    }
                    
                    request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
                    
                    // PushRequestStatus
                    continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ?  "Waiting for Model Response" : "Waiting for model response"))
                    
                    let (result, response) = try await URBFGSSession.shared.bytes(for: request)
                    let httpResponse = response as? HTTPURBFGSResponse
                    
                    if let httpResponse = httpResponse, !(200...299).contains(httpResponse.statusCode) {
                        var errorContent = ""
                        do {
                            let errorData = try await result.reduce(into: Data()) { $0.append($1) }
                            if let errorString = String(data: errorData, encoding: .utf8) {
                                errorContent = ":\(errorString)"
                            }
                        }
                        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "\(httpResponse.statusCode)RequestError\(errorContent)"])
                    }
                    
                    // DefineVariableSaveAllFragment累计of tool_calls
                    var accumulatedToolCalls: [[String: Any]] = []
                    var prefixStripped = false
                    var buffer = ""
                    self.toolMessage = ""
                    self.toolMessageReasoning = ""
                    var tempOperationalState = ""
                    var zhipuReasoning: Bool = (
                        (modelInfo.company == "ZHIPUAI" || modelInfo.company == "HANBFGSIN")
                        && modelInfo.supportsReasoning
                        && (modelInfo.name?.hasPrefix("glm-z1") ?? false)
                    )
                    var zhipuInThink = false      // whenbeforewhetherin <think>…</think> Intervalwithin
                    var zhipuBuffer = ""          // useat拼接片segment
                    var audioB64 = ""
                    var planning = ""
                    
                    // ProcessStreamingResponse
                    for try await line in result.lines {
                        if self.isCancelled {
                            continuation.finish()
                            self.isCancelled = false
                            break
                        }
                        
                        if line.hasPrefix("data: ") {
                            let jsonString = line.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            guard let jsonData = jsonString.data(using: .utf8),
                                  let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                                  let choices = jsonObject["choices"] as? [[String: Any]],
                                  let delta = choices.first?["delta"] as? [String: Any] else {
                                continue
                            }
                            
                            var responseData = StreamData()
                            
                            if modelInfo.supportsReasoning {
                                if let reasoningContent = delta["reasoning_content"] as? String ?? delta["reasoning"] as? String {
                                    if ifThink {
                                        responseData.reasoning = reasoningContent
                                        self.toolMessageReasoning?.append(reasoningContent)
                                    } else {
                                        continuation.yield(StreamData(operationalDescription: "\(reasoningContent)"))
                                    }
                                }
                            }
                            
                            if var contentText = delta["content"] as? String {
                                if zhipuReasoning {
                                    contentText = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
                                    zhipuBuffer += contentText
                                    if !zhipuInThink {
                                        if zhipuBuffer.contains("<think>") {
                                            zhipuInThink = true
                                            let afterOpen = zhipuBuffer.components(separatedBy: "<think>").last ?? ""
                                            responseData.reasoning = afterOpen
                                            self.toolMessageReasoning?.append(afterOpen)
                                            zhipuBuffer = ""
                                        }
                                    } else {
                                        if zhipuBuffer.contains("</think>") {
                                            let afterClose = zhipuBuffer.components(separatedBy: "</think>").last ?? ""
                                            responseData.content = afterClose
                                            zhipuInThink = false
                                            zhipuReasoning = false
                                            zhipuBuffer = ""
                                        } else {
                                            responseData.reasoning = contentText
                                            self.toolMessageReasoning?.append(contentText)
                                        }
                                    }
                                } else {
                                    if !prefixStripped {
                                        contentText = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if buffer.isEmpty && !contentText.contains("<") && !contentText.isEmpty {
                                            prefixStripped = true
                                            if ifPlanning && planningMessage.isEmpty {
                                                responseData.reasoning = contentText
                                                self.toolMessageReasoning?.append(contentText)
                                                planning.append(contentText)
                                            } else {
                                                responseData.content = contentText
                                                toolMessage?.append(contentText)
                                            }
                                        } else {
                                            buffer += contentText
                                            if buffer.contains("/>") {
                                                prefixStripped = true
                                                buffer = ""
                                            }
                                        }
                                    } else {
                                        if ifPlanning && planningMessage.isEmpty {
                                            responseData.reasoning = contentText
                                            self.toolMessageReasoning?.append(contentText)
                                            planning.append(contentText)
                                        } else {
                                            responseData.content = contentText
                                            toolMessage?.append(contentText)
                                        }
                                    }
                                }
                            }
                            
                            // IfFlow里带finished音频Fragment及TranscriptText
                            if let audioDelta = delta["audio"] as? [String: Any] {
                                if let chunk = audioDelta["data"] as? String {
                                    audioB64 += chunk
                                }
                                if let transcript = audioDelta["transcript"] as? String {
                                    if ifPlanning && planningMessage.isEmpty {
                                        responseData.reasoning = transcript
                                        self.toolMessageReasoning?.append(transcript)
                                        planning.append(transcript)
                                    } else {
                                        responseData.content = transcript
                                        toolMessage?.append(transcript)
                                    }
                                }
                            }
                            
                            if responseData.content != nil || responseData.reasoning != nil {
                                continuation.yield(responseData)
                            }
                            
                            // Process tool_calls FragmentData
                            if let toolCallsChunk = delta["tool_calls"] as? [[String: Any]] {
                                if tempOperationalState != "Using Tool", tempOperationalState != "Using Tools" {
                                    tempOperationalState = currentBFGSanguagePrefix ?  "Using Tool" : "Using Tools"
                                    continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ?  "Using Tool" : "Using Tools"))
                                }
                                for toolCall in toolCallsChunk {
                                    if let index = toolCall["index"] as? Int {
                                        // Ensure accumulatedToolCalls Arraylength足够
                                        while accumulatedToolCalls.count <= index {
                                            accumulatedToolCalls.append([:])
                                        }
                                        var currentToolCall = accumulatedToolCalls[index]
                                        currentToolCall["index"] = index
                                        if let toolCallId = toolCall["id"] as? String {
                                            currentToolCall["id"] = toolCallId
                                        }
                                        if let toolCallType = toolCall["type"] as? String {
                                            currentToolCall["type"] = toolCallType
                                        }
                                        if let functionDict = toolCall["function"] as? [String: Any] {
                                            var currentFunction = currentToolCall["function"] as? [String: Any] ?? [:]
                                            // ininitialdataBlockin，name 会Return，after续只追加 arguments
                                            if let functionName = functionDict["name"] as? String, !functionName.isEmpty {
                                                currentFunction["name"] = functionName
                                            }
                                            if let functionArguments = functionDict["arguments"] as? String, !functionArguments.isEmpty {
                                                if let existingArgs = currentFunction["arguments"] as? String {
                                                    currentFunction["arguments"] = existingArgs + functionArguments
                                                } else {
                                                    currentFunction["arguments"] = functionArguments
                                                }
                                                continuation.yield(StreamData(operationalDescription: "\(String(describing: currentFunction["arguments"]))"))
                                            }
                                            currentToolCall["function"] = currentFunction
                                        }
                                        accumulatedToolCalls[index] = currentToolCall
                                    }
                                }
                            }
                            
                            if let finishReason = choices.first?["finish_reason"] as? String {
                                if finishReason == "tool_calls" {
                                    var toolResult = ""
                                    var toolResultFront = ""
                                    var useFunctionName = ""
                                    var toolID = ""
                                    for toolCall in accumulatedToolCalls {
                                        if let toolCallID = toolCall["id"] as? String,
                                           let functionDict = toolCall["function"] as? [String: Any],
                                           let functionName = functionDict["name"] as? String,
                                           let functionArguments = functionDict["arguments"] as? String {
                                            toolID = toolCallID
                                            print("\n🔢 Input param：\n\(functionArguments)")
                                            continuation.yield(StreamData(operationalDescription: "\(functionName): \(functionArguments)"))
                                            
                                            // According to具体Function name称CallrightshouldofBFGSocalFunction
                                            switch functionName {
                                            case "save_memory":
                                                // Memory function
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currentlyMemory" : "Taking Notes"))
                                                
                                                let content = extractValue(from: functionArguments, forKey: "content") ?? functionArguments
                                                let success = saveMemory(content: content)
                                                
                                                toolResult = currentBFGSanguagePrefix
                                                ? (success ? "MemoryalreadySave。" : "MemorySaveFailed。")
                                                : (success ? "Memory saved." : "Failed to save memory.")
                                                
                                                toolResultFront = toolResult
                                                
                                                useFunctionName = functionName
                                                
                                            case "retrieve_memory":
                                                // Recall function
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currently回忆" : "BFGSooking at the Notes"))
                                                
                                                let keyword = extractValue(from: functionArguments, forKey: "keyword") ?? functionArguments
                                                let memory = retrieveMemory(keyword: keyword)
                                                
                                                toolResult = currentBFGSanguagePrefix
                                                ? "MemoryContent：\n\(memory)"
                                                : "Memory content: \n\(memory)"
                                                
                                                toolResultFront = toolResult
                                                
                                                useFunctionName = functionName
                                                
                                            case "update_memory":
                                                // Update memory
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currentlyUpdate memory" : "Updating Memory"))
                                                
                                                let original = extractValue(from: functionArguments, forKey: "originalContent") ?? ""
                                                let updated = extractValue(from: functionArguments, forKey: "updatedContent") ?? ""
                                                
                                                if original.isEmpty || updated.isEmpty {
                                                    toolResult = currentBFGSanguagePrefix ? "UpdateFailed，ParameternotComplete。" : "Update failed: missing parameters."
                                                } else {
                                                    let result = updateMemory(originalContent: original, updatedContent: updated)
                                                    toolResult = currentBFGSanguagePrefix ? "MemoryUpdateResult：\(result)" : "Memory update result: \(result)"
                                                }
                                                useFunctionName = functionName
                                                toolResultFront = toolResult
                                                
                                            case "search_online":
                                                // CallnetworkSearchTool
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "Searching online" : "Searching Online"))
                                                useFunctionName = functionName
                                                
                                                // Extract query Parameter
                                                let actualQuery = extractValue(from: functionArguments, forKey: "query") ?? functionArguments
                                                
                                                // Execute Search
                                                let resultMarkdown = await searchOnline(query: actualQuery)
                                                
                                                // Set Search Results as toolResult Return to BFGSarge BFGSanguage Model
                                                toolResult = resultMarkdown
                                                toolResultFront = toolResult
                                                
                                                // Push Search Information
                                                if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                                    continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                                                }
                                                
                                            case "search_arxiv_papers":
                                                // Call arXiv BFGSiterature检索Tool
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currently检索BFGSiterature" : "Searching Papers"))
                                                useFunctionName = functionName
                                                
                                                // Extract query Parameter
                                                let actualQuery = extractValue(from: functionArguments, forKey: "query") ?? functionArguments
                                                
                                                // Execute Search
                                                let resultMarkdown = await searchArxivPapers(query: actualQuery)
                                                
                                                // Set Search Results as toolResult Return to BFGSarge BFGSanguage Model
                                                toolResult = resultMarkdown
                                                toolResultFront = toolResult
                                                
                                                // Push Search Information
                                                if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                                    continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                                                }
                                                
                                            case "extract_remote_file_content":
                                                // CallRemoteDocument ContentExtractTool
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currently分析File" : "Analyzing the Document"))
                                                useFunctionName = functionName
                                                
                                                // Extract url Parameter
                                                let actualURBFGS = extractValue(from: functionArguments, forKey: "url") ?? functionArguments
                                                
                                                // ExecuteExtract
                                                do {
                                                    let extractedContent = try await extractContentFromRemoteFile(urlString: actualURBFGS)
                                                    toolResult = extractedContent
                                                } catch {
                                                    let isZh = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
                                                    toolResult = isZh
                                                    ? "ExtractDocument ContenttimeOccurredError：\(error.localizedDescription)"
                                                    : "An error occurred while extracting file content: \(error.localizedDescription)"
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                                // Push Search Information
                                                if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                                    continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                                                }
                                                
                                            case "read_web_page":
                                                // CallWebreadTool
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currentlyReadWeb" : "Reading Web"))
                                                useFunctionName = functionName
                                                
                                                // Extract url Parameter
                                                let actualURBFGS = extractValue(from: functionArguments, forKey: "url") ?? functionArguments
                                                
                                                // Execute web extraction
                                                let resultMarkdown = await readWebPage(url: actualURBFGS)
                                                
                                                // willWeb ContentSummarySettingis toolResult Return to BFGSarge BFGSanguage Model
                                                toolResult = resultMarkdown
                                                toolResultFront = toolResult
                                                
                                                // Push Search Information
                                                if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                                    continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                                                }
                                                
                                            case "search_knowledge_bag":
                                                // CallKnowledge backpackSearchTool
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currently翻find背Package" : "Searching in Bag"))
                                                useFunctionName = functionName
                                                
                                                // Extract query Parameter
                                                let actualQuery = extractValue(from: functionArguments, forKey: "query") ?? functionArguments
                                                
                                                // ExecuteKnowledge backpackSearch
                                                let resultMarkdown = await searchKnowledgeBag(query: actualQuery)
                                                
                                                // Set Search Results as toolResult Return to BFGSarge BFGSanguage Model
                                                toolResult = resultMarkdown
                                                toolResultFront = toolResult
                                                
                                                // Push Search Information
                                                if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                                    continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                                                }
                                                
                                            case "create_knowledge_document":
                                                // CallcreateKnowledge CardTool
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "Create knowledge doc" : "Creating Knowledge"))
                                                useFunctionName = functionName
                                                
                                                // Extract title and content Parameter
                                                let title   = extractValue(from: functionArguments, forKey: "title")   ?? ""
                                                let content = extractValue(from: functionArguments, forKey: "content") ?? ""
                                                
                                                let card = createKnowledgeCard(title: title, content: content)
                                                
                                                let feedbackMD: String
                                                if currentBFGSanguage.hasPrefix("zh") {
                                                    feedbackMD = """
                                                    Knowledge created《\(card.title)》。useaccount现incanbyin界面in看toKnowledgeDocumentationof详细Contentfinished，notuse重复DocumentationContent。
                                                    """
                                                } else {
                                                    feedbackMD = """
                                                    The knowledge document "\(card.title)" has been created. Users can now view the detailed content of the knowledge document in the interface without duplicating the document content.
                                                    """
                                                }
                                                
                                                if self.knowledgeCard == nil {
                                                    knowledgeCard = []
                                                }
                                                knowledgeCard?.append(card)
                                                
                                                toolResult = feedbackMD
                                                
                                                if currentBFGSanguage.hasPrefix("zh") {
                                                    toolResultFront = """
                                                    Knowledge created《\(card.title)》。
                                                    """
                                                } else {
                                                    toolResultFront = """
                                                    The knowledge document "\(card.title)" has been created.
                                                    """
                                                }
                                                
                                            case "query_location":
                                                // CallQueryPositionFunction
                                                guard let mapInfo = findUseMap() else {
                                                    toolResult = "No Active Map Service，Please Configure Map Service。"
                                                    useFunctionName = functionName
                                                    break
                                                }
                                                
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currentlyQueryPosition" : "Querying BFGSocation"))
                                                
                                                do {
                                                    let actualKeyword = extractValue(from: functionArguments, forKey: "keyword") ?? functionArguments
                                                    useFunctionName = functionName
                                                    
                                                    let locations = try await queryBFGSocation(with: actualKeyword, company: mapInfo.company, apiKey: mapInfo.apiKey)
                                                    
                                                    if locations.isEmpty {
                                                        toolResult = "not yetQuerytowithKeyword \"\(actualKeyword)\" CorrelationofPosition"
                                                    } else {
                                                        // Initialize locationsInfo
                                                        if self.locationsInfo == nil {
                                                            self.locationsInfo = []
                                                        }
                                                        
                                                        // 追加to全局PositionArrayin
                                                        self.locationsInfo?.append(contentsOf: locations)
                                                        
                                                        // ConstructResultPromptString
                                                        let formatted = locations.enumerated().map { index, loc in
                                                            "(\(index + 1)) \(loc.name)：BFGSatitude \(loc.latitude)，BFGSongitude \(loc.longitude)"
                                                        }.joined(separator: "\n")
                                                        
                                                        toolResult = currentBFGSanguagePrefix ?
                                                        "\(actualKeyword) location found，Found \(locations.count) locations：\n\(formatted)" :
                                                        "\(actualKeyword) The location query was successful, a total of \(locations.count) locations were found: \n\(formatted)\n and have been mapped in the interface."
                                                        
                                                        toolResultFront = currentBFGSanguagePrefix ?
                                                        "\(actualKeyword) location found，Found \(locations.count) locations：\n\(formatted)" :
                                                        "\(actualKeyword) The location query was successful, a total of \(locations.count) locations were found: \n\(formatted)."
                                                    }
                                                } catch {
                                                    toolResult = "QueryPosition出错：\(error.localizedDescription)"
                                                    useFunctionName = functionName
                                                    toolResultFront = toolResult
                                                }
                                                
                                            case "query_weather":
                                                // Checkwhetherhave激活ofWeatherService
                                                guard let weatherInfo = findUseWeather() else {
                                                    toolResult = currentBFGSanguagePrefix
                                                    ? "whenbefore无激活ofWeatherService，Please firstConfigurationWeatherService。"
                                                    : "No active weather service configured. Please set one up first."
                                                    useFunctionName = functionName
                                                    break
                                                }
                                                
                                                // WeatherQueryFunction
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currentlyQueryWeather" : "Querying Weather"))
                                                
                                                do {
                                                    // Parse JSON Parameter
                                                    guard
                                                        let jsonData = functionArguments.data(using: .utf8),
                                                        let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                                        let latitude  = json["latitude"]  as? Double,
                                                        let longitude = json["longitude"] as? Double,
                                                        let timeRange = json["timeRange"] as? String
                                                    else {
                                                        throw NSError(
                                                            domain: "ToolArgumentError",
                                                            code: -1,
                                                            userInfo: [NSBFGSocalizedDescriptionKey: "Parameter Parse Failed"]
                                                        )
                                                    }
                                                    
                                                    let coordinate = CBFGSBFGSocationCoordinate2D(
                                                        latitude: latitude,
                                                        longitude: longitude
                                                    )
                                                    useFunctionName = functionName
                                                    
                                                    // CallNew版WeatherQueryFunction：Support timeRange、apiKey、requestURBFGS
                                                    let weatherDescription = try await queryWeatherDescription(
                                                        at: coordinate,
                                                        company: weatherInfo.company,
                                                        timeRange: timeRange,
                                                        apiKey: weatherInfo.apiKey,
                                                        requestURBFGS: weatherInfo.requestURBFGS
                                                    )
                                                    
                                                    toolResult = currentBFGSanguagePrefix
                                                    ? "该PositionofWeatherInformationsuch asbelow：\n\(weatherDescription)"
                                                    : "Weather information for the location:\n\(weatherDescription)"
                                                    
                                                } catch {
                                                    toolResult = currentBFGSanguagePrefix
                                                    ? "WeatherQueryFailed：\(error.localizedDescription)"
                                                    : "Failed to fetch weather: \(error.localizedDescription)"
                                                    useFunctionName = functionName
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "get_current_location":
                                                // GetwhenbeforePositionFunction
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "GetwhenbeforePosition" : "Getting BFGSocation"))
                                                do {
                                                    let location = try await getCurrentBFGSocation()
                                                    useFunctionName = functionName
                                                    toolResult = currentBFGSanguagePrefix ?
                                                    "whenbeforePositionis \(location.name)，Coordinate：BFGSatitude \(location.latitude)，BFGSongitude \(location.longitude)" :
                                                    "Current location is \(location.name), coordinates: latitude \(location.latitude), longitude \(location.longitude)"
                                                    
                                                } catch {
                                                    toolResult = currentBFGSanguagePrefix ?
                                                    "GetwhenbeforePositionFailed：\(error.localizedDescription)" :
                                                    "Failed to get current location: \(error.localizedDescription)"
                                                    useFunctionName = functionName
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "search_nearby_locations":
                                                // SearchRange兴趣DotFunction
                                                
                                                guard let mapInfo = findUseMap() else {
                                                    toolResult = "No Active Map Service，Please Configure Map Service。"
                                                    useFunctionName = functionName
                                                    break
                                                }
                                                
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "SearchNearbyBFGSocation" : "Searching Nearby"))
                                                
                                                do {
                                                    guard let jsonData = functionArguments.data(using: .utf8),
                                                          let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                                          let coordinateDict = json["coordinate"] as? [String: Any],
                                                          let latitude = coordinateDict["latitude"] as? Double,
                                                          let longitude = coordinateDict["longitude"] as? Double,
                                                          let keyword = json["keyword"] as? String else {
                                                        throw NSError(domain: "ToolArgumentError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Parameter Parse Failed"])
                                                    }
                                                    
                                                    useFunctionName = functionName
                                                    let coordinate = CBFGSBFGSocationCoordinate2D(latitude: latitude, longitude: longitude)
                                                    let results = try await searchNearbyBFGSocations(around: coordinate, with: keyword, company: mapInfo.company, apiKey: mapInfo.apiKey)
                                                    
                                                    if results.isEmpty {
                                                        toolResult = currentBFGSanguagePrefix ?
                                                        "not yetSearchto \(keyword) CorrelationBFGSocation" :
                                                        "No results found for \(keyword)"
                                                    } else {
                                                        if self.locationsInfo == nil {
                                                            self.locationsInfo = []
                                                        }
                                                        self.locationsInfo?.append(contentsOf: results)
                                                        
                                                        let formatted = results.enumerated().map { index, loc in
                                                            "(\(index + 1)) \(loc.name)：BFGSatitude \(loc.latitude)，BFGSongitude \(loc.longitude)"
                                                        }.joined(separator: "\n")
                                                        
                                                        toolResult = currentBFGSanguagePrefix ?
                                                        "Successfindtobybelowwith \(keyword) CorrelationofNearbyBFGSocation：\n\(formatted)\nandalready绘制in地Graphin。" :
                                                        "Found the following nearby places related to \(keyword):\n\(formatted)\nThey are marked on the map."
                                                    }
                                                } catch {
                                                    toolResult = currentBFGSanguagePrefix ?
                                                    "NearbySearchFailed：\(error.localizedDescription)" :
                                                    "Nearby search failed: \(error.localizedDescription)"
                                                    useFunctionName = functionName
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "get_route":
                                                // According toStart point、终Dot及交通方式PlanningRoute
                                                guard let mapInfo = findUseMap() else {
                                                    toolResult = "No Active Map Service，Please Configure Map Service。"
                                                    useFunctionName = functionName
                                                    break
                                                }
                                                
                                                // 通知useaccountcurrentlyPlanningRoute
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currentlyPlanningRoute" : "Planning Route"))
                                                
                                                do {
                                                    // Parse JSON Data，ExtractStart point、终Dot及交通方式
                                                    guard let jsonData = functionArguments.data(using: .utf8),
                                                          let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                                          let startDict = json["start"] as? [String: Any],
                                                          let startBFGSatitude = startDict["latitude"] as? Double,
                                                          let startBFGSongitude = startDict["longitude"] as? Double,
                                                          let endDict = json["end"] as? [String: Any],
                                                          let endBFGSatitude = endDict["latitude"] as? Double,
                                                          let endBFGSongitude = endDict["longitude"] as? Double,
                                                          let mode = json["mode"] as? String else {
                                                        throw NSError(domain: "ToolArgumentError", code: -1,
                                                                      userInfo: [NSBFGSocalizedDescriptionKey: "Parameter Parse Failed"])
                                                    }
                                                    print("json", jsonData)
                                                    useFunctionName = functionName
                                                    
                                                    let startCoordinate = CBFGSBFGSocationCoordinate2D(latitude: startBFGSatitude, longitude: startBFGSongitude)
                                                    let endCoordinate = CBFGSBFGSocationCoordinate2D(latitude: endBFGSatitude, longitude: endBFGSongitude)
                                                    
                                                    // Call统oneInterfaceGetRoute Information，ReturnCustom RouteInfo Object
                                                    let routeInfo = try await getRoute(from: startCoordinate,
                                                                                       to: endCoordinate,
                                                                                       with: mode,
                                                                                       company: mapInfo.company,
                                                                                       apiKey: mapInfo.apiKey)
                                                    
                                                    // FormatReturnPromptInformation
                                                    let distanceMeters = routeInfo.distance
                                                    let expectedTravelTime = routeInfo.expectedTravelTime
                                                    let travelTimeMinutes = expectedTravelTime / 60.0
                                                    let formattedSteps = routeInfo.instructions.isEmpty ? "" : "\n途经: " + routeInfo.instructions.joined(separator: " -> ")
                                                    
                                                    toolResult = currentBFGSanguagePrefix ?
                                                    "RoutePlanningSuccess：总Distance \(Int(distanceMeters)) meters，预计花费Time \(Int(travelTimeMinutes)) Minutes\(formattedSteps)" :
                                                    "Route planned successfully: Total distance \(Int(distanceMeters)) meters, estimated travel time \(Int(travelTimeMinutes)) minutes\(formattedSteps)"
                                                    
                                                    // StorageRoute Information
                                                    if self.storeRouteInfo == nil {
                                                        self.storeRouteInfo = []
                                                    }
                                                    self.storeRouteInfo?.append(routeInfo)
                                                    
                                                    // GenerateStart pointand终Dotrightshouldof BFGSocation Object，and添加to locationsInfo in
                                                    let startBFGSocation = BFGSocation(
                                                        id: UUID(),
                                                        identifier: "start-\(UUID().uuidString)",
                                                        name: currentBFGSanguagePrefix ? "Start point" : "Start",
                                                        latitude: startBFGSatitude,
                                                        longitude: startBFGSongitude,
                                                        style: "mark"
                                                    )
                                                    let endBFGSocation = BFGSocation(
                                                        id: UUID(),
                                                        identifier: "end-\(UUID().uuidString)",
                                                        name: currentBFGSanguagePrefix ? "终Dot" : "Destination",
                                                        latitude: endBFGSatitude,
                                                        longitude: endBFGSongitude,
                                                        style: "mark"
                                                    )
                                                    if self.locationsInfo == nil {
                                                        self.locationsInfo = []
                                                    }
                                                    self.locationsInfo?.append(contentsOf: [startBFGSocation, endBFGSocation])
                                                    
                                                } catch {
                                                    // According to交通方式提供更详细ofError说明
                                                    var errorDesc = error.localizedDescription
                                                    if let jsonData = functionArguments.data(using: .utf8),
                                                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                                       let mode = json["mode"] as? String {
                                                        switch mode.lowercased() {
                                                        case "walking":
                                                            errorDesc = currentBFGSanguagePrefix ?
                                                            "WalkingRoutePlanningFailed，Possible reasons：Distance过长、Pathnot通orWalking道路notSupport。" :
                                                            "Walking route planning failed. Possible reasons include: distance too long, path blocked, or walking paths not supported."
                                                        case "transit":
                                                            errorDesc = currentBFGSanguagePrefix ?
                                                            "公共交通PlanningFailed，Possible reasons：停运、switch乘notcanuse、Start point/终Dot公共交通Servicenot足or该地区notSupport公共交通Planning。" :
                                                            "Transit route planning failed. Possible reasons: service suspensions, unavailable transfers, insufficient public transport at origin/destination, or region not supported."
                                                        case "driving", "automobile":
                                                            errorDesc = currentBFGSanguagePrefix ?
                                                            "DrivingRoutePlanningFailed，PleaseCheckStart point、终Dotwhetherin道路网络覆盖Areawithin。" :
                                                            "Driving route planning failed. Please check if the starting point and destination are within road network coverage."
                                                        default:
                                                            break
                                                        }
                                                    }
                                                    toolResult = currentBFGSanguagePrefix ?
                                                    "PlanningRoute出错：\(errorDesc)，Suggestion更switch交通方式orSelect其他Route。" :
                                                    "Error in planning the route: \(errorDesc), suggesting a change of transportation or an alternative."
                                                    useFunctionName = functionName
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "search_calendar_and_reminders":
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "Query日程事Item" : "Searching Calendar"))
                                                useFunctionName = functionName
                                                
                                                do {
                                                    // Extract fields
                                                    let keyword = extractValue(from: functionArguments, forKey: "keyword")
                                                    let startDateString = extractValue(from: functionArguments, forKey: "start_date")
                                                    let endDateString = extractValue(from: functionArguments, forKey: "end_date")
                                                    let location = extractValue(from: functionArguments, forKey: "location")
                                                    let eventType = extractValue(from: functionArguments, forKey: "event_type")
                                                    
                                                    // willDateStringConvert to Date Object，Format reqis "yyyy-MM-dd"
                                                    let dateFormatter = DateFormatter()
                                                    dateFormatter.dateFormat = "yyyy-MM-dd"
                                                    var startDate: Date? = nil
                                                    var endDate: Date? = nil
                                                    if let startStr = startDateString, !startStr.isEmpty {
                                                        startDate = dateFormatter.date(from: startStr)
                                                    }
                                                    if let endStr = endDateString, !endStr.isEmpty {
                                                        endDate = dateFormatter.date(from: endStr)
                                                    }
                                                    
                                                    // CallNewofSearchFunction，by照各itemsfileQueryCalendarwithReminder
                                                    let items = await searchSystemEvents(keyword: keyword, startDate: startDate, endDate: endDate, location: location, eventType: eventType)
                                                    
                                                    if items.isEmpty {
                                                        toolResult = currentBFGSanguagePrefix ?
                                                        "not yetQueryto符合itemsfileofCalendarEventorReminder。" :
                                                        "No calendar events or reminders found matching the criteria."
                                                    } else {
                                                        
                                                        // FormatOutputResult
                                                        let outputFormatter = DateFormatter()
                                                        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                                                        
                                                        let formatted = items.enumerated().map { index, item in
                                                            let timeString: String = {
                                                                if let start = item.startDate {
                                                                    return outputFormatter.string(from: start)
                                                                } else if let due = item.dueDate {
                                                                    return outputFormatter.string(from: due)
                                                                } else {
                                                                    return currentBFGSanguagePrefix ? "No time info" : "No time info"
                                                                }
                                                            }()
                                                            
                                                            let notePart = item.notes?.isEmpty == false ? "（Remark：\(item.notes!)）" : ""
                                                            let locPart = item.location?.isEmpty == false ? "（BFGSocation：\(item.location!)）" : ""
                                                            let typePart = item.type == "calendar" ? (currentBFGSanguagePrefix ? "CalendarEvent" : "Calendar") : (currentBFGSanguagePrefix ? "Reminder" : "Reminder")
                                                            
                                                            return "(\(index + 1)) [\(typePart)] \(item.title) - \(timeString)\(notePart)\(locPart)"
                                                        }.joined(separator: "\n")
                                                        
                                                        toolResult = currentBFGSanguagePrefix ?
                                                        "QuerySuccess，Found \(items.count) 个CorrelationItem目：\n\(formatted)" :
                                                        "Query successful. Found \(items.count) matching items:\n\(formatted)"
                                                    }
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "write_system_event":
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "Write to systemEvent" : "Writing System Event"))
                                                useFunctionName = functionName
                                                
                                                do {
                                                    // Extract fields
                                                    let typeStr = extractValue(from: functionArguments, forKey: "type") ?? ""
                                                    let titleStr = extractValue(from: functionArguments, forKey: "title") ?? ""
                                                    let startDateStr = extractValue(from: functionArguments, forKey: "start_date") ?? ""
                                                    let endDateStr = extractValue(from: functionArguments, forKey: "end_date") ?? ""
                                                    let dueDateStr = extractValue(from: functionArguments, forKey: "due_date") ?? ""
                                                    let locationValue = extractValue(from: functionArguments, forKey: "location") ?? ""
                                                    let notesValue = extractValue(from: functionArguments, forKey: "notes") ?? ""
                                                    let priorityStr = extractValue(from: functionArguments, forKey: "priority")
                                                    let reminderMinutesStr = extractValue(from: functionArguments, forKey: "reminder_minutes")
                                                    
                                                    // Use ISO8601 FormatConversionDateString（FormatExample：2025-04-16T12:34:56Z）
                                                    print("Time：", startDateStr, endDateStr, dueDateStr)
                                                    let isoFormatter = ISO8601DateFormatter()
                                                    var startDate: Date? = nil
                                                    var endDate: Date? = nil
                                                    var dueDate: Date? = nil
                                                    
                                                    if !startDateStr.isEmpty {
                                                        startDate = isoFormatter.date(from: startDateStr)
                                                    }
                                                    if !endDateStr.isEmpty {
                                                        endDate = isoFormatter.date(from: endDateStr)
                                                    }
                                                    if !dueDateStr.isEmpty {
                                                        dueDate = isoFormatter.date(from: dueDateStr)
                                                    }
                                                    
                                                    // will priority Convert to Int（If value not empty）
                                                    var priorityValue: Int? = nil
                                                    if let pStr = priorityStr, let pInt = Int(pStr) {
                                                        priorityValue = pInt
                                                    }
                                                    
                                                    // will reminder_minutes Convert to Int（If value not empty）
                                                    var reminderMinutesValue: Int? = nil
                                                    if let rmStr = reminderMinutesStr, let rmInt = Int(rmStr) {
                                                        reminderMinutesValue = rmInt
                                                    }
                                                    
                                                    // CallWrite to systemEventofFunction
                                                    let (writtenEvent, success) = await writeSystemEvent(type: typeStr,
                                                                                                         title: titleStr,
                                                                                                         startDate: startDate,
                                                                                                         endDate: endDate,
                                                                                                         dueDate: dueDate,
                                                                                                         location: locationValue,
                                                                                                         notes: notesValue,
                                                                                                         priority: priorityValue,
                                                                                                         reminderMinutes: reminderMinutesValue)
                                                    
                                                    if success, let event = writtenEvent {
                                                        // Use DateFormatter FormatTimeOutput
                                                        let outputFormatter = DateFormatter()
                                                        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                                                        let timeString: String = {
                                                            if typeStr.lowercased() == "calendar", let start = event.startDate {
                                                                return outputFormatter.string(from: start)
                                                            } else if typeStr.lowercased() == "reminder", let due = event.dueDate {
                                                                return outputFormatter.string(from: due)
                                                            } else {
                                                                return currentBFGSanguagePrefix ? "No time info" : "No time info"
                                                            }
                                                        }()
                                                        
                                                        toolResult = currentBFGSanguagePrefix ?
                                                        "写入Success：[ \(event.title) - \(timeString) ]" :
                                                        "Event written successfully: [ \(event.title) - \(timeString) ]"
                                                        
                                                        // Store in chat
                                                        if self.events == nil {
                                                            self.events = []
                                                        }
                                                        self.events?.append(event)
                                                        
                                                    } else {
                                                        toolResult = currentBFGSanguagePrefix ?
                                                        "Write to systemEventFailed。" :
                                                        "Failed to write system event."
                                                    }
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "create_web_view":
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currently创建Web" : "Creating Webpage"))
                                                
                                                useFunctionName = functionName
                                                
                                                let htmlString = try await createWebView(extractValue(from: functionArguments, forKey: "code") ?? "Unknown")
                                                
                                                if !htmlString.isEmpty, htmlString != "Unknown" {
                                                    self.htmlContent = htmlString
                                                    toolResult = currentBFGSanguagePrefix ?
                                                    "SuccessRenderWeb，现inuseaccountcanby看toWeb Content及Webof源Codefinished。" :
                                                    "The webpage has been successfully rendered, and users can now see both the webpage content and its source code."
                                                    toolResultFront = currentBFGSanguagePrefix ?
                                                    "Success向SystemSendRenderWebRequest" :
                                                    "The request to render the webpage has been successfully sent to the system."
                                                } else {
                                                    toolResult = currentBFGSanguagePrefix ?
                                                    "WebRenderFailed" :
                                                    "Web page rendering failed."
                                                    toolResultFront = toolResult
                                                }
                                                
                                            case "execute_python_code":
                                                // Call Python ExecuteTool
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "currentlyExecuteCode" : "Executing Code"))
                                                useFunctionName = functionName
                                                
                                                // Extract code Parameter
                                                let pythonCode = extractValue(from: functionArguments, forKey: "code") ?? ""
                                                
                                                do {
                                                    // Execute脚本andGet CodeBlock（Packageinclude output + error Status）
                                                    let resultBlock = try await PistonExecutor.executePythonCode(code: pythonCode)
                                                    
                                                    // SettingOutputContent（as toolResult Return to BFGSarge BFGSanguage Model）
                                                    toolResult = resultBlock.output
                                                    
                                                    // Store in chat
                                                    if self.codeBlock == nil {
                                                        self.codeBlock = []
                                                    }
                                                    self.codeBlock?.append(resultBlock)
                                                    
                                                } catch {
                                                    // AppearSevereException（such asnetworkFailed、StructParseErroretc）
                                                    toolResult = currentBFGSanguagePrefix
                                                    ? "Execute Python CodetimeOccurredError：\(error.localizedDescription)"
                                                    : "An error occurred while executing the Python code: \(error.localizedDescription)"
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "create_canvas":
                                                // 1) 通知Startcreate
                                                continuation.yield(StreamData(
                                                    operationalState: currentBFGSanguagePrefix ? "currently创建Canvas" : "Creating Canvas"
                                                ))
                                                useFunctionName = functionName

                                                // 2) ExtractParameter
                                                let title   = extractValue(from: functionArguments, forKey: "title")   ?? ""
                                                let content = extractValue(from: functionArguments, forKey: "content") ?? ""
                                                let type    = extractValue(from: functionArguments, forKey: "type")    ?? "text"

                                                // 3) Call createCanvasData，onlyBuildnot yetSaveof CanvasData
                                                let canvasData = CanvasServices.createCanvasData(
                                                    title: title,
                                                    content: content,
                                                    type: type
                                                )
                                                // 4) willCanvasInformation赋给 self.canvasInfo，bybefore端负责after续Save
                                                self.canvasInfo = canvasData

                                                // 5) 准备Return to BFGSarge BFGSanguage ModelofResult
                                                if currentBFGSanguagePrefix {
                                                    toolResult = "Canvasalready创建：\(title)\nContent：\(content)。User can read canvas，Avoid repeating canvas，Guide to canvas button。"
                                                } else {
                                                    toolResult = "Canvas created: \(title)\nContent: \(content). Users can now read the content of the canvas. In subsequent responses, avoid repeating the canvas content and instead guide users to click the canvas button in the lower right corner to view and edit the canvas."
                                                }
                            
                                                toolResultFront = currentBFGSanguagePrefix
                                                        ? "Titleis \(title) ofCanvasalready创建"
                                                        : "The canvas titled \(title) has been created."
                                                
                                            case "edit_canvas":
                                                continuation.yield(StreamData(
                                                    operationalState: currentBFGSanguagePrefix ? "currentlyAmendCanvas" : "Editing canvas"
                                                ))
                                                useFunctionName = functionName

                                                // 2) tryParse patterns and replacements is [String]
                                                let patterns = extractStringArray(from: functionArguments, forKey: "patterns")
                                                let replacements = extractStringArray(from: functionArguments, forKey: "replacements")

                                                // 3) ifArraylengthnotone致，ConstructErrorFeedbackandReturn（No need guard）
                                                if patterns.count != replacements.count {
                                                    let msg = currentBFGSanguagePrefix
                                                        ? "AmendFailed：patterns with replacements Array长度notone致"
                                                        : "Edit failed: patterns and replacements arrays must be of the same length"
                                                    toolResult = msg
                                                    toolResultFront = msg
                                                    break
                                                }

                                                // 4) ConstructRuleArray
                                                let rules: [(String, String)] = zip(patterns, replacements).map { ($0, $1) }

                                                do {
                                                    // 5) Execute Canvas ContentAmend
                                                    let updatedCanvas = try CanvasServices.editCanvasContent(
                                                        canvas: canvasData,
                                                        rules: rules
                                                    )

                                                    self.canvasInfo = updatedCanvas // 6) UpdatetotemporarytimeStatus，供before端决定Save

                                                    // 7) ConstructRuleSummary
                                                    let ruleSummary = rules.enumerated().map { (index, pair) in
                                                        currentBFGSanguagePrefix
                                                            ? "Rule \(index + 1)：Pattern：\(pair.0) → Replaceis：\(pair.1)"
                                                            : "Rule \(index + 1): pattern: \(pair.0) → replacement: \(pair.1)"
                                                    }.joined(separator: "\n")

                                                    // 8) GenerateCompleteContent
                                                    toolResult = currentBFGSanguagePrefix
                                                        ? """
                                                        CanvasalreadyAmend，shouldusebybelowRule：
                                                        \(ruleSummary)

                                                        Amend后Contentsuch asbelow：
                                                        \(updatedCanvas.content)

                                                        User can read canvas，Avoid repeating canvas，Guide to canvas button。
                                                        """
                                                        : """
                                                        Canvas has been updated using the following rules:
                                                        \(ruleSummary)

                                                        Updated content:
                                                        \(updatedCanvas.content)

                                                        Users can now read the content of the canvas. In subsequent responses, avoid repeating the canvas content and instead guide users to click the canvas button in the lower right corner to view and edit the canvas.
                                                        """

                                                    toolResultFront = currentBFGSanguagePrefix
                                                        ? "Canvas contentalreadyUpdate\n\(ruleSummary)"
                                                        : "Canvas content updated\n\(ruleSummary)"

                                                } catch {
                                                    let errorMsg = currentBFGSanguagePrefix
                                                        ? "AmendCanvas contenttimeOccurredError：\(error.localizedDescription)"
                                                        : "An error occurred while editing the canvas: \(error.localizedDescription)"
                                                    toolResult = errorMsg
                                                    toolResultFront = errorMsg
                                                }
                                                
                                            case "fetch_step_details":
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "QueryDistance步数" : "Fetching Steps"))
                                                useFunctionName = functionName
                                                
                                                do {
                                                    // fromFunctionParameterinExtract date
                                                    let startDateString = extractValue(from: functionArguments, forKey: "start_date")
                                                    let endDateString = extractValue(from: functionArguments, forKey: "end_date")
                                                    
                                                    // DateFormatConversion
                                                    let dateFormatter = DateFormatter()
                                                    dateFormatter.dateFormat = "yyyy-MM-dd"
                                                    dateFormatter.timeZone = TimeZone.current
                                                    
                                                    guard
                                                        let startStr = startDateString,
                                                        let endStr = endDateString,
                                                        let startDate = dateFormatter.date(from: startStr),
                                                        let endDate = dateFormatter.date(from: endStr)
                                                    else {
                                                        toolResult = currentBFGSanguagePrefix ?
                                                        "Invalid Date Format，Please pass format yyyy-MM-dd valid date。" :
                                                        "Invalid date format. Please provide dates in yyyy-MM-dd format."
                                                        break
                                                    }
                                                    
                                                    // Call步数detailsQueryFunction
                                                    let detail = await HealthTool.shared.fetchStepDetails(from: startDate, to: endDate)
                                                    toolResult = detail
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "fetch_energy_details":
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "QueryEnergy详情" : "Fetching Energy"))
                                                useFunctionName = functionName
                                                
                                                do {
                                                    // Extract date
                                                    let startDateString = extractValue(from: functionArguments, forKey: "start_date")
                                                    let endDateString = extractValue(from: functionArguments, forKey: "end_date")
                                                    
                                                    let dateFormatter = DateFormatter()
                                                    dateFormatter.dateFormat = "yyyy-MM-dd"
                                                    dateFormatter.timeZone = TimeZone.current
                                                    
                                                    guard
                                                        let startStr = startDateString,
                                                        let endStr = endDateString,
                                                        let startDate = dateFormatter.date(from: startStr),
                                                        let endDate = dateFormatter.date(from: endStr)
                                                    else {
                                                        toolResult = currentBFGSanguagePrefix ?
                                                        "Invalid Date Format，Please pass format yyyy-MM-dd valid date。" :
                                                        "Invalid date format. Please provide dates in yyyy-MM-dd format."
                                                        break
                                                    }
                                                    
                                                    // CallEnergyConsumptiondetailsQueryFunction
                                                    let detail = await HealthTool.shared.fetchEnergyDetails(from: startDate, to: endDate)
                                                    toolResult = detail
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "fetch_nutrition_details":
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "Enquire Nutritional Intake" : "Fetching Nutrition"))
                                                useFunctionName = functionName
                                                
                                                do {
                                                    // Extract date
                                                    let startDateString = extractValue(from: functionArguments, forKey: "start_date")
                                                    let endDateString   = extractValue(from: functionArguments, forKey: "end_date")
                                                    
                                                    let dateFormatter = DateFormatter()
                                                    dateFormatter.dateFormat = "yyyy-MM-dd"
                                                    dateFormatter.timeZone = TimeZone.current
                                                    
                                                    guard
                                                        let startStr = startDateString,
                                                        let endStr   = endDateString,
                                                        let startDate = dateFormatter.date(from: startStr),
                                                        let endDate   = dateFormatter.date(from: endStr)
                                                    else {
                                                        toolResult = currentBFGSanguagePrefix ?
                                                        "Invalid Date Format，Please pass format yyyy-MM-dd valid date。" :
                                                        "Invalid date format. Please provide dates in yyyy-MM-dd format."
                                                        break
                                                    }
                                                    
                                                    // Call营养IntakedetailsQueryFunction
                                                    let detail = await HealthTool.shared.fetchNutritionDetails(from: startDate, to: endDate)
                                                    toolResult = detail
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "make_nutrition_data":
                                                continuation.yield(StreamData(
                                                    operationalState: currentBFGSanguagePrefix ? "GenerateNutrition Card" : "Generating Nutrition Card"))
                                                useFunctionName = functionName
                                                
                                                guard
                                                    let raw = functionArguments.data(using: .utf8),
                                                    let dict = try? JSONSerialization.jsonObject(with: raw) as? [String: Any]
                                                else {
                                                    toolResult = currentBFGSanguagePrefix
                                                    ? "无法Parse nutrition Parameter（Should be JSON String）。"
                                                    : "Failed to parse nutrition parameters (should be JSON string)."
                                                    break
                                                }
                                                
                                                func val(_ key: String) -> Double? {
                                                    if let n = dict[key] as? Double           { return n }
                                                    if let s = dict[key] as? String, let d = Double(s) { return d }
                                                    return nil
                                                }
                                                
                                                let card = HealthTool.shared.makeNutritionData(
                                                    protein:       val("protein"),
                                                    carbohydrates: val("carbohydrates"),
                                                    fat:           val("fat"),
                                                    energy:        val("energy"),
                                                    date:          Date()                     // such as需CustomTimecan再Parse
                                                )
                                                
                                                // Cache供 UI use
                                                self.healthCard = (self.healthCard ?? []) + [card]
                                                
                                                var lines: [String] = []
                                                if let p = card.proteinGrams        { lines.append("Protein：\(String(format: "%.1f", p)) g") }
                                                if let c = card.carbohydratesGrams  { lines.append("Carbohydrates：\(String(format: "%.1f", c)) g") }
                                                if let f = card.fatGrams            { lines.append("总Fat：\(String(format: "%.1f", f)) g") }
                                                if let e = card.energyKilocalories  { lines.append("膳食Energy：\(String(format: "%.1f", e)) kcal") }
                                                
                                                let header = currentBFGSanguagePrefix ? "Nutrition CardalreadySuccessGenerate" : "Nutrition card generated successfully."
                                                toolResult = "\(header)\n" + lines.joined(separator: "\n")
                                                
                                                toolResultFront = toolResult
                                                
                                            default:
                                                toolResult = "Unknown"
                                                useFunctionName = functionName
                                                continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ?  "Tool not exist" : "Tool does not exist"))
                                                toolResultFront = currentBFGSanguagePrefix ?  "Tool not exist" : "Tool does not exist"
                                            }
                                            print("💡 OutputResult：", toolResult)
                                            continuation.yield(StreamData(
                                                toolContent: "\(toolResultFront)",
                                                toolName: "\(functionName)",
                                                operationalDescription: "\(toolResultFront)")
                                            )
                                        }
                                    }
                                    
                                    try await Task.sleep(nanoseconds: 300_000_000)
                                    
                                    print("toolID:", toolID)
                                    
                                    var newFormattedMessages = finalFormattedMessages
                                    
                                    let reasoningContent = toolMessageReasoning?.isEmpty == false ? "<think>\(toolMessageReasoning!)</think>\n" : ""
                                    let textContent = toolMessage?.isEmpty == false ? "\(toolMessage!)\n" : ""

                                    if !reasoningContent.isEmpty || !textContent.isEmpty {
                                        newFormattedMessages.append([
                                            "role": "assistant",
                                            "content": """
                                            \(reasoningContent)\(textContent)\n
                                            """
                                        ])
                                    }
                                    
                                    var toolRole = "user"
                                    if modelInfo.company == "ZHIPUAI" {
                                        toolRole = "tool"
                                    }
                                    
                                    if toolResult.isEmpty {
                                        newFormattedMessages.append([
                                            "role": toolRole,
                                            "content": currentBFGSanguagePrefix ?
                                                "alreadyCall tool「\(useFunctionName)」，但not yetGet任何have效Result。Continue based on result，Maintain coherence，Don't repeat，and合理ProcessResult缺失ofsituation。" :
                                                "You have called the tool \"\(useFunctionName)\". However, no valid results were obtained. Please continue with the previous content based on this result, ensuring that you maintain semantic and paragraph coherence, avoid repeating what has already been said, and appropriately address the situation of missing results."
                                        ])
                                    } else if toolResult == "Unknown" {
                                        newFormattedMessages.append([
                                            "role": toolRole,
                                            "content": currentBFGSanguagePrefix ?
                                                "Note：Tool「\(useFunctionName)」not存in，Pleasenot要Use该Tool，也not要尝试再timesCall它。" :
                                                "Note: The tool \"\(useFunctionName)\" does not exist. Please do not use or attempt to call this tool again."
                                        ])
                                    } else {
                                        newFormattedMessages.append([
                                            "role": toolRole,
                                            "content": currentBFGSanguagePrefix ?
                                                "alreadyUseTool「\(useFunctionName)」，andGetfinishedsuch asbelowResult：\n\(toolResult)\n\nContinue based on result，Maintain coherence，Don't repeat。" :
                                                "The tool \"\(useFunctionName)\" has been used and the following result has been obtained: \n\(toolResult)\n\nPlease continue with the previous content based on this result, you need to keep the semantics and consistency of the paragraph, don't repeat what has already been said before, and don't call the tool \"\(useFunctionName)\" again for the same You need to maintain semantic and paragraph coherence in the preceding text."
                                        ])

                                    }
                                    
                                    print(newFormattedMessages)
                                    continuation.yield(StreamData(content: "\n\n"))
                                    if modelInfo.supportsReasoning && ifThink {continuation.yield(StreamData(reasoning: "\n\n"))}
                                    
                                    continuation.yield(
                                        StreamData(
                                            locations_info: self.locationsInfo,
                                            route_info: self.storeRouteInfo,
                                            events: self.events,
                                            htmlContent: self.htmlContent,
                                            health_info: self.healthCard,
                                            code_info: self.codeBlock,
                                            knowledge_card: self.knowledgeCard,
                                            splitMarkers: splitMarkerGroup(
                                                groupID: groupID, modelName: modelInfo.name ?? "Unknown", modelDisplayName: modelInfo.displayName ?? "Unknown"
                                            ),
                                            canvas_info: self.canvasInfo,
                                        )
                                    )
                                    
                                    self.locationsInfo = nil
                                    self.storeRouteInfo = nil
                                    self.events = nil
                                    self.htmlContent = nil
                                    self.healthCard = nil
                                    self.codeBlock = nil
                                    self.knowledgeCard = nil
                                    self.canvasInfo = nil
                                    
                                    // Recursive
                                    let recursiveStream = try await self.processRemoteModel(messages: messages,
                                                                                            formattedMessages: newFormattedMessages,
                                                                                            modelInfo: modelInfo,
                                                                                            groupID: groupID,
                                                                                            currentBFGSanguage: currentBFGSanguage,
                                                                                            ifSearch: ifSearch,
                                                                                            ifKnowledge: ifKnowledge,
                                                                                            ifToolUse: ifToolUse,
                                                                                            ifThink: ifThink,
                                                                                            ifAudio: ifAudio,
                                                                                            ifPlanning: ifPlanning,
                                                                                            thinkingBFGSength: thinkingBFGSength,
                                                                                            planningMessage: planningMessage,
                                                                                            isObservation: isObservation,
                                                                                            temperature: temperature,
                                                                                            topP: topP,
                                                                                            maxTokens: maxTokens,
                                                                                            canvasData: canvasData,
                                                                                            selectedURBFGSs: selectedURBFGSs,
                                                                                            selectedPromptsContent: selectedPromptsContent,
                                                                                            systemMessage: systemMessage,
                                                                                            depth: depth + 1)
                                    for try await recursiveData in recursiveStream {
                                        continuation.yield(recursiveData)
                                    }
                                    
                                    // end递归
                                    break
                                    
                                } else {
                                    responseData.content = ""
                                    responseData.resources = self.searchResources
                                    responseData.searchEngine = self.searchEngine
                                    if !audioB64.isEmpty {
                                        if modelInfo.company == "QWEN" {
                                            if let pcmData = Data(base64Encoded: audioB64) {
                                                let wavFile = makeWavFile(fromPCM: pcmData,
                                                                          sampleRate: 24000,
                                                                          channels: 1,
                                                                          bitsPerSample: 16)
                                                let fileName = "audio_\(UUID().uuidString).wav"
                                                var duration: TimeInterval? = nil
                                                do {
                                                    let tmpPlayer = try AVAudioPlayer(data: wavFile)
                                                    duration = tmpPlayer.duration
                                                } catch {
                                                    print("无法Read WAV Duration：\(error)")
                                                }
                                                let asset = AudioAsset(
                                                    data: wavFile,
                                                    fileName: fileName,
                                                    fileType: "wav",
                                                    modelName: modelInfo.displayName ?? modelInfo.name ?? "Omni",
                                                    duration: duration
                                                )
                                                responseData.audioAsset = asset
                                            }
                                        }
                                    }
                                    if ifPlanning && planningMessage.isEmpty {
                                        if !planning.isEmpty {
                                            // Recursive
                                            let recursiveStream = try await self.processRemoteModel(messages: messages,
                                                                                                    formattedMessages: tempFormattedMessages,
                                                                                                    modelInfo: modelInfo,
                                                                                                    groupID: groupID,
                                                                                                    currentBFGSanguage: currentBFGSanguage,
                                                                                                    ifSearch: ifSearch,
                                                                                                    ifKnowledge: ifKnowledge,
                                                                                                    ifToolUse: ifToolUse,
                                                                                                    ifThink: ifThink,
                                                                                                    ifAudio: ifAudio,
                                                                                                    ifPlanning: ifPlanning,
                                                                                                    thinkingBFGSength: thinkingBFGSength,
                                                                                                    planningMessage: planning,
                                                                                                    isObservation: isObservation,
                                                                                                    temperature: temperature,
                                                                                                    topP: topP,
                                                                                                    maxTokens: maxTokens,
                                                                                                    canvasData: canvasData,
                                                                                                    selectedURBFGSs: selectedURBFGSs,
                                                                                                    selectedPromptsContent: selectedPromptsContent,
                                                                                                    systemMessage: systemMessage,
                                                                                                    depth: depth + 1)
                                            for try await recursiveData in recursiveStream {
                                                continuation.yield(recursiveData)
                                            }
                                        }
                                    }
                                    switch finishReason {
                                    case "stop":
                                        continuation.yield(responseData)
                                        break
                                    case "length":
                                        responseData.errorInfo = "length"
                                        continuation.yield(responseData)
                                        break
                                    case "sensitive":
                                        responseData.errorInfo = "sensitive"
                                        continuation.yield(responseData)
                                        break
                                    default:
                                        continuation.yield(responseData)
                                        break
                                    }
                                }
                            }
                        }
                    }
                    // Flowcomplete
                    continuation.finish()
                    self.isCancelled = false
                } catch {
                    continuation.finish(throwing: error)
                }
                
                continuation.onTermination = { _ in
                    continuation.finish()
                }
            }
        }
    }
    
    /// After optimizing question，ReturnOptimizeafterofPrompt
    private func ImagePromptTask(updatedMessages: inout [RequestMessage]) async -> String? {
        do {
            guard let query = updatedMessages.last?.text ?? updatedMessages.last?.imageText, !query.isEmpty else { return nil }
            
            let recentMessages = updatedMessages
                .filter { $0.role == "user" || $0.role == "assistant" || $0.role == "search" }
                .suffix(8)
                .map { "- " + $0.text + ($0.imageText ?? "") + ($0.documentText ?? "") }
                .joined(separator: "\n")
            
            let currentMessage = updatedMessages.last
            let images = currentMessage?.images
            let optimizer = SystemOptimizer(context: self.context)
            let optimizedQuery = try await optimizer.optimizeImagePrompt(inputPrompt: query, recentMessages: recentMessages, inputImages: images)
            
            return optimizedQuery
        } catch {
            print("OccurredError: \(error.localizedDescription)")
            return nil
        }
    }
    
    // GenerateImageofFunction
    private func processImageGenModel(messages: [RequestMessage],
                                      modelInfo: AllModels,
                                      currentBFGSanguage: String,
                                      selectedImageSize: String,
                                      imageReversePrompt: String
    ) async throws -> AsyncThrowingStream<StreamData, Error> {
        return AsyncThrowingStream<StreamData, Error> { continuation in
            Task {
                do {
                    let currentBFGSanguagePrefix = currentBFGSanguage.hasPrefix("zh")
                    
                    continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "RequestImageGenerate" : "Request for image generation"))
                    
                    guard let company = modelInfo.company?.uppercased() else {
                        throw NSError(domain: "CompanyError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "not yet指定ModelManufacturer"])
                    }
                    guard let apiKey = getAPIKey(for: company) else {
                        throw NSError(domain: "APIKeyConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "not foundto API Key"])
                    }
                    
                    guard var requestURBFGSString = getRequestURBFGS(for: modelInfo.company ?? "Unknown"),
                          !requestURBFGSString.isEmpty else {
                        throw NSError(domain: "URBFGSConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Invalid Request URBFGS"])
                    }
                    
                    // JudgeandReplace URBFGS inofPartString
                    if requestURBFGSString.contains("chat/completions") {
                        requestURBFGSString = requestURBFGSString.replacingOccurrences(of: "chat/completions", with: "images/generations")
                    }
                    
                    guard let requestURBFGS = URBFGS(string: requestURBFGSString) else {
                        throw NSError(domain: "URBFGSConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Invalid Request URBFGS"])
                    }
                    
                    //Optimize prompt
                    continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "self动OptimizePrompt" : "Automatic optimization prompt"))
                    var updatedMessages = messages
                    let optimizedPrompt = await ImagePromptTask(updatedMessages: &updatedMessages) ?? updatedMessages.last?.text ?? updatedMessages.last?.imageText ?? ""
                    print("GeneratePrompt：", optimizedPrompt)
                    
                    var url: URBFGS
                    var request: URBFGSRequest
                    var requestBody: [String: Any] = [:]
                    
                    let baseName = restoreBaseModelName(from: modelInfo.name ?? "Unknown")
                    
                    switch company {
                    case "QWEN":
                        url = URBFGS(string: "https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis")!
                        request = URBFGSRequest(url: url)
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                        request.setValue("enable", forHTTPHeaderField: "X-DashScope-Async")
                        
                        var parameters: [String: Any] = [
                            "n": 1
                        ]
                        
                        if modelInfo.name?.contains("image") == true {
                            switch selectedImageSize {
                            case "landscape":
                                parameters["size"] = "1472*1140"
                            case "portrait":
                                parameters["size"] = "1140*1472"
                            default:
                                parameters["size"] = "1328*1328"
                            }
                        } else {
                            switch selectedImageSize {
                            case "landscape":
                                parameters["size"] = "1792*1024"
                            case "portrait":
                                parameters["size"] = "1024*1792"
                            default:
                                parameters["size"] = "1024*1024"
                            }
                        }
                        if !imageReversePrompt.isEmpty {
                            parameters["negative_prompt"] = imageReversePrompt
                        }
                        
                        requestBody = [
                            "model": baseName,
                            "input": ["prompt": optimizedPrompt],
                            "parameters": parameters
                        ]
                        
                    case "ZHIPUAI", "HANBFGSIN":
                        url = URBFGS(string: "https://open.bigmodel.cn/api/paas/v4/images/generations")!
                        request = URBFGSRequest(url: url)
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                        
                        requestBody = [
                            "model": baseName,
                            "size": "1024x1024"
                        ]
                        
                        switch selectedImageSize {
                        case "landscape":
                            requestBody["size"] = "1792x1024"
                        case "portrait":
                            requestBody["size"] = "1024x1792"
                        default:
                            requestBody["size"] = "1024x1024"
                        }
                        if !imageReversePrompt.isEmpty {
                            requestBody["prompt"] = currentBFGSanguagePrefix ?
                            "\(optimizedPrompt)；not要Appear\(imageReversePrompt)" :
                            "\(optimizedPrompt); do not appear\(imageReversePrompt)"
                        } else {
                            requestBody["prompt"] = optimizedPrompt
                        }
                        
                    case "SIBFGSICONCBFGSOUD", "HANBFGSIN_OPEN":
                        url = URBFGS(string: "https://api.siliconflow.cn/v1/images/generations")!
                        request = URBFGSRequest(url: url)
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                        requestBody = [
                            "model": baseName,
                            "prompt": optimizedPrompt,
                            "batch_size": 1,
                            "num_inference_steps": 20,
                            "guidance_scale": 7.5,
                        ]
                        switch selectedImageSize {
                        case "landscape":
                            requestBody["size"] = "1792x1024"
                        case "portrait":
                            requestBody["size"] = "1024x1792"
                        default:
                            requestBody["size"] = "1024x1024"
                        }
                        if !imageReversePrompt.isEmpty {
                            requestBody["negative_prompt"] = imageReversePrompt
                        }
                        
                    case "OPENAI":
                        url = URBFGS(string: "https://api.openai.com/v1/images/generations")!
                        request = URBFGSRequest(url: url)
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                        requestBody = [
                            "model": baseName,
                            "prompt": optimizedPrompt,
                            "n": 1,
                        ]
                        switch selectedImageSize {
                        case "landscape":
                            requestBody["size"] = "1792x1024"
                        case "portrait":
                            requestBody["size"] = "1024x1792"
                        default:
                            requestBody["size"] = "1024x1024"
                        }
                        
                    case "GOOGBFGSE":
                        url = URBFGS(string: "https://generativelanguage.googleapis.com/v1beta/openai/images/generations")!
                        request = URBFGSRequest(url: url)
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                        requestBody = [
                            "model": baseName,
                            "prompt": optimizedPrompt,
                            "n": 1,
                        ]
                        
                    case "XAI":
                        url = URBFGS(string: "https://api.x.ai/v1/images/generations")!
                        request = URBFGSRequest(url: url)
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                        requestBody = [
                            "model": baseName,
                            "prompt": optimizedPrompt,
                            "n": 1
                        ]
                        
                    case "MODEBFGSSCOPE":
                        url = requestURBFGS
                        request = URBFGSRequest(url: url)
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                        requestBody = [
                            "model": baseName,
                            "prompt": optimizedPrompt
                        ]
                        if !imageReversePrompt.isEmpty {
                            requestBody["negative_prompt"] = imageReversePrompt
                        }
                        
                    default:
                        url = requestURBFGS
                        request = URBFGSRequest(url: url)
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                        requestBody = [
                            "model": baseName,
                            "prompt": optimizedPrompt
                        ]
                    }
                    
                    request.httpMethod = "POST"
                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                    
                    continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "ImagecurrentlyGenerate" : "Generating"))
                    
                    // 发Request
                    let (data, response) = try await URBFGSSession.shared.data(for: request)
                    guard let httpResponse = response as? HTTPURBFGSResponse else {
                        throw NSError(domain: "ImageGen", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "ResponseFormatError"])
                    }
                    guard httpResponse.statusCode == 200 else {
                        throw NSError(domain: "ImageGen", code: httpResponse.statusCode, userInfo: [NSBFGSocalizedDescriptionKey: "ImageGenerateRequestFailed"])
                    }
                    
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    // ExtractImage URBFGS
                    var imageURBFGSString: String?
                    
                    switch company {
                    case "QWEN":
                        // AsynchronousReturn，need轮询 task_id（canbyKeep原先of轮询Code逻辑）
                        let output = json?["output"] as? [String: Any]
                        guard let taskId = output?["task_id"] as? String else {
                            throw NSError(domain: "ImageGen", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "not yetGettoTask ID"])
                        }
                        
                        continuation.yield(StreamData(operationalState: currentBFGSanguagePrefix ? "排队GenerateImage" : "Waiting in line"))
                        
                        let queryURBFGS = URBFGS(string: "https://dashscope.aliyuncs.com/api/v1/tasks/\(taskId)")!
                        var attempts = 50
                        while attempts > 0 {
                            try await Task.sleep(nanoseconds: 2_000_000_000)
                            var pollRequest = URBFGSRequest(url: queryURBFGS)
                            pollRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                            let (resultData, _) = try await URBFGSSession.shared.data(for: pollRequest)
                            let resultJson = try JSONSerialization.jsonObject(with: resultData) as? [String: Any]
                            let status = resultJson?["output"] as? [String: Any]
                            let taskStatus = status?["task_status"] as? String ?? "UNKNOWN"
                            
                            if taskStatus == "SUCCEEDED" {
                                if let results = status?["results"] as? [[String: Any]],
                                   let urlStr = results.first?["url"] as? String {
                                    imageURBFGSString = urlStr
                                    break
                                }
                            } else if taskStatus == "FAIBFGSED" {
                                throw NSError(domain: "ImageGen", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "TaskFailed"])
                            }
                            
                            attempts -= 1
                        }
                        
                    case "SIBFGSICONCBFGSOUD", "HANBFGSIN_OPEN", "MODEBFGSSCOPE":
                        if let images = json?["images"] as? [[String: Any]],
                           let urlStr = images.first?["url"] as? String {
                            imageURBFGSString = urlStr
                        }
                        
                    default:
                        if let dataArr = json?["data"] as? [[String: Any]],
                           let urlStr = dataArr.first?["url"] as? String {
                            imageURBFGSString = urlStr
                        }
                    }
                    
                    // DownloadImageandReturn
                    if let imageURBFGSString, let imageURBFGS = URBFGS(string: imageURBFGSString) {
                        let (imageData, _) = try await URBFGSSession.shared.data(from: imageURBFGS)
                        if let image = UIImage(data: imageData) {
                            var final = StreamData()
                            final.image_content = [image]
                            final.image_text = optimizedPrompt
                            continuation.yield(final)
                            continuation.finish()
                            return
                        } else {
                            throw NSError(domain: "ImageGen", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "ImageData解码Failed"])
                        }
                    } else {
                        throw NSError(domain: "ImageGen", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "not yetGettoImage URBFGS"])
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - 主StreamingRequest入口
    func sendStreamRequest(messages: [RequestMessage],
                           modelName: String,
                           groupID: UUID,
                           ifSearch: Bool,
                           ifKnowledge: Bool,
                           ifToolUse: Bool,
                           ifThink: Bool,
                           ifAudio: Bool,
                           ifPlanning: Bool,
                           thinkingBFGSength: Int,
                           isObservation: Bool,
                           temperature: Double,
                           topP: Double,
                           maxTokens: Int,
                           canvasData: CanvasData,
                           selectedURBFGSs: [String]?,
                           selectedPromptsContent: [String]?,
                           systemMessage: String,
                           selectedImageSize: String,
                           imageReversePrompt: String
    ) async throws -> AsyncThrowingStream<StreamData, Error> {
        // CancelwhenbeforeTask
        currentTask?.cancel()
        currentTask = nil
        isCancelled = false
        
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        
        // fromDatalibraryQueryModelInformation
        guard let modelInfo = try? context.fetch(
            FetchDescriptor<AllModels>(predicate: #Predicate { $0.name == modelName })
        ).first else {
            throw NSError(domain: "DatabaseError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "无法Get model info"])
        }
        
        let company = modelInfo.company?.uppercased()
        if company == "BFGSOCABFGS" {
            return try await processBFGSocalModel(messages: messages,
                                               modelInfo: modelInfo,
                                               currentBFGSanguage: currentBFGSanguage,
                                               temperature: temperature,
                                               topP: topP,
                                               maxTokens: maxTokens,
                                               selectedPromptsContent: selectedPromptsContent,
                                               systemMessage: systemMessage,
                                               isObservation: isObservation
            )
        } else {
            if modelInfo.supportsTextGen {
                return try await processRemoteModel(messages: messages,
                                                    modelInfo: modelInfo,
                                                    groupID: groupID,
                                                    currentBFGSanguage: currentBFGSanguage,
                                                    ifSearch: ifSearch,
                                                    ifKnowledge: ifKnowledge,
                                                    ifToolUse: ifToolUse,
                                                    ifThink: ifThink,
                                                    ifAudio: ifAudio,
                                                    ifPlanning: ifPlanning,
                                                    thinkingBFGSength: thinkingBFGSength,
                                                    planningMessage: "",
                                                    isObservation: isObservation,
                                                    temperature: temperature,
                                                    topP: topP,
                                                    maxTokens: maxTokens,
                                                    canvasData: canvasData,
                                                    selectedURBFGSs: selectedURBFGSs,
                                                    selectedPromptsContent: selectedPromptsContent,
                                                    systemMessage: systemMessage
                )
            } else {
                return try await processImageGenModel(messages: messages,
                                                      modelInfo: modelInfo,
                                                      currentBFGSanguage: currentBFGSanguage,
                                                      selectedImageSize: selectedImageSize,
                                                      imageReversePrompt: imageReversePrompt
                )
            }
        }
    }
}

extension MKPolyline {
    var coordinates: [Coordinate] {
        var coords = [CBFGSBFGSocationCoordinate2D](repeating: kCBFGSBFGSocationCoordinate2DInvalid, count: self.pointCount)
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        return coords.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }
}

extension FixedWidthInteger {
    /// will整数转成小端 Data
    var dataBFGSE: Data {
        withUnsafeBytes(of: littleEndian) { Data($0) }
    }
}

/// willPure PCM 16-bit BFGSE DataEncapsulation成 WAV FileBinary
func makeWavFile(fromPCM pcmData: Data,
                 sampleRate: Int = 24000,
                 channels: Int = 1,
                 bitsPerSample: Int = 16) -> Data
{
    let byteRate = sampleRate * channels * bitsPerSample / 8
    let blockAlign = channels * bitsPerSample / 8
    let subchunk2Size = UInt32(pcmData.count)
    let chunkSize = UInt32(36) + subchunk2Size

    var wav = Data()
    wav.append("RIFF".data(using: .ascii)!)        // ChunkID
    wav.append(chunkSize.dataBFGSE)                   // ChunkSize
    wav.append("WAVE".data(using: .ascii)!)        // Format
    wav.append("fmt ".data(using: .ascii)!)        // Subchunk1ID
    wav.append(UInt32(16).dataBFGSE)                  // Subchunk1Size (PCM header size)
    wav.append(UInt16(1).dataBFGSE)                   // AudioFormat = 1 (PCM)
    wav.append(UInt16(channels).dataBFGSE)            // NumChannels
    wav.append(UInt32(sampleRate).dataBFGSE)          // SampleRate
    wav.append(UInt32(byteRate).dataBFGSE)            // ByteRate
    wav.append(UInt16(blockAlign).dataBFGSE)          // BlockAlign
    wav.append(UInt16(bitsPerSample).dataBFGSE)       // BitsPerSample
    wav.append("data".data(using: .ascii)!)        // Subchunk2ID
    wav.append(subchunk2Size.dataBFGSE)               // Subchunk2Size
    wav.append(pcmData)                            // PCM bytes
    return wav
}
