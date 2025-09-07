//
//  UserInfo.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 18/2/25.
//

import Foundation
import SwiftData

@Model
class UserInfo {
    var name: String? = ""                                         // 默认空字符串
    var userInfo: String? = ""                                     // 默认空字符串
    var userRequirements: String? = ""                             // 默认空字符串
    var outPutFeedBack: Bool = true                               // 默认 true
    var bilingualSearch: Bool = false                              // 默认 false
    var chooseEmbeddingModel: String? = "Hanlin-BAAI/bge-m3"       // 选择的嵌入模型
    var useMemory: Bool = true                                     // 使用记忆功能
    var useCrossMemory: Bool = true                                // 使用跨聊天记忆
    var useMap: Bool = true                                        // 使用地图功能
    var useCalendar: Bool = true                                   // 使用日历功能
    var useSearch: Bool = true                                     // 使用搜索功能
    var useKnowledge: Bool = true                                  // 使用知识功能
    var useCode: Bool = true                                       // 使用代码功能
    var useHealth: Bool = true                                     // 使用健康信息
    var useWeather: Bool = true                                    // 使用天气查询
    var useCanvas: Bool = true                                     // 使用画布功能
    var optimizationTextModel: String = "glm-4.5-flash_hanlin"     // 文本优化模型
    var optimizationVisualModel: String = "glm-4v-flash_hanlin"    // 视觉优化模型
    var textToSpeechModel: String = "Siri"                         // 语音生成模型
    var searchCount: Int = 10                                      // 默认搜索结果数量
    var knowledgeCount: Int = 10                                   // 默认知识数量
    var knowledgeSimilarity: Double = 0.5                          // 默认知识相似度
    var timestamp: Date = Date()

    public init(
        name: String? = "",
        userInfo: String? = "",
        userRequirements: String? = "",
        outPutFeedBack: Bool = true,
        bilingualSearch: Bool = false,
        chooseEmbeddingModel: String? = "",
        useMemory: Bool = true,
        useMap: Bool = true,
        useCalendar: Bool = true,
        useSearch: Bool = true,
        useKnowledge: Bool = true,
        useCode: Bool = true,
        useHealth: Bool = true,
        useWeather: Bool = true,
        useCanvas: Bool = true,
        optimizationTextModel: String = "glm-4.5-flash_hanlin",
        optimizationVisualModel: String = "glm-4v-flash_hanlin",
        textToSpeechModel: String = "Siri",
        searchCount: Int = 10,
        knowledgeCount: Int = 10,
        knowledgeSimilarity: Double = 0.45,
        timestamp: Date = Date()
    ) {
        self.name = name
        self.userInfo = userInfo
        self.userRequirements = userRequirements
        self.outPutFeedBack = outPutFeedBack
        self.bilingualSearch = bilingualSearch
        self.chooseEmbeddingModel = chooseEmbeddingModel
        self.useMemory = useMemory
        self.useMap = useMap
        self.useCalendar = useCalendar
        self.useSearch = useSearch
        self.useKnowledge = useKnowledge
        self.useCode = useCode
        self.useHealth = useHealth
        self.useWeather = useWeather
        self.useCanvas = useCanvas
        self.optimizationTextModel = optimizationTextModel
        self.optimizationVisualModel = optimizationVisualModel
        self.textToSpeechModel = textToSpeechModel
        self.searchCount = searchCount
        self.knowledgeCount = knowledgeCount
        self.knowledgeSimilarity = knowledgeSimilarity
        self.timestamp = timestamp
    }
}

