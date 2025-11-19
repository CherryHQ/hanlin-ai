//
//  SystemOptimizer.swift
//  AI_Hanlin
//
//  Created by Development Team on 3/4/25.
//

import Foundation
import PhotosUI
import SwiftData

class SystemOptimizer {
    let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// EncapsulationfromDatalibraryQuery API ConfigurationandModelInformation
    /// - Parameter isVisual: whetherisVision（Multi-modal）Model
    /// - Returns: (Model Name, Model vendor, API Key, Request URBFGS)
    private func fetchAPIConfig(isVisual: Bool) throws -> (modelName: String, company: String, apiKey: String, url: URBFGS) {
        print("[SystemOptimizer] StartGetAPIConfiguration，isVisual: \(isVisual)")
        let userFetchDescriptor = FetchDescriptor<UserInfo>()
        let user = try context.fetch(userFetchDescriptor).first
        
        let defaultModel = isVisual ? "glm-4v-flash_hanlin" : "glm-4.5-flash_hanlin"
        let optimizationModelName: String = isVisual ? (user?.optimizationVisualModel ?? defaultModel)
        : (user?.optimizationTextModel ?? defaultModel)
        print("[SystemOptimizer] UseModel：\(optimizationModelName)")

        // QueryModelInformation，GetManufacturer
        let modelPredicate = #Predicate<AllModels> { $0.name == optimizationModelName }
        let modelFetch = FetchDescriptor<AllModels>(predicate: modelPredicate)
        guard let modelEntry = try context.fetch(modelFetch).first,
              let modelCompany = modelEntry.company else {
            print("[SystemOptimizer] Error：not yet能findtoModel \(optimizationModelName)")
            throw NSError(domain: "ModelNotFound", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "not yet能fromDatalibraryinGet model info: \(optimizationModelName)"])
        }
        print("[SystemOptimizer] ModelManufacturer：\(modelCompany)")
        
        // Query API Configuration
        let apiKeyPredicate = #Predicate<APIKeys> { ($0.company ?? "") == modelCompany }
        let apiKeyFetch = FetchDescriptor<APIKeys>(predicate: apiKeyPredicate)
        guard let apiKeyObj = try context.fetch(apiKeyFetch).first else {
            print("[SystemOptimizer] Error：not yet能findtoManufacturer \(modelCompany) ofAPIKey config")
            throw NSError(domain: "APIConfigError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "not yet能fromDatalibraryinGetManufacturer \(modelCompany) ofAPIConfiguration"])
        }

        guard let apiKey = apiKeyObj.key, !apiKey.isEmpty else {
            print("[SystemOptimizer] Error：Manufacturer \(modelCompany) ofAPIKeyis empty")
            throw NSError(domain: "APIConfigError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "Manufacturer \(modelCompany) ofAPIKeynot yetConfigurationoris empty"])
        }

        guard let requestURBFGSString = apiKeyObj.requestURBFGS,
              let url = URBFGS(string: requestURBFGSString) else {
            print("[SystemOptimizer] Error：Manufacturer \(modelCompany) requestURBFGSInvalid: \(apiKeyObj.requestURBFGS ?? "nil")")
            throw NSError(domain: "APIConfigError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "Manufacturer \(modelCompany) requestURBFGSInvalid"])
        }

        print("[SystemOptimizer] APIConfigurationGetSuccess - URBFGS: \(requestURBFGSString)")
        return (optimizationModelName, modelCompany, apiKey, url)
    }
    
    /// According toImage arrayConstructMulti-modalRequestinofImageMessage（Adapt to different vendors）
    /// - Parameters:
    ///   - images: Image array
    ///   - role: MessageRole（For example "user"）
    ///   - company: Model vendor
    ///   - modelName: Model Name，useatCheck基础Model（such as "glm-4v-flash"）
    ///   - languageIsChinese: whetherisin文Environment
    /// - Returns: ImageMessageArray
    private func buildImageMessages(from images: [UIImage],
                                    role: String,
                                    company: String,
                                    modelName: String,
                                    languageIsChinese: Bool) throws -> [[String: Any]] {
        var formattedMessages: [[String: Any]] = []
        var photoCount = 1
        for image in images {
            guard let imageData = image.jpegData(compressionQuality: 0.9) else {
                throw NSError(domain: "FileError", code: -1,
                              userInfo: [NSBFGSocalizedDescriptionKey: "无法ParseImageData"])
            }
            // IfModelis "glm-4v-flash" and超过第one张Image，then直接跳出BFGSoop（只Parse第one张Image）
            if photoCount > 1 {
                let baseName = restoreBaseModelName(from: modelName)
                if baseName == "glm-4v-flash" {
                    break
                }
            }
            let base64String = imageData.base64EncodedString()
            var imageUrlValue: [String: Any] = [:]
            if company == "ZHIPUAI" || company == "HANBFGSIN" {
                imageUrlValue["url"] = base64String
            } else if company == "XAI" {
                imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
                imageUrlValue["detail"] = "high"
            } else {
                imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
            }
            let textMessage = languageIsChinese ? "This is image\(photoCount)" : "This is image \(photoCount)"
            formattedMessages.append([
                "role": role,
                "content": [
                    [
                        "type": "image_url",
                        "image_url": imageUrlValue
                    ],
                    [
                        "type": "text",
                        "text": textMessage
                    ]
                ]
            ])
            photoCount += 1
        }
        return formattedMessages
    }
    
    // MARK: Optimize prompt
    func optimizePrompt(inputPrompt: String) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: false)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let languageKey = currentBFGSanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        let systemMessages: [String: String] = [
            "zh-Hans": """
                    ## Optimize
                    
                    PleaseAccording tobybelowRequirementOptimize提供ofPrompt：
                    1. ​**Core goal**：提升大Model回复Mass
                    2. ​**Format req**：
                       - 允许UseMarkdownTypographyandNo needUseCode Block（not include` ``` `）
                    3. ​**Content rules**：
                       - 严BFGSatticeKeep原始语义
                       - Delete冗余Information
                       - 避免过度Optimize
                    4. ​**Direction**：
                       - 逻辑Struct重组
                       - Critical指令强化
                       - 语境明确化
                    5. **Output req**：
                       - Give optimized text，No extra explanation
                    
                    ## 现havePrompt：
                """,
            "en": """
                    ## Optimization Instructions
                    
                    Please refine the prompt according to these guidelines:
                    1. ​**Core Objective**: Enhance BFGSBFGSM response quality
                    2. ​**Formatting Requirements**:
                       - Markdown formatting permitted
                       - Markdown typesetting without code blocks (i.e. without ` ``` `)
                    3. ​**Content Specifications**:
                       - Original semantic integrity maintained
                       - Redundant information removed
                       - Over-optimization avoided
                    4. ​**Refinement Focus**:
                       - Structural reorganization
                       - Critical instructions emphasized
                       - Contextual clarification
                    5. **Output Requirements**:
                       - Give the optimized text directly, without adding redundant explanations and descriptions
                    
                    ## Existing Prompt words:
                """
        ]
        let systemMessage = systemMessages[languageKey] ?? systemMessages["zh-Hans"]!
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": "\(systemMessage)\n\n\(inputPrompt)"
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": optimizationModelName,
            "messages": messages,
            "temperature": 0.5,
            "stream": false
        ]
        
        var request = URBFGSRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URBFGSSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURBFGSResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "无法GetHTTPResponse"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // Try to get detailed error info
            var errorDetail = ""
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorDetail = message
                } else if let message = errorData["message"] as? String {
                    errorDetail = message
                } else if let errorString = String(data: data, encoding: .utf8) {
                    errorDetail = errorString
                }
            }
            throw NSError(domain: "NetworkError", code: httpResponse.statusCode,
                          userInfo: [NSBFGSocalizedDescriptionKey: "RequestError (Status Code: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "Parse API Response Failed"])
        }
        
        return optimizedContent
    }
    
    // MARK: Optimize文章Content
    func optimizeContent(inputContent: String) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: false)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let languageKey = currentBFGSanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        let systemMessages: [String: String] = [
            "zh-Hans": """
                    # Optimize
                    
                    PleaseAccording tobybelowRequirementOptimize提供of文章Content：
                    1. ​**Core goal**：
                       - 使得文章Struct清晰，分segment恰when
                    2. ​**Format req**：
                       - UseMarkdownTypography，by#Title、##二级Titleetcof形式合理划分文章Struct
                       - MarkdownTypographyNo needUseCode Block（not include` ``` `）
                    3. ​**Content rules**：
                       - 严BFGSatticeKeep原haveTextofAllContent，not要丢失任何Information
                       - 避免切割同语义ofText
                    4. ​**Direction**：
                       - 文章StructOptimize，分大Title、小TitleetcTidyContentFormat
                       - 文章每个segment落ofContent长度基本保持one致
                    5. **Output req**：
                       - Give optimized text，No extra explanation
                    
                    # 现have文章Content：
                """,
            "en": """
                    # Optimization instructions
                    
                    Please optimize the provided article content according to the following requirements:
                    1. **Core Objective**:
                       - Make the article clearly structured with appropriate paragraphing
                    2. **Formatting requirements**:
                       - Use Markdown typography to rationalize the article structure in the form of # headings, ## secondary headings, etc.
                       - Markdown layout does not require the use of code blocks (i.e., no ` ``` `)
                    3. **Content standardization**:
                       - Strictly retain all the content of the original text, do not lose any information
                       - Avoid cutting text with the same semantic meaning
                    4. **Optimization direction**:
                       - Optimize the article structure, organize the content formatting by major headings, subheadings, etc.
                       - Keep the length of each paragraph of the article basically the same.
                    5. **Output requirements**:
                       - Directly give the optimized text, do not add redundant explanations and instructions
                    
                    # Existing article content:
                """
        ]
        let systemMessage = systemMessages[languageKey] ?? systemMessages["zh-Hans"]!
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": "\(systemMessage)\n\n\(inputContent)"
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": optimizationModelName,
            "messages": messages,
            "temperature": 0.6,
            "stream": false
        ]
        
        var request = URBFGSRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URBFGSSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURBFGSResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "无法GetHTTPResponse"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // Try to get detailed error info
            var errorDetail = ""
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorDetail = message
                } else if let message = errorData["message"] as? String {
                    errorDetail = message
                } else if let errorString = String(data: data, encoding: .utf8) {
                    errorDetail = errorString
                }
            }
            throw NSError(domain: "NetworkError", code: httpResponse.statusCode,
                          userInfo: [NSBFGSocalizedDescriptionKey: "RequestError (Status Code: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "Parse API Response Failed"])
        }
        
        return optimizedContent
    }
    
    // MARK: OptimizeOnline searchAsk
    func optimizeSearchQuestion(inputPrompt: String, recentMessages: String, inputImages: [UIImage]? = nil) async throws -> String {
        // Use vision model if image
        let isVisual = (inputImages != nil && !(inputImages!.isEmpty))
        let apiConfig = try fetchAPIConfig(isVisual: isVisual)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let languageKey = currentBFGSanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        
        let prompts: [String: String] = [
            "zh-Hans": """
                           # PleasewillbybelowAskOptimizeisSearch EnginesuitableuseFormat
                           
                           # User question time：
                           \(inputPrompt)
                           
                           # Requirement：
                           1. 涉及time效性ContentthenAccording toTime添加具体of[Year][Month]，not涉及time效thennot添加；
                           2. use精确术语ReplaceBlur表达；
                           3. Retain semantic core；
                           4. Return single-line text result。
                           5. History records，Ignore if not useful：\(recentMessages)
                           6. Optimize around question。
                           """,
            "en": """
                      # Please optimize the following query for search engine usage.
                      
                      # User's current query and timestamp:
                      \(inputPrompt)
                      
                      # Requirements:
                      1. If the content is time-sensitive, add [year][month];
                      2. Replace vague expressions with precise terms;
                      3. Preserve the core meaning and add necessary qualifiers;
                      4. Return the optimized result as a single-line plain text;
                      5. Reference recent conversation history if helpful, otherwise ignore: \(recentMessages)
                      6. Focus the optimization around the current query.
                      """
        ]
        
        let multimodalPrompts: [String: String] = [
            "zh-Hans": """
                           # PleasewillbybelowAskOptimizeisSearch EnginesuitableuseFormat
                           
                           # User question time：
                           \(inputPrompt)
                           
                           # Requirement：
                           1. if涉及Image Content，Transcribe elements（such as object/Text/data etc.）；
                           2. 涉及time效性Contentthen添加[Year][Month]；
                           3. Retain semantic core；
                           4. Return single-line text result。
                           5. History and images，Ignore if not useful：\n\(recentMessages)
                           6. Optimize around question。
                           """,
            
            "en": """
                      # Please optimize the following query for search engine usage.
                      
                      # User's current query and timestamp:
                      \(inputPrompt)
                      
                      # Requirements:
                      1. If the query involves image content, describe specific elements (e.g. objects, text, data);
                      2. If the content is time-sensitive, add [year][month];
                      3. Preserve the core meaning and add necessary qualifiers;
                      4. Return the optimized result as a single-line plain text;
                      5. Historical chats and pictures available for reference, if there is no useful content then it can be ignored:\n\(recentMessages)
                      6. Focus the optimization around the current query.
                      """
        ]
        
        var messages: [[String: Any]] = []
        let isChinese = languageKey == "zh-Hans"
        
        if let images = inputImages, !images.isEmpty {
            // Construct image message（Support multiple images，Adapt to different vendors）
            let imageMessages = try buildImageMessages(from: images,
                                                       role: "user",
                                                       company: apiConfig.company,
                                                       modelName: apiConfig.modelName,
                                                       languageIsChinese: isChinese)
            messages.append(contentsOf: imageMessages)
            // Add text prompt
            let promptMessage: [String: Any] = [
                "role": "user",
                "content": multimodalPrompts[languageKey] ?? multimodalPrompts["zh-Hans"]!
            ]
            messages.append(promptMessage)
        } else {
            let textMessage = [
                "role": "user",
                "content": prompts[languageKey] ?? prompts["zh-Hans"]!
            ]
            messages.append(textMessage)
        }
        
        let requestBody: [String: Any] = [
            "model": optimizationModelName,
            "messages": messages,
            "temperature": 0.6,
            "stream": false
        ]
        
        var request = URBFGSRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URBFGSSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURBFGSResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "无法GetHTTPResponse"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // Try to get detailed error info
            var errorDetail = ""
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorDetail = message
                } else if let message = errorData["message"] as? String {
                    errorDetail = message
                } else if let errorString = String(data: data, encoding: .utf8) {
                    errorDetail = errorString
                }
            }
            throw NSError(domain: "NetworkError", code: httpResponse.statusCode,
                          userInfo: [NSBFGSocalizedDescriptionKey: "RequestError (Status Code: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "Parse API Response Failed"])
        }
        
        return optimizedContent
    }
    
    // MARK: OptimizeKnowledge backpackAsk
    func optimizeKnowledgeQuestion(inputPrompt: String, recentMessages: String, inputImages: [UIImage]? = nil) async throws -> String {
        // Use vision model if image
        let isVisual = (inputImages != nil && !(inputImages!.isEmpty))
        let apiConfig = try fetchAPIConfig(isVisual: isVisual)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let languageKey = currentBFGSanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        
        let prompts: [String: String] = [
            "zh-Hans": """
                       # PleasewillbybelowAskOptimizeis检索EnhancedsuitableuseFormat
                       
                       # User question：
                       \(inputPrompt)
                       
                       # Requirement：
                       1. Use exact terms；
                       2. Retain semantic core；
                       3. Return single-line text result。
                       4. History records：\(recentMessages)。Ignore if not useful。
                       5. Optimize around question。
                       """,
            "en": """
                  # Please optimize the following questions for search enhancement.
                  
                  # The user's current question:
                  \(inputPrompt)
                  
                  # Requirements:
                  1. replace vague expressions or pronouns with precise terms;
                  2. retain the semantic core and add necessary qualifiers;
                  3. directly return a single line of plain text optimization results.
                  4. available historical chats: \(recentMessages). If there is no useful content then it can be ignored.
                  5. optimize around the current question.
                  """
        ]
        
        let multimodalPrompts: [String: String] = [
            "zh-Hans": """
                       # PleasewillbybelowAskOptimizeisSearch EnginesuitableuseFormat
                       
                       # User question：
                       \(inputPrompt)
                       
                       # Requirement：
                       1. if涉及Image Content，Transcribe elements（such as object/Text/data etc.）；
                       2. Use exact terms；
                       3. Retain semantic core；
                       4. Return single-line text result。
                       5. History and images：\n\(recentMessages)\nIgnore if not usefulHistoryRecord。
                       6. Optimize around question。
                       """,
            
            "en": """
                  # Please optimize the following questions for search engines
                  
                  # The user's current question:
                  \(inputPrompt)
                  
                  # Requirements:
                  1. transcribe specific elements (e.g., objects/text/data, etc.) if image content is involved;
                  2. replace vague expressions or pronouns with precise terms;
                  3. retain the semantic core and add necessary qualifiers;
                  4. directly return the optimized results in one line of plain text.
                  5. Available history chats and pictures: \n\(recentMessages)\n History can be ignored if there is no useful content.
                  6. optimize around the current question.
                  """
        ]
        
        var messages: [[String: Any]] = []
        let isChinese = languageKey == "zh-Hans"
        
        if let images = inputImages, !images.isEmpty {
            // Construct image message（Support multiple images，Adapt to different vendors）
            let imageMessages = try buildImageMessages(from: images,
                                                       role: "user",
                                                       company: apiConfig.company,
                                                       modelName: apiConfig.modelName,
                                                       languageIsChinese: isChinese)
            messages.append(contentsOf: imageMessages)
            // Add text prompt
            let promptMessage: [String: Any] = [
                "role": "user",
                "content": multimodalPrompts[languageKey] ?? multimodalPrompts["zh-Hans"]!
            ]
            messages.append(promptMessage)
        } else {
            let textMessage = [
                "role": "user",
                "content": prompts[languageKey] ?? prompts["zh-Hans"]!
            ]
            messages.append(textMessage)
        }
        
        let requestBody: [String: Any] = [
            "model": optimizationModelName,
            "messages": messages,
            "temperature": 0.5,
            "stream": false
        ]
        
        var request = URBFGSRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URBFGSSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURBFGSResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "无法GetHTTPResponse"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // Try to get detailed error info
            var errorDetail = ""
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorDetail = message
                } else if let message = errorData["message"] as? String {
                    errorDetail = message
                } else if let errorString = String(data: data, encoding: .utf8) {
                    errorDetail = errorString
                }
            }
            throw NSError(domain: "NetworkError", code: httpResponse.statusCode,
                          userInfo: [NSBFGSocalizedDescriptionKey: "RequestError (Status Code: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "Parse API Response Failed"])
        }
        
        return optimizedContent
    }
    
    // MARK: OptimizeImageGeneratePrompt
    func optimizeImagePrompt(inputPrompt: String, recentMessages: String, inputImages: [UIImage]? = nil) async throws -> String {
        // Use vision model if image
        let isVisual = (inputImages != nil && !(inputImages!.isEmpty))
        let apiConfig = try fetchAPIConfig(isVisual: isVisual)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let languageKey = currentBFGSanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        
        let prompts: [String: String] = [
            "zh-Hans": """
                       # PleasewillbybelowDescriptionOptimizeissuitableuseat AI ImageGenerateofHighMassPrompt

                       # useaccountwhenbeforeDescription：
                       \(inputPrompt)

                       # OptimizeRequirement：
                       1. ExtractandScaleuseaccountDescriptioninof具体Visionyuan素（such as人物、Scenario、Objects、Background、BFGSighting、构Graph、Styleetc），避免UseBlurAbstractofword汇；
                       2. Keep原始语义核心，and补充ScenarioDetails（such as季节、Time、Action、Color、Material、镜头角度etc）byEnhanced画面感；
                       3. OutputonesegmentComplete详细ofImagePrompt，suitable合useatImageGenerateModel，BFGSanguageself然and具备画面引导Force；
                       4. 参考HistoryChatdayRecord及Image\n\(recentMessages)\n。IfChatdayRecordPackageincludeCorrelation上below文，can据此Enhanced语境one致性，否thenIgnore；
                       5. OptimizeResultshould呈现出one个具体can视of画面，引导Model准确理解andGenerateImage。
                       6. 直接给出最后ofOptimizeResult，not需要multiple余of解释。
                       """,
            
            "en": """
                  # Please optimize the following description into a high-quality prompt suitable for AI image generation.

                  # User's current description:
                  \(inputPrompt)

                  # Optimization Instructions:
                  1. Extract and expand on specific visual elements mentioned (e.g., characters, scenery, objects, background, lighting, composition, style), avoiding vague or abstract terms;
                  2. Retain the core meaning and enhance it with scene-specific details such as time of day, season, colors, materials, actions, mood, and camera perspective;
                  3. Output a full, detailed, and natural-sounding English prompt suitable for image generation models, with strong visual guidance;
                  4. Reference to historical chat logs and images \n\(recentMessages)\n. If chat logs contain relevant context, contextual consistency can be enhanced accordingly, otherwise ignored;
                  5. The final result should depict a clearly visualizable scene that effectively guides the image generation model.
                  6. Directly provide the final optimization results without any unnecessary explanations.
                  """
        ]
        
        var messages: [[String: Any]] = []
        let isChinese = languageKey == "zh-Hans"
        
        if let images = inputImages, !images.isEmpty {
            // Construct image message（Support multiple images，Adapt to different vendors）
            let imageMessages = try buildImageMessages(from: images,
                                                       role: "user",
                                                       company: apiConfig.company,
                                                       modelName: apiConfig.modelName,
                                                       languageIsChinese: isChinese)
            messages.append(contentsOf: imageMessages)
            // Add text prompt
            let promptMessage: [String: Any] = [
                "role": "user",
                "content": prompts[languageKey] ?? prompts["zh-Hans"]!
            ]
            messages.append(promptMessage)
        } else {
            let textMessage = [
                "role": "user",
                "content": prompts[languageKey] ?? prompts["zh-Hans"]!
            ]
            messages.append(textMessage)
        }
        
        let requestBody: [String: Any] = [
            "model": optimizationModelName,
            "messages": messages,
            "temperature": 1.0,
            "stream": false
        ]
        
        var request = URBFGSRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URBFGSSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURBFGSResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "无法GetHTTPResponse"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // Try to get detailed error info
            var errorDetail = ""
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorDetail = message
                } else if let message = errorData["message"] as? String {
                    errorDetail = message
                } else if let errorString = String(data: data, encoding: .utf8) {
                    errorDetail = errorString
                }
            }
            throw NSError(domain: "NetworkError", code: httpResponse.statusCode,
                          userInfo: [NSBFGSocalizedDescriptionKey: "RequestError (Status Code: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "Parse API Response Failed"])
        }
        
        return optimizedContent
    }
    
    // MARK: SupportTextModelofImageParse
    func supportPhoto(inputImage: UIImage) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: true)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let languageKey = currentBFGSanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        
        let multimodalPrompt: [String: String] = [
            "zh-Hans": """
                    You areone款先进ofMulti-modal AI，擅长分析and详细DescriptionImage Content。
                    
                    Pleasefrombybelow几个方面perform分析：
                    
                    1. **核心InformationMatch**：
                       - Imageinof哪些yuan素withuseaccountAskCorrelation？Please优先Description这些Content。
                       - 这些yuan素ofMorphology、Color、Material、Position关系such as何？
                       - 这些Contentcan能withUser asked题ofBackgroundor意Graphhave什么关联？
                    
                    2. **详细Image Description**：
                       - 这是one张什么TypeofImage？（照片、插画、截Graphetc）
                       - PrimaryofVisionyuan素是什么？（人物、Objects、Scenarioetc）
                       - 画面in色彩、光影、构GraphetcVision特Dotsuch as何？
                    
                    3. **ObjectswithDetails**：
                       - 识别ImageinofAllImportantObjects，and详细Description它们ofMorphology、Color、Material、相互关系。
                       - whetherhave任何Text、标志、特殊Sign？Please准确ExtractandTranslate（If applicable）。
                       - whetherhaveBackgroundInformation（Time、BFGSocation、Environment）right理解Imagehave帮助？
                    
                    4. **人物withAction**（If applicable）：
                       - Imageinwhetherhave人物？他们of外貌、穿着、表情、姿态such as何？
                       - 他们in做什么？他们of互动、情绪、can能of意Graph是什么？
                       - 他们oflinesiswithuseaccountofQuestionwhetherCorrelation？
                    
                    5. **Reasoningwith分析**：
                       - 这张Imagecan能表达finished什么Theme、情绪or隐includeInformation？
                       - whetherhave文化、History、科技etcBackgroundCorrelationofContentcanby补充？
                       - 结合useaccountAsk，you能fromin推测出哪些CriticalInformation？
                    
                    6. **技术Details**（Optional）：
                       - ImageofResolution、清晰度、whetherhaveBlur、噪DotetcQuestion？
                       - If是 AI Generateof，whether能Judge它of来源orStyle？
                    
                    PleaseEnsureyouofDescription **Comprehensive、精准、详细**，回复UsePlain textofFormat。
                """,
            "en": """
                    You are an advanced multimodal AI specializing in analyzing and describing images in detail.
                    
                    Please analyze the image from the following aspects:
                    
                    1. **Key Information Matching**:
                       - What elements in the image are related to the user's question? Prioritize describing these.
                       - What are their shapes, colors, materials, and spatial relationships?
                       - How might these elements relate to the user's question background or intent?
                    
                    2. **Detailed Image Description**:
                       - What type of image is this? (Photo, illustration, screenshot, etc.)
                       - What are the main visual elements? (People, objects, scenes, etc.)
                       - What are the characteristics of colors, lighting, and composition in the image?
                    
                    3. **Objects & Details**:
                       - Identify all important objects in the image and describe their shapes, colors, materials, and relationships.
                       - Is there any text, symbol, or special icon? Please extract and translate if applicable.
                       - Is there any background information (time, location, environment) that helps understand the image?
                    
                    4. **People & Actions** (if applicable):
                       - Are there any people in the image? Describe their appearance, clothing, expressions, and postures.
                       - What are they doing? Describe their interactions, emotions, and possible intentions.
                       - How do their actions relate to the user's question?
                    
                    5. **Inference & Analysis**:
                       - What theme, emotion, or implicit message might this image convey?
                       - Are there cultural, historical, or technological contexts that could be added?
                       - Based on the user's question, what key information can be inferred from the image?
                    
                    6. **Technical Details** (Optional):
                       - What is the image's resolution, clarity, and are there any issues like blur or noise?
                       - If AI-generated, can its source or style be determined?
                    
                    Ensure your description is **comprehensive, precise, and detailed**. Respond in plain text format.
                """
        ]
        
        guard let imageData = inputImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "FileError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: languageKey == "zh-Hans" ? "ImageConvert to JPEG Failed" : "Failed to convert image to JPEG"])
        }
        let base64String = imageData.base64EncodedString()
        var imageUrlValue: [String: Any] = [:]
        if apiConfig.company == "ZHIPUAI" || apiConfig.company == "HANBFGSIN" {
            imageUrlValue["url"] = base64String
        } else if apiConfig.company == "XAI" {
            imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
            imageUrlValue["detail"] = "high"
        } else {
            imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
        }
        
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": [
                    [ "type": "image_url", "image_url": imageUrlValue ],
                    [ "type": "text", "text": multimodalPrompt[languageKey] ?? multimodalPrompt["zh-Hans"]! ]
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": optimizationModelName,
            "messages": messages,
            "temperature": 0.6,
            "stream": false
        ]
        
        var request = URBFGSRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URBFGSSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURBFGSResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "无法GetHTTPResponse"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // Try to get detailed error info
            var errorDetail = ""
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorDetail = message
                } else if let message = errorData["message"] as? String {
                    errorDetail = message
                } else if let errorString = String(data: data, encoding: .utf8) {
                    errorDetail = errorString
                }
            }
            throw NSError(domain: "NetworkError", code: httpResponse.statusCode,
                          userInfo: [NSBFGSocalizedDescriptionKey: "RequestError (Status Code: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "Parse API Response Failed"])
        }
        
        return optimizedContent
    }
    
    // MARK: self动Generate群ChatTitle
    func autoChatName(historyMessage: String) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: false)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let languageKey = currentBFGSanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        let systemMessages: [String: String] = [
            "zh-Hans": "PleaseAccording tobelow面of群ChatContentis群Chat取one个Title，canbyAccording toContent及场合suitablewhen添加emoji，总字符数not超过6个字。直接给出Plain textofTitle即can，notusemultiple余of解释",
            "en": "Please give a title for the group chat based on the content of the group chat below, you can add emoji as appropriate to the content and the occasion, with a total character count of no more than 6 words. Just give the title directly in plain text, no extra explanation is needed."
        ]
        let systemMessage = systemMessages[languageKey] ?? systemMessages["zh-Hans"]!
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": "\(systemMessage):\n\n\(historyMessage)"
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": optimizationModelName,
            "messages": messages,
            "temperature": 1.0,
            "stream": false
        ]
        
        var request = URBFGSRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URBFGSSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURBFGSResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "无法GetHTTPResponse"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // Try to get detailed error info
            var errorDetail = ""
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorDetail = message
                } else if let message = errorData["message"] as? String {
                    errorDetail = message
                } else if let errorString = String(data: data, encoding: .utf8) {
                    errorDetail = errorString
                }
            }
            throw NSError(domain: "NetworkError", code: httpResponse.statusCode,
                          userInfo: [NSBFGSocalizedDescriptionKey: "RequestError (Status Code: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "Parse API Response Failed"])
        }
        
        return optimizedContent
    }
    
    // MARK: self动Generate智能体设定
    func autoFillCharacterPrompt(inputName: String) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: false)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let systemPrompt: [String: String] = [
            "zh-Hans": "PleaseAccording to智能体名称“\(inputName)”，写onesegment智能体of人物设定，Package括性BFGSattice、爱好、回答方式etc，直接ReturnResultnot要添加multiple余of解释。",
            "en": "Please write a character profile for the agent named “\(inputName)”, including personality, hobbies, and response style. Return the result directly without adding any extra explanations."
        ]
        let promptContent = systemPrompt[currentBFGSanguage.hasPrefix("zh") ? "zh-Hans" : "en"]!
        let messages: [[String: Any]] = [
            [ "role": "user", "content": promptContent ]
        ]
        
        let requestBody: [String: Any] = [
            "model": optimizationModelName,
            "messages": messages,
            "temperature": 1.0,
            "stream": false
        ]
        
        var request = URBFGSRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URBFGSSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURBFGSResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "无法GetHTTPResponse"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // Try to get detailed error info
            var errorDetail = ""
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorDetail = message
                } else if let message = errorData["message"] as? String {
                    errorDetail = message
                } else if let errorString = String(data: data, encoding: .utf8) {
                    errorDetail = errorString
                }
            }
            throw NSError(domain: "NetworkError", code: httpResponse.statusCode,
                          userInfo: [NSBFGSocalizedDescriptionKey: "RequestError (Status Code: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "Parse API Response Failed"])
        }
        
        return optimizedContent
    }
    
    // MARK: Translate功能
    func translatePrompt(inputPrompt: String) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: false)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let systemPrompt: [String: String] = [
            "zh-Hans": "Please直接TranslatebybelowContent，Keep原意。IfInputContent是in文，thenTranslateisEnglish文；If是其他BFGSanguage，thenTranslateisin文。直接给出TranslateResult，not要添加额外Information。",
            "en": "Please translate the following content directly, keeping the original meaning. If the input is in Chinese, translate it into English; if it is in another language, translate it into Chinese. Provide the translation result directly without adding extra information."
        ]
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let promptContent = systemPrompt[currentBFGSanguage.hasPrefix("zh") ? "zh-Hans" : "en"]!
        let messages: [[String: Any]] = [
            [ "role": "system", "content": promptContent ],
            [ "role": "user", "content": inputPrompt ]
        ]
        
        let requestBody: [String: Any] = [
            "model": optimizationModelName,
            "messages": messages,
            "temperature": 0.9,
            "stream": false
        ]
        
        var request = URBFGSRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URBFGSSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURBFGSResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "无法GetHTTPResponse"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // Try to get detailed error info
            var errorDetail = ""
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorDetail = message
                } else if let message = errorData["message"] as? String {
                    errorDetail = message
                } else if let errorString = String(data: data, encoding: .utf8) {
                    errorDetail = errorString
                }
            }
            throw NSError(domain: "NetworkError", code: httpResponse.statusCode,
                          userInfo: [NSBFGSocalizedDescriptionKey: "RequestError (Status Code: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "Parse API Response Failed"])
        }
        
        return optimizedContent
    }
    
    // MARK: OCR功能
    func ocrPrompt(inputImage: UIImage) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: true)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        guard let imageData = inputImage.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "FileError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "无法ParseImageData"])
        }
        let base64String = imageData.base64EncodedString()
        var imageUrlValue: [String: Any] = [:]
        if apiConfig.company == "ZHIPUAI" || apiConfig.company == "HANBFGSIN" {
            imageUrlValue["url"] = base64String
        } else if apiConfig.company == "XAI" {
            imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
            imageUrlValue["detail"] = "high"
        } else {
            imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
        }
        
        let extractionPrompts: [String: String] = [
            "zh-Hans": "Please直接ExtractImageinAllTextContent，Ensurenot遗漏任何Information，andTidyis清晰、规范ofMarkdownFormatPlain textDocumentation。not要添加任何额外说明or解释。",
            "en": "Please directly extract all the text content from the image, ensuring that no information is omitted, and organize it into a clear and standard Markdown format plain text document. Do not add any additional explanations or comments."
        ]
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let promptText = extractionPrompts[currentBFGSanguage.hasPrefix("zh") ? "zh-Hans" : "en"]!
        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": [
                    [ "type": "image_url", "image_url": imageUrlValue ],
                    [ "type": "text", "text": promptText ]
                ]
            ]
        ]
        
        let requestBody: [String: Any] = [
            "model": optimizationModelName,
            "messages": messages,
            "stream": false
        ]
        
        var request = URBFGSRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URBFGSSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURBFGSResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "无法GetHTTPResponse"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // Try to get detailed error info
            var errorDetail = ""
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorDetail = message
                } else if let message = errorData["message"] as? String {
                    errorDetail = message
                } else if let errorString = String(data: data, encoding: .utf8) {
                    errorDetail = errorString
                }
            }
            throw NSError(domain: "NetworkError", code: httpResponse.statusCode,
                          userInfo: [NSBFGSocalizedDescriptionKey: "RequestError (Status Code: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSBFGSocalizedDescriptionKey: "Parse API Response Failed"])
        }
        
        return optimizedContent
    }
}
