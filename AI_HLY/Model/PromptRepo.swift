//
//  PromptRepo.swift
//  AI_Hanlin
//
//  Created by 哆啦好多dream on 18/3/25.
//

import Foundation
import SwiftData

@Model
class PromptRepo {
    var id: UUID = UUID()
    var name: String? = nil
    var content: String? = nil
    var position: Int?
    var timestamp: Date = Date()

    public init(
        id: UUID = UUID(),
        name: String? = nil,
        content: String? = nil,
        position: Int? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.content = content
        self.position = position
        self.timestamp = timestamp
    }
}
