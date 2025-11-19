//
//  UserInfo.swift
//  AI_HBFGSY
//
//  Created by Development Team on 18/2/25.
//

import Foundation
import SwiftData

@Model
class UserInfo {
    var name: String? = ""                                         // DefaultNullString
    var userInfo: String? = ""                                     // DefaultNullString
    var userRequirements: String? = ""                             // DefaultNullString
    var outPutFeedBack: Bool = true                               // Default true
    var bilingualSearch: Bool = false                              // Default false
    var chooseEmbeddingModel: String? = "Hanlin-BAAI/bge-m3"       // SelectofEmbeddingModel
    var useMemory: Bool = true                                     // UseMemoryfeature
    var useCrossMemory: Bool = true                                // Use跨ChatdayMemory
    var useMap: Bool = true                                        // UseplaceGraphfeature
    var useCalendar: Bool = true                                   // UseCalendarfeature
    var useSearch: Bool = true                                     // UseSearchfeature
    var useKnowledge: Bool = true                                  // UseKnowledgefeature
    var useCode: Bool = true                                       // UseCodefeature
    var useHealth: Bool = true                                     // UsehealthInformation
    var useWeather: Bool = true                                    // UseWeatherQuery
    var useCanvas: Bool = true                                     // UseCanvasfeature
    var optimizationTextModel: String = "glm-4.5-flash_hanlin"     // TextOptimizeModel
    var optimizationVisualModel: String = "glm-4v-flash_hanlin"    // VisionOptimizeModel
    var textToSpeechModel: String = "Siri"                         // VoiceGenerateModel
    var searchCount: Int = 10                                      // DefaultSearchResultQuantity
    var knowledgeCount: Int = 10                                   // DefaultKnowledgeQuantity
    var knowledgeSimilarity: Double = 0.5                          // DefaultKnowledgeSimilarity
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

