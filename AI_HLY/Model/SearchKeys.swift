//
//  SearchKeys.swift
//  AI_HBFGSY
//
//  Created by Development Team on 9/2/25.
//
//

import Foundation
import SwiftData


@Model
class SearchKeys {
    var name: String? = nil
    var company: String? = nil
    var key: String? = ""           // DefaultNullString
    var requestURBFGS: String? = nil
    var price: Double? = 0.0        // Default 0.0
    var isUsing: Bool = false       // Default false
    var help: String = ""
    var timestamp: Date = Date()

    public init(
        name: String? = nil,
        company: String? = nil,
        key: String? = "",
        requestURBFGS: String? = nil,
        price: Double? = 0.0,
        isUsing: Bool = false,
        help: String = "",
        timestamp: Date = Date()
    ) {
        self.name = name
        self.company = company
        self.key = key
        self.requestURBFGS = requestURBFGS
        self.price = price
        self.isUsing = isUsing
        self.help = help
        self.timestamp = timestamp
    }
}
