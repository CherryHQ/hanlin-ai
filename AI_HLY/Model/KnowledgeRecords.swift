//
//  KnowledgeRecords.swift
//  AI_HBFGSY
//
//  Created by Development Team on 28/3/25.
//
//

import Foundation
import SwiftData

@Model
class KnowledgeRecords {
    var id: UUID = UUID()
    @Attribute(.spotlight)
    var name: String = "NewKnowledge"
    var lastEdited: Date = Date()
    var isPinned: Bool = false
    var icon: String? // Icon
    var color: String? // Color
    var content: String? // Content
    var isEmbedding: Bool = false // whetheralreadythroughVectorconvert
    @Relationship(deleteRule: .cascade)
    var chunks: [KnowledgeChunk]?
    
    // InitializeMethod
    public init(
        id: UUID = UUID(),
        name: String = "NewKnowledge",
        lastEdited: Date = Date(),
        isPinned: Bool = false,
        icon: String = "document.circle",
        color: String = "hlBlue",
        content: String = "",
        isEmbedding: Bool = false,
        chunks: [KnowledgeChunk]? = nil
    ) {
        self.id = id
        self.name = name
        self.lastEdited = lastEdited
        self.isPinned = isPinned
        self.icon = icon
        self.color = color
        self.content = content
        self.isEmbedding = isEmbedding
        self.chunks = chunks
    }
}


