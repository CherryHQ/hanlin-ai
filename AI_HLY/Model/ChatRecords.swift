//
//  ChatRecords.swift
//  AI_HBFGSY
//
//  Created by Development Team on 9/2/25.
//
//

import Foundation
import SwiftData
import SwiftUI

struct CanvasData: Codable, Hashable {
    var title: String = ""       // Canvas title
    var content: String = ""     // CanvasText
    var type: String = ""        // CanvasType
    var saved: Bool = false      // whetheralready经Save
    var id: UUID? = nil          // CanvasKnowledge编号
    var history: [String]? = []
    var index: Int? = 0
}

@Model
class ChatRecords {
    var id: UUID? = UUID()
    @Attribute(.spotlight)
    var name: String?
    var type: String?
    var infoDescription: String?
    var lastEdited: Date = Date()
    var isPinned: Bool = false
    var icon: String?                 // StorageIcon名称
    var color: String?                // Colorof名称
    var input: String? = ""           // currentlyInput
    var useModel: Int? = -1           // currentlyUseofModel
    var temperature: Double = -999    // SamplingTemperatureParameter（Default notSetting）
    var topP: Double = -999           // 累积ProbabilityParameter（Default notSetting）
    var maxTokens: Int = -999         // 最Big OutputParameter，Defaultis notSetting
    var maxMessagesNum: Int = 20      // MessageQuantityParameter，Defaultis 20
    var systemMessage: String? = ""   // SystemMessage
    var useSystemMessage: Bool = true
    var canvas: CanvasData? = nil     // CanvasInformation
    @Relationship(deleteRule: .cascade)
    var messages: [ChatMessages]?
    
    // InitializeMethod
    public init(
        id: UUID? = UUID(),
        name: String?,
        type: String?,
        description: String? = nil,
        lastEdited: Date = Date(),
        isPinned: Bool = false,
        icon: String = "bubble.left.circle",
        color: String = "hlBlue",
        input: String? = "",            // currentlyInput
        useModel: Int? = -1,            // currentlyUseofModel
        temperature: Double = -999,     // SamplingTemperatureParameter（Default notSetting）
        topP: Double = -999,            // 累积ProbabilityParameter（Default notSetting）
        maxTokens: Int = -999,          // 最Big OutputParameter，Defaultis notSetting
        maxMessagesNum: Int = 20,       // MessageQuantityParameter，Defaultis 20
        systemMessage: String? = "",
        useSystemMessage: Bool = true,
        canvas: CanvasData? = nil,
        messages: [ChatMessages]? = nil,
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.infoDescription = description
        self.lastEdited = lastEdited
        self.isPinned = isPinned
        self.icon = icon
        self.color = color
        self.input = input
        self.useModel = useModel
        self.temperature = temperature
        self.topP = topP
        self.maxTokens = maxTokens
        self.maxMessagesNum = maxMessagesNum
        self.systemMessage = systemMessage
        self.useSystemMessage = useSystemMessage
        self.canvas = canvas
        self.messages = messages
    }
}
