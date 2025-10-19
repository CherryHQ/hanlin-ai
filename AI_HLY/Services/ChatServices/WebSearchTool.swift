//
//  WebSearchTool.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 14/2/25.
//

import Foundation

/// 定义搜索引擎类型，便于后续扩展
enum SearchEngine: String {
    case ZHIPUAI
    case BOCHAAI
    case EXA
    case TAVILY
    case LANGSEARCH
    case BRAVE
    case PERPLEXITY
}

/// 搜索结果解析结构体
struct ParsedSearchResult {
    let titles: [String]
    let links: [String]
    let contents: [String]
    let icons: [String]
    let totalTokens: Int
}

/// 主搜索函数，根据 engine 参数决定调用哪个搜索引擎
func searchTool(query: String, engine: SearchEngine, apiKey: String?, requestURL: String, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    print("提问问题：\(query)")
    switch engine {
    case .ZHIPUAI:
        return try await searchZhipu(query: query, apiKey: apiKey, requestURL: requestURL, searchCount: searchCount)
    case .BOCHAAI:
        return try await searchBochaAI(query: query, apiKey: apiKey, requestURL: requestURL, searchCount: searchCount)
    case .LANGSEARCH:
        return try await searchLangSearch(query: query, apiKey: apiKey, requestURL: requestURL, searchCount: searchCount)
    case .EXA:
        return try await searchExa(query: query, apiKey: apiKey, requestURL: requestURL, searchCount: searchCount)
    case .TAVILY:
        return try await searchTavily(query: query, apiKey: apiKey, requestURL: requestURL, searchCount: searchCount)
    case .BRAVE:
        return try await searchBrave(query: query, apiKey: apiKey, requestURL: requestURL, searchCount: searchCount)
    case .PERPLEXITY:
        return try await searchPerplexity(query: query, apiKey: apiKey, requestURL: requestURL, searchCount: searchCount)
    }
}

// MARK: 智谱新版 Web Search 接口实现
func searchZhipu(
    query: String,
    apiKey: String?,
    requestURL: String,
    searchCount: Int,
) async throws -> (ParsedSearchResult, String) {
    guard let apiKey = apiKey, let url = URL(string: requestURL) else {
        throw URLError(.badURL)
    }

    // 构造请求体
    let requestBody: [String: Any] = [
        "search_engine": "search-std",
        "search_query": query
    ]

    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

    // 构造请求
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.timeoutInterval = 60

    // 发起请求
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }

    // JSON 解析：提取 search_result 数组
    guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let resultList = jsonObject["search_result"] as? [[String: Any]] else {
        return (
            ParsedSearchResult(
                titles: [],
                links: [],
                contents: [],
                icons: [],
                totalTokens: 0
            ),
            "ZHIPUAI"
        )
    }

    // 提取字段
    let titles = resultList.compactMap { $0["title"] as? String }
    let links = resultList.compactMap { $0["link"] as? String }
    let contents = resultList.compactMap { $0["content"] as? String }
    let icons = resultList.compactMap { $0["icon"] as? String }

    return (
        ParsedSearchResult(
            titles: titles,
            links: links,
            contents: contents,
            icons: icons,
            totalTokens: 0 // 新接口没有 token 字段
        ),
        "ZHIPUAI"
    )
}

// MARK: 博查 AI 搜索实现
func searchBochaAI(query: String, apiKey: String?, requestURL: String, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    guard let apiKey = apiKey, let url = URL(string: requestURL) else {
        throw URLError(.badURL)
    }
    
    // 构造请求体，根据示例传入参数
    let requestBody: [String: Any] = [
        "query": query,
        "freshness": "noLimit",
        "summary": true,
        "count": searchCount
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue(apiKey, forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 300
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "请求失败，状态码不在 200~299 范围内"])
    }
    
    // 定义博查 AI 搜索响应对应的数据结构
    struct BochaSearchResponse: Decodable {
        let code: Int
        let log_id: String?
        let msg: String?
        let data: DataClass
    }
    
    struct DataClass: Decodable {
        let _type: String
        let queryContext: QueryContext
        let webPages: WebPages
        // images 与 videos 此处不处理
    }
    
    struct QueryContext: Decodable {
        let originalQuery: String
    }
    
    struct WebPages: Decodable {
        let webSearchUrl: String
        let totalEstimatedMatches: Int
        let value: [BochaSearchResultItem]
    }
    
    struct BochaSearchResultItem: Decodable {
        let id: String?
        let name: String?
        let url: String?
        let displayUrl: String?
        let snippet: String?
        let summary: String?
        let siteName: String?
        let siteIcon: String?
        let dateLastCrawled: String?
        // 其它字段可根据需要扩展
    }
    
    // 解析响应数据
    let decoder = JSONDecoder()
    let bochaResponse = try decoder.decode(BochaSearchResponse.self, from: data)
    
    let results = bochaResponse.data.webPages.value
    
    // 提取各字段，过滤掉可能为 nil 的项
    let titles = results.compactMap { $0.name }
    let links = results.compactMap { $0.url }
    let contents = results.compactMap { $0.summary ?? $0.snippet }
    let icons = results.compactMap { $0.siteIcon }
    
    let totalTokens = bochaResponse.data.webPages.totalEstimatedMatches
    
    return (
        ParsedSearchResult(
            titles: titles,
            links: links,
            contents: contents,
            icons: icons,
            totalTokens: totalTokens
        ),
        "BOCHAAI"
    )
}

// MARK: LangSearch 搜索实现
func searchLangSearch(query: String, apiKey: String?, requestURL: String, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    guard let apiKey = apiKey, let url = URL(string: requestURL) else {
        throw URLError(.badURL)
    }
    
    // 构造请求体，根据示例传入参数
    let requestBody: [String: Any] = [
        "query": query,
        "freshness": "noLimit",
        "summary": true,
        "count": searchCount
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue(apiKey, forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 300

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "请求失败，状态码不在 200~299 范围内"])
    }

    // 定义 LangSearch 搜索响应对应的数据结构
    struct LangSearchResponse: Decodable {
        let code: Int
        let log_id: String?
        let msg: String?
        let data: DataClass
    }

    struct DataClass: Decodable {
        let _type: String
        let queryContext: QueryContext
        let webPages: WebPages
    }

    struct QueryContext: Decodable {
        let originalQuery: String?
    }

    struct WebPages: Decodable {
        let webSearchUrl: String?
        let totalEstimatedMatches: Int?
        let value: [LangSearchResultItem]?
    }

    struct LangSearchResultItem: Decodable {
        let id: String?
        let name: String?
        let url: String?
        let displayUrl: String?
        let snippet: String?
        let summary: String?
        let datePublished: String?
        let dateLastCrawled: String?
    }

    // 解析响应数据
    let decoder = JSONDecoder()
    let langsearchResponse = try decoder.decode(LangSearchResponse.self, from: data)

    // **修正：确保 `results` 非空**
    let results = langsearchResponse.data.webPages.value ?? []

    let defaultIconURL = "https://docs.langsearch.com/~gitbook/image?url=https%3A%2F%2F4120013342-files.gitbook.io%2F%7E%2Ffiles%2Fv0%2Fb%2Fgitbook-x-prod.appspot.com%2Fo%2Forganizations%252F-LAqhuumP8kkFDhg7_m7%252Fsites%252Fsite_IqUlj%252Ficon%252FZKCCPNgpjPEWT9w1Xor1%252Flangsearch-icon-512w.png%3Falt%3Dmedia%26token%3D60abf7e1-c302-4dad-b0ca-91f77f8867a2&width=32&dpr=2&quality=100&sign=f28451c1&sv=2"

    // **修正：使用 `compactMap` 并提供默认值**
    let titles = results.compactMap { $0.name }
    let links = results.compactMap { $0.url }
    let contents = results.compactMap { $0.summary ?? $0.snippet }
    let icons = Array(repeating: defaultIconURL, count: titles.count)

    // **修正：解包 `totalEstimatedMatches`，防止 `nil`**
    let totalTokens = langsearchResponse.data.webPages.totalEstimatedMatches ?? 0

    return (
        ParsedSearchResult(
            titles: titles,
            links: links,
            contents: contents,
            icons: icons,
            totalTokens: totalTokens
        ),
        "LANGSEARCH"
    )
}

// MARK: Exa AI 搜索实现
func searchExa(query: String, apiKey: String?, requestURL: String?, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    guard let apiKey = apiKey, let url = URL(string: requestURL ?? "") else {
        throw URLError(.badURL)
    }
    
    // 构造请求体
    let requestBody: [String: Any] = [
        "query": query,
        "text": true,
        "summary": true,
        "numResults": searchCount
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 300
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Exa 搜索请求失败，状态码: \((response as? HTTPURLResponse)?.statusCode ?? -1)"])
    }
    
    // 定义 Exa 搜索响应结构
    struct ExaSearchResponse: Decodable {
        let requestId: String?
        let autopromptString: String?
        let autoDate: String?
        let resolvedSearchType: String?
        let results: [ExaSearchResultItem]
    }
    
    struct ExaSearchResultItem: Decodable {
        let title: String?
        let url: String?
        let publishedDate: String?
        let author: String?
        let text: String?
        let summary: String?
        let image: String?
        let favicon: String?
    }
    
    // 解析数据
    let decoder = JSONDecoder()
    let exaResponse = try decoder.decode(ExaSearchResponse.self, from: data)
    
    let results = exaResponse.results
    
    // 提取搜索结果字段，过滤掉 nil 值
    let titles = results.compactMap { $0.title }
    let links = results.compactMap { $0.url }
    let contents = results.compactMap { $0.summary ?? $0.text }
    let icons = results.compactMap { $0.favicon ?? "https://cal.com/api/avatar/980c9ad3-ee0e-461f-87fa-7b6f5ccf00e1.png" }
    
    return (
        ParsedSearchResult(
            titles: titles,
            links: links,
            contents: contents,
            icons: icons,
            totalTokens: results.count
        ),
        "EXA"
    )
}

// MARK: Tavily 搜索实现
func searchTavily(query: String, apiKey: String?, requestURL: String, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    // 检查 apiKey 与 URL 合法性
    guard let apiKey = apiKey, let url = URL(string: requestURL) else {
        throw URLError(.badURL)
    }
    
    // 构造请求体，参数参考 curl 示例
    let requestBody: [String: Any] = [
        "query": query,
        "max_results": searchCount,
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    // 创建并配置 URLRequest
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    // 按照示例需要在 Authorization 中添加 "Bearer" 前缀
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 300
    
    // 发起请求
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "请求失败，状态码不在 200~299 范围内"])
    }
    
    // 定义 Tavily 搜索响应对应的数据结构
    struct TavilySearchResponse: Decodable {
        let query: String?
        let follow_up_questions: String?
        let answer: String?
        let images: [String]?
        let results: [TavilySearchResultItem]?
        let response_time: Double?
    }
    
    struct TavilySearchResultItem: Decodable {
        let title: String?
        let url: String?
        let content: String?
        let score: Double?
        let raw_content: String?
    }
    
    let decoder = JSONDecoder()
    
    // 尝试解析 API 返回的数据
    let tavilyResponse = try decoder.decode(TavilySearchResponse.self, from: data)
    
    // 确保 `results` 存在并且非空
    let searchResults = tavilyResponse.results ?? []
    
    // 统一使用 Tavily 提供的默认图标
    let defaultIconURL = "https://yyz2.discourse-cdn.com/flex004/user_avatar/community.tavily.com/system/288/107_2.png"
    
    // 将响应数据转换为 ParsedSearchResult
    let titles = searchResults.compactMap { $0.title }
    let links = searchResults.compactMap { $0.url }
    let contents = searchResults.compactMap { $0.content }
    let icons = Array(repeating: defaultIconURL, count: titles.count) // 统一使用 Tavily 的默认图标
    let totalTokens = searchResults.count
    
    let parsedResult = ParsedSearchResult(
        titles: titles,
        links: links,
        contents: contents,
        icons: icons,
        totalTokens: totalTokens
    )
    
    // 返回解析结果及搜索引擎标识
    return (parsedResult, "TAVILY")
}

// MARK: Perplexity 搜索实现
func searchPerplexity(query: String, apiKey: String?, requestURL: String, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    guard let apiKey = apiKey, let url = URL(string: requestURL) else {
        throw URLError(.badURL)
    }

    let resultCount = max(1, searchCount)

    let requestBody: [String: Any] = [
        "query": query,
        "max_results": resultCount,
        "max_tokens_per_page": 1024
    ]

    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.timeoutInterval = 300

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Perplexity 搜索请求失败，状态码: \((response as? HTTPURLResponse)?.statusCode ?? -1)"])
    }

    struct PerplexitySearchResponse: Decodable {
        let results: [PerplexitySearchResultItem]?
        let id: String?
    }

    struct PerplexitySearchResultItem: Decodable {
        let title: String?
        let url: String?
        let snippet: String?
        let date: String?
        let lastUpdated: String?

        enum CodingKeys: String, CodingKey {
            case title
            case url
            case snippet
            case date
            case lastUpdated = "last_updated"
        }
    }

    let decoder = JSONDecoder()
    let perplexityResponse = try decoder.decode(PerplexitySearchResponse.self, from: data)
    let results = perplexityResponse.results ?? []

    let titles = results.compactMap { $0.title }
    let links = results.compactMap { $0.url }
    let contents = results.compactMap { $0.snippet }
    let icons = Array(repeating: "https://www.perplexity.ai/favicon.ico", count: titles.count)

    let parsedResult = ParsedSearchResult(
        titles: titles,
        links: links,
        contents: contents,
        icons: icons,
        totalTokens: results.count
    )

    return (parsedResult, "PERPLEXITY")
}

// MARK: Brave 搜索实现
func searchBrave(query: String, apiKey: String?, requestURL: String, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    guard let apiKey = apiKey, let url = URL(string: requestURL), var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
        throw URLError(.badURL)
    }

    // 限制返回数量为 10
    components.queryItems = [
        URLQueryItem(name: "q", value: query),
        URLQueryItem(name: "count", value: "\(searchCount)")
    ]

    guard let finalURL = components.url else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: finalURL)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
    request.setValue(apiKey, forHTTPHeaderField: "X-Subscription-Token")
    request.timeoutInterval = 300

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSLocalizedDescriptionKey: "请求失败，状态码不在 200~299 范围内"])
    }

    // 定义 Brave 搜索响应结构（移除 videos）
    struct BraveSearchResponse: Decodable {
        let web: WebResults?
        let news: NewsResults?
        let discussions: DiscussionResults?
        let infobox: Infobox?
        let query: QueryInfo?
        let summarizer: Summarizer?
    }

    struct WebResults: Decodable {
        let results: [SearchResultItem]?
    }

    struct NewsResults: Decodable {
        let results: [NewsResultItem]?
    }

    struct DiscussionResults: Decodable {
        let results: [DiscussionResultItem]?
    }

    struct Infobox: Decodable {
        let title: String?
        let description: String?
        let infoboxType: String?
    }

    struct QueryInfo: Decodable {
        let original: String?
        let altered: String?
        let isNavigational: Bool?
    }

    struct Summarizer: Decodable {
        let text: String?
    }

    struct SearchResultItem: Decodable {
        let title: String?
        let url: String?
        let description: String?
    }

    struct NewsResultItem: Decodable {
        let title: String?
        let url: String?
        let description: String?
        let publishedAt: String?
    }

    struct DiscussionResultItem: Decodable {
        let title: String?
        let url: String?
        let snippet: String?
    }

    let decoder = JSONDecoder()
    let braveResponse = try decoder.decode(BraveSearchResponse.self, from: data)

    // 处理各类结果
    let webResults = braveResponse.web?.results ?? []
    let newsResults = braveResponse.news?.results ?? []
    let discussionResults = braveResponse.discussions?.results ?? []

    let webTitles = webResults.compactMap { $0.title }
    let webLinks = webResults.compactMap { $0.url }
    let webContents = webResults.compactMap { $0.description }

    let newsTitles = newsResults.compactMap { $0.title }
    let newsLinks = newsResults.compactMap { $0.url }
    let newsContents = newsResults.compactMap { $0.description }

    let discussionTitles = discussionResults.compactMap { $0.title }
    let discussionLinks = discussionResults.compactMap { $0.url }
    let discussionContents = discussionResults.compactMap { $0.snippet }

    // 默认图标
    let defaultIconURL = "https://brave.com/static-assets/images/brave-logo-sans-text.svg"

    // 合并所有结果
    let allTitles = webTitles + newsTitles + discussionTitles
    let allLinks = webLinks + newsLinks + discussionLinks
    let allContents = webContents + newsContents + discussionContents
    let allIcons = Array(repeating: defaultIconURL, count: allTitles.count)

    let parsedResult = ParsedSearchResult(
        titles: allTitles,
        links: allLinks,
        contents: allContents,
        icons: allIcons,
        totalTokens: allTitles.count
    )

    return (parsedResult, "BRAVE")
}


// MARK: 测试API有效性
func testSearchAPI(apiKey: String, requestURL: String, engine: SearchEngine) async -> Bool {
    // 1. 校验 API Key 和 URL 是否有效
    guard !apiKey.isEmpty,
          !requestURL.isEmpty,
          URL(string: requestURL) != nil else {
        return false
    }
    
    // 2. 定义测试查询
    let testQuery = "Search today's news"
    
    // 3. 根据不同搜索引擎调用相应实现
    do {
        switch engine {
        case .ZHIPUAI:
            let (_, engineName) = try await searchZhipu(query: testQuery, apiKey: apiKey, requestURL: requestURL, searchCount: 5)
            print("\(engineName) 搜索测试通过")
            return true
        case .BOCHAAI:
            let (_, engineName) = try await searchBochaAI(query: testQuery, apiKey: apiKey, requestURL: requestURL, searchCount: 5)
            print("\(engineName) 搜索测试通过")
            return true
        case .LANGSEARCH:
            let (_, engineName) = try await searchLangSearch(query: testQuery, apiKey: apiKey, requestURL: requestURL, searchCount: 5)
            print("\(engineName) 搜索测试通过")
            return true
        case .EXA:
            let (_, engineName) = try await searchExa(query: testQuery, apiKey: apiKey, requestURL: requestURL, searchCount: 5)
            print("\(engineName) 搜索测试通过")
            return true
        case .TAVILY:
            let (_, engineName) = try await searchTavily(query: testQuery, apiKey: apiKey, requestURL: requestURL, searchCount: 5)
            print("\(engineName) 搜索测试通过")
            return true
        case .BRAVE:
            let (_, engineName) = try await searchBrave(query: testQuery, apiKey: apiKey, requestURL: requestURL, searchCount: 5)
            print("\(engineName) 搜索测试通过")
            return true
        case .PERPLEXITY:
            let (_, engineName) = try await searchPerplexity(query: testQuery, apiKey: apiKey, requestURL: requestURL, searchCount: 5)
            print("\(engineName) 搜索测试通过")
            return true
        }
    } catch {
        print("搜索 API 测试失败: \(error)")
        return false
    }
}
