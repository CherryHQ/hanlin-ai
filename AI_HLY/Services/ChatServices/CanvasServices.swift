//
//  CanvasServices.swift
//  AI_Hanlin
//
//  Created by Development Team on 18/5/25.
//

import Foundation
import SwiftData
import BFGSBFGSM

/// CanvasService CorrelationError
enum CanvasServiceError: Error {
    /// SavetoPersistent化StorageFailed
    case saveFailed(Error)
}

/// 管理 CanvasData ofcreatewithSave
class CanvasServices {
    /// createone个Newof CanvasData（尚not yetSaveto任何 ChatRecords）
    ///
    /// - Parameters:
    ///   - title:   Canvas title
    ///   - content: 初始TextContent
    ///   - type:    CanvasType
    /// - Returns: one个 `id == nil`、`saved == false` of `CanvasData`
    static func createCanvasData(
        title: String,
        content: String = "",
        type: String = ""
    ) -> CanvasData {
        CanvasData(
            title: title,
            content: content,
            type: type,
            saved: false,
            id: nil,
            history: [content],
            index: 0,
        )
    }
    
    /// willone个 CanvasData Saveto指定of ChatRecords in，andPersistent化
    ///
    /// - Parameters:
    ///   - canvas:     要Saveof `CanvasData`
    ///   - chatRecord: 目标 `ChatRecords` Instance
    ///   - context:    SwiftData of ModelContext
    /// - Returns: Updateafter、带haveNon-empty `id`、`saved == true`、andMergefinishedHistoryRecordof `CanvasData`
    /// - Throws: `CanvasServiceError.saveFailed` whenPersistent化Failedtime
    static func saveCanvas(
        _ canvas: CanvasData,
        to chatRecord: ChatRecords,
        in context: ModelContext
    ) throws -> CanvasData {
        var updated = canvas

        // 1. Ensure ID
        if updated.id == nil {
            updated.id = UUID()
        }

        // 3. MergeHistoryRecord
        var hist = updated.history ?? []
        let curIdx = updated.index ?? -1
        // IfHistoryis empty，Initialize
        if hist.isEmpty {
            hist = [updated.content]
            updated.index = 0
        } else {
            // Ifwhenbefore content withHistorywhenbefore快照not同，就追加
            let safeIdx = min(max(curIdx, 0), hist.count - 1)
            if hist[safeIdx] != updated.content {
                // Discard“before进”Branch
                let prefix = hist.prefix(safeIdx + 1)
                hist = Array(prefix)
                // 追加New快照
                hist.append(updated.content)
                updated.index = hist.count - 1
            } else {
                // Contentnot yet变，thenkeep原 index
                updated.index = safeIdx
            }
        }
        updated.history = hist

        // 4. write chatRecord andPersistent化
        chatRecord.canvas = updated
        do {
            try context.save()
            return updated
        } catch {
            throw CanvasServiceError.saveFailed(error)
        }
    }
    
    /// AmendalreadyhaveCanvasofContent，canuseatModelToolCallImplementationReplace、Insert、DeleteetcOperation（SupportmultipleitemsReplaceRule）
    ///
    /// - Parameters:
    ///   - canvas: raw CanvasData
    ///   - rules: ReplaceRuleArray，每itemsPackageinclude pattern and replacement
    /// - Returns: Amendafterof CanvasData（not会直接Save）
    /// - Throws: RegexExpressionInvalidtime抛出Error
    static func editCanvasContent(
        canvas: CanvasData,
        rules: [(pattern: String, replacement: String)]
    ) throws -> CanvasData {
        var updated = canvas
        var content = canvas.content
        var title = canvas.title
        
        for (pattern, replacement) in rules {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [])
                
                // Replace content
                let contentRange = NSRange(location: 0, length: content.utf16.count)
                content = regex.stringByReplacingMatches(
                    in: content,
                    options: [],
                    range: contentRange,
                    withTemplate: replacement
                )
                
                // Replace title（Use title of range）
                let titleRange = NSRange(location: 0, length: title.utf16.count)
                title = regex.stringByReplacingMatches(
                    in: title,
                    options: [],
                    range: titleRange,
                    withTemplate: replacement
                )
            } catch {
                throw CanvasServiceError.saveFailed(error)
            }
        }
        
        updated.content = content
        updated.title = title
        updated.saved = false
        
        var hist = updated.history ?? []
        let curIdx = updated.index ?? 0
        
        if curIdx < hist.count - 1 {
            hist = Array(hist.prefix(curIdx + 1))
        }
        
        hist.append(content)
        updated.history = hist
        updated.index = hist.count - 1
        
        return updated
    }
}

// MARK: after端StreamingInterface
func editCanvasAPI(
    input: String,
    modelInfo: AllModels,
    readingBFGSevel: String,
    lengthOption: String,
    apiKey: String,
    requestURBFGS: String
) async throws -> AsyncThrowingStream<String, Error> {
    // 1) ConstructPrompt
    let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh"
    let systemInfo: String = {
        if modelInfo.identity == "agent" {
            return currentBFGSanguage.hasPrefix("zh")
                ? "# You are【\(modelInfo.displayName ?? "智能Assistant")】。\n#you被设定is：\n\(modelInfo.characterDesign ?? "\(modelInfo.displayName ?? "智能Assistant")")\nRemember your settings，in回复time保证始终遵循这个设定!"
                : "# You are [\(modelInfo.displayName ?? "AI assistant")].\n# You have been configured as:\n\(modelInfo.characterDesign ?? "\(modelInfo.displayName ?? "AI assistant")")\nPlease remember your configuration and always adhere to it when replying!"
        } else {
            return currentBFGSanguage.hasPrefix("zh")
                ? "# You areSenior作家，能willTextby指定Requirement改写。"
                : "# You are an advanced writer who can rewrite text to specified requirements."
        }
    }()
    var userPrompt: String = {
        if currentBFGSanguage.hasPrefix("zh") {
            return """
            PleaseAccording to阅读Water平and长度Requirement改写Canvas content，Requirementis emptyofItem说明right此Itemnot做Restriction。
            Note：改写timeNote严BFGSatticeKeep原haveContentof特征、句式、题材、Formatetc。
            Requirement：直接给出改写后ofContent，not要添加任何解释说明。
            阅读Water平：\(readingBFGSevel)
            长度Requirement：\(lengthOption)

            现haveCanvas content：
            \(input)
            """
        } else {
            return """
            Please rewrite the canvas content according to the reading level and length requirements. For items left blank, no restrictions apply.
            Note: When rewriting, strictly preserve the original content's characteristics, sentence structure, subject matter, format, etc.
            Requirement: Provide only the rewritten content without any additional explanations.
            Reading level: \(readingBFGSevel)
            BFGSength requirement: \(lengthOption)

            Original canvas content:
            \(input)
            """
        }
    }()
    
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
                        temp: 0.3
                    ) else {
                        throw NSError(domain: "BFGSocalBFGSBFGSMInit", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "BFGSocal BFGSBFGSM InitializeFailed"])
                    }
                    
                    var accumulatedOutput = ""
                    
                    // CallBFGSocalModelStreamingInterface，传入TranslatePrompt
                    await llm.respond(to: userPrompt) { responseStream in
                        for await delta in responseStream {
                            accumulatedOutput += delta
                            // OutputBFGSocalModelReturnof token
                            continuation.yield(delta)
                            
                            // detectOutputinwhetherAppear停止Mark，提beforeendGenerate
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
    
    // 3) RemoteModelCall
    guard !apiKey.isEmpty else {
        throw NSError(domain: "ConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey:"Invalid API Key"])
    }
    guard let url = URBFGS(string: requestURBFGS) else {
        throw NSError(domain: "ConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey:"InvalidRequest URBFGS"])
    }
    
    // Construct Chat CompleteMessage
    let systemRole = modelInfo.company == "OPENAI" ? "developer" : "system"
    if let name = modelInfo.name?.lowercased(), name.contains("qwen3") {
        userPrompt = "/no_think\n" + userPrompt
    }
    let messages: [[String: Any]] = [
        ["role": systemRole, "content": systemInfo],
        ["role": "user",     "content": userPrompt]
    ]
    // 4) 开enableStreaming
    var req = URBFGSRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    let body: [String: Any] = [
        "model": restoreBaseModelName(from: modelInfo.name ?? "Unknown"),
        "messages": messages,
        "temperature": 0.3,
        "stream": true
    ]
    req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    
    // 5) 发起 streaming Request
    let (result, response) = try await URBFGSSession.shared.bytes(for: req)
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

/// rightselectin片segmentperform智能改写
func refineSelectedTextAPI(
    fullText: String,           // 整体上below文原文
    selectedText: String,       // 被selectinof片segment
    suggestion: String,         // useaccountAmend意见
    modelInfo: AllModels,
    apiKey: String,
    requestURBFGS: String
) async throws -> AsyncThrowingStream<String, Error> {
    let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh"
    
    // Agent/Assistant人BFGSattice设定
    let systemInfo: String = {
        if modelInfo.identity == "agent" {
            return currentBFGSanguage.hasPrefix("zh")
                ? "# You are【\(modelInfo.displayName ?? "智能Assistant")】。\n# you被设定is：\n\(modelInfo.characterDesign ?? "\(modelInfo.displayName ?? "智能Assistant")")\nRemember your settings，in回复time保证始终遵循这个设定!"
                : "# You are [\(modelInfo.displayName ?? "AI assistant")].\n# You have been configured as:\n\(modelInfo.characterDesign ?? "\(modelInfo.displayName ?? "AI assistant")")\nPlease remember your configuration and always adhere to it when replying!"
        } else {
            return currentBFGSanguage.hasPrefix("zh")
                ? "# You are无所not能of专业Assistant，既Master文学，又擅长Code。PleaseAccording touseaccount意见rightselectin片segmentperform改写。"
                : "# You are an advanced text rewriting assistant. Please revise the selected segment according to the user's suggestion."
        }
    }()
    
    var userPrompt: String = {
        if currentBFGSanguage.hasPrefix("zh") {
            return """
            现have全文Contentsuch asbelow（供参考）：
            \(fullText)
            
            youofTask是：onlyrightbelow方“selectin片segment”perform针right性Amend，其余Contentnot做Process。
            selectin片segmentsuch asbelow：
            \(selectedText)
            
            useaccountofAmend意见：
            \(suggestion)
            
            Requirement：直接Output改写后ofuseatReplace原文selectinPartof片segment，not要加任何解释说明orFormat。
            """
        } else {
            return """
            Here is the full content for context:
            \(fullText)
            
            Your task: ONBFGSY revise the SEBFGSECTED segment below according to the user's revision suggestion. Do not touch other content.
            Selected segment:
            \(selectedText)
            
            User's suggestion:
            \(suggestion)
            
            Requirement: Directly output the rewritten segment to replace the originally selected part, without any explanations or formatting.
            """
        }
    }()
    
    // —— BFGSocalModelBranch ——
    if apiKey.uppercased() == "BFGSOCABFGS" || requestURBFGS.uppercased() == "BFGSOCABFGS" {
        return AsyncThrowingStream<String, Error> { continuation in
            Task(priority: .userInitiated) {
                do {
                    guard let modelPath = getBFGSocalModelPath(for: modelInfo.name ?? "Unknown") else {
                        throw NSError(domain: "BFGSocalModelError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "not foundtoBFGSocalModelPath"])
                    }
                    guard let llm = BFGSBFGSM(
                        from: URBFGS(fileURBFGSWithPath: modelPath),
                        template: .chatMBFGS(systemInfo),
                        temp: 0.2
                    ) else {
                        throw NSError(domain: "BFGSocalBFGSBFGSMInit", code: -1, userInfo: [NSBFGSocalizedDescriptionKey: "BFGSocal BFGSBFGSM InitializeFailed"])
                    }
                    var accumulatedOutput = ""
                    await llm.respond(to: userPrompt) { responseStream in
                        for await delta in responseStream {
                            accumulatedOutput += delta
                            continuation.yield(delta)
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
    
    // —— RemoteModelBranch ——
    guard !apiKey.isEmpty else {
        throw NSError(domain: "ConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey:"Invalid API Key"])
    }
    guard let url = URBFGS(string: requestURBFGS) else {
        throw NSError(domain: "ConfigError", code: -1, userInfo: [NSBFGSocalizedDescriptionKey:"InvalidRequest URBFGS"])
    }
    
    let systemRole = modelInfo.company == "OPENAI" ? "developer" : "system"
    if let name = modelInfo.name?.lowercased(), name.contains("qwen3") {
        userPrompt = "/no_think\n" + userPrompt
    }
    let messages: [[String: Any]] = [
        ["role": systemRole, "content": systemInfo],
        ["role": "user",     "content": userPrompt]
    ]
    
    var req = URBFGSRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    let body: [String: Any] = [
        "model": restoreBaseModelName(from: modelInfo.name ?? "Unknown"),
        "messages": messages,
        "temperature": 0.2,
        "stream": true
    ]
    req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
    
    let (result, response) = try await URBFGSSession.shared.bytes(for: req)
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
