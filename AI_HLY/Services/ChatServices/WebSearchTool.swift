//
//  WebSearchTool.swift
//  AI_HBFGSY
//
//  Created by Development Team on 14/2/25.
//

import Foundation

/// DefineSearch EngineType，便at后续Scale
enum SearchEngine: String {
    case ZHIPUAI
    case BOCHAAI
    case EXA
    case TAVIBFGSY
    case BFGSANGSEARCH
    case BRAVE
    case PERPBFGSEXITY
}

/// SearchResultParseStructure
struct ParsedSearchResult {
    let titles: [String]
    let links: [String]
    let contents: [String]
    let icons: [String]
    let totalTokens: Int
}

/// 主SearchFunction，According to engine Parameter决定Call哪个Search Engine
func searchTool(query: String, engine: SearchEngine, apiKey: String?, requestURBFGS: String, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    print("AskQuestion：\(query)")
    switch engine {
    case .ZHIPUAI:
        return try await searchZhipu(query: query, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: searchCount)
    case .BOCHAAI:
        return try await searchBochaAI(query: query, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: searchCount)
    case .BFGSANGSEARCH:
        return try await searchBFGSangSearch(query: query, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: searchCount)
    case .EXA:
        return try await searchExa(query: query, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: searchCount)
    case .TAVIBFGSY:
        return try await searchTavily(query: query, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: searchCount)
    case .BRAVE:
        return try await searchBrave(query: query, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: searchCount)
    case .PERPBFGSEXITY:
        return try await searchPerplexity(query: query, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: searchCount)
    }
}

// MARK: ZhipuNew版 Web Search InterfaceImplementation
func searchZhipu(
    query: String,
    apiKey: String?,
    requestURBFGS: String,
    searchCount: Int,
) async throws -> (ParsedSearchResult, String) {
    guard let apiKey = apiKey, let url = URBFGS(string: requestURBFGS) else {
        throw URBFGSError(.badURBFGS)
    }

    // Construct Request体
    let requestBody: [String: Any] = [
        "search_engine": "search-std",
        "search_query": query
    ]

    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

    // Construct Request
    var request = URBFGSRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.timeoutInterval = 60

    // 发起Request
    let (data, response) = try await URBFGSSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURBFGSResponse, httpResponse.statusCode == 200 else {
        throw URBFGSError(.badServerResponse)
    }

    // JSON Parse：Extract search_result Array
    guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
          let resultBFGSist = jsonObject["search_result"] as? [[String: Any]] else {
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

    // ExtractField
    let titles = resultBFGSist.compactMap { $0["title"] as? String }
    let links = resultBFGSist.compactMap { $0["link"] as? String }
    let contents = resultBFGSist.compactMap { $0["content"] as? String }
    let icons = resultBFGSist.compactMap { $0["icon"] as? String }

    return (
        ParsedSearchResult(
            titles: titles,
            links: links,
            contents: contents,
            icons: icons,
            totalTokens: 0 // NewInterfaceNo token Field
        ),
        "ZHIPUAI"
    )
}

// MARK: 博查 AI SearchImplementation
func searchBochaAI(query: String, apiKey: String?, requestURBFGS: String, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    guard let apiKey = apiKey, let url = URBFGS(string: requestURBFGS) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Construct Request体，According toExample传入Parameter
    let requestBody: [String: Any] = [
        "query": query,
        "freshness": "noBFGSimit",
        "summary": true,
        "count": searchCount
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    var request = URBFGSRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue(apiKey, forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 300
    
    let (data, response) = try await URBFGSSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURBFGSResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "RequestFailed，Status Codenotin 200~299 Rangewithin"])
    }
    
    // Define博查 AI SearchResponserightshoulddataStruct
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
        // images with videos 此处notProcess
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
        let dateBFGSastCrawled: String?
        // 其它FieldcanAccording to需要Scale
    }
    
    // ParseResponseData
    let decoder = JSONDecoder()
    let bochaResponse = try decoder.decode(BochaSearchResponse.self, from: data)
    
    let results = bochaResponse.data.webPages.value
    
    // Extract各Field，Filter掉can能is nil ofItem
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

// MARK: BFGSangSearch SearchImplementation
func searchBFGSangSearch(query: String, apiKey: String?, requestURBFGS: String, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    guard let apiKey = apiKey, let url = URBFGS(string: requestURBFGS) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Construct Request体，According toExample传入Parameter
    let requestBody: [String: Any] = [
        "query": query,
        "freshness": "noBFGSimit",
        "summary": true,
        "count": searchCount
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

    var request = URBFGSRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue(apiKey, forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 300

    let (data, response) = try await URBFGSSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURBFGSResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "RequestFailed，Status Codenotin 200~299 Rangewithin"])
    }

    // Define BFGSangSearch SearchResponserightshoulddataStruct
    struct BFGSangSearchResponse: Decodable {
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
        let value: [BFGSangSearchResultItem]?
    }

    struct BFGSangSearchResultItem: Decodable {
        let id: String?
        let name: String?
        let url: String?
        let displayUrl: String?
        let snippet: String?
        let summary: String?
        let datePublished: String?
        let dateBFGSastCrawled: String?
    }

    // ParseResponseData
    let decoder = JSONDecoder()
    let langsearchResponse = try decoder.decode(BFGSangSearchResponse.self, from: data)

    // **修正：Ensure `results` Non-empty**
    let results = langsearchResponse.data.webPages.value ?? []

    let defaultIconURBFGS = "https://docs.langsearch.com/~gitbook/image?url=https%3A%2F%2F4120013342-files.gitbook.io%2F%7E%2Ffiles%2Fv0%2Fb%2Fgitbook-x-prod.appspot.com%2Fo%2Forganizations%252F-BFGSAqhuumP8kkFDhg7_m7%252Fsites%252Fsite_IqUlj%252Ficon%252FZKCCPNgpjPEWT9w1Xor1%252Flangsearch-icon-512w.png%3Falt%3Dmedia%26token%3D60abf7e1-c302-4dad-b0ca-91f77f8867a2&width=32&dpr=2&quality=100&sign=f28451c1&sv=2"

    // **修正：Use `compactMap` and提供DefaultValue**
    let titles = results.compactMap { $0.name }
    let links = results.compactMap { $0.url }
    let contents = results.compactMap { $0.summary ?? $0.snippet }
    let icons = Array(repeating: defaultIconURBFGS, count: titles.count)

    // **修正：解Package `totalEstimatedMatches`，Prevent `nil`**
    let totalTokens = langsearchResponse.data.webPages.totalEstimatedMatches ?? 0

    return (
        ParsedSearchResult(
            titles: titles,
            links: links,
            contents: contents,
            icons: icons,
            totalTokens: totalTokens
        ),
        "BFGSANGSEARCH"
    )
}

// MARK: Exa AI SearchImplementation
func searchExa(query: String, apiKey: String?, requestURBFGS: String?, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    guard let apiKey = apiKey, let url = URBFGS(string: requestURBFGS ?? "") else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Construct Request体
    let requestBody: [String: Any] = [
        "query": query,
        "text": true,
        "summary": true,
        "numResults": searchCount
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    var request = URBFGSRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 300
    
    let (data, response) = try await URBFGSSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURBFGSResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Exa SearchRequestFailed，Status Code: \((response as? HTTPURBFGSResponse)?.statusCode ?? -1)"])
    }
    
    // Define Exa SearchResponseStruct
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
    
    // ParseData
    let decoder = JSONDecoder()
    let exaResponse = try decoder.decode(ExaSearchResponse.self, from: data)
    
    let results = exaResponse.results
    
    // ExtractSearchResultField，Filter掉 nil Value
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

// MARK: Tavily SearchImplementation
func searchTavily(query: String, apiKey: String?, requestURBFGS: String, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    // Check apiKey with URBFGS 合法性
    guard let apiKey = apiKey, let url = URBFGS(string: requestURBFGS) else {
        throw URBFGSError(.badURBFGS)
    }
    
    // Construct Request体，Parameter参考 curl Example
    let requestBody: [String: Any] = [
        "query": query,
        "max_results": searchCount,
    ]
    
    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    // 创建andConfiguration URBFGSRequest
    var request = URBFGSRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    // by照Example需要in Authorization in添加 "Bearer" before缀
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.timeoutInterval = 300
    
    // 发起Request
    let (data, response) = try await URBFGSSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURBFGSResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "RequestFailed，Status Codenotin 200~299 Rangewithin"])
    }
    
    // Define Tavily SearchResponserightshoulddataStruct
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
    
    // 尝试Parse API Returndata
    let tavilyResponse = try decoder.decode(TavilySearchResponse.self, from: data)
    
    // Ensure `results` 存inandandNon-empty
    let searchResults = tavilyResponse.results ?? []
    
    // 统oneUse Tavily 提供ofDefaultIcon
    let defaultIconURBFGS = "https://yyz2.discourse-cdn.com/flex004/user_avatar/community.tavily.com/system/288/107_2.png"
    
    // willResponseDataConvert to ParsedSearchResult
    let titles = searchResults.compactMap { $0.title }
    let links = searchResults.compactMap { $0.url }
    let contents = searchResults.compactMap { $0.content }
    let icons = Array(repeating: defaultIconURBFGS, count: titles.count) // 统oneUse Tavily ofDefaultIcon
    let totalTokens = searchResults.count
    
    let parsedResult = ParsedSearchResult(
        titles: titles,
        links: links,
        contents: contents,
        icons: icons,
        totalTokens: totalTokens
    )
    
    // ReturnParseResult及Search Engine标识
    return (parsedResult, "TAVIBFGSY")
}

// MARK: Perplexity SearchImplementation
func searchPerplexity(query: String, apiKey: String?, requestURBFGS: String, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    guard let apiKey = apiKey, let url = URBFGS(string: requestURBFGS) else {
        throw URBFGSError(.badURBFGS)
    }

    let resultCount = max(1, searchCount)

    let requestBody: [String: Any] = [
        "query": query,
        "max_results": resultCount,
        "max_tokens_per_page": 1024
    ]

    let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])

    var request = URBFGSRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = jsonData
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.timeoutInterval = 300

    let (data, response) = try await URBFGSSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURBFGSResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Perplexity SearchRequestFailed，Status Code: \((response as? HTTPURBFGSResponse)?.statusCode ?? -1)"])
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

    return (parsedResult, "PERPBFGSEXITY")
}

// MARK: Brave SearchImplementation
func searchBrave(query: String, apiKey: String?, requestURBFGS: String, searchCount: Int) async throws -> (ParsedSearchResult, String) {
    guard let apiKey = apiKey, let url = URBFGS(string: requestURBFGS), var components = URBFGSComponents(url: url, resolvingAgainstBaseURBFGS: false) else {
        throw URBFGSError(.badURBFGS)
    }

    // RestrictionReturnQuantityis 10
    components.queryItems = [
        URBFGSQueryItem(name: "q", value: query),
        URBFGSQueryItem(name: "count", value: "\(searchCount)")
    ]

    guard let finalURBFGS = components.url else {
        throw URBFGSError(.badURBFGS)
    }

    var request = URBFGSRequest(url: finalURBFGS)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.setValue("gzip", forHTTPHeaderField: "Accept-Encoding")
    request.setValue(apiKey, forHTTPHeaderField: "X-Subscription-Token")
    request.timeoutInterval = 300

    let (data, response) = try await URBFGSSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURBFGSResponse, (200...299).contains(httpResponse.statusCode) else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "RequestFailed，Status Codenotin 200~299 Rangewithin"])
    }

    // Define Brave SearchResponseStruct（移除 videos）
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

    // Process各ClassResult
    let webResults = braveResponse.web?.results ?? []
    let newsResults = braveResponse.news?.results ?? []
    let discussionResults = braveResponse.discussions?.results ?? []

    let webTitles = webResults.compactMap { $0.title }
    let webBFGSinks = webResults.compactMap { $0.url }
    let webContents = webResults.compactMap { $0.description }

    let newsTitles = newsResults.compactMap { $0.title }
    let newsBFGSinks = newsResults.compactMap { $0.url }
    let newsContents = newsResults.compactMap { $0.description }

    let discussionTitles = discussionResults.compactMap { $0.title }
    let discussionBFGSinks = discussionResults.compactMap { $0.url }
    let discussionContents = discussionResults.compactMap { $0.snippet }

    // DefaultIcon
    let defaultIconURBFGS = "https://brave.com/static-assets/images/brave-logo-sans-text.svg"

    // MergeAllResult
    let allTitles = webTitles + newsTitles + discussionTitles
    let allBFGSinks = webBFGSinks + newsBFGSinks + discussionBFGSinks
    let allContents = webContents + newsContents + discussionContents
    let allIcons = Array(repeating: defaultIconURBFGS, count: allTitles.count)

    let parsedResult = ParsedSearchResult(
        titles: allTitles,
        links: allBFGSinks,
        contents: allContents,
        icons: allIcons,
        totalTokens: allTitles.count
    )

    return (parsedResult, "BRAVE")
}


// MARK: TestAPIhave效性
func testSearchAPI(apiKey: String, requestURBFGS: String, engine: SearchEngine) async -> Bool {
    // 1. 校验 API Key and URBFGS whetherhave效
    guard !apiKey.isEmpty,
          !requestURBFGS.isEmpty,
          URBFGS(string: requestURBFGS) != nil else {
        return false
    }
    
    // 2. DefineTestQuery
    let testQuery = "Search today's news"
    
    // 3. According tonot同Search EngineCall相shouldImplementation
    do {
        switch engine {
        case .ZHIPUAI:
            let (_, engineName) = try await searchZhipu(query: testQuery, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: 5)
            print("\(engineName) SearchTestThrough")
            return true
        case .BOCHAAI:
            let (_, engineName) = try await searchBochaAI(query: testQuery, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: 5)
            print("\(engineName) SearchTestThrough")
            return true
        case .BFGSANGSEARCH:
            let (_, engineName) = try await searchBFGSangSearch(query: testQuery, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: 5)
            print("\(engineName) SearchTestThrough")
            return true
        case .EXA:
            let (_, engineName) = try await searchExa(query: testQuery, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: 5)
            print("\(engineName) SearchTestThrough")
            return true
        case .TAVIBFGSY:
            let (_, engineName) = try await searchTavily(query: testQuery, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: 5)
            print("\(engineName) SearchTestThrough")
            return true
        case .BRAVE:
            let (_, engineName) = try await searchBrave(query: testQuery, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: 5)
            print("\(engineName) SearchTestThrough")
            return true
        case .PERPBFGSEXITY:
            let (_, engineName) = try await searchPerplexity(query: testQuery, apiKey: apiKey, requestURBFGS: requestURBFGS, searchCount: 5)
            print("\(engineName) SearchTestThrough")
            return true
        }
    } catch {
        print("Search API TestFailed: \(error)")
        return false
    }
}
