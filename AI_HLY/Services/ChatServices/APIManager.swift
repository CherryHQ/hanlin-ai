//
//  Services/APIManager.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 4/2/25.
//

import Foundation
import PhotosUI
import SwiftData
import LLM
import MapKit
import Accelerate

// MARK: - 数据结构定义
struct splitMarkerGroup {
    var groupID: UUID
    var modelName: String
    var modelDisplayName: String
}

struct StreamData {
    var content: String?            // 回复内容
    var reasoning: String?          // 推理过程
    var toolContent: String?        // 工具内容
    var toolName: String?           // 工具名称
    var resources: [Resource]?      // 资料来源
    var searchEngine: String?       // 搜索引擎
    var image_content: [UIImage]?   // 图片内容
    var image_text: String?         // 图片描述
    var audioContent: Data?         // 音频数据
    var document_text: String?      // 文件内容
    var search_text: String?        // 搜索内容
    var locations_info: [Location]? // 位置信息
    var route_info: [RouteInfo]?    // 路线信息
    var events: [EventItem]?        // 事件信息
    var htmlContent: String?         // 网页内容
    var health_info: [HealthData]?  // 健康数据
    var code_info: [CodeBlock]?     // 代码数据
    var knowledge_card: [KnowledgeCard]? // 知识卡片
    var audioAsset: AudioAsset?     // 音频数据
    var autoTitle: String?          // 自动标题
    var errorInfo: String?          // 模型错误信息
    var operationalState: String?   // 运行状态信息
    var operationalDescription: String? // 运行描述
    var splitMarkers: splitMarkerGroup? // 分割标记组
    var canvas_info: CanvasData?    // 画布数据
}

struct RequestMessage {
    var role: String                // 信息角色
    var text: String                // 信息内容
    var images: [UIImage]? = nil    // 图像内容
    var imageText: String?          // 图像描述
    var document: [URL]? = nil      // 文档地址
    var documentText: String?       // 文档内容
    var htmlContent: String?        // 网页内容
    var codeBlock: [CodeBlock]?     // 代码内容
    var knowledgeCard: [KnowledgeCard]? // 知识卡片
    var prompt: [PromptCard]? = nil // 提示词卡片
    var modelName: String           // 模型名称
    var modelDisplayName: String    // 模型显示名称
}


// MARK: - APIManager
class APIManager {
    
    // MARK: 属性声明
    private var searchResources: [Resource]?
    private var searchEngine: String?           // 搜索引擎
    private var documentText: String?           // 文件内容
    private var imageText: String?              // 图片描述
    private var searchText: String?             // 搜索内容
    private var locationsInfo: [Location]?      // 位置信息
    private var storeRouteInfo: [RouteInfo]?    // 路线信息
    private var events: [EventItem]?            // 事件信息
    private var htmlContent: String?            // 网页编码
    private var healthCard: [HealthData]?       // 营养卡片
    private var codeBlock: [CodeBlock]?         // 代码块
    private var knowledgeCard: [KnowledgeCard]? // 知识卡片
    private var canvasInfo: CanvasData?         // 画布信息
    private var toolMessage: String?            // 工具使用说明
    private var toolMessageReasoning: String?   // 工具使用思考
    private var autoTitle: String?
    private var dataIndex: Int?
    
    private var context: ModelContext
    private var currentTask: URLSessionDataTask? // 当前流式请求任务
    private var isCancelled = false              // 请求取消标记
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // 解析参数
    func extractValue(from jsonString: String, forKey key: String) -> String? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        do {
            if let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let value = dict[key] as? String {
                return value
            }
        } catch {
            print("JSON解析失败：\(error)")
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
            print("JSON解析失败：\(error)")
        }
        return []
    }
    
    // 记忆函数
    func saveMemory(content: String) -> Bool {
        do {
            let newMemory = MemoryArchive(content: content, timestamp: Date())
            context.insert(newMemory)
            try context.save()
            print("成功保存记忆：\(content)")
            return true
        } catch {
            print("保存记忆失败：\(error)")
            return false
        }
    }

    // 回忆函数
    func retrieveMemory(keyword: String) -> String {
        
        print("召回记忆关键词：", keyword)
        
        // 1. 加载 JSON 配置（仅加载一次）
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
        
        // 1.1 构建双向同义词映射
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
        
        // 2. 分词（去除停用词）
        func tokenize(_ text: String) -> [String] {
            text
                .lowercased()
                .split { $0.isWhitespace || $0.isPunctuation || $0 == ";" || $0 == "；" }
                .map(String.init)
                .filter { !$0.isEmpty && !config.stopWords.contains($0) }
        }
        
        // 3. 编辑距离（拼写相近）
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
        
        // 4. 解析关键词
        let terms = tokenize(keyword)
        guard !terms.isEmpty else {
            return "请输入有效关键词 / Please enter valid keywords."
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
                    
                    // 1) 完整匹配
                    if content.contains(term) {
                        score += term.count * 4
                    }
                    
                    // 2) 编辑距离匹配
                    for w in words {
                        if abs(w.count - term.count) > 2 { continue }
                        let dist = levenshtein(term, w)
                        if dist <= 2 && dist < term.count {
                            score += max(0, term.count - dist) * 2
                            break
                        }
                    }
                    
                    // 3) 同义词匹配（含双向）
                    if let syns = expandedSynonymMap[term] {
                        for syn in syns where content.contains(syn) {
                            score += term.count
                            break
                        }
                    }
                    
                    // 4) 字符重叠匹配
                    if isChinese && term.count > 1 {
                        for ch in term where !config.stopChars.contains(ch) {
                            if content.contains(ch) {
                                score += 1
                            }
                        }
                    }
                    
                    if !isChinese && term.count > 1 {
                        for ch in term where !config.stopChars.contains(ch) && ch.isLetter {
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
                return zh ? "没有找到与 “\(keyword)” 相关的记忆" : "No memory found related to “\(keyword)”"
            }
            
            let sorted = scored.sorted {
                $0.1 != $1.1 ? $0.1 > $1.1 : $0.0.timestamp > $1.0.timestamp
            }
            
            let results = sorted.map {
                $0.0.content!.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            print("召回记忆结果：", results.joined(separator: "\n\n"))
            return results.joined(separator: "\n\n")
            
        } catch {
            return "检索过程中出现了错误 / Error during memory retrieval: \(error.localizedDescription)"
        }
    }
    
    // 更新记忆
    func updateMemory(originalContent: String, updatedContent: String) -> String {
        // 1. 使用 SwiftData 的类型安全谓词，匹配 content 等于 originalContent
        let descriptor = FetchDescriptor<MemoryArchive>(
            predicate: #Predicate { memory in
                memory.content == originalContent
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            // 2. 执行查询
            let results = try context.fetch(descriptor)
            
            // 3. 如果没有匹配项
            guard !results.isEmpty else {
                return "未找到与原记忆 “\(originalContent)” 完全匹配的记录"
            }
            
            // 4. 更新内容和时间戳
            for memory in results {
                memory.content = updatedContent
                memory.timestamp = Date()
            }
            
            // 5. SwiftData 会自动保存变更
            return "成功将 \(results.count) 条记忆从 “\(originalContent)” 更新为 “\(updatedContent)”"
            
        } catch {
            // 6. 错误处理
            return "更新过程中出现错误：\(error.localizedDescription)"
        }
    }
    
    // 主动搜索
    func searchOnline(query: String) async -> String {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
                ? "没有有效的查询内容"
                : "No valid query content."
        }
        
        // 获取搜索引擎配置
        guard let (engine, apiKey, requestURL) = getActiveSearchEngine() else {
            return Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
                ? "用户未启用搜索引擎，请引导用户进入 设置 > 工具 > 联网搜索 中按照指示配置搜索引擎的API并启用搜索引擎。"
                : "The user has not enabled the search engine. Please guide the user to go to Settings > Tools > Web Search and follow the instructions to configure the search engine API and enable the search engine."
        }
        
        let searchCount = getSearchCount()
        let bilingual = isBilingualSearchEnabled()
        
        do {
            // 第一次搜索：原始 query
            let (result1, usedEngine) = try await searchTool(
                query: query,
                engine: engine,
                apiKey: apiKey,
                requestURL: requestURL,
                searchCount: searchCount
            )
            var combinedTitles = result1.titles
            var combinedLinks = result1.links
            var combinedContents = result1.contents
            var combinedIcons = result1.icons
            
            // 如果启用双语搜索，再翻译一次 query 并搜索
            if bilingual {
                let translated = try await SystemOptimizer(context: self.context)
                    .translatePrompt(inputPrompt: query)
                let (result2, _) = try await searchTool(
                    query: translated,
                    engine: engine,
                    apiKey: apiKey,
                    requestURL: requestURL,
                    searchCount: searchCount
                )
                combinedTitles.append(contentsOf: result2.titles)
                combinedLinks.append(contentsOf: result2.links)
                combinedContents.append(contentsOf: result2.contents)
                combinedIcons.append(contentsOf: result2.icons)
            }
            
            // 构造 Markdown 摘要
            var md = ""
            let isZh = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
            if !combinedContents.isEmpty {
                md += isZh
                    ? "# 内容摘要：\n\n"
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
                    ? "未找到相关信息。\n"
                    : "No relevant information found.\n"
            }
            
            // 构造最终回复
            let prefix = isZh
                ? "搜索关键词：\(query)\n\n网络资料，供您参考，引用内容时在对应的内容后标注 [index] 引用：\n\n\(md)"
                : "Search keywords: \(query)\n\nWeb materials for your reference. When citing content, please indicate with [index] after the corresponding content:\n\(md)"
            
            let searchResult = prefix
            
            // 记录搜索数据
            self.searchText = searchResult.trimmingCharacters(in: .whitespacesAndNewlines)
            let newResources = zip(combinedIcons, zip(combinedTitles, combinedLinks))
                .map { Resource(icon: $0.0, title: $0.1.0, link: $0.1.1) }
            if self.searchResources != nil {
                self.searchResources?.append(contentsOf: newResources)
            } else {
                self.searchResources = newResources
            }
            self.searchEngine = usedEngine
            
            return searchResult
            
        } catch {
            let isZh = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
            return isZh
                ? "搜索时发生错误：\(error.localizedDescription)"
                : "An error occurred during search: \(error.localizedDescription)"
        }
    }
    
    /// 主动搜索 arXiv 文献
    func searchArxivPapers(query: String) async -> String {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
                ? "没有有效的查询内容"
                : "No valid query content."
        }
        
        let searchCount = getSearchCount()
        
        do {
            // 构造 arXiv API 查询 URL
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let urlString = "https://export.arxiv.org/api/query?search_query=all:\(encodedQuery)&start=0&max_results=\(searchCount)"
            
            guard let url = URL(string: urlString) else {
                return Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
                    ? "无法构建有效的 arXiv 请求 URL。"
                    : "Failed to construct a valid arXiv request URL."
            }
            
            // 发送请求
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // 解析返回的 Atom XML
            let xml = String(decoding: data, as: UTF8.self)
            
            // 提取文献信息
            let entries = xml.components(separatedBy: "<entry>").dropFirst()
            
            var papers: [(title: String, summary: String, idLink: String, pdfLink: String, published: String, authors: [String])] = []
            
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
                    let idLink = String(entry[idStart..<idEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let published = String(entry[publishedStart..<publishedEnd]).prefix(10).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // 提取作者
                    var authors: [String] = []
                    let authorSections = entry.components(separatedBy: "<author>").dropFirst()
                    for authorSection in authorSections {
                        if let nameStart = authorSection.range(of: "<name>")?.upperBound,
                           let nameEnd = authorSection.range(of: "</name>")?.lowerBound {
                            let name = String(authorSection[nameStart..<nameEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                            authors.append(name)
                        }
                    }
                    
                    // 提取 PDF 链接
                    var pdfLink = ""
                    let linkSections = entry.components(separatedBy: "<link ")
                    for linkSection in linkSections {
                        if linkSection.contains("type=\"application/pdf\""),
                           let hrefStart = linkSection.range(of: "href=\"")?.upperBound,
                           let hrefEnd = linkSection[hrefStart...].range(of: "\"")?.lowerBound {
                            pdfLink = String(linkSection[hrefStart..<hrefEnd])
                            break
                        }
                    }
                    
                    if !idLink.isEmpty {
                        papers.append((title, summary, idLink, pdfLink, published, authors))
                    }
                }
            }
            
            // 构造 Markdown 摘要
            var md = ""
            let isZh = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
            if !papers.isEmpty {
                md += isZh
                    ? "# 文献摘要：\n\n"
                    : "# Paper Summaries:\n\n"
                
                for (i, paper) in papers.enumerated() {
                    if self.dataIndex == nil {
                        self.dataIndex = 1
                    } else {
                        self.dataIndex! += 1
                    }
                    
                    md += "## [\(self.dataIndex ?? i+1)] \(paper.title)\n\n"
                    md += isZh
                        ? "**发表时间：** \(paper.published)\n\n"
                        : "**Published Date:** \(paper.published)\n\n"
                    
                    if !paper.authors.isEmpty {
                        let authorsString = paper.authors.joined(separator: ", ")
                        if isZh {
                            md += "**作者：** \(authorsString)\n\n"
                        } else {
                            md += "**Authors:** \(authorsString)\n\n"
                        }
                    }
                    
                    md += isZh
                        ? "**摘要：**\n\(paper.summary.prefix(6000))\n\n"
                        : "**Summary:**\n\(paper.summary.prefix(6000))\n\n"
                    
                    if !paper.pdfLink.isEmpty {
                        md += isZh
                            ? "**PDF 下载：** [允许通过 extract_remote_file_content 工具精读](\(paper.pdfLink))\n\n---\n\n"
                            : "**PDF Download:** [Allow detailed reading through the extract_remote_file_content tool](\(paper.pdfLink))\n\n---\n\n"
                    } else {
                        // 如果没找到 pdfLink，就用 idLink
                        md += isZh
                            ? "**摘要链接：** [允许通过 read_web_page 工具精读](\(paper.idLink))\n\n---\n\n"
                            : "**Abstract Link:** [Allow detailed reading through the read_web_page tool](\(paper.idLink))\n\n---\n\n"
                    }
                }
            } else {
                md = isZh
                    ? "未找到相关文献。\n"
                    : "No relevant papers found.\n"
            }
            
            // 构造最终回复
            let prefix = isZh
                ? "搜索关键词：\(query)\n\narXiv 文献资料，供您参考，引用内容时在对应的内容后标注 [index] 引用：\n\n\(md)"
                : "Search keywords: \(query)\n\narXiv papers for your reference. When citing content, please indicate with [index] after the corresponding content:\n\n\(md)"
            
            let searchResult = prefix
            
            // 记录搜索数据
            self.searchText = searchResult.trimmingCharacters(in: .whitespacesAndNewlines)
            let arxivIconURL = "https://info.arxiv.org/brand/images/brand-supergraphic.jpg"
            let newResources = papers.map {
                Resource(icon: arxivIconURL, title: $0.title, link: $0.idLink)
            }
            if self.searchResources != nil {
                self.searchResources?.append(contentsOf: newResources)
            } else {
                self.searchResources = newResources
            }
            self.searchEngine = "ARXIV"
            
            return searchResult
            
        } catch {
            let isZh = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
            return isZh
                ? "搜索 arXiv 时发生错误：\(error.localizedDescription)"
                : "An error occurred while searching arXiv: \(error.localizedDescription)"
        }
    }
    
    /// 根据在线文件 URL 下载并提取文本内容
    func extractContentFromRemoteFile(urlString: String) async throws -> String {
        guard let originalURL = URL(string: urlString) else {
            return "无效的链接：\(urlString)"
        }
        
        func downloadFile(from url: URL) async throws -> (Data, URLResponse) {
            return try await URLSession.shared.data(from: url)
        }
        
        do {
            var data: Data
            var response: URLResponse
            
            // 尝试第一次下载
            do {
                (data, response) = try await downloadFile(from: originalURL)
            } catch {
                if urlString.lowercased().hasPrefix("http://"),
                   let httpsURL = URL(string: urlString.replacingOccurrences(of: "http://", with: "https://")) {
                    do {
                        (data, response) = try await downloadFile(from: httpsURL)
                    } catch {
                        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "下载失败（已尝试 HTTP 和 HTTPS）：\(error.localizedDescription)"])
                    }
                } else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "下载失败：\(error.localizedDescription)"])
                }
            }
            
            // 根据 MIME 类型判断文件扩展名
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
            
            // 保存到本地临时目录
            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(extensionFromMimeType)
            
            try data.write(to: tempFileURL)
            
            // 使用已有 extractContent(from:) 函数提取文本
            let extractedText = try await extractContent(from: tempFileURL)
            
            // 下载后可选择删除临时文件
            try? FileManager.default.removeItem(at: tempFileURL)
            
            // 组织成 Markdown
            let isZh = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
            let fileName = originalURL.lastPathComponent.isEmpty ? "下载文件" : originalURL.lastPathComponent
            let markdownContent = "- **[\(fileName)](\(originalURL.absoluteString))**\n  \(extractedText)\n\n"
            
            let prefix = isZh
                ? "文件链接：\(originalURL.absoluteString)\n\n以下是解析后的文件内容：\n\n"
                : "File URL: \(originalURL.absoluteString)\n\nHere is the extracted content from the file:\n\n"
            
            let finalResult = prefix + markdownContent
            
            // 更新状态
            self.searchText = finalResult.trimmingCharacters(in: .whitespacesAndNewlines)
            let hanlinIconURL = "HANLINWEB" // 暂用，可换自己的
            let newResource = Resource(icon: hanlinIconURL, title: fileName, link: originalURL.absoluteString)
            
            if self.searchResources != nil {
                self.searchResources?.append(newResource)
            } else {
                self.searchResources = [newResource]
            }
            self.searchEngine = "HANLINWEB"
            
            return finalResult
            
        } catch {
            return "下载或解析文件失败：\(error.localizedDescription)"
        }
    }
    
    // 主动翻找
    func searchKnowledgeBag(query: String) async -> String {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
                ? "没有有效的查询内容"
                : "No valid query content."
        }

        do {
            // 执行知识搜索
            guard let result = await self.performKnowledgeSearch(query: query) else {
                return Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
                    ? "未在知识背包中找到相关内容。"
                    : "No relevant content found in the Knowledge Bag."
            }

            // 构造最终 Markdown 返回内容
            let isZh = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
            let prefix = isZh
                ? "知识关键词：\(query)\n\n以下为知识背包中找到的参考内容：\n\n"
                : "Knowledge keywords: \(query)\n\nHere is the reference content found in your Knowledge Bag:\n\n"

            let finalResult = prefix + result

            // 更新状态
            self.searchText = finalResult.trimmingCharacters(in: .whitespacesAndNewlines)
            self.searchEngine = "HANLINBAG"

            return finalResult
        }
    }
    
    /// 主动读取网页内容：从单个 URL 中提取正文并构造 Markdown 格式摘要
    func readWebPage(url: String) async -> String {
        // 校验 URL 是否有效
        guard !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
            ? "没有有效的网页链接。"
            : "No valid URL provided."
        }
        
        // 执行网页提取
        let extractedPages = await fetchWebPageContent(from: [url])
        
        guard let (url, title, content, icon) = extractedPages.first else {
            return Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
            ? "未能成功提取网页内容。"
            : "Failed to extract web page content."
        }
        
        // 构造 Markdown 内容
        let isZh = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
        let markdown = "- ![\(title)](\(icon))\n  \(content.prefix(5000))\n\n"
        
        let prefix = isZh
        ? "网页链接：\(url)\n\n以下是解析后的网页内容摘要：\n\n"
        : "Web URL: \(url)\n\nHere is the extracted summary from the web page:\n\n"
        
        let finalResult = prefix + markdown
        
        // 更新状态
        self.searchText = finalResult.trimmingCharacters(in: .whitespacesAndNewlines)
        let newResource = Resource(icon: icon, title: title, link: url)
        if self.searchResources != nil {
            self.searchResources?.append(newResource)
        } else {
            self.searchResources = [newResource]
        }
        if self.searchEngine == nil || self.searchEngine?.isEmpty == true {
            self.searchEngine = "HANLINWEB"
        }
        
        return finalResult
    }
    
    /// 异步生成网页预览
    func createWebView(_ html: String) async throws -> String {
        var cleaned = html

        // 1. 去除 Markdown 代码块标记 ```...```
        if let fenceRegex = try? NSRegularExpression(
            pattern: "(?m)^```[\\s\\S]*?```\\s*",
            options: []
        ) {
            let range = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
            cleaned = fenceRegex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }

        // 2. 去除 HTML 注释 <!-- ... -->
        if let commentRegex = try? NSRegularExpression(
            pattern: "<!--[\\s\\S]*?-->",
            options: [.dotMatchesLineSeparators]
        ) {
            let range = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
            cleaned = commentRegex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "")
        }

        // 3. 修剪首尾空白字符（空格、换行等）
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        // 4. 合并连续空行为单个空行
        if let blankLinesRegex = try? NSRegularExpression(
            pattern: "(?m)^[ \\t]*\\n{2,}",
            options: []
        ) {
            let range = NSRange(cleaned.startIndex..<cleaned.endIndex, in: cleaned)
            cleaned = blankLinesRegex.stringByReplacingMatches(in: cleaned, options: [], range: range, withTemplate: "\n\n")
        }

        return cleaned
    }
    
    // 生成知识卡片
    func createKnowledgeCard(title: String, content: String) -> KnowledgeCard {
        var raw = content
        
        // 1. 去掉开头的 ``` 及可能的语言标注
        if raw.hasPrefix("```") {
            // 找到首个换行，删掉 fence 那行
            if let fenceEnd = raw.firstIndex(of: "\n") {
                raw = String(raw[raw.index(after: fenceEnd)...])
            }
        }
        
        // 2. 去掉结尾的 ``` 及可能的多余空行
        if raw.hasSuffix("```") {
            // 找到最后一个 fence
            if let lastFence = raw.range(of: "```", options: .backwards)?.lowerBound {
                raw = String(raw[..<lastFence])
            }
        }
        
        // 3. 修剪首尾空白和换行
        raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 4. 构造并返回 KnowledgeCard
        return KnowledgeCard(title: title, content: raw)
    }
    
    // MARK: - 数据库查询相关
    // 查询模型密钥
    private func getAPIKey(for company: String) -> String? {
        let predicate = #Predicate<APIKeys> { $0.company == company }
        let fetchDescriptor = FetchDescriptor<APIKeys>(predicate: predicate)
        return (try? context.fetch(fetchDescriptor).first)?.key
    }
    
    // 查询模型请求地址
    private func getRequestURL(for company: String) -> String? {
        let predicate = #Predicate<APIKeys> { $0.company == company }
        let fetchDescriptor = FetchDescriptor<APIKeys>(predicate: predicate)
        return (try? context.fetch(fetchDescriptor).first)?.requestURL
    }
    
    // 双语检索是否启用
    private func isBilingualSearchEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.bilingualSearch
        }
        return false
    }
    
    // 记忆功能是否启用
    private func isMemoryEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useMemory
        }
        return false
    }
    
    // 跨聊天记忆功能是否启用
    private func isCrossMemoryEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useCrossMemory
        }
        return false
    }
    
    // 地图功能是否启用
    private func isMapEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useMap
        }
        return false
    }
    
    // 日历功能是否启用
    private func isCalendarEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useCalendar
        }
        return false
    }
    
    // 健康功能是否启用
    private func isHealthEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useHealth
        }
        return false
    }
    
    // 网页功能是否启用
    private func isCodeEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useCode
        }
        return false
    }
    
    // 搜索功能是否启用
    private func isSearchEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useSearch
        }
        return false
    }
    
    // 知识功能是否启用
    private func isKnowledgeEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useKnowledge
        }
        return false
    }
    
    // 天气查询是否启用
    private func isWeatherEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useWeather
        }
        return false
    }
    
    // 画布功能是否启用
    private func isCanvasEnabled() -> Bool {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.useCanvas
        }
        return false
    }
    
    // 检查使用的地图
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
            print("获取地图服务失败: \(error.localizedDescription)")
        }
        return nil
    }
    
    // 检查使用的天气
    private func findUseWeather() -> (company: String, apiKey: String, requestURL: String)? {
        let fetchRequest = FetchDescriptor<ToolKeys>(predicate: #Predicate {
            $0.toolClass == "weather" && $0.isUsing == true
        })
        do {
            let mapKeys = try context.fetch(fetchRequest)
            if let activeMap = mapKeys.first {
                return (activeMap.company, activeMap.key, activeMap.requestURL)
            }
        } catch {
            print("获取天气服务失败: \(error.localizedDescription)")
        }
        return nil
    }
    
    // 搜索数量
    private func getSearchCount() -> Int {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.searchCount
        }
        return 10
    }
    
    // 知识数量
    private func getKnowledgeCount() -> Int {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.knowledgeCount
        }
        return 10
    }
    
    // 知识相似度
    private func getKnowleageSimilarity() -> Double {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        if let userInfo = try? context.fetch(fetchDescriptor).first {
            return userInfo.knowledgeSimilarity
        }
        return 0.5
    }
    
    // 激活的搜索引擎
    private func getActiveSearchEngine() -> (engine: SearchEngine, apiKey: String?, requestURL: String)? {
        let fetchRequest = FetchDescriptor<SearchKeys>(predicate: #Predicate { $0.isUsing == true })
        do {
            let searchKeys = try context.fetch(fetchRequest)
            if let activeKey = searchKeys.first,
               let engine = SearchEngine(rawValue: activeKey.company?.uppercased() ?? "Unknown") {
                return (engine, activeKey.key, activeKey.requestURL) as? (engine: SearchEngine, apiKey: String?, requestURL: String)
            }
        } catch {
            print("获取搜索引擎失败: \(error.localizedDescription)")
        }
        return nil
    }
    
    // MARK: - 系统消息生成
    private func getSystemMessageText(
        modelDisplayName: String,
        modelInfo: AllModels,
        query: String
    ) -> String {
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let isZh = currentLanguage.hasPrefix("zh")

        // 当前时间
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        let now = dateFormatter.string(from: Date())

        let weekFormatter = DateFormatter()
        weekFormatter.locale = Locale(identifier: currentLanguage)
        weekFormatter.dateFormat = "EEEE"
        let weekDay = weekFormatter.string(from: Date())

        // 模块 1：身份设定
        let identitySection: String = {
            if modelInfo.identity == "model" {
                return isZh
                    ? "# 你正作为协作型群聊的AI成员【\(modelDisplayName)】。"
                    : "# You are participating in a collaborative group chat as an AI member [\(modelDisplayName)]."
            } else {
                let config = modelInfo.characterDesign?.trimmingCharacters(in: .whitespacesAndNewlines)
                let hasConfig = config != nil && !(config!.isEmpty)

                if isZh {
                    return hasConfig
                    ? """
                    # 你正作为协作型群聊的智能伙伴【\(modelDisplayName)】。
                    你被设定为：
                    \(config!)
                    请记住你的设定，在回复时保证始终遵循这个设定。
                    """
                    : """
                    # 你正作为协作型群聊的智能伙伴【\(modelDisplayName)】。
                    请在回复中保持身份一致性与角色风格。
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

        // 模块 2：时间信息
        let timeSection = isZh
            ? "# 当前时间：\(now)（\(weekDay)）"
            : "# Current Time: \(now) (\(weekDay))"

        // 模块 3：群聊行为规范
        let guidelineSection = isZh
            ? """
            # 群聊行为规范
            1. 重视用户需求：话题围绕用户，以用户问题为核心；
            2. 匿名发言：不透露身份信息，中立观察，保持自身身份一致性；
            3. 差异化视角：基于专长输出独特观点，不要重复观点；
            4. 建设性互动：理性补充观点，保持友好；
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
                ? "# 群聊目标：\n严格遵守规范，通过多元视角启发用户决策。\n# 工具提示：系统支持工具递归多次调用，你可以通过灵活的工具组合使用更好的解决任务，维持高效协作。"
                : "# Chat Goal:\nStrictly adhere to standards and inspire user decisions through diverse perspectives.\n# Tool Tip: The system supports multiple recursive calls of tools, allowing you to flexibly combine tools to better solve tasks and maintain efficient collaboration."
        } else {
            goalSection = isZh
                ? "# 群聊目标：\n严格遵守规范，通过多元视角启发用户决策，维持高效协作。"
                : "# Chat Goal:\nStrictly adhere to standards, inspire user decision-making through diverse perspectives, and maintain efficient collaboration."
        }

        // 模块 5：用户信息
        var userInfoSection = ""
        if let info = try? context.fetch(FetchDescriptor<UserInfo>()).first {
            var items: [String] = []
            if let name = info.name, !name.isEmpty {
                items.append(isZh ? "- 用户昵称：\(name)" : "- User Nickname: \(name)")
            }
            if let intro = info.userInfo, !intro.isEmpty {
                items.append(isZh ? "- 用户自我介绍：\n\(intro)" : "- User Self-Introduction:\n\(intro)")
            }
            if let requirements = info.userRequirements, !requirements.isEmpty {
                items.append(isZh ? "- 用户对你的要求：\n\(requirements)" : "- User Requests:\n\(requirements)")
            }
            if !items.isEmpty {
                userInfoSection = isZh
                    ? "# 当前用户信息：\n" + items.joined(separator: "\n\n")
                    : "# Current User Information:\n" + items.joined(separator: "\n\n")
            }
        }

        // 模块 6：记忆信息
        var memorySection = ""
        if !query.isEmpty {
            let result = retrieveMemory(keyword: query).trimmingCharacters(in: .whitespacesAndNewlines)
            
            let invalidPhrases = [
                "没有找到与",
                "No memory found related to",
                "请输入有效关键词",
                "Please enter valid keywords",
                "检索过程中出现了错误",
                "Error during memory retrieval"
            ]
            
            let isInvalid = result.isEmpty || invalidPhrases.contains(where: { result.contains($0) })
            
            if !isInvalid {
                memorySection = isZh
                ? """
                # 记忆
                在回答用户问题时，请尽量忘记大部分不相关的信息。只有当用户提供的信息与当前问题或对话内容非常相关时，才记住这些信息并加以使用。
                信息：
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
                        isZh ? "\n\n如果用户更新了记忆，你可以调用记忆工具重新记忆。"
                        : "\n\nIf the user updates the memory, you may call the memory tool to update it."
                    )
                }
            }
        }

        // 汇总所有模块
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
        
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let isZh = currentLanguage.hasPrefix("zh")
        
        // 模块 1：个性设定（模型设定）
        var personalitySection = ""
        if modelInfo.identity != "model" {
            let character = modelInfo.characterDesign?.trimmingCharacters(in: .whitespacesAndNewlines)
            let hasCharacter = character != nil && !(character!.isEmpty)
            
            if isZh {
                personalitySection = hasCharacter
                ? """
                # 个性设定
                你是【\(modelDisplayName)】。
                你的设定是：
                \(character!)
                请记住你的设定，在回复时始终遵循这个设定。
                """
                : """
                # 个性设定
                你是【\(modelDisplayName)】。
                请在回复中始终保持你的角色风格与一致性。
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
        
        // 模块 2：用户信息（用户昵称、自我介绍、要求）
        var userInfoSection = ""
        if let info = try? context.fetch(FetchDescriptor<UserInfo>()).first {
            var parts: [String] = []
            
            if let name = info.name, !name.isEmpty {
                parts.append(isZh ? "- 用户昵称：\(name)" : "- User Nickname: \(name)")
            }
            if let intro = info.userInfo, !intro.isEmpty {
                parts.append(isZh ? "- 自我介绍：\n\(intro)" : "- Self-Introduction:\n\(intro)")
            }
            if let requirements = info.userRequirements, !requirements.isEmpty {
                parts.append(isZh ? "- 用户对你的要求：\n\(requirements)" : "- User Requests:\n\(requirements)")
            }
            
            if !parts.isEmpty {
                userInfoSection = isZh
                ? """
                # 用户信息
                \(parts.joined(separator: "\n\n"))
                """
                : """
                # User Info
                \(parts.joined(separator: "\n\n"))
                """
            }
        }
        
        // 模块 3：系统提示（customSystemMessage）
        var systemSection = ""
        if !customSystemMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            systemSection = isZh
            ? """
            # 系统提示
            \(customSystemMessage)
            """
            : """
            # System Prompt
            \(customSystemMessage)
            """
        }
        
        // 模块 4：记忆信息（retrieveMemory）
        var memorySection = ""
        if !query.isEmpty {
            let result = retrieveMemory(keyword: query).trimmingCharacters(in: .whitespacesAndNewlines)
            
            let invalidPhrases = [
                "没有找到与",
                "No memory found related to",
                "请输入有效关键词",
                "Please enter valid keywords",
                "检索过程中出现了错误",
                "Error during memory retrieval"
            ]
            
            let isInvalid = result.isEmpty || invalidPhrases.contains(where: { result.contains($0) })
            
            if !isInvalid {
                memorySection = isZh
                ? """
                # 记忆
                在回答用户问题时，请尽量忘记大部分不相关的信息。只有当用户提供的信息与当前问题或对话内容非常相关时，才记住这些信息并加以使用。
                信息：
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
                        isZh ? "\n\n如果用户更新了记忆，你可以调用记忆工具重新记忆。"
                        : "\n\nIf the user updates the memory, you may call the memory tool to update it."
                    )
                }
            }
        }
        
        // MARK: - 拼接所有非空模块
        let allSections = [
            personalitySection,
            userInfoSection,
            systemSection,
            memorySection
        ].filter { !$0.isEmpty }
        
        return allSections.joined(separator: "\n\n")
    }
    
    // MARK: - 任务取消
    func cancelCurrentRequest() {
        isCancelled = true
        currentTask?.cancel()
        currentTask = nil
    }
    
    // MARK: - 本地模型处理相关
    /// 构建本地模型所需的格式化文本（封装消息内容、文件处理等）
    private func buildLocalFormattedMessages(from
        messages: [RequestMessage],
        modelInfo: AllModels,
        currentLanguage: String,
        selectedPromptsContent: [String]?,
        isObservation: Bool
    ) async throws -> [Chat] {
        
        var chats: [Chat] = []
        let isChinese = currentLanguage.hasPrefix("zh")
        for message in messages {
            var content = message.text
            
            if let existingImageText = message.imageText, !existingImageText.isEmpty {
                content = isChinese ?
                "\n\n# 图片信息：\(existingImageText)\n\n\(content)" :
                "\n\n# Image Information:\(existingImageText)\n\n\(content)"
            }
            
            // 处理文件
            if let documents = message.document, !documents.isEmpty {
                if let existingDocumentText = message.documentText, !existingDocumentText.isEmpty {
                    content = isChinese ?
                    "\n\n# 文件信息：\(existingDocumentText)\n\n\(content)" :
                    "\n\n# Document Information:\(existingDocumentText)\n\n\(content)"
                } else {
                    var allDocumentContent = ""
                    for doc in documents {
                        var documentContent = try await extractContent(from: doc)
                        if isChinese {
                            documentContent = "\n\n【文件名】\n\(doc.lastPathComponent)\n\n【文本内容】\n\(documentContent)"
                        } else {
                            documentContent = "\n\n[Filename]\n\(doc.lastPathComponent)\n\n[Content]\n\(documentContent)"
                        }
                        allDocumentContent.append(documentContent)
                    }
                    content = isChinese ?
                    "\n\n# 文件信息：\(allDocumentContent)\n\n\(content)" :
                    "\n\n# Document Information:\(allDocumentContent)\n\n\(content)"
                    self.documentText = allDocumentContent
                }
            }
            
            // 处理 assistant 消息
            if message.role == "assistant", !content.isEmpty {
                if message.modelName != modelInfo.name {
                    content = isChinese
                        ? "<历史记录中\(message.modelDisplayName)的发言/>\(message.text)"
                        : "<Message from \(message.modelDisplayName) in the historical record/>\(message.text)"
                }
                chats.append((.bot, content))
            }
            
            // 处理 user 消息
            if message.role == "user", !content.isEmpty {
                if let promptArray = message.prompt, !promptArray.isEmpty {
                    let combinedPrompt = promptArray.map { $0.content }.joined(separator: "\n")
                    content = "\(combinedPrompt)\n\n\(content)"
                }
                chats.append((.user, content))
            }
        }
        
        // 若为观察模式，追加提示信息
        if isObservation {
            let observationMessage = isChinese ? "我在观察，你继续讨论" : "I am observing, you continue to discuss."
            chats.append((.user, observationMessage))
        }
        
        return chats
    }
    
    /// 本地模型处理：构造 prompt 格式、加载模型、发起预测并流式返回结果
    private func processLocalModel(messages: [RequestMessage],
                                   modelInfo: AllModels,
                                   currentLanguage: String,
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
                    let isChinese = currentLanguage.hasPrefix("zh")
                    
                    // 输出状态：处理对话内容
                    continuation.yield(StreamData(operationalState: isChinese ? "处理对话内容" : "Processing dialogue content"))
                    
                    // 构造系统提示（默认或自定义）
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
                    
                    // 利用模板格式化对话记录，转换为 Chat 数组
                    let chats = try await buildLocalFormattedMessages(
                        from: messages,
                        modelInfo: modelInfo,
                        currentLanguage: currentLanguage,
                        selectedPromptsContent: selectedPromptsContent,
                        isObservation: isObservation
                    )
                    
                    // 将最后一条用户消息作为当前输入，其余作为历史记录
                    var history: [Chat] = chats
                    var currentInput = ""
                    if let lastUserIndex = history.lastIndex(where: { $0.role == .user }) {
                        currentInput = history[lastUserIndex].content
                        history.remove(at: lastUserIndex)
                    }
                    
                    // 输出状态：加载本地模型
                    continuation.yield(StreamData(operationalState: isChinese ? "加载本地模型" : "Loading local models"))
                    
                    // 获取本地模型路径（确保 getLocalModelPath 返回非 nil）
                    guard let modelPath = getLocalModelPath(for: modelInfo.name ?? "Unknown") else {
                        throw NSError(domain: "LocalModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "模型路径无效"])
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
                    
                    // 初始化 LLM.swift 本地模型及参数调节
                    guard let llm = LLM(
                        from: URL(fileURLWithPath: modelPath),
                        template: .chatML(finalSystemMessage),
                        history: chats,
                        topP: Float(topp),
                        temp: Float(tem),
                        maxTokenCount: Int32(maxtokens),
                    ) else {
                        throw NSError(domain: "LocalLLMInit", code: -1, userInfo: [NSLocalizedDescriptionKey: "本地 LLM 初始化失败"])
                    }
                    
                    // 输出状态：等待模型响应
                    continuation.yield(StreamData(operationalState: isChinese ? "等待模型响应" : "Waiting for model response"))
                    
                    // 定义累积输出的变量，用于检测停止标记（例如 chatML 模板中的 "<|im_end|>"）
                    var accumulatedOutput = ""
                    let reasoningFlag = "</think>"
                    var isReasoning = modelInfo.supportsReasoning
                    var prefixStripped = false
                    var buffer = ""
                    // 调用流式接口逐 token 返回结果
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
                            
                            // 检测累积输出中是否出现停止标记
                            if accumulatedOutput.contains("im_end") {
                                // 检测到停止标记后调用停止方法，让底层模型尽快结束生成
                                llm.stop()
                                break
                            }
                            if accumulatedOutput.contains("im_start") {
                                // 检测到停止标记后调用停止方法，让底层模型尽快结束生成
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
    
    // MARK: - 远程模型处理相关
    /// 构建远程请求所需的格式化消息（包含文本、图片、文件、观察提示等）
    private func buildFormattedMessages(from messages: [RequestMessage],
                                        modelInfo: AllModels,
                                        currentLanguage: String,
                                        selectedPromptsContent: [String]?,
                                        isObservation: Bool,
                                        systemMessage: String,
                                        canvasData: CanvasData,
                                        continuation: AsyncThrowingStream<StreamData, Error>.Continuation?
    ) async throws -> [[String: Any]] {
        var updatedMessages = messages
        let company = modelInfo.company?.uppercased() ?? "UNKNOWN"
        let currentLanguagePrefix = currentLanguage.hasPrefix("zh")
        
        // 插入系统消息（若第一条消息不是 system）
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
            
            // 如果有提示词则将提示词加到内容之前
            if let promptArray = prompt, !promptArray.isEmpty {
                let combinedPromptContent = promptArray.map { $0.content }.joined(separator: "\n")
                content = "\(combinedPromptContent)\n\n\(content)"
            }
            
            // 对 assistant 消息进行标记处理
            if role == "assistant", message.modelName != modelInfo.name {
                content = currentLanguagePrefix
                ? "<历史记录中\(message.modelDisplayName)的发言/>\(message.text)"
                : "<Message from \(message.modelDisplayName) in the historical record/>\(message.text)"
            }
            
            // 处理图片
            if let images = message.images, !images.isEmpty {
                if modelInfo.supportsMultimodal {
                    for image in images {
                        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                            throw NSError(domain: "FileError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解析图片数据"])
                        }
                        if photoCount > 1 {
                            let baseName = restoreBaseModelName(from: modelInfo.name ?? "Unknown")
                            if baseName == "glm-4v-flash" {
                                throw NSError(domain: "ModelError", code: -1, userInfo: [NSLocalizedDescriptionKey: "由于模型能力限制，glm-4v-flash模型只能解析一张图片，多张图片处理请选用更高级的视觉模型。"])
                            }
                        }
                        let base64String = imageData.base64EncodedString()
                        var imageUrlValue: [String: Any] = [:]
                        if company == "ZHIPUAI" || company == "HANLIN" {
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
                                    "text": currentLanguagePrefix ? "这是图片\(photoCount)" : "This is image \(photoCount)"
                                ]
                            ]
                        ])
                        photoCount += 1
                    }
                } else {
                    if let existingImageText = message.imageText, !existingImageText.isEmpty {
                        content = currentLanguagePrefix ?
                        "\n\n# 图片信息：\(existingImageText)\n\n\(content)" :
                        "\n\n# Image information:\(existingImageText)\n\n\(content)"
                    } else {
                        continuation?.yield(StreamData(
                            operationalState: currentLanguagePrefix ? "解析图片内容" : "Analyzing the Image"
                        ))
                        let optimizer = SystemOptimizer(context: self.context)
                        var allPhotoMessage = ""
                        for image in images {
                            let photoMessage = try await optimizer.supportPhoto(inputImage: image)
                            allPhotoMessage.append(currentLanguagePrefix ?
                                                   "\n\n- 图片\(photoCount)描述：\(photoMessage)" :
                                                    "\n\n- Image \(photoCount) Description: \(photoMessage)")
                            photoCount += 1
                        }
                        content = currentLanguagePrefix ?
                        "\n\n# 图片信息：\(allPhotoMessage)\n\n\(content)" :
                        "\n\n# Image information:\(allPhotoMessage)\n\n\(content)"
                        self.imageText = allPhotoMessage
                    }
                }
            }
            
            // 处理文件
            if let documents = message.document, !documents.isEmpty {
                if let existingDocumentText = message.documentText, !existingDocumentText.isEmpty {
                    content = currentLanguagePrefix ?
                    "\n\n# 文件信息：\(existingDocumentText)\n\n\(content)" :
                    "\n\n# Document Information:\(existingDocumentText)\n\n\(content)"
                } else {
                    var allDocumentContent = ""
                    for doc in documents {
                        var documentContent = try await extractContent(from: doc)
                        if currentLanguagePrefix {
                            documentContent = "\n\n【文件名】\n\(doc.lastPathComponent)\n\n【文本内容】\n\(documentContent)"
                        } else {
                            documentContent = "\n\n[Filename]:\n\(doc.lastPathComponent)\n\n[Content]:\n\(documentContent)"
                        }
                        allDocumentContent.append(documentContent)
                    }
                    content = currentLanguagePrefix ?
                    "\n\n# 文件信息：\(allDocumentContent)\n\n\(content)" :
                    "\n\n# Document Information:\(allDocumentContent)\n\n\(content)"
                    self.documentText = allDocumentContent
                }
            }
            
            // 处理网页
            if let html = message.htmlContent, !html.isEmpty {
                let htmlText = currentLanguagePrefix ?
                "\n\n<系统备注>调用“create_web_view”工具时使用的网页的源代码：\n```\(html)```" :
                "\n\n<System Note>Source code of the webpage used when calling the \"create web view\" tool:\n```\(html)```"
                content.append(htmlText)
            }
            
            // 处理代码
            if let codeBlocks = message.codeBlock, !codeBlocks.isEmpty {
                var codeText = currentLanguagePrefix
                ? "\n\n<系统备注>调用工具“execute_python_code”时使用的代码及其输出："
                : "\n\n<System Note>Code and its output used when calling the tool \"execute python code\":"
                
                for block in codeBlocks {
                    codeText += "\n\n```python\n\(block.code)\n```"
                    
                    if !block.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        codeText += currentLanguagePrefix
                        ? "\n\n对应输出如下：\n```\n\(block.output)\n```"
                        : "\n\nThe output was:\n```\n\(block.output)\n```"
                    }
                }
                
                content.append(codeText)
            }
            
            // 处理知识卡片
            if let knowledgeCards = message.knowledgeCard, !knowledgeCards.isEmpty {
                var knowledgeText = currentLanguagePrefix
                ? "\n\n<系统备注>调用工具“create_knowledge_card”时撰写的知识文档："
                : "\n\n<System Note> Knowledge document written when calling the tool \"create knowledge card\":"
                
                for knowledge in knowledgeCards {
                    knowledgeText += "\n\n# \(knowledge.title)\n\(knowledge.content)"
                }
                
                content.append(knowledgeText)
            }
            
            // 对非 "information", "error" 和 "search" 类型消息，直接添加原始消息；若 role 为 "search"，转换为 "user"
            if role != "information", role != "search", role != "error" {
                formattedMessages.append(["role": role, "content": content])
            } else if role == "search" {
                formattedMessages.append(["role": "user", "content": content])
            }
            
            // 检查是否有多个system数据，如果有多个只保留第一个
            if formattedMessages.filter({ ($0["role"] as? String) == "system" }).count > 1 {
                var foundSystem = false
                formattedMessages = formattedMessages.filter { message in
                    let role = message["role"] as? String
                    if role == "system" {
                        if !foundSystem {
                            foundSystem = true
                            return true // 保留第一个
                        } else {
                            return false // 过滤掉多余的
                        }
                    }
                    return true // 非 system 消息保留
                }
            }
        }
        
        if !canvasData.content.isEmpty {
            // 构造完整画布内容字符串（包括标题与正文）
            let canvasMessage: String
            if currentLanguagePrefix {
                canvasMessage = """
                    <系统备注开始>
                    画布标题：
                    \(canvasData.title)
                    
                    画布内容：
                    \(canvasData.content)
                    
                    如需修改画布内容，请使用 edit_canvas 工具。
                    注意：标题与内容是分开存储的，正则表达式规则应分别制定，如果修改内容较多，可以使用 create_canvas 工具创建一个新的画布，原有画布的内容将会被覆盖。
                    </系统备注结束>
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
            
            // 构建 assistant 消息
            let assistantMessage: [String: String] = [
                "role": "user",
                "content": canvasMessage
            ]
            
            // 插入位置：紧跟最后一个 user 消息之前
            if let lastUserIndex = formattedMessages.lastIndex(where: { $0["role"] as! String == "user" }) {
                formattedMessages.insert(assistantMessage, at: lastUserIndex - 1)
            } else {
                // 若找不到 user 消息，就直接追加
                formattedMessages.append(assistantMessage)
            }
        }
        
        // 若为观察模式，追加提示信息
        if isObservation {
            let observationMessage = currentLanguagePrefix
                ? "请继续刚才的讨论，我正在旁观记录，不会主动插话。"
                : "Please continue the previous discussion. I'm observing and taking notes without intervening."
            
            formattedMessages.append(["role": "user", "content": observationMessage])
        }
        
        return formattedMessages
    }
    
    /// 搜索任务：优化问题、执行搜索、合并搜索结果并构造 Markdown 格式摘要
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
            
            guard let (engine, apiKey, requestURL) = getActiveSearchEngine() else {
                print("未找到启用的搜索引擎，请检查数据库设置。")
                return
            }
            
            // 第一次搜索：原始语言
            let (searchResult1, searchEngine) = try await searchTool(query: optimizedQuery, engine: engine, apiKey: apiKey, requestURL: requestURL, searchCount: searchCount)
            var combinedTitles = searchResult1.titles
            var combinedLinks = searchResult1.links
            var combinedContents = searchResult1.contents
            var combinedIcons = searchResult1.icons
            
            // 若启用双语搜索，则翻译查询并执行第二次搜索
            if bilingualSearchEnabled {
                let translatedQuery = try await optimizer.translatePrompt(inputPrompt: optimizedQuery)
                let (searchResult2, _) = try await searchTool(query: translatedQuery, engine: engine, apiKey: apiKey, requestURL: requestURL, searchCount: searchCount)
                
                combinedTitles.append(contentsOf: searchResult2.titles)
                combinedLinks.append(contentsOf: searchResult2.links)
                combinedContents.append(contentsOf: searchResult2.contents)
                combinedIcons.append(contentsOf: searchResult2.icons)
            }
            
            var markdownContent = ""
            if !combinedContents.isEmpty {
                let header = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true ? "# 内容摘要：\n\n" : "# Content Summary:\n\n"
                markdownContent.append(header)
                
                for (index, content) in combinedContents.enumerated() {
                    let title = combinedTitles.indices.contains(index) ? combinedTitles[index] : "无标题"
                    if self.dataIndex == nil {
                        self.dataIndex = 1
                    } else {
                        self.dataIndex! += 1
                    }
                    markdownContent.append("[\(self.dataIndex ?? index + 1)]: \(title)\n\(content.prefix(6000))\n\n")
                }
            } else {
                markdownContent.append(Locale.preferredLanguages.first?.hasPrefix("zh") ?? true ? "未找到相关信息\n" : "No relevant information found\n")
            }
            
            let userMessage = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
                ? "搜索关键词：\(optimizedQuery)\n\n网络资料，供您参考，引用内容时在对应的内容后标注 [index] 引用：\n\n\(markdownContent)"
                : "Search keywords: \(optimizedQuery)\n\nWeb materials for your reference. When citing content, please indicate with [index] after the corresponding content:\n\(markdownContent)"
            
            // 记录搜索数据
            self.searchText = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            let newResources = zip(combinedIcons, zip(combinedTitles, combinedLinks))
                .map { Resource(icon: $0.0, title: $0.1.0, link: $0.1.1) }
            if self.searchResources != nil {
                self.searchResources?.append(contentsOf: newResources)
            } else {
                self.searchResources = newResources
            }
            self.searchEngine = searchEngine
        } catch {
            print("搜索过程中发生错误: \(error.localizedDescription)")
        }
    }
    
    /// 网页阅读任务：从选中的 URL 中提取网页内容，并构造 Markdown 格式摘要
    private func performWebPageTask(with selectedURLs: [String]) async {
        guard !selectedURLs.isEmpty else { return }
        let extractedWebPages = await fetchWebPageContent(from: selectedURLs)
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
            let webMessage = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
            ? "\n网页内容，供您参考：\n\n\(webContentMarkdown)"
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
                self.searchEngine = "HANLINWEB"
            }
        }
    }
    
    /// 自动生成标题：若历史消息正好为 3 条，则调用优化器生成自动标题
    /// 自动生成标题：若历史消息正好为 1、3、11 条，则调用优化器生成自动标题
    private func autoGenerateTitleIfNeeded(from messages: [RequestMessage]) async throws {
        // 需要生成标题的历史消息条数
        let autoTitleCounts: Set<Int> = [1, 3, 11]
        // 只统计用户和助手的消息
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
    
    /// 知识书包翻找相关内容
    /// 计算输入文本的向量表示
    private func computeEmbedding(for text: String) async throws -> [Float] {
        // 1. 从数据库中获取用户信息，提取已选择的向量模型名称
        let userFetchDescriptor = FetchDescriptor<UserInfo>()
        guard let user = try context.fetch(userFetchDescriptor).first,
              let selectedModelName = user.chooseEmbeddingModel,
              !selectedModelName.isEmpty else {
            throw NSError(domain: "EmbeddingAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "请先选择嵌入模型"])
        }
        
        // 2. 通过 getEmbeddingModelList() 查询模型列表，找到匹配的模型
        let models = getEmbeddingModelList()
        guard let selectedModel = models.first(where: { $0.name == selectedModelName }) else {
            throw NSError(domain: "EmbeddingAPI", code: -2, userInfo: [NSLocalizedDescriptionKey: "未找到对应的嵌入模型"])
        }
        
        // 3. 根据模型的所属厂商，从数据库中查询 APIKey 记录
        guard let key = getAPIKey(for: selectedModel.company) else {
            throw NSError(domain: "EmbeddingAPI", code: -3, userInfo: [NSLocalizedDescriptionKey: "无效的 API Key"])
        }
        
        // 4. 检查请求 URL 是否有效
        guard let _ = URL(string: selectedModel.requestURL), !selectedModel.requestURL.isEmpty else {
            throw NSError(domain: "EmbeddingAPI", code: -4, userInfo: [NSLocalizedDescriptionKey: "无效的请求 URL"])
        }
        
        // 5. 调用 generateEmbeddings，传入单个文本构成的数组
        let embeddings = try await generateEmbeddings(
            for: [text],
            modelName: selectedModel.name,
            apiKey: key,
            apiURL: selectedModel.requestURL
        )
        
        guard let firstEmbedding = embeddings.first else {
            throw NSError(domain: "EmbeddingAPI", code: -5, userInfo: [NSLocalizedDescriptionKey: "返回的 embedding 数量与输入文本数量不一致"])
        }
        
        return firstEmbedding
    }
    
    /// 计算两个向量的余弦相似度
    private func cosineSimilarity(_ v1: [Float], _ v2: [Float]) -> Float {
        // 保证长度一致，取最小长度进行计算
        let count = min(v1.count, v2.count)
        let n = vDSP_Length(count)
        
        // 1. 计算点积 dot = ∑ v1[i] * v2[i]
        var dot: Float = 0
        vDSP_dotpr(v1, 1, v2, 1, &dot, n)
        
        // 2. 计算二范数的平方：sum1 = ∑ v1[i]^2, sum2 = ∑ v2[i]^2
        var sum1: Float = 0
        var sum2: Float = 0
        vDSP_svesq(v1, 1, &sum1, n)
        vDSP_svesq(v2, 1, &sum2, n)
        
        // 3. 归一化并避免除零：denom = ||v1|| * ||v2|| + ε
        let denom = sqrt(sum1) * sqrt(sum2) + Float.leastNonzeroMagnitude
        
        // 4. 返回余弦相似度
        return dot / denom
    }

    /// 将文本拆分成小写词语数组
    private func tokenize(_ text: String) -> [String] {
        let separators = CharacterSet.alphanumerics.inverted
        return text
            .lowercased()
            .components(separatedBy: separators)
            .filter { !$0.isEmpty }
    }

    /// 使用 TF–IDF 权重计算加权 Jaccard 相似度
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
        
        // 交集权重 = ∑ idf(token)
        let interWeight = intersection.reduce(0) { $0 + (idfMap[$1] ?? 0) }
        // 并集权重 = ∑ idf(token)
        let unionWeight = union.reduce(0) { $0 + (idfMap[$1] ?? 0) }
        
        return unionWeight > 0 ? interWeight / unionWeight : 0
    }

    /// 执行知识库搜索，返回 Markdown 格式的知识摘要
    private func performKnowledgeSearch(query: String) async -> String? {
        do {
            // 1. 计算查询的向量表示
            let queryVector = try await computeEmbedding(for: query)
            
            // 2. 拉取所有知识片段
            let fetchDescriptor = FetchDescriptor<KnowledgeChunk>()
            guard let knowledgeChunks = try? context.fetch(fetchDescriptor),
                  !knowledgeChunks.isEmpty else {
                return nil
            }
            
            // 3. 构建 TF–IDF 的 IDF 映射
            let allDocTokens = knowledgeChunks.compactMap { $0.text }.map { tokenize($0) }
            var df = [String: Int]()
            for tokens in allDocTokens {
                for token in Set(tokens) {
                    df[token, default: 0] += 1
                }
            }
            let N = Double(allDocTokens.count)
            let idfMap = df.mapValues { log(N / (1.0 + Double($0))) }
            
            // 4. 配置语义/字面匹配权重和过滤阈值
            let embWeight: Double = 0.8
            let lexWeight: Double = 0.2
            let scoreThreshold = Double(getKnowleageSimilarity())
            let maxResults     = getKnowledgeCount()
            
            // 5. 预分词
            let queryTokens = tokenize(query)
            
            // 6. 计算综合评分并过滤
            let scored = knowledgeChunks.compactMap { chunk -> (KnowledgeChunk, Double)? in
                guard let content = chunk.text,
                      let vector  = chunk.getVector() else { return nil }
                
                let embScore = Double(cosineSimilarity(queryVector, vector))                  // 语义得分
                let docTokens = tokenize(content)
                let lexScore  = weightedJaccard(
                    between: queryTokens,
                    and: docTokens,
                    idfMap: idfMap
                )                                                                             // 字面得分
                
                // 动态融合：当字面得分过低时退化为纯语义得分
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
            
            // 7. 排序 & 取前 N
            let topResults = scored
                .sorted { $0.1 > $1.1 }
                .prefix(maxResults)
            
            // 8. 生成 Markdown 摘要
            let isZH = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
            var markdown = isZH
                ? "知识书包翻找结果，供您参考，引用时请标注 [index]：\n"
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
                
                let scoreLabel = isZH
                    ? "内容匹配得分"
                    : "Content match score"

                markdown.append("""
                \n[\(refIndex)](\(scoreLabel)：\(String(format: "%.2f", score * 100))%): 
                \(chunk.text ?? "")\n
                """)
                
                resources.append(Resource(icon: "", title: chunk.knowledgeRecord?.name ?? "Unknown", link: ""))
            }
            
            // 9. 合并并去重资源列表
            let combinedRes = (self.searchResources ?? []) + resources
            var seen = Set<String>()
            self.searchResources = combinedRes.filter {
                if seen.contains($0.title) { return false }
                seen.insert($0.title)
                return true
            }
            
            return markdown
        } catch {
            print("计算向量失败: \(error.localizedDescription)")
            return error.localizedDescription
        }
    }
    
    /// 将用户最后提问进行优化后，调用知识库搜索，并将搜索结果追加到 updatedMessages 中
    func performSearchTask(updatedMessages: inout [RequestMessage]) async {
        do {
            // 1. 获取用户最近一次提问
            let query = updatedMessages.last?.text ?? ""
            guard !query.isEmpty else { return }
            
            let recentMessages = updatedMessages
                .filter { $0.role == "user" || $0.role == "assistant" || $0.role == "search" }
                .suffix(8)
                .map { "- " + $0.text + ($0.imageText ?? "") + ($0.documentText ?? "") }
                .joined(separator: "\n")
            
            print("优化的原问题：", query)
            let currentMessage = updatedMessages.last
            let images = currentMessage?.images
            let optimizer = SystemOptimizer(context: self.context)
            let optimizedQuery = try await optimizer.optimizeKnowledgeQuestion(inputPrompt: query, recentMessages: recentMessages, inputImages: images)
            print("优化后的问题：", optimizedQuery)
            
            if let knowledgeMarkdown = await self.performKnowledgeSearch(query: optimizedQuery) {
                // 将搜索结果追加到 searchText 中
                self.searchText = knowledgeMarkdown.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // 如果 searchEngine 为空，则设置默认值
                if self.searchEngine == nil || self.searchEngine?.isEmpty == true {
                    self.searchEngine = "HANLINBAG"
                }
                
                // 5. 将搜索结果打包为一条新的消息并追加到对话中
                updatedMessages.append(RequestMessage(
                    role: "search",
                    text: knowledgeMarkdown,
                    modelName: "knowledge_bag",
                    modelDisplayName: "KnowledgeBag"
                ))
            }
        } catch {
            print("知识背包搜索过程中发生错误: \(error.localizedDescription)")
        }
    }
    
    // 远程模型处理：构造格式化消息、执行搜索与网页阅读任务、自动生成标题、构造请求并处理流式响应
    private func processRemoteModel(messages: [RequestMessage],
                                    formattedMessages: [[String: Any]]? = nil,
                                    modelInfo: AllModels,
                                    groupID: UUID,
                                    currentLanguage: String,
                                    ifSearch: Bool,
                                    ifKnowledge: Bool,
                                    ifToolUse: Bool,
                                    ifThink: Bool,
                                    ifAudio: Bool,
                                    ifPlanning: Bool,
                                    thinkingLength: Int,
                                    planningMessage: String,
                                    isObservation: Bool,
                                    temperature: Double,
                                    topP: Double,
                                    maxTokens: Int,
                                    canvasData: CanvasData,
                                    selectedURLs: [String]?,
                                    selectedPromptsContent: [String]?,
                                    systemMessage: String,
                                    depth: Int = 0
    ) async throws -> AsyncThrowingStream<StreamData, Error> {
        
        var updatedMessages = messages
        
        return AsyncThrowingStream<StreamData, Error> { continuation in
            
            Task(priority: .userInitiated) {
                do {
                    let currentLanguagePrefix = currentLanguage.hasPrefix("zh")
                    var tempFormattedMessages: [[String: Any]]
                    var finalFormattedMessages: [[String: Any]]
                    
                    if depth == 0 {
                        // 执行知识背包翻找
                        if ifKnowledge {
                            continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "翻找知识背包" : "Searching Backpack"))
                            await self.performSearchTask(updatedMessages: &updatedMessages)
                            // 推送搜索信息
                            if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                            }
                        }
                        
                        // 执行联网搜索
                        if ifSearch {
                            continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在联网搜索" : "Searching Online"))
                            await self.performSearchTask(with: messages)
                            // 推送搜索信息
                            if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                            }
                        }
                        
                        // 执行读取网页
                        if let urls = selectedURLs, !urls.isEmpty {
                            continuation.yield(StreamData(operationalState: currentLanguagePrefix ?  "正在阅读网页" : "Reading Webpage"))
                            await self.performWebPageTask(with: urls)
                            // 推送搜索信息
                            if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                            }
                        }
                        
                        // 加入搜索内容信息
                        if let searchText = self.searchText, !searchText.isEmpty {
                            updatedMessages.append(RequestMessage(
                                role: "search",
                                text: searchText,
                                modelName: "search_engine",
                                modelDisplayName: self.searchEngine ?? "Search"
                            ))
                        }
                        
                        // 联网任务完成，开始生成请求
                        continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "处理对话内容" : "Processing"))
                        
                        // 格式化消息
                        finalFormattedMessages = try await buildFormattedMessages(
                            from: updatedMessages,
                            modelInfo: modelInfo,
                            currentLanguage: currentLanguage,
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
                            throw NSError(domain: "ProcessError", code: -1, userInfo: [NSLocalizedDescriptionKey: "格式化消息为空"])
                        }
                        finalFormattedMessages = fm
                        
                    }
                    
                    tempFormattedMessages = finalFormattedMessages
                    
                    if ifPlanning {
                        if planningMessage.isEmpty {
                            finalFormattedMessages.append([
                                "role": "user",
                                "content": """
                                在回答该问题之前，请先进行系统性思考和任务规划：

                                1. 理解问题背景：提取核心目标与上下文关键信息；
                                2. 结构化任务拆解：明确解决思路、关键步骤与子任务的先后依赖关系；
                                3. 输出详细计划：列出每一步应做什么、所需资源、关键前提条件以及建议使用的工具名称（如有）；

                                直接输出该任务的完整规划方案。不要进行任何实际解答、输出结论或附带说明，也不要添加多余的解释和说明。
                                """
                            ])
                        } else {
                            finalFormattedMessages.append([
                                "role": "user",
                                "content": """
                                基于当前的用户提问，请你严格按照下面方案给出的步骤，解决当前问题：

                                <think>
                                \(planningMessage)
                                </think>

                                执行时请务必遵循以下要求：
                                - 每一步对应一个逻辑片段，确保结构清晰、思路连贯；
                                - 必须体现对规划内容的落实，避免跳过步骤或随意发挥；
                                
                                直接输出最终解答，无需重复规划内容、规划结构或其他添加多余的解释性语言。
                                """
                            ])
                        }
                    }
                    
                    // 自动生成标题
                    try await autoGenerateTitleIfNeeded(from: messages)
                    
                    continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在发送请求" : "Sending request"))
                    
                    print(finalFormattedMessages)
                    
                    // 获取 API Key 和请求 URL
                    guard let apiKey = getAPIKey(for: modelInfo.company ?? "Unknown") else {
                        throw NSError(domain: "APIConfigError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的 API Key"])
                    }
                    guard let requestURLString = getRequestURL(for: modelInfo.company ?? "Unknown"),
                          let requestURL = URL(string: requestURLString),
                          !requestURLString.isEmpty else {
                        throw NSError(domain: "URLConfigError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的请求 URL"])
                    }
                    
                    // 构造请求
                    var request = URLRequest(url: requestURL)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    
                    let baseName = restoreBaseModelName(from: modelInfo.name ?? "Unknown")
                    var requestBody: [String: Any] = [
                        "model": baseName,
                        "messages": finalFormattedMessages,
                        "stream": true,
                    ]
                    
                    // 参数设置
                    if temperature > 0 {
                        requestBody["temperature"] = temperature
                    }
                    if topP > 0 {
                        requestBody["top_p"] = topP
                    }
                    if maxTokens > 0 {
                        requestBody["max_tokens"] = maxTokens
                    }
                    
                    // 工具设置
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
                        // 获得工具
                        requestBody["tools"] = tools
                    }
                    
                    if modelInfo.supportReasoningChange {
                        if modelInfo.company == "QWEN" ||
                            modelInfo.company == "MODELSCOPE" ||
                            modelInfo.company == "SILICONCLOUD" ||
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
                        } else if modelInfo.company == "ZHIPUAI" || modelInfo.company == "HANLIN" || modelInfo.company == "DOUBAO" {
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
                            // 给最后一句话加上/think 或者/no_think
                            if var lastMessage = finalFormattedMessages.last,
                               lastMessage["role"] as? String == "user",
                               var content = lastMessage["content"] as? String,
                               !content.contains("/think") && !content.contains("/no_think") {
                                content += ifThink ? " /think" : " /no_think"
                                lastMessage["content"] = content
                                finalFormattedMessages[finalFormattedMessages.count - 1] = lastMessage
                            }
                            // 更新 requestBody
                            requestBody["messages"] = finalFormattedMessages
                        }
                    }
                    
                    if modelInfo.supportsReasoning && ifThink && thinkingLength != 0 {
                        switch thinkingLength {
                        case 1:
                            // 短暂思考
                            if modelInfo.company == "OPENAI" || modelInfo.company == "GOOGLE" || modelInfo.company == "XAI" {
                                requestBody["reasoning_effort"] = "low"
                            } else if modelInfo.company == "QWEN" || modelInfo.company == "MODELSCOPE" || modelInfo.company == "SILICONCLOUD" {
                                requestBody["thinking_budget"] = 1024
                            }
                            
                        case 2:
                            // 中等思考
                            if modelInfo.company == "OPENAI" || modelInfo.company == "GOOGLE" || modelInfo.company == "XAI" {
                                requestBody["reasoning_effort"] = "medium"
                            } else if modelInfo.company == "QWEN" || modelInfo.company == "MODELSCOPE" || modelInfo.company == "SILICONCLOUD" {
                                requestBody["thinking_budget"] = 8192
                            }

                        case 3:
                            // 深度思考
                            if modelInfo.company == "OPENAI" || modelInfo.company == "GOOGLE" || modelInfo.company == "XAI" {
                                requestBody["reasoning_effort"] = "high"
                            } else if modelInfo.company == "QWEN" || modelInfo.company == "MODELSCOPE" || modelInfo.company == "SILICONCLOUD" {
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
                    
                    // 推送请求状态
                    continuation.yield(StreamData(operationalState: currentLanguagePrefix ?  "等待模型响应" : "Waiting for model response"))
                    
                    let (result, response) = try await URLSession.shared.bytes(for: request)
                    let httpResponse = response as? HTTPURLResponse
                    
                    if let httpResponse = httpResponse, !(200...299).contains(httpResponse.statusCode) {
                        var errorContent = ""
                        do {
                            let errorData = try await result.reduce(into: Data()) { $0.append($1) }
                            if let errorString = String(data: errorData, encoding: .utf8) {
                                errorContent = ":\(errorString)"
                            }
                        }
                        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "\(httpResponse.statusCode)请求错误\(errorContent)"])
                    }
                    
                    // 定义变量保存所有分片累计的 tool_calls
                    var accumulatedToolCalls: [[String: Any]] = []
                    var prefixStripped = false
                    var buffer = ""
                    self.toolMessage = ""
                    self.toolMessageReasoning = ""
                    var tempOperationalState = ""
                    var zhipuReasoning: Bool = (
                        (modelInfo.company == "ZHIPUAI" || modelInfo.company == "HANLIN")
                        && modelInfo.supportsReasoning
                        && (modelInfo.name?.hasPrefix("glm-z1") ?? false)
                    )
                    var zhipuInThink = false      // 当前是否在 <think>…</think> 区间内
                    var zhipuBuffer = ""          // 用于拼接片段
                    var audioB64 = ""
                    var planning = ""
                    
                    // 处理流式响应
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
                            
                            // 如果流里带了音频分片及转录文本
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
                            
                            // 处理 tool_calls 分片数据
                            if let toolCallsChunk = delta["tool_calls"] as? [[String: Any]] {
                                if tempOperationalState != "正在使用工具", tempOperationalState != "Using Tools" {
                                    tempOperationalState = currentLanguagePrefix ?  "正在使用工具" : "Using Tools"
                                    continuation.yield(StreamData(operationalState: currentLanguagePrefix ?  "正在使用工具" : "Using Tools"))
                                }
                                for toolCall in toolCallsChunk {
                                    if let index = toolCall["index"] as? Int {
                                        // 确保 accumulatedToolCalls 数组长度足够
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
                                            // 在最初的数据块中，name 会返回，后续只追加 arguments
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
                                            print("\n🔢 输入参数：\n\(functionArguments)")
                                            continuation.yield(StreamData(operationalDescription: "\(functionName): \(functionArguments)"))
                                            
                                            // 根据具体函数名称调用对应的本地函数
                                            switch functionName {
                                            case "save_memory":
                                                // 记忆函数
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在记忆" : "Taking Notes"))
                                                
                                                let content = extractValue(from: functionArguments, forKey: "content") ?? functionArguments
                                                let success = saveMemory(content: content)
                                                
                                                toolResult = currentLanguagePrefix
                                                ? (success ? "记忆已保存。" : "记忆保存失败。")
                                                : (success ? "Memory saved." : "Failed to save memory.")
                                                
                                                toolResultFront = toolResult
                                                
                                                useFunctionName = functionName
                                                
                                            case "retrieve_memory":
                                                // 回忆函数
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在回忆" : "Looking at the Notes"))
                                                
                                                let keyword = extractValue(from: functionArguments, forKey: "keyword") ?? functionArguments
                                                let memory = retrieveMemory(keyword: keyword)
                                                
                                                toolResult = currentLanguagePrefix
                                                ? "记忆内容：\n\(memory)"
                                                : "Memory content: \n\(memory)"
                                                
                                                toolResultFront = toolResult
                                                
                                                useFunctionName = functionName
                                                
                                            case "update_memory":
                                                // 更新记忆
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在更新记忆" : "Updating Memory"))
                                                
                                                let original = extractValue(from: functionArguments, forKey: "originalContent") ?? ""
                                                let updated = extractValue(from: functionArguments, forKey: "updatedContent") ?? ""
                                                
                                                if original.isEmpty || updated.isEmpty {
                                                    toolResult = currentLanguagePrefix ? "更新失败，参数不完整。" : "Update failed: missing parameters."
                                                } else {
                                                    let result = updateMemory(originalContent: original, updatedContent: updated)
                                                    toolResult = currentLanguagePrefix ? "记忆更新结果：\(result)" : "Memory update result: \(result)"
                                                }
                                                useFunctionName = functionName
                                                toolResultFront = toolResult
                                                
                                            case "search_online":
                                                // 调用网络搜索工具
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在联网搜索" : "Searching Online"))
                                                useFunctionName = functionName
                                                
                                                // 提取 query 参数
                                                let actualQuery = extractValue(from: functionArguments, forKey: "query") ?? functionArguments
                                                
                                                // 执行搜索
                                                let resultMarkdown = await searchOnline(query: actualQuery)
                                                
                                                // 将搜索结果设置为 toolResult 返回给大模型
                                                toolResult = resultMarkdown
                                                toolResultFront = toolResult
                                                
                                                // 推送搜索信息
                                                if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                                    continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                                                }
                                                
                                            case "search_arxiv_papers":
                                                // 调用 arXiv 文献检索工具
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在检索文献" : "Searching Papers"))
                                                useFunctionName = functionName
                                                
                                                // 提取 query 参数
                                                let actualQuery = extractValue(from: functionArguments, forKey: "query") ?? functionArguments
                                                
                                                // 执行搜索
                                                let resultMarkdown = await searchArxivPapers(query: actualQuery)
                                                
                                                // 将搜索结果设置为 toolResult 返回给大模型
                                                toolResult = resultMarkdown
                                                toolResultFront = toolResult
                                                
                                                // 推送搜索信息
                                                if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                                    continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                                                }
                                                
                                            case "extract_remote_file_content":
                                                // 调用远程文件内容提取工具
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在分析文件" : "Analyzing the Document"))
                                                useFunctionName = functionName
                                                
                                                // 提取 url 参数
                                                let actualURL = extractValue(from: functionArguments, forKey: "url") ?? functionArguments
                                                
                                                // 执行提取
                                                do {
                                                    let extractedContent = try await extractContentFromRemoteFile(urlString: actualURL)
                                                    toolResult = extractedContent
                                                } catch {
                                                    let isZh = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
                                                    toolResult = isZh
                                                    ? "提取文件内容时发生错误：\(error.localizedDescription)"
                                                    : "An error occurred while extracting file content: \(error.localizedDescription)"
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                                // 推送搜索信息
                                                if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                                    continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                                                }
                                                
                                            case "read_web_page":
                                                // 调用网页阅读工具
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在读取网页" : "Reading Web"))
                                                useFunctionName = functionName
                                                
                                                // 提取 url 参数
                                                let actualURL = extractValue(from: functionArguments, forKey: "url") ?? functionArguments
                                                
                                                // 执行网页提取
                                                let resultMarkdown = await readWebPage(url: actualURL)
                                                
                                                // 将网页内容摘要设置为 toolResult 返回给大模型
                                                toolResult = resultMarkdown
                                                toolResultFront = toolResult
                                                
                                                // 推送搜索信息
                                                if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                                    continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                                                }
                                                
                                            case "search_knowledge_bag":
                                                // 调用知识背包搜索工具
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在翻找背包" : "Searching in Bag"))
                                                useFunctionName = functionName
                                                
                                                // 提取 query 参数
                                                let actualQuery = extractValue(from: functionArguments, forKey: "query") ?? functionArguments
                                                
                                                // 执行知识背包搜索
                                                let resultMarkdown = await searchKnowledgeBag(query: actualQuery)
                                                
                                                // 将搜索结果设置为 toolResult 返回给大模型
                                                toolResult = resultMarkdown
                                                toolResultFront = toolResult
                                                
                                                // 推送搜索信息
                                                if let searchEngine = self.searchEngine, !searchEngine.isEmpty {
                                                    continuation.yield(StreamData(searchEngine: self.searchEngine, search_text: self.searchText))
                                                }
                                                
                                            case "create_knowledge_document":
                                                // 调用创建知识卡片工具
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "创建知识文档" : "Creating Knowledge"))
                                                useFunctionName = functionName
                                                
                                                // 提取 title 和 content 参数
                                                let title   = extractValue(from: functionArguments, forKey: "title")   ?? ""
                                                let content = extractValue(from: functionArguments, forKey: "content") ?? ""
                                                
                                                let card = createKnowledgeCard(title: title, content: content)
                                                
                                                let feedbackMD: String
                                                if currentLanguage.hasPrefix("zh") {
                                                    feedbackMD = """
                                                    已创建知识文档《\(card.title)》。用户现在可以在界面中看到知识文档的详细内容了，不用重复文档内容。
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
                                                
                                                if currentLanguage.hasPrefix("zh") {
                                                    toolResultFront = """
                                                    已创建知识文档《\(card.title)》。
                                                    """
                                                } else {
                                                    toolResultFront = """
                                                    The knowledge document "\(card.title)" has been created.
                                                    """
                                                }
                                                
                                            case "query_location":
                                                // 调用查询位置函数
                                                guard let mapInfo = findUseMap() else {
                                                    toolResult = "当前无激活的地图服务，请先配置地图服务。"
                                                    useFunctionName = functionName
                                                    break
                                                }
                                                
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在查询位置" : "Querying Location"))
                                                
                                                do {
                                                    let actualKeyword = extractValue(from: functionArguments, forKey: "keyword") ?? functionArguments
                                                    useFunctionName = functionName
                                                    
                                                    let locations = try await queryLocation(with: actualKeyword, company: mapInfo.company, apiKey: mapInfo.apiKey)
                                                    
                                                    if locations.isEmpty {
                                                        toolResult = "未查询到与关键字 \"\(actualKeyword)\" 相关的位置"
                                                    } else {
                                                        // 初始化 locationsInfo
                                                        if self.locationsInfo == nil {
                                                            self.locationsInfo = []
                                                        }
                                                        
                                                        // 追加到全局位置数组中
                                                        self.locationsInfo?.append(contentsOf: locations)
                                                        
                                                        // 构造结果提示字符串
                                                        let formatted = locations.enumerated().map { index, loc in
                                                            "(\(index + 1)) \(loc.name)：纬度 \(loc.latitude)，经度 \(loc.longitude)"
                                                        }.joined(separator: "\n")
                                                        
                                                        toolResult = currentLanguagePrefix ?
                                                        "\(actualKeyword) 的位置查询成功，共找到 \(locations.count) 个地点：\n\(formatted)" :
                                                        "\(actualKeyword) The location query was successful, a total of \(locations.count) locations were found: \n\(formatted)\n and have been mapped in the interface."
                                                        
                                                        toolResultFront = currentLanguagePrefix ?
                                                        "\(actualKeyword) 的位置查询成功，共找到 \(locations.count) 个地点：\n\(formatted)" :
                                                        "\(actualKeyword) The location query was successful, a total of \(locations.count) locations were found: \n\(formatted)."
                                                    }
                                                } catch {
                                                    toolResult = "查询位置出错：\(error.localizedDescription)"
                                                    useFunctionName = functionName
                                                    toolResultFront = toolResult
                                                }
                                                
                                            case "query_weather":
                                                // 检查是否有激活的天气服务
                                                guard let weatherInfo = findUseWeather() else {
                                                    toolResult = currentLanguagePrefix
                                                    ? "当前无激活的天气服务，请先配置天气服务。"
                                                    : "No active weather service configured. Please set one up first."
                                                    useFunctionName = functionName
                                                    break
                                                }
                                                
                                                // 天气查询函数
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在查询天气" : "Querying Weather"))
                                                
                                                do {
                                                    // 解析 JSON 参数
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
                                                            userInfo: [NSLocalizedDescriptionKey: "参数解析失败"]
                                                        )
                                                    }
                                                    
                                                    let coordinate = CLLocationCoordinate2D(
                                                        latitude: latitude,
                                                        longitude: longitude
                                                    )
                                                    useFunctionName = functionName
                                                    
                                                    // 调用新版天气查询函数：支持 timeRange、apiKey、requestURL
                                                    let weatherDescription = try await queryWeatherDescription(
                                                        at: coordinate,
                                                        company: weatherInfo.company,
                                                        timeRange: timeRange,
                                                        apiKey: weatherInfo.apiKey,
                                                        requestURL: weatherInfo.requestURL
                                                    )
                                                    
                                                    toolResult = currentLanguagePrefix
                                                    ? "该位置的天气信息如下：\n\(weatherDescription)"
                                                    : "Weather information for the location:\n\(weatherDescription)"
                                                    
                                                } catch {
                                                    toolResult = currentLanguagePrefix
                                                    ? "天气查询失败：\(error.localizedDescription)"
                                                    : "Failed to fetch weather: \(error.localizedDescription)"
                                                    useFunctionName = functionName
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "get_current_location":
                                                // 获取当前位置函数
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "获取当前位置" : "Getting Location"))
                                                do {
                                                    let location = try await getCurrentLocation()
                                                    useFunctionName = functionName
                                                    toolResult = currentLanguagePrefix ?
                                                    "当前位置为 \(location.name)，坐标：纬度 \(location.latitude)，经度 \(location.longitude)" :
                                                    "Current location is \(location.name), coordinates: latitude \(location.latitude), longitude \(location.longitude)"
                                                    
                                                } catch {
                                                    toolResult = currentLanguagePrefix ?
                                                    "获取当前位置失败：\(error.localizedDescription)" :
                                                    "Failed to get current location: \(error.localizedDescription)"
                                                    useFunctionName = functionName
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "search_nearby_locations":
                                                // 搜索范围兴趣点函数
                                                
                                                guard let mapInfo = findUseMap() else {
                                                    toolResult = "当前无激活的地图服务，请先配置地图服务。"
                                                    useFunctionName = functionName
                                                    break
                                                }
                                                
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "搜索周边地点" : "Searching Nearby"))
                                                
                                                do {
                                                    guard let jsonData = functionArguments.data(using: .utf8),
                                                          let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                                          let coordinateDict = json["coordinate"] as? [String: Any],
                                                          let latitude = coordinateDict["latitude"] as? Double,
                                                          let longitude = coordinateDict["longitude"] as? Double,
                                                          let keyword = json["keyword"] as? String else {
                                                        throw NSError(domain: "ToolArgumentError", code: -1, userInfo: [NSLocalizedDescriptionKey: "参数解析失败"])
                                                    }
                                                    
                                                    useFunctionName = functionName
                                                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                                    let results = try await searchNearbyLocations(around: coordinate, with: keyword, company: mapInfo.company, apiKey: mapInfo.apiKey)
                                                    
                                                    if results.isEmpty {
                                                        toolResult = currentLanguagePrefix ?
                                                        "未搜索到 \(keyword) 相关地点" :
                                                        "No results found for \(keyword)"
                                                    } else {
                                                        if self.locationsInfo == nil {
                                                            self.locationsInfo = []
                                                        }
                                                        self.locationsInfo?.append(contentsOf: results)
                                                        
                                                        let formatted = results.enumerated().map { index, loc in
                                                            "(\(index + 1)) \(loc.name)：纬度 \(loc.latitude)，经度 \(loc.longitude)"
                                                        }.joined(separator: "\n")
                                                        
                                                        toolResult = currentLanguagePrefix ?
                                                        "成功找到以下与 \(keyword) 相关的周边地点：\n\(formatted)\n并已绘制在地图中。" :
                                                        "Found the following nearby places related to \(keyword):\n\(formatted)\nThey are marked on the map."
                                                    }
                                                } catch {
                                                    toolResult = currentLanguagePrefix ?
                                                    "周边搜索失败：\(error.localizedDescription)" :
                                                    "Nearby search failed: \(error.localizedDescription)"
                                                    useFunctionName = functionName
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "get_route":
                                                // 根据起点、终点及交通方式规划路线
                                                guard let mapInfo = findUseMap() else {
                                                    toolResult = "当前无激活的地图服务，请先配置地图服务。"
                                                    useFunctionName = functionName
                                                    break
                                                }
                                                
                                                // 通知用户正在规划路线
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在规划路线" : "Planning Route"))
                                                
                                                do {
                                                    // 解析 JSON 数据，提取起点、终点及交通方式
                                                    guard let jsonData = functionArguments.data(using: .utf8),
                                                          let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                                          let startDict = json["start"] as? [String: Any],
                                                          let startLatitude = startDict["latitude"] as? Double,
                                                          let startLongitude = startDict["longitude"] as? Double,
                                                          let endDict = json["end"] as? [String: Any],
                                                          let endLatitude = endDict["latitude"] as? Double,
                                                          let endLongitude = endDict["longitude"] as? Double,
                                                          let mode = json["mode"] as? String else {
                                                        throw NSError(domain: "ToolArgumentError", code: -1,
                                                                      userInfo: [NSLocalizedDescriptionKey: "参数解析失败"])
                                                    }
                                                    print("json", jsonData)
                                                    useFunctionName = functionName
                                                    
                                                    let startCoordinate = CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
                                                    let endCoordinate = CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
                                                    
                                                    // 调用统一接口获取路线信息，返回自定义 RouteInfo 对象
                                                    let routeInfo = try await getRoute(from: startCoordinate,
                                                                                       to: endCoordinate,
                                                                                       with: mode,
                                                                                       company: mapInfo.company,
                                                                                       apiKey: mapInfo.apiKey)
                                                    
                                                    // 格式化返回提示信息
                                                    let distanceMeters = routeInfo.distance
                                                    let expectedTravelTime = routeInfo.expectedTravelTime
                                                    let travelTimeMinutes = expectedTravelTime / 60.0
                                                    let formattedSteps = routeInfo.instructions.isEmpty ? "" : "\n途经: " + routeInfo.instructions.joined(separator: " -> ")
                                                    
                                                    toolResult = currentLanguagePrefix ?
                                                    "路线规划成功：总距离 \(Int(distanceMeters)) 米，预计花费时间 \(Int(travelTimeMinutes)) 分钟\(formattedSteps)" :
                                                    "Route planned successfully: Total distance \(Int(distanceMeters)) meters, estimated travel time \(Int(travelTimeMinutes)) minutes\(formattedSteps)"
                                                    
                                                    // 存储路线信息
                                                    if self.storeRouteInfo == nil {
                                                        self.storeRouteInfo = []
                                                    }
                                                    self.storeRouteInfo?.append(routeInfo)
                                                    
                                                    // 生成起点和终点对应的 Location 对象，并添加到 locationsInfo 中
                                                    let startLocation = Location(
                                                        id: UUID(),
                                                        identifier: "start-\(UUID().uuidString)",
                                                        name: currentLanguagePrefix ? "起点" : "Start",
                                                        latitude: startLatitude,
                                                        longitude: startLongitude,
                                                        style: "mark"
                                                    )
                                                    let endLocation = Location(
                                                        id: UUID(),
                                                        identifier: "end-\(UUID().uuidString)",
                                                        name: currentLanguagePrefix ? "终点" : "Destination",
                                                        latitude: endLatitude,
                                                        longitude: endLongitude,
                                                        style: "mark"
                                                    )
                                                    if self.locationsInfo == nil {
                                                        self.locationsInfo = []
                                                    }
                                                    self.locationsInfo?.append(contentsOf: [startLocation, endLocation])
                                                    
                                                } catch {
                                                    // 根据交通方式提供更详细的错误说明
                                                    var errorDesc = error.localizedDescription
                                                    if let jsonData = functionArguments.data(using: .utf8),
                                                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                                                       let mode = json["mode"] as? String {
                                                        switch mode.lowercased() {
                                                        case "walking":
                                                            errorDesc = currentLanguagePrefix ?
                                                            "步行路线规划失败，可能原因包括：距离过长、路径不通或步行道路不支持。" :
                                                            "Walking route planning failed. Possible reasons include: distance too long, path blocked, or walking paths not supported."
                                                        case "transit":
                                                            errorDesc = currentLanguagePrefix ?
                                                            "公共交通规划失败，可能原因包括：停运、换乘不可用、起点/终点公共交通服务不足或该地区不支持公共交通规划。" :
                                                            "Transit route planning failed. Possible reasons: service suspensions, unavailable transfers, insufficient public transport at origin/destination, or region not supported."
                                                        case "driving", "automobile":
                                                            errorDesc = currentLanguagePrefix ?
                                                            "驾车路线规划失败，请检查起点、终点是否在道路网络覆盖区域内。" :
                                                            "Driving route planning failed. Please check if the starting point and destination are within road network coverage."
                                                        default:
                                                            break
                                                        }
                                                    }
                                                    toolResult = currentLanguagePrefix ?
                                                    "规划路线出错：\(errorDesc)，建议更换交通方式或选择其他路线。" :
                                                    "Error in planning the route: \(errorDesc), suggesting a change of transportation or an alternative."
                                                    useFunctionName = functionName
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "search_calendar_and_reminders":
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "查询日程事项" : "Searching Calendar"))
                                                useFunctionName = functionName
                                                
                                                do {
                                                    // 从函数参数中分别提取各字段
                                                    let keyword = extractValue(from: functionArguments, forKey: "keyword")
                                                    let startDateString = extractValue(from: functionArguments, forKey: "start_date")
                                                    let endDateString = extractValue(from: functionArguments, forKey: "end_date")
                                                    let location = extractValue(from: functionArguments, forKey: "location")
                                                    let eventType = extractValue(from: functionArguments, forKey: "event_type")
                                                    
                                                    // 将日期字符串转换为 Date 对象，格式要求为 "yyyy-MM-dd"
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
                                                    
                                                    // 调用新的搜索函数，按照各条件查询日历与提醒事项
                                                    let items = await searchSystemEvents(keyword: keyword, startDate: startDate, endDate: endDate, location: location, eventType: eventType)
                                                    
                                                    if items.isEmpty {
                                                        toolResult = currentLanguagePrefix ?
                                                        "未查询到符合条件的日历事件或提醒事项。" :
                                                        "No calendar events or reminders found matching the criteria."
                                                    } else {
                                                        
                                                        // 格式化输出结果
                                                        let outputFormatter = DateFormatter()
                                                        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                                                        
                                                        let formatted = items.enumerated().map { index, item in
                                                            let timeString: String = {
                                                                if let start = item.startDate {
                                                                    return outputFormatter.string(from: start)
                                                                } else if let due = item.dueDate {
                                                                    return outputFormatter.string(from: due)
                                                                } else {
                                                                    return currentLanguagePrefix ? "无时间信息" : "No time info"
                                                                }
                                                            }()
                                                            
                                                            let notePart = item.notes?.isEmpty == false ? "（备注：\(item.notes!)）" : ""
                                                            let locPart = item.location?.isEmpty == false ? "（地点：\(item.location!)）" : ""
                                                            let typePart = item.type == "calendar" ? (currentLanguagePrefix ? "日历事件" : "Calendar") : (currentLanguagePrefix ? "提醒事项" : "Reminder")
                                                            
                                                            return "(\(index + 1)) [\(typePart)] \(item.title) - \(timeString)\(notePart)\(locPart)"
                                                        }.joined(separator: "\n")
                                                        
                                                        toolResult = currentLanguagePrefix ?
                                                        "查询成功，共找到 \(items.count) 个相关项目：\n\(formatted)" :
                                                        "Query successful. Found \(items.count) matching items:\n\(formatted)"
                                                    }
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "write_system_event":
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "写入系统事件" : "Writing System Event"))
                                                useFunctionName = functionName
                                                
                                                do {
                                                    // 从函数参数中分别提取各字段
                                                    let typeStr = extractValue(from: functionArguments, forKey: "type") ?? ""
                                                    let titleStr = extractValue(from: functionArguments, forKey: "title") ?? ""
                                                    let startDateStr = extractValue(from: functionArguments, forKey: "start_date") ?? ""
                                                    let endDateStr = extractValue(from: functionArguments, forKey: "end_date") ?? ""
                                                    let dueDateStr = extractValue(from: functionArguments, forKey: "due_date") ?? ""
                                                    let locationValue = extractValue(from: functionArguments, forKey: "location") ?? ""
                                                    let notesValue = extractValue(from: functionArguments, forKey: "notes") ?? ""
                                                    let priorityStr = extractValue(from: functionArguments, forKey: "priority")
                                                    let reminderMinutesStr = extractValue(from: functionArguments, forKey: "reminder_minutes")
                                                    
                                                    // 使用 ISO8601 格式转换日期字符串（格式示例：2025-04-16T12:34:56Z）
                                                    print("时间：", startDateStr, endDateStr, dueDateStr)
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
                                                    
                                                    // 将 priority 转换为 Int（若传入值非空）
                                                    var priorityValue: Int? = nil
                                                    if let pStr = priorityStr, let pInt = Int(pStr) {
                                                        priorityValue = pInt
                                                    }
                                                    
                                                    // 将 reminder_minutes 转换为 Int（若传入值非空）
                                                    var reminderMinutesValue: Int? = nil
                                                    if let rmStr = reminderMinutesStr, let rmInt = Int(rmStr) {
                                                        reminderMinutesValue = rmInt
                                                    }
                                                    
                                                    // 调用写入系统事件的函数
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
                                                        // 使用 DateFormatter 格式化时间输出
                                                        let outputFormatter = DateFormatter()
                                                        outputFormatter.dateFormat = "yyyy-MM-dd HH:mm"
                                                        let timeString: String = {
                                                            if typeStr.lowercased() == "calendar", let start = event.startDate {
                                                                return outputFormatter.string(from: start)
                                                            } else if typeStr.lowercased() == "reminder", let due = event.dueDate {
                                                                return outputFormatter.string(from: due)
                                                            } else {
                                                                return currentLanguagePrefix ? "无时间信息" : "No time info"
                                                            }
                                                        }()
                                                        
                                                        toolResult = currentLanguagePrefix ?
                                                        "写入成功：[ \(event.title) - \(timeString) ]" :
                                                        "Event written successfully: [ \(event.title) - \(timeString) ]"
                                                        
                                                        // 存入聊天框
                                                        if self.events == nil {
                                                            self.events = []
                                                        }
                                                        self.events?.append(event)
                                                        
                                                    } else {
                                                        toolResult = currentLanguagePrefix ?
                                                        "写入系统事件失败。" :
                                                        "Failed to write system event."
                                                    }
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "create_web_view":
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在创建网页" : "Creating Webpage"))
                                                
                                                useFunctionName = functionName
                                                
                                                let htmlString = try await createWebView(extractValue(from: functionArguments, forKey: "code") ?? "Unknown")
                                                
                                                if !htmlString.isEmpty, htmlString != "Unknown" {
                                                    self.htmlContent = htmlString
                                                    toolResult = currentLanguagePrefix ?
                                                    "成功渲染网页，现在用户可以看到网页内容及网页的源代码了。" :
                                                    "The webpage has been successfully rendered, and users can now see both the webpage content and its source code."
                                                    toolResultFront = currentLanguagePrefix ?
                                                    "成功向系统发送渲染网页请求" :
                                                    "The request to render the webpage has been successfully sent to the system."
                                                } else {
                                                    toolResult = currentLanguagePrefix ?
                                                    "网页渲染失败" :
                                                    "Web page rendering failed."
                                                    toolResultFront = toolResult
                                                }
                                                
                                            case "execute_python_code":
                                                // 调用 Python 执行工具
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "正在执行代码" : "Executing Code"))
                                                useFunctionName = functionName
                                                
                                                // 提取 code 参数
                                                let pythonCode = extractValue(from: functionArguments, forKey: "code") ?? ""
                                                
                                                do {
                                                    // 执行脚本并获取 CodeBlock（包含 output + error 状态）
                                                    let resultBlock = try await PistonExecutor.executePythonCode(code: pythonCode)
                                                    
                                                    // 设置输出内容（作为 toolResult 返回给大模型）
                                                    toolResult = resultBlock.output
                                                    
                                                    // 存入聊天框
                                                    if self.codeBlock == nil {
                                                        self.codeBlock = []
                                                    }
                                                    self.codeBlock?.append(resultBlock)
                                                    
                                                } catch {
                                                    // 出现严重异常（如网络失败、结构解析错误等）
                                                    toolResult = currentLanguagePrefix
                                                    ? "执行 Python 代码时发生错误：\(error.localizedDescription)"
                                                    : "An error occurred while executing the Python code: \(error.localizedDescription)"
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "create_canvas":
                                                // 1) 通知开始创建
                                                continuation.yield(StreamData(
                                                    operationalState: currentLanguagePrefix ? "正在创建画布" : "Creating Canvas"
                                                ))
                                                useFunctionName = functionName

                                                // 2) 提取参数
                                                let title   = extractValue(from: functionArguments, forKey: "title")   ?? ""
                                                let content = extractValue(from: functionArguments, forKey: "content") ?? ""
                                                let type    = extractValue(from: functionArguments, forKey: "type")    ?? "text"

                                                // 3) 调用 createCanvasData，仅构建未保存的 CanvasData
                                                let canvasData = CanvasServices.createCanvasData(
                                                    title: title,
                                                    content: content,
                                                    type: type
                                                )
                                                // 4) 将画布信息赋给 self.canvasInfo，由前端负责后续保存
                                                self.canvasInfo = canvasData

                                                // 5) 准备返回给大模型的结果
                                                if currentLanguagePrefix {
                                                    toolResult = "画布已创建：\(title)\n内容：\(content)。用户现在可以阅读画布的内容，后续回答中避免赘述画布内容重复，而是应该引导用户点击右下角的画布按钮前往画布以查看和编辑画布内容。"
                                                } else {
                                                    toolResult = "Canvas created: \(title)\nContent: \(content). Users can now read the content of the canvas. In subsequent responses, avoid repeating the canvas content and instead guide users to click the canvas button in the lower right corner to view and edit the canvas."
                                                }
                            
                                                toolResultFront = currentLanguagePrefix
                                                        ? "标题为 \(title) 的画布已创建"
                                                        : "The canvas titled \(title) has been created."
                                                
                                            case "edit_canvas":
                                                continuation.yield(StreamData(
                                                    operationalState: currentLanguagePrefix ? "正在修改画布" : "Editing canvas"
                                                ))
                                                useFunctionName = functionName

                                                // 2) 尝试解析 patterns 和 replacements 为 [String]
                                                let patterns = extractStringArray(from: functionArguments, forKey: "patterns")
                                                let replacements = extractStringArray(from: functionArguments, forKey: "replacements")

                                                // 3) 若数组长度不一致，构造错误反馈并返回（无需 guard）
                                                if patterns.count != replacements.count {
                                                    let msg = currentLanguagePrefix
                                                        ? "修改失败：patterns 与 replacements 数组长度不一致"
                                                        : "Edit failed: patterns and replacements arrays must be of the same length"
                                                    toolResult = msg
                                                    toolResultFront = msg
                                                    break
                                                }

                                                // 4) 构造规则数组
                                                let rules: [(String, String)] = zip(patterns, replacements).map { ($0, $1) }

                                                do {
                                                    // 5) 执行 Canvas 内容修改
                                                    let updatedCanvas = try CanvasServices.editCanvasContent(
                                                        canvas: canvasData,
                                                        rules: rules
                                                    )

                                                    self.canvasInfo = updatedCanvas // 6) 更新到临时状态，供前端决定保存

                                                    // 7) 构造规则摘要
                                                    let ruleSummary = rules.enumerated().map { (index, pair) in
                                                        currentLanguagePrefix
                                                            ? "规则 \(index + 1)：模式：\(pair.0) → 替换为：\(pair.1)"
                                                            : "Rule \(index + 1): pattern: \(pair.0) → replacement: \(pair.1)"
                                                    }.joined(separator: "\n")

                                                    // 8) 生成完整内容
                                                    toolResult = currentLanguagePrefix
                                                        ? """
                                                        画布已修改，应用以下规则：
                                                        \(ruleSummary)

                                                        修改后内容如下：
                                                        \(updatedCanvas.content)

                                                        用户现在可以阅读画布的内容，后续回答中避免赘述画布内容重复，而是应该引导用户点击右下角的画布按钮前往画布以查看和编辑画布内容。
                                                        """
                                                        : """
                                                        Canvas has been updated using the following rules:
                                                        \(ruleSummary)

                                                        Updated content:
                                                        \(updatedCanvas.content)

                                                        Users can now read the content of the canvas. In subsequent responses, avoid repeating the canvas content and instead guide users to click the canvas button in the lower right corner to view and edit the canvas.
                                                        """

                                                    toolResultFront = currentLanguagePrefix
                                                        ? "画布内容已更新\n\(ruleSummary)"
                                                        : "Canvas content updated\n\(ruleSummary)"

                                                } catch {
                                                    let errorMsg = currentLanguagePrefix
                                                        ? "修改画布内容时发生错误：\(error.localizedDescription)"
                                                        : "An error occurred while editing the canvas: \(error.localizedDescription)"
                                                    toolResult = errorMsg
                                                    toolResultFront = errorMsg
                                                }
                                                
                                            case "fetch_step_details":
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "查询距离步数" : "Fetching Steps"))
                                                useFunctionName = functionName
                                                
                                                do {
                                                    // 从函数参数中提取日期字符串
                                                    let startDateString = extractValue(from: functionArguments, forKey: "start_date")
                                                    let endDateString = extractValue(from: functionArguments, forKey: "end_date")
                                                    
                                                    // 日期格式转换
                                                    let dateFormatter = DateFormatter()
                                                    dateFormatter.dateFormat = "yyyy-MM-dd"
                                                    dateFormatter.timeZone = TimeZone.current
                                                    
                                                    guard
                                                        let startStr = startDateString,
                                                        let endStr = endDateString,
                                                        let startDate = dateFormatter.date(from: startStr),
                                                        let endDate = dateFormatter.date(from: endStr)
                                                    else {
                                                        toolResult = currentLanguagePrefix ?
                                                        "日期格式无效，请传入格式为 yyyy-MM-dd 的有效日期。" :
                                                        "Invalid date format. Please provide dates in yyyy-MM-dd format."
                                                        break
                                                    }
                                                    
                                                    // 调用步数详情查询函数
                                                    let detail = await HealthTool.shared.fetchStepDetails(from: startDate, to: endDate)
                                                    toolResult = detail
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "fetch_energy_details":
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "查询能量详情" : "Fetching Energy"))
                                                useFunctionName = functionName
                                                
                                                do {
                                                    // 提取日期字符串
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
                                                        toolResult = currentLanguagePrefix ?
                                                        "日期格式无效，请传入格式为 yyyy-MM-dd 的有效日期。" :
                                                        "Invalid date format. Please provide dates in yyyy-MM-dd format."
                                                        break
                                                    }
                                                    
                                                    // 调用能量消耗详情查询函数
                                                    let detail = await HealthTool.shared.fetchEnergyDetails(from: startDate, to: endDate)
                                                    toolResult = detail
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "fetch_nutrition_details":
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "查询营养摄入" : "Fetching Nutrition"))
                                                useFunctionName = functionName
                                                
                                                do {
                                                    // 提取日期字符串
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
                                                        toolResult = currentLanguagePrefix ?
                                                        "日期格式无效，请传入格式为 yyyy-MM-dd 的有效日期。" :
                                                        "Invalid date format. Please provide dates in yyyy-MM-dd format."
                                                        break
                                                    }
                                                    
                                                    // 调用营养摄入详情查询函数
                                                    let detail = await HealthTool.shared.fetchNutritionDetails(from: startDate, to: endDate)
                                                    toolResult = detail
                                                }
                                                
                                                toolResultFront = toolResult
                                                
                                            case "make_nutrition_data":
                                                continuation.yield(StreamData(
                                                    operationalState: currentLanguagePrefix ? "生成营养卡片" : "Generating Nutrition Card"))
                                                useFunctionName = functionName
                                                
                                                guard
                                                    let raw = functionArguments.data(using: .utf8),
                                                    let dict = try? JSONSerialization.jsonObject(with: raw) as? [String: Any]
                                                else {
                                                    toolResult = currentLanguagePrefix
                                                    ? "无法解析 nutrition 参数（应为 JSON 字符串）。"
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
                                                    date:          Date()                     // 如需自定义时间可再解析
                                                )
                                                
                                                // 缓存供 UI 用
                                                self.healthCard = (self.healthCard ?? []) + [card]
                                                
                                                var lines: [String] = []
                                                if let p = card.proteinGrams        { lines.append("蛋白质：\(String(format: "%.1f", p)) g") }
                                                if let c = card.carbohydratesGrams  { lines.append("碳水化合物：\(String(format: "%.1f", c)) g") }
                                                if let f = card.fatGrams            { lines.append("总脂肪：\(String(format: "%.1f", f)) g") }
                                                if let e = card.energyKilocalories  { lines.append("膳食能量：\(String(format: "%.1f", e)) kcal") }
                                                
                                                let header = currentLanguagePrefix ? "营养卡片已成功生成" : "Nutrition card generated successfully."
                                                toolResult = "\(header)\n" + lines.joined(separator: "\n")
                                                
                                                toolResultFront = toolResult
                                                
                                            default:
                                                toolResult = "Unknown"
                                                useFunctionName = functionName
                                                continuation.yield(StreamData(operationalState: currentLanguagePrefix ?  "工具不存在" : "Tool does not exist"))
                                                toolResultFront = currentLanguagePrefix ?  "工具不存在" : "Tool does not exist"
                                            }
                                            print("💡 输出结果：", toolResult)
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
                                            "content": currentLanguagePrefix ?
                                                "已调用工具「\(useFunctionName)」，但未获得任何有效结果。请基于该结果继续前文内容，你需要保持语义和段落的连贯性，不要重复之前已经说过的内容，并合理处理结果缺失的情况。" :
                                                "You have called the tool \"\(useFunctionName)\". However, no valid results were obtained. Please continue with the previous content based on this result, ensuring that you maintain semantic and paragraph coherence, avoid repeating what has already been said, and appropriately address the situation of missing results."
                                        ])
                                    } else if toolResult == "Unknown" {
                                        newFormattedMessages.append([
                                            "role": toolRole,
                                            "content": currentLanguagePrefix ?
                                                "注意：工具「\(useFunctionName)」不存在，请不要使用该工具，也不要尝试再次调用它。" :
                                                "Note: The tool \"\(useFunctionName)\" does not exist. Please do not use or attempt to call this tool again."
                                        ])
                                    } else {
                                        newFormattedMessages.append([
                                            "role": toolRole,
                                            "content": currentLanguagePrefix ?
                                                "已使用工具「\(useFunctionName)」，并获得了如下结果：\n\(toolResult)\n\n请基于该结果继续前文内容，你需要保持语义和段落的连贯性，不要重复之前已经说过的内容。" :
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
                                    
                                    // 递归处理
                                    let recursiveStream = try await self.processRemoteModel(messages: messages,
                                                                                            formattedMessages: newFormattedMessages,
                                                                                            modelInfo: modelInfo,
                                                                                            groupID: groupID,
                                                                                            currentLanguage: currentLanguage,
                                                                                            ifSearch: ifSearch,
                                                                                            ifKnowledge: ifKnowledge,
                                                                                            ifToolUse: ifToolUse,
                                                                                            ifThink: ifThink,
                                                                                            ifAudio: ifAudio,
                                                                                            ifPlanning: ifPlanning,
                                                                                            thinkingLength: thinkingLength,
                                                                                            planningMessage: planningMessage,
                                                                                            isObservation: isObservation,
                                                                                            temperature: temperature,
                                                                                            topP: topP,
                                                                                            maxTokens: maxTokens,
                                                                                            canvasData: canvasData,
                                                                                            selectedURLs: selectedURLs,
                                                                                            selectedPromptsContent: selectedPromptsContent,
                                                                                            systemMessage: systemMessage,
                                                                                            depth: depth + 1)
                                    for try await recursiveData in recursiveStream {
                                        continuation.yield(recursiveData)
                                    }
                                    
                                    // 结束递归
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
                                                    print("无法读取 WAV 时长：\(error)")
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
                                            // 递归处理
                                            let recursiveStream = try await self.processRemoteModel(messages: messages,
                                                                                                    formattedMessages: tempFormattedMessages,
                                                                                                    modelInfo: modelInfo,
                                                                                                    groupID: groupID,
                                                                                                    currentLanguage: currentLanguage,
                                                                                                    ifSearch: ifSearch,
                                                                                                    ifKnowledge: ifKnowledge,
                                                                                                    ifToolUse: ifToolUse,
                                                                                                    ifThink: ifThink,
                                                                                                    ifAudio: ifAudio,
                                                                                                    ifPlanning: ifPlanning,
                                                                                                    thinkingLength: thinkingLength,
                                                                                                    planningMessage: planning,
                                                                                                    isObservation: isObservation,
                                                                                                    temperature: temperature,
                                                                                                    topP: topP,
                                                                                                    maxTokens: maxTokens,
                                                                                                    canvasData: canvasData,
                                                                                                    selectedURLs: selectedURLs,
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
                    // 流完成
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
    
    /// 将用户最后提问进行优化后，返回优化后的提示词
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
            print("发生错误: \(error.localizedDescription)")
            return nil
        }
    }
    
    // 生成图像的函数
    private func processImageGenModel(messages: [RequestMessage],
                                      modelInfo: AllModels,
                                      currentLanguage: String,
                                      selectedImageSize: String,
                                      imageReversePrompt: String
    ) async throws -> AsyncThrowingStream<StreamData, Error> {
        return AsyncThrowingStream<StreamData, Error> { continuation in
            Task {
                do {
                    let currentLanguagePrefix = currentLanguage.hasPrefix("zh")
                    
                    continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "请求图像生成" : "Request for image generation"))
                    
                    guard let company = modelInfo.company?.uppercased() else {
                        throw NSError(domain: "CompanyError", code: -1, userInfo: [NSLocalizedDescriptionKey: "未指定模型厂商"])
                    }
                    guard let apiKey = getAPIKey(for: company) else {
                        throw NSError(domain: "APIKeyConfigError", code: -1, userInfo: [NSLocalizedDescriptionKey: "未找到 API Key"])
                    }
                    
                    guard var requestURLString = getRequestURL(for: modelInfo.company ?? "Unknown"),
                          !requestURLString.isEmpty else {
                        throw NSError(domain: "URLConfigError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的请求 URL"])
                    }
                    
                    // 判断并替换 URL 中的部分字符串
                    if requestURLString.contains("chat/completions") {
                        requestURLString = requestURLString.replacingOccurrences(of: "chat/completions", with: "images/generations")
                    }
                    
                    guard let requestURL = URL(string: requestURLString) else {
                        throw NSError(domain: "URLConfigError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的请求 URL"])
                    }
                    
                    //优化提示词
                    continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "自动优化提示" : "Automatic optimization prompt"))
                    var updatedMessages = messages
                    let optimizedPrompt = await ImagePromptTask(updatedMessages: &updatedMessages) ?? updatedMessages.last?.text ?? updatedMessages.last?.imageText ?? ""
                    print("生成提示词：", optimizedPrompt)
                    
                    var url: URL
                    var request: URLRequest
                    var requestBody: [String: Any] = [:]
                    
                    let baseName = restoreBaseModelName(from: modelInfo.name ?? "Unknown")
                    
                    switch company {
                    case "QWEN":
                        url = URL(string: "https://dashscope.aliyuncs.com/api/v1/services/aigc/text2image/image-synthesis")!
                        request = URLRequest(url: url)
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                        request.setValue("enable", forHTTPHeaderField: "X-DashScope-Async")
                        
                        var parameters: [String: Any] = [
                            "n": 1
                        ]
                        switch selectedImageSize {
                        case "landscape":
                            parameters["size"] = "1792*1024"
                        case "portrait":
                            parameters["size"] = "1024*1792"
                        default:
                            parameters["size"] = "1024*1024"
                        }
                        if !imageReversePrompt.isEmpty {
                            parameters["negative_prompt"] = imageReversePrompt
                        }
                        
                        requestBody = [
                            "model": baseName,
                            "input": ["prompt": optimizedPrompt],
                            "parameters": parameters
                        ]
                        
                    case "ZHIPUAI", "HANLIN":
                        url = URL(string: "https://open.bigmodel.cn/api/paas/v4/images/generations")!
                        request = URLRequest(url: url)
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
                            requestBody["prompt"] = currentLanguagePrefix ?
                            "\(optimizedPrompt)；不要出现\(imageReversePrompt)" :
                            "\(optimizedPrompt); do not appear\(imageReversePrompt)"
                        } else {
                            requestBody["prompt"] = optimizedPrompt
                        }
                        
                    case "SILICONCLOUD", "HANLIN_OPEN":
                        url = URL(string: "https://api.siliconflow.cn/v1/images/generations")!
                        request = URLRequest(url: url)
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
                        url = URL(string: "https://api.openai.com/v1/images/generations")!
                        request = URLRequest(url: url)
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
                        
                    case "XAI":
                        url = URL(string: "https://api.x.ai/v1/images/generations")!
                        request = URLRequest(url: url)
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                        requestBody = [
                            "model": baseName,
                            "prompt": optimizedPrompt,
                            "n": 1
                        ]
                        
                    case "MODELSCOPE":
                        url = requestURL
                        request = URLRequest(url: url)
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
                        url = requestURL
                        request = URLRequest(url: url)
                        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                        requestBody = [
                            "model": baseName,
                            "prompt": optimizedPrompt
                        ]
                    }
                    
                    request.httpMethod = "POST"
                    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                    
                    continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "图像正在生成" : "Generating"))
                    
                    // 发请求
                    let (data, response) = try await URLSession.shared.data(for: request)
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NSError(domain: "ImageGen", code: -1, userInfo: [NSLocalizedDescriptionKey: "响应格式错误"])
                    }
                    guard httpResponse.statusCode == 200 else {
                        throw NSError(domain: "ImageGen", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "图像生成请求失败"])
                    }
                    
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    // 提取图片 URL
                    var imageURLString: String?
                    
                    switch company {
                    case "QWEN":
                        // 异步返回，需要轮询 task_id（可以保留原先的轮询代码逻辑）
                        let output = json?["output"] as? [String: Any]
                        guard let taskId = output?["task_id"] as? String else {
                            throw NSError(domain: "ImageGen", code: -1, userInfo: [NSLocalizedDescriptionKey: "未获取到任务 ID"])
                        }
                        
                        continuation.yield(StreamData(operationalState: currentLanguagePrefix ? "排队生成图像" : "Waiting in line"))
                        
                        let queryURL = URL(string: "https://dashscope.aliyuncs.com/api/v1/tasks/\(taskId)")!
                        var attempts = 50
                        while attempts > 0 {
                            try await Task.sleep(nanoseconds: 2_000_000_000)
                            var pollRequest = URLRequest(url: queryURL)
                            pollRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                            let (resultData, _) = try await URLSession.shared.data(for: pollRequest)
                            let resultJson = try JSONSerialization.jsonObject(with: resultData) as? [String: Any]
                            let status = resultJson?["output"] as? [String: Any]
                            let taskStatus = status?["task_status"] as? String ?? "UNKNOWN"
                            
                            if taskStatus == "SUCCEEDED" {
                                if let results = status?["results"] as? [[String: Any]],
                                   let urlStr = results.first?["url"] as? String {
                                    imageURLString = urlStr
                                    break
                                }
                            } else if taskStatus == "FAILED" {
                                throw NSError(domain: "ImageGen", code: -1, userInfo: [NSLocalizedDescriptionKey: "任务失败"])
                            }
                            
                            attempts -= 1
                        }
                        
                    case "SILICONCLOUD", "HANLIN_OPEN", "MODELSCOPE":
                        if let images = json?["images"] as? [[String: Any]],
                           let urlStr = images.first?["url"] as? String {
                            imageURLString = urlStr
                        }
                        
                    default:
                        if let dataArr = json?["data"] as? [[String: Any]],
                           let urlStr = dataArr.first?["url"] as? String {
                            imageURLString = urlStr
                        }
                    }
                    
                    // 下载图片并返回
                    if let imageURLString, let imageURL = URL(string: imageURLString) {
                        let (imageData, _) = try await URLSession.shared.data(from: imageURL)
                        if let image = UIImage(data: imageData) {
                            var final = StreamData()
                            final.image_content = [image]
                            final.image_text = optimizedPrompt
                            continuation.yield(final)
                            continuation.finish()
                            return
                        } else {
                            throw NSError(domain: "ImageGen", code: -1, userInfo: [NSLocalizedDescriptionKey: "图片数据解码失败"])
                        }
                    } else {
                        throw NSError(domain: "ImageGen", code: -1, userInfo: [NSLocalizedDescriptionKey: "未获取到图像 URL"])
                    }
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - 主流式请求入口
    func sendStreamRequest(messages: [RequestMessage],
                           modelName: String,
                           groupID: UUID,
                           ifSearch: Bool,
                           ifKnowledge: Bool,
                           ifToolUse: Bool,
                           ifThink: Bool,
                           ifAudio: Bool,
                           ifPlanning: Bool,
                           thinkingLength: Int,
                           isObservation: Bool,
                           temperature: Double,
                           topP: Double,
                           maxTokens: Int,
                           canvasData: CanvasData,
                           selectedURLs: [String]?,
                           selectedPromptsContent: [String]?,
                           systemMessage: String,
                           selectedImageSize: String,
                           imageReversePrompt: String
    ) async throws -> AsyncThrowingStream<StreamData, Error> {
        // 取消当前任务
        currentTask?.cancel()
        currentTask = nil
        isCancelled = false
        
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        
        // 从数据库查询模型信息
        guard let modelInfo = try? context.fetch(
            FetchDescriptor<AllModels>(predicate: #Predicate { $0.name == modelName })
        ).first else {
            throw NSError(domain: "DatabaseError", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取模型信息"])
        }
        
        let company = modelInfo.company?.uppercased()
        if company == "LOCAL" {
            return try await processLocalModel(messages: messages,
                                               modelInfo: modelInfo,
                                               currentLanguage: currentLanguage,
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
                                                    currentLanguage: currentLanguage,
                                                    ifSearch: ifSearch,
                                                    ifKnowledge: ifKnowledge,
                                                    ifToolUse: ifToolUse,
                                                    ifThink: ifThink,
                                                    ifAudio: ifAudio,
                                                    ifPlanning: ifPlanning,
                                                    thinkingLength: thinkingLength,
                                                    planningMessage: "",
                                                    isObservation: isObservation,
                                                    temperature: temperature,
                                                    topP: topP,
                                                    maxTokens: maxTokens,
                                                    canvasData: canvasData,
                                                    selectedURLs: selectedURLs,
                                                    selectedPromptsContent: selectedPromptsContent,
                                                    systemMessage: systemMessage
                )
            } else {
                return try await processImageGenModel(messages: messages,
                                                      modelInfo: modelInfo,
                                                      currentLanguage: currentLanguage,
                                                      selectedImageSize: selectedImageSize,
                                                      imageReversePrompt: imageReversePrompt
                )
            }
        }
    }
}

extension MKPolyline {
    var coordinates: [Coordinate] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: self.pointCount)
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        return coords.map { Coordinate(latitude: $0.latitude, longitude: $0.longitude) }
    }
}

extension FixedWidthInteger {
    /// 将整数转成小端 Data
    var dataLE: Data {
        withUnsafeBytes(of: littleEndian) { Data($0) }
    }
}

/// 将纯 PCM 16-bit LE 数据封装成 WAV 文件二进制
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
    wav.append(chunkSize.dataLE)                   // ChunkSize
    wav.append("WAVE".data(using: .ascii)!)        // Format
    wav.append("fmt ".data(using: .ascii)!)        // Subchunk1ID
    wav.append(UInt32(16).dataLE)                  // Subchunk1Size (PCM header size)
    wav.append(UInt16(1).dataLE)                   // AudioFormat = 1 (PCM)
    wav.append(UInt16(channels).dataLE)            // NumChannels
    wav.append(UInt32(sampleRate).dataLE)          // SampleRate
    wav.append(UInt32(byteRate).dataLE)            // ByteRate
    wav.append(UInt16(blockAlign).dataLE)          // BlockAlign
    wav.append(UInt16(bitsPerSample).dataLE)       // BitsPerSample
    wav.append("data".data(using: .ascii)!)        // Subchunk2ID
    wav.append(subchunk2Size.dataLE)               // Subchunk2Size
    wav.append(pcmData)                            // PCM bytes
    return wav
}
