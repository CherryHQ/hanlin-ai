//
//  VisionIntent.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 13/2/25.
//

import AppIntents
import SwiftUI


struct OpenVisionIntent: AppIntent {
    static var openAppWhenRun: Bool = true
    static var title: LocalizedStringResource = "Activate Vision"
    static var description = IntentDescription("Open App’s Visual Page")
    static var supportsWidget: Bool = true
    static var supportsForegroundExecution: Bool = true
    static var suggestedInvocationPhrase: String? = "Activate Vision"
    
    @MainActor
    func perform() async throws -> some IntentResult {
        
        if let url = URL(string: "AI-Hanlin://openVisionView") { // 自定义 URL Scheme
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
        return .result()
    }
}
