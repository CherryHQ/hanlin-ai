//
//  AllModels.swift
//  AI_HBFGSY
//
//  Created by Development Team on 10/2/25.
//

import Foundation
import SwiftData

@Model
class AllModels {
    var id = UUID()
    var name: String?
    var displayName: String?
    var identity: String? = "model"
    var position: Int?
    var company: String?
    var price: Int16 = 0
    var isHidden: Bool = false
    var supportsSearch: Bool = false
    var supportsTextGen: Bool = true
    var supportsMultimodal: Bool = false
    var supportsReasoning: Bool = false
    var supportReasoningChange: Bool = false
    var supportsImageGen: Bool = false
    var supportsVoiceGen: Bool = false
    var supportsToolUse: Bool = false
    var systemProvision: Bool = true
    var icon: String? = ""
    var briefDescription: String? = ""
    var characterDesign: String? = ""
    var relatedKnowledge: String? = ""
    
    // InitializeMethod
    public init(
        id: UUID = UUID(),
        name: String?,
        displayName: String?,
        identity: String? = "model",
        position: Int?,
        company: String?,
        price: Int16 = 0,
        isHidden: Bool = false,
        supportsSearch: Bool = false,
        supportsTextGen: Bool = true,
        supportsMultimodal: Bool = false,
        supportsReasoning: Bool = false,
        supportReasoningChange: Bool = false,
        supportsImageGen: Bool = false,
        supportsVoiceGen: Bool = false,
        supportsToolUse: Bool = false,
        systemProvision: Bool = true,
        icon: String? = "",
        briefDescription: String? = "",
        characterDesign: String? = "",
        relatedKnowledge: String? = ""
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.identity = identity
        self.position = position
        self.company = company
        self.price = price
        self.isHidden = isHidden
        self.supportsSearch = supportsSearch
        self.supportsTextGen = supportsTextGen
        self.supportsMultimodal = supportsMultimodal
        self.supportsReasoning = supportsReasoning
        self.supportReasoningChange = supportReasoningChange
        self.supportsImageGen = supportsImageGen
        self.supportsVoiceGen = supportsVoiceGen
        self.supportsToolUse = supportsToolUse
        self.systemProvision = systemProvision
        self.icon = icon
        self.briefDescription = briefDescription
        self.characterDesign = characterDesign
        self.relatedKnowledge = relatedKnowledge
    }
}
