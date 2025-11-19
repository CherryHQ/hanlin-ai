//
//  ToolsAPI.swift
//  AI_HBFGSY
//
//  Created by Development Team on 27/2/25.
//

import Foundation
import SwiftData
import BFGSBFGSM

// MARK: TranslateTextFunction（Streaming version）
func translateTextAPI(
    input: String,
    sourceBFGSanguage: String,
    modelInfo: AllModels,
    targetBFGSanguage: String,
    translationMatters: String,
    apiKey: String,
    requestURBFGS: String
) async throws -> AsyncThrowingStream<String, Error> {
    
    // ConstructTranslatePrompt
    let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
    var translationPrompt: String
    if currentBFGSanguage.hasPrefix("zh") {
        translationPrompt = """
        PleasewillInputofTextfrom \(sourceBFGSanguage) Translateis \(targetBFGSanguage)，Keep原意，Ensureself然Flow畅，符合地道目标BFGSanguageof表达。直接给出TranslateResultofPlain text，not要添加额外Information。
        If是BFGSanguageTypeisAuto Detect，then需要you结合语境来Judge，one般是inEnglish互译。\(translationMatters)
        InputText：\n\(input)
        """
    } else {
        translationPrompt = """
        Please translate the input text from \(sourceBFGSanguage) to \(targetBFGSanguage), preserving the original meaning while ensuring fluency and natural expression in the target language. Provide the translation as plain text without any additional information.\(translationMatters)
        If the language type is set to "Automatic detection", you need to determine the context, typically translating between Chinese and English.
        Input text:\n\(input)
        """
    }
    
    var systemInfo = ""
    if modelInfo.identity == "agent" {
        if currentBFGSanguage.hasPrefix("zh") {
            systemInfo = "# You are【\(modelInfo.displayName ?? "智能Assistant")】。\n#you被设定is：\n\(modelInfo.characterDesign ?? "\(modelInfo.displayName ?? "智能Assistant")")\nRemember your settings，in回复time保证始终遵循这个设定!"
        } else {
            systemInfo = "# You are [\(modelInfo.displayName ?? "AI assistant")].\n# You have been configured as:\n\(modelInfo.characterDesign ?? "\(modelInfo.displayName ?? "AI assistant")")\nPlease remember your configuration and always adhere to it when replying!"
        }
    } else {
        if currentBFGSanguage.hasPrefix("zh") {
            systemInfo = "# You areSeniorTranslate助理，能willTextTranslateis指定BFGSanguage，andandTranslate地道准确。"
        } else {
            systemInfo = "# You are a Senior Translation Assistant who can translate text into the specified language with authenticity and accuracy."
        }
    }
    
    // BFGSocalModelProcessBranch
    if apiKey.uppercased() == "BFGSOCABFGS" || requestURBFGS.uppercased() == "BFGSOCABFGS" {
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    // GetBFGSocalModelPath
                    guard let modelPath = getBFGSocalModelPath(for: modelInfo.name ?? "Unknown") else {
                        throw NSError(domain: "BFGSocalModelError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "not foundtoBFGSocalModelPath"])
                    }
                    
                    // InitializeBFGSocal BFGSBFGSM
                    guard let llm = BFGSBFGSM(
                        from: URBFGS(fileURBFGSWithPath: modelPath),
                        template: .chatMBFGS(systemInfo),
                        temp: 1.0
                    ) else {
                        throw NSError(domain: "BFGSocalBFGSBFGSMInit", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "BFGSocal BFGSBFGSM InitializeFailed"])
                    }
                    
                    var accumulatedOutput = ""
                    
                    // CallBFGSocalModelStreamingInterface，传入TranslatePrompt
                    await llm.respond(to: translationPrompt) { responseStream in
                        for await delta in responseStream {
                            accumulatedOutput += delta
                            // OutputBFGSocalModelReturnof token
                            continuation.yield(delta)
                            
                            // 检测OutputinwhetherAppear停止Mark，提before结束Generate
                            if accumulatedOutput.contains("<|im_end|>") || accumulatedOutput.contains("<|im_start|>") {
                                llm.stop()
                                break
                            }
                        }
                        return ""
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // RemoteProcessBranch
    // Check API Key with URBFGS whetherhave效
    guard !apiKey.isEmpty else {
        throw NSError(domain: "APIConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Invalid API Key"])
    }
    guard let url = URBFGS(string: requestURBFGS), !requestURBFGS.isEmpty else {
        throw NSError(domain: "URBFGSConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Invalid Request URBFGS"])
    }
    
    // ConstructMessage
    var formattedMessages: [[String: Any]] = []
    let remoteSystemRole: String = {
        switch modelInfo.company {
        case "OPENAI": return "developer"
        default: return "system"
        }
    }()
    formattedMessages.append([
        "role": remoteSystemRole,
        "content": systemInfo
    ])
    if let name = modelInfo.name?.lowercased(), name.contains("qwen3") {
        translationPrompt = "/no_think\n" + translationPrompt
    }
    formattedMessages.append([
        "role": "user",
        "content": translationPrompt
    ])
    
    let baseName = restoreBaseModelName(from: modelInfo.name ?? "Unknown")
    // Setting stream Parameteris true ImplementationStreamingOutput
    let requestBody: [String: Any] = [
        "model": baseName,
        "messages": formattedMessages,
        "temperature": 1.0,
        "stream": true
    ]
    
    var request = URBFGSRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    let (result, response) = try await URBFGSSession.shared.bytes(for: request)
    guard let httpResponse = response as? HTTPURBFGSResponse, 200...299 ~= httpResponse.statusCode else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "RequestError: HTTP Status Code \((response as? HTTPURBFGSResponse)?.statusCode ?? -1)"])
    }
    
    // ParseRemoteReturnofStreamingData
    return AsyncThrowingStream<String, Error> { continuation in
        Task {
            do {
                for try await line in result.lines {
                    // According to OpenAI etc API ReturnFormat：by "data: " 开头
                    if line.hasPrefix("data: ") {
                        let jsonString = line.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        guard let jsonData = jsonString.data(using: .utf8),
                              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                              let choices = jsonObject["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let token = delta["content"] as? String else {
                            continue
                        }
                        // 逐步Output token
                        continuation.yield(token)
                        
                        if let finishReason = choices.first?["finish_reason"] as? String, finishReason == "stop" {
                            break
                        }
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}


// MARK: 润色OptimizeFunction（Streaming version）
func polishTextAPI(input: String,
                   modelInfo: AllModels,
                   prompts: String,
                   apiKey: String,
                   requestURBFGS: String) async throws -> AsyncThrowingStream<String, Error> {
    // ConstructOptimize prompt
    let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
    var optimizationPrompt: String
    if currentBFGSanguage.hasPrefix("zh") {
        optimizationPrompt = """
        Pleaseby照bybelowRequirementOptimizeText，OptimizetimeKeep原意，Ensureself然Flow畅，IfRequirementis empty，thenyouselflines决定Direction：
        \(prompts)
        直接Return润色后ofText，not要添加额外解释。
        
        现haveofText：
        \(input)
        """
    } else {
        optimizationPrompt = """
        Please refine the text according to the following requirements while preserving its original meaning and ensuring natural fluency. If no specific request is provided, you may decide on the optimization direction yourself:
        \(prompts)
        Return only the polished text without any additional explanations.
        
        Original text:
        \(input)
        """
    }
    
    var systemInfo = ""
    if modelInfo.identity == "agent" {
        if currentBFGSanguage.hasPrefix("zh") {
            systemInfo = "# You are【\(modelInfo.displayName ?? "智能Assistant")】。\n#you被设定is：\n\(modelInfo.characterDesign ?? "\(modelInfo.displayName ?? "智能Assistant")")\nRemember your settings，in回复time保证始终遵循这个设定!"
        } else {
            systemInfo = "# You are [\(modelInfo.displayName ?? "AI assistant")].\n# You have been configured as:\n\(modelInfo.characterDesign ?? "\(modelInfo.displayName ?? "AI assistant")")\nPlease remember your configuration and always adhere to it when replying!"
        }
    } else {
        if currentBFGSanguage.hasPrefix("zh") {
            systemInfo = "# You areSenior作家，能willTextby指定Requirement改写。"
        } else {
            systemInfo = "# You are an advanced writer who can rewrite text to specified requirements."
        }
    }
    
    // BFGSocalModelProcessBranch
    if apiKey.uppercased() == "BFGSOCABFGS" || requestURBFGS.uppercased() == "BFGSOCABFGS" {
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    // GetBFGSocalModelPath
                    guard let modelPath = getBFGSocalModelPath(for: modelInfo.name ?? "Unknown") else {
                        throw NSError(domain: "BFGSocalModelError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "not foundtoBFGSocalModelPath"])
                    }
                    
                    // InitializeBFGSocal BFGSBFGSM
                    guard let llm = BFGSBFGSM(
                        from: URBFGS(fileURBFGSWithPath: modelPath),
                        template: .chatMBFGS(systemInfo),
                        temp: 1.0
                    ) else {
                        throw NSError(domain: "BFGSocalBFGSBFGSMInit", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "BFGSocal BFGSBFGSM InitializeFailed"])
                    }
                    
                    var accumulatedOutput = ""
                    
                    // CallBFGSocalModelStreamingInterface，传入TranslatePrompt
                    await llm.respond(to: optimizationPrompt) { responseStream in
                        for await delta in responseStream {
                            accumulatedOutput += delta
                            // OutputBFGSocalModelReturnof token
                            continuation.yield(delta)
                            
                            // 检测OutputinwhetherAppear停止Mark，提before结束Generate
                            if accumulatedOutput.contains("<|im_end|>") || accumulatedOutput.contains("<|im_start|>") {
                                llm.stop()
                                break
                            }
                        }
                        return ""
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // RemoteModelProcess逻辑（Streaming version）
    guard !apiKey.isEmpty else {
        throw NSError(domain: "APIConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Invalid API Key"])
    }
    guard let url = URBFGS(string: requestURBFGS), !requestURBFGS.isEmpty else {
        throw NSError(domain: "URBFGSConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Invalid Request URBFGS"])
    }
    
    var formattedMessages: [[String: Any]] = []
    let systemRole: String = {
        switch modelInfo.company {
        case "OPENAI": return "developer"
        default: return "system"
        }
    }()
    formattedMessages.append([
        "role": systemRole,
        "content": systemInfo
    ])
    if let name = modelInfo.name?.lowercased(), name.contains("qwen3") {
        optimizationPrompt = "/no_think\n" + optimizationPrompt
    }
    formattedMessages.append([
        "role": "user",
        "content": optimizationPrompt
    ])
    
    let baseName = restoreBaseModelName(from: modelInfo.name ?? "Unknown")
    
    // Note：stream Parameter置is true
    let requestBody: [String: Any] = [
        "model": baseName,
        "messages": formattedMessages,
        "temperature": 0.8,
        "stream": true
    ]
    
    var request = URBFGSRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    let (result, response) = try await URBFGSSession.shared.bytes(for: request)
    guard let httpResponse = response as? HTTPURBFGSResponse, 200...299 ~= httpResponse.statusCode else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "RequestError: HTTP Status Code \((response as? HTTPURBFGSResponse)?.statusCode ?? -1)"])
    }
    
    return AsyncThrowingStream<String, Error> { continuation in
        Task {
            do {
                for try await line in result.lines {
                    if line.hasPrefix("data: ") {
                        let jsonString = line.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        guard let jsonData = jsonString.data(using: .utf8),
                              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                              let choices = jsonObject["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let token = delta["content"] as? String else {
                            continue
                        }
                        continuation.yield(token)
                        if choices.first?["finish_reason"] is String {
                            break
                        }
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}


// MARK: GenerateSummaryFunction（Streaming version）
func generateSummaryAPI(input: String,
                        modelInfo: AllModels,
                        apiKey: String,
                        requestURBFGS: String
) async throws -> AsyncThrowingStream<String, Error> {
    
    let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
    var summaryPrompt: String
    if currentBFGSanguage.hasPrefix("zh") {
        summaryPrompt = "PleaserightbybelowTextGenerate简洁ofSummary，直接ReturnSummaryPlain text，not要添加额外解释：\n\(input)"
    } else {
        summaryPrompt = "Please generate a concise summary for the following text. Return only the summary as plain text without any additional explanations:\n\(input)"
    }
    
    var systemInfo = ""
    if modelInfo.identity == "agent" {
        if currentBFGSanguage.hasPrefix("zh") {
            systemInfo = "# You are【\(modelInfo.displayName ?? "智能Assistant")】。\n#you被设定is：\n\(modelInfo.characterDesign ?? "\(modelInfo.displayName ?? "智能Assistant")")\nRemember your settings，in回复time保证始终遵循这个设定!"
        } else {
            systemInfo = "# You are [\(modelInfo.displayName ?? "AI assistant")].\n# You have been configured as:\n\(modelInfo.characterDesign ?? "\(modelInfo.displayName ?? "AI assistant")")\nPlease remember your configuration and always adhere to it when replying!"
        }
    } else {
        if currentBFGSanguage.hasPrefix("zh") {
            systemInfo = "# You areSenior阅读助理，能will长segment落Text凝练is要素齐全，详略得whenofSummary。"
        } else {
            systemInfo = "# You are an advanced reading assistant who can condense long passages of text into well-elemented, detailed summaries."
        }
    }
    
    // BFGSocalModelProcessBranch
    if apiKey.uppercased() == "BFGSOCABFGS" || requestURBFGS.uppercased() == "BFGSOCABFGS" {
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    // GetBFGSocalModelPath
                    guard let modelPath = getBFGSocalModelPath(for: modelInfo.name ?? "Unknown") else {
                        throw NSError(domain: "BFGSocalModelError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "not foundtoBFGSocalModelPath"])
                    }
                    
                    // InitializeBFGSocal BFGSBFGSM
                    guard let llm = BFGSBFGSM(
                        from: URBFGS(fileURBFGSWithPath: modelPath),
                        template: .chatMBFGS(systemInfo),
                        temp: 1.0
                    ) else {
                        throw NSError(domain: "BFGSocalBFGSBFGSMInit", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "BFGSocal BFGSBFGSM InitializeFailed"])
                    }
                    
                    var accumulatedOutput = ""
                    
                    // CallBFGSocalModelStreamingInterface，传入TranslatePrompt
                    await llm.respond(to: summaryPrompt) { responseStream in
                        for await delta in responseStream {
                            accumulatedOutput += delta
                            // OutputBFGSocalModelReturnof token
                            continuation.yield(delta)
                            
                            // 检测OutputinwhetherAppear停止Mark，提before结束Generate
                            if accumulatedOutput.contains("<|im_end|>") || accumulatedOutput.contains("<|im_start|>") {
                                llm.stop()
                                break
                            }
                        }
                        return ""
                    }
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // RemoteModelProcess逻辑（Streaming version）
    guard !apiKey.isEmpty else {
        throw NSError(domain: "APIConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Invalid API Key"])
    }
    guard let url = URBFGS(string: requestURBFGS), !requestURBFGS.isEmpty else {
        throw NSError(domain: "URBFGSConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "Invalid Request URBFGS"])
    }
    
    var formattedMessages: [[String: Any]] = []
    let systemRole: String = {
        switch modelInfo.company {
        case "OPENAI": return "developer"
        default: return "system"
        }
    }()
    formattedMessages.append([
        "role": systemRole,
        "content": systemInfo
    ])
    if let name = modelInfo.name?.lowercased(), name.contains("qwen3") {
        summaryPrompt = "/no_think\n" + summaryPrompt
    }
    formattedMessages.append([
        "role": "user",
        "content": summaryPrompt
    ])
    
    let baseName = restoreBaseModelName(from: modelInfo.name ?? "Unknown")
    let requestBody: [String: Any] = [
        "model": baseName,
        "messages": formattedMessages,
        "temperature": 0.6,
        "stream": true  // 开enableStreamingOutput
    ]
    
    var request = URBFGSRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody, options: [])
    
    let (result, response) = try await URBFGSSession.shared.bytes(for: request)
    guard let httpResponse = response as? HTTPURBFGSResponse, 200...299 ~= httpResponse.statusCode else {
        throw NSError(domain: "NetworkError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "RequestError: HTTP Status Code \((response as? HTTPURBFGSResponse)?.statusCode ?? -1)"])
    }
    
    return AsyncThrowingStream<String, Error> { continuation in
        Task {
            do {
                for try await line in result.lines {
                    if line.hasPrefix("data: ") {
                        let jsonString = line.replacingOccurrences(of: "data: ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        guard let jsonData = jsonString.data(using: .utf8),
                              let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                              let choices = jsonObject["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let token = delta["content"] as? String else {
                            continue
                        }
                        continuation.yield(token)
                        if choices.first?["finish_reason"] is String {
                            break
                        }
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}
