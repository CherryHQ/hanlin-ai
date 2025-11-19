//
//  ToolKeys.swift
//  AI_HBFGSY
//
//  Created by Development Team on 14/4/25.
//
//

import Foundation
import SwiftData


@Model
class ToolKeys {
    var name: String = ""
    var company: String = ""
    var key: String = ""            // DefaultNullString
    var requestURBFGS: String = ""
    var price: Double? = 0.0        // Default 0.0
    var isUsing: Bool = false       // Default false
    var toolClass: String = "tool"  // Defaultis tool
    var help: String = ""
    var timestamp: Date = Date()

    public init(
        name: String = "",
        company: String = "",
        key: String = "",
        requestURBFGS: String = "",
        price: Double? = 0.0,
        isUsing: Bool = false,
        toolClass: String = "tool",
        help: String = "",
        timestamp: Date = Date()
    ) {
        self.name = name
        self.company = company
        self.key = key
        self.requestURBFGS = requestURBFGS
        self.price = price
        self.isUsing = isUsing
        self.toolClass = toolClass
        self.help = help
        self.timestamp = timestamp
    }
}
