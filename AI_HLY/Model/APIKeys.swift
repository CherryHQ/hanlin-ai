//
//  APIKeys.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 9/2/25.
//
//

import Foundation
import SwiftData

enum APIType: String, CaseIterable, Codable {
    case openAI = "OpenAI"
    case openAIResponse = "OpenAI-Response"
    case gemini = "Gemini"
    case anthropic = "Anthropic"
}

enum APIFrom: String, CaseIterable, Codable {
    case system = "system"
    case custom = "custom"
}

@Model
class APIKeys {
    var name: String? = ""
    var company: String? = ""
    var key: String? = ""          // 默认空字符串
    var requestURL: String? = nil
    var isHidden: Bool = true      // 默认 true
    var help: String = ""
    private var apiTypeRawValue: String = APIType.openAI.rawValue
    private var fromRawValue: String = APIFrom.system.rawValue
    var timestamp: Date = Date()

    var apiType: APIType {
        get { APIType(rawValue: apiTypeRawValue) ?? .openAI }
        set { apiTypeRawValue = newValue.rawValue }
    }

    var from: APIFrom {
        get { APIFrom(rawValue: fromRawValue) ?? .system }
        set { fromRawValue = newValue.rawValue }
    }

    public init(
        name: String? = "",
        company: String? = "",
        key: String? = "",
        requestURL: String? = nil,
        isHidden: Bool = true,
        help: String = "",
        apiType: APIType = .openAI,
        from: APIFrom = .system,
        timestamp: Date = Date()
    ) {
        self.name = name
        self.company = company
        self.key = key
        self.requestURL = requestURL
        self.isHidden = isHidden
        self.help = help
        self.apiTypeRawValue = apiType.rawValue
        self.fromRawValue = from.rawValue
        self.timestamp = timestamp
    }
}
