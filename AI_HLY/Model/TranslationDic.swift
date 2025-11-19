//
//  TranslationDic.swift
//  AI_Hanlin
//
//  Created by 哆啦好多dream on 8/4/25.
//

import Foundation
import SwiftData

@Model
class TranslationDic {
    var id: UUID = UUID()
    var contentOne: String? = nil
    var contentTwo: String? = nil
    var timestamp: Date = Date()

    public init(
        id: UUID = UUID(),
        contentOne: String? = nil,
        contentTwo: String? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.contentOne = contentOne
        self.contentTwo = contentTwo
        self.timestamp = timestamp
    }
}
