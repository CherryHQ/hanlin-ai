//
//  SystemOptimizer.swift
//  AI_Hanlin
//
//  Created by 哆啦好多梦 on 3/4/25.
//

import Foundation
import PhotosUI
import SwiftData

class SystemOptimizer {
    let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// 封装从数据库查询 API 配置和模型信息
    /// - Parameter isVisual: 是否为视觉（多模态）模型
    /// - Returns: (模型名称, 模型所属厂商, API Key, 请求 URL)
    private func fetchAPIConfig(isVisual: Bool) throws -> (modelName: String, company: String, apiKey: String, url: URL) {
        print("[SystemOptimizer] 开始获取API配置，isVisual: \(isVisual)")
        let userFetchDescriptor = FetchDescriptor<UserInfo>()
        let user = try context.fetch(userFetchDescriptor).first
        
        let defaultModel = isVisual ? "glm-4v-flash_hanlin" : "glm-4.5-flash_hanlin"
        let optimizationModelName: String = isVisual ? (user?.optimizationVisualModel ?? defaultModel)
        : (user?.optimizationTextModel ?? defaultModel)
        print("[SystemOptimizer] 使用模型：\(optimizationModelName)")

        // 查询模型信息，获取厂商
        let modelPredicate = #Predicate<AllModels> { $0.name == optimizationModelName }
        let modelFetch = FetchDescriptor<AllModels>(predicate: modelPredicate)
        guard let modelEntry = try context.fetch(modelFetch).first,
              let modelCompany = modelEntry.company else {
            print("[SystemOptimizer] 错误：未能找到模型 \(optimizationModelName)")
            throw NSError(domain: "ModelNotFound", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "未能从数据库中获取模型信息: \(optimizationModelName)"])
        }
        print("[SystemOptimizer] 模型厂商：\(modelCompany)")
        
        // 查询 API 配置
        let apiKeyPredicate = #Predicate<APIKeys> { ($0.company ?? "") == modelCompany }
        let apiKeyFetch = FetchDescriptor<APIKeys>(predicate: apiKeyPredicate)
        guard let apiKeyObj = try context.fetch(apiKeyFetch).first else {
            print("[SystemOptimizer] 错误：未能找到厂商 \(modelCompany) 的API密钥配置")
            throw NSError(domain: "APIConfigError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "未能从数据库中获取厂商 \(modelCompany) 的API配置"])
        }

        guard let apiKey = apiKeyObj.key, !apiKey.isEmpty else {
            print("[SystemOptimizer] 错误：厂商 \(modelCompany) 的API密钥为空")
            throw NSError(domain: "APIConfigError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "厂商 \(modelCompany) 的API密钥未配置或为空"])
        }

        guard let requestURLString = apiKeyObj.requestURL,
              let url = URL(string: requestURLString) else {
            print("[SystemOptimizer] 错误：厂商 \(modelCompany) 的请求URL无效: \(apiKeyObj.requestURL ?? "nil")")
            throw NSError(domain: "APIConfigError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "厂商 \(modelCompany) 的请求URL无效"])
        }

        print("[SystemOptimizer] API配置获取成功 - URL: \(requestURLString)")
        return (optimizationModelName, modelCompany, apiKey, url)
    }
    
    /// 根据图片数组构造多模态请求中的图片消息（适配不同厂商）
    /// - Parameters:
    ///   - images: 图片数组
    ///   - role: 消息角色（例如 "user"）
    ///   - company: 模型所属厂商
    ///   - modelName: 模型名称，用于检查基础模型（如 "glm-4v-flash"）
    ///   - languageIsChinese: 是否为中文环境
    /// - Returns: 图片消息数组
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
                              userInfo: [NSLocalizedDescriptionKey: "无法解析图片数据"])
            }
            // 如果模型为 "glm-4v-flash" 且超过第一张图片，则直接跳出循环（只解析第一张图片）
            if photoCount > 1 {
                let baseName = restoreBaseModelName(from: modelName)
                if baseName == "glm-4v-flash" {
                    break
                }
            }
            let base64String = imageData.base64EncodedString()
            var imageUrlValue: [String: Any] = [:]
            if company == "ZHIPUAI" || company == "HANLIN" {
                imageUrlValue["url"] = base64String
            } else if company == "XAI" {
                imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
                imageUrlValue["detail"] = "high"
            } else {
                imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
            }
            let textMessage = languageIsChinese ? "这是图片\(photoCount)" : "This is image \(photoCount)"
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
    
    // MARK: 优化提示词
    func optimizePrompt(inputPrompt: String) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: false)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let languageKey = currentLanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        let systemMessages: [String: String] = [
            "zh-Hans": """
                    ## 优化指令
                    
                    请根据以下要求优化提供的提示词：
                    1. ​**核心目标**：提升大模型回复质量
                    2. ​**格式要求**：
                       - 允许使用Markdown排版且无需使用代码块（即不包含` ``` `）
                    3. ​**内容规范**：
                       - 严格保留原始语义
                       - 删除冗余信息
                       - 避免过度优化
                    4. ​**优化方向**：
                       - 逻辑结构重组
                       - 关键指令强化
                       - 语境明确化
                    5. **输出要求**：
                       - 直接给出优化后的文本，不要添加冗余的解释和说明
                    
                    ## 现有提示词：
                """,
            "en": """
                    ## Optimization Instructions
                    
                    Please refine the prompt according to these guidelines:
                    1. ​**Core Objective**: Enhance LLM response quality
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
        
        var request = URLRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法获取HTTP响应"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // 尝试获取详细错误信息
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
                          userInfo: [NSLocalizedDescriptionKey: "请求错误 (状态码: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "解析 API 响应失败"])
        }
        
        return optimizedContent
    }
    
    // MARK: 优化文章内容
    func optimizeContent(inputContent: String) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: false)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let languageKey = currentLanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        let systemMessages: [String: String] = [
            "zh-Hans": """
                    # 优化指令
                    
                    请根据以下要求优化提供的文章内容：
                    1. ​**核心目标**：
                       - 使得文章结构清晰，分段恰当
                    2. ​**格式要求**：
                       - 使用Markdown排版，以#标题、##二级标题等的形式合理划分文章结构
                       - Markdown排版无需使用代码块（即不包含` ``` `）
                    3. ​**内容规范**：
                       - 严格保留原有文本的所有内容，不要丢失任何信息
                       - 避免切割同语义的文本
                    4. ​**优化方向**：
                       - 文章结构优化，分大标题、小标题等整理内容格式
                       - 文章每个段落的内容长度基本保持一致
                    5. **输出要求**：
                       - 直接给出优化后的文本，不要添加冗余的解释和说明
                    
                    # 现有文章内容：
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
        
        var request = URLRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法获取HTTP响应"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // 尝试获取详细错误信息
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
                          userInfo: [NSLocalizedDescriptionKey: "请求错误 (状态码: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "解析 API 响应失败"])
        }
        
        return optimizedContent
    }
    
    // MARK: 优化联网搜索提问
    func optimizeSearchQuestion(inputPrompt: String, recentMessages: String, inputImages: [UIImage]? = nil) async throws -> String {
        // 根据是否存在图片决定使用视觉模型
        let isVisual = (inputImages != nil && !(inputImages!.isEmpty))
        let apiConfig = try fetchAPIConfig(isVisual: isVisual)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let languageKey = currentLanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        
        let prompts: [String: String] = [
            "zh-Hans": """
                           # 请将以下提问优化为搜索引擎适用格式
                           
                           # 用户当前提问及提问时间：
                           \(inputPrompt)
                           
                           # 要求：
                           1. 涉及时效性内容则根据时间添加具体的[年份][月份]，不涉及时效则不添加；
                           2. 用精确术语替换模糊表达；
                           3. 保留语义核心并补充必要限定词；
                           4. 直接返回单行纯文本优化结果。
                           5. 可供参考的历史聊天记录，如果没有有用的内容则可以忽略：\(recentMessages)
                           6. 围绕当前提问进行优化。
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
                           # 请将以下提问优化为搜索引擎适用格式
                           
                           # 用户当前提问及提问时间：
                           \(inputPrompt)
                           
                           # 要求：
                           1. 若涉及图片内容，需转写具体元素（如物体/文字/数据等）；
                           2. 涉及时效性内容则添加[年份][月份]；
                           3. 保留语义核心并补充必要限定词；
                           4. 直接返回单行纯文本优化结果。
                           5. 可供参考的历史聊天记录及图片，如果没有有用的内容则可以忽略：\n\(recentMessages)
                           6. 围绕当前提问进行优化。
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
            // 构造图片消息（支持多张图片，适配不同厂商）
            let imageMessages = try buildImageMessages(from: images,
                                                       role: "user",
                                                       company: apiConfig.company,
                                                       modelName: apiConfig.modelName,
                                                       languageIsChinese: isChinese)
            messages.append(contentsOf: imageMessages)
            // 添加单独的文本提示消息
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
        
        var request = URLRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法获取HTTP响应"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // 尝试获取详细错误信息
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
                          userInfo: [NSLocalizedDescriptionKey: "请求错误 (状态码: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "解析 API 响应失败"])
        }
        
        return optimizedContent
    }
    
    // MARK: 优化知识背包提问
    func optimizeKnowledgeQuestion(inputPrompt: String, recentMessages: String, inputImages: [UIImage]? = nil) async throws -> String {
        // 根据是否存在图片决定使用视觉模型
        let isVisual = (inputImages != nil && !(inputImages!.isEmpty))
        let apiConfig = try fetchAPIConfig(isVisual: isVisual)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let languageKey = currentLanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        
        let prompts: [String: String] = [
            "zh-Hans": """
                       # 请将以下提问优化为检索增强适用格式
                       
                       # 用户当前提问：
                       \(inputPrompt)
                       
                       # 要求：
                       1. 用精确术语替换模糊表达或代称；
                       2. 保留语义核心并补充必要限定词；
                       3. 直接返回单行纯文本优化结果。
                       4. 可供参考的历史聊天记录：\(recentMessages)。如果没有有用的内容则可以忽略。
                       5. 围绕当前提问进行优化。
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
                       # 请将以下提问优化为搜索引擎适用格式
                       
                       # 用户当前提问：
                       \(inputPrompt)
                       
                       # 要求：
                       1. 若涉及图片内容，需转写具体元素（如物体/文字/数据等）；
                       2. 用精确术语替换模糊表达或代称；
                       3. 保留语义核心并补充必要限定词；
                       4. 直接返回单行纯文本优化结果。
                       5. 可供参考的历史聊天记录及图片：\n\(recentMessages)\n如果没有有用的内容则可以忽略历史记录。
                       6. 围绕当前提问进行优化。
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
            // 构造图片消息（支持多张图片，适配不同厂商）
            let imageMessages = try buildImageMessages(from: images,
                                                       role: "user",
                                                       company: apiConfig.company,
                                                       modelName: apiConfig.modelName,
                                                       languageIsChinese: isChinese)
            messages.append(contentsOf: imageMessages)
            // 添加单独的文本提示消息
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
        
        var request = URLRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法获取HTTP响应"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // 尝试获取详细错误信息
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
                          userInfo: [NSLocalizedDescriptionKey: "请求错误 (状态码: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "解析 API 响应失败"])
        }
        
        return optimizedContent
    }
    
    // MARK: 优化图片生成提示词
    func optimizeImagePrompt(inputPrompt: String, recentMessages: String, inputImages: [UIImage]? = nil) async throws -> String {
        // 根据是否存在图片决定使用视觉模型
        let isVisual = (inputImages != nil && !(inputImages!.isEmpty))
        let apiConfig = try fetchAPIConfig(isVisual: isVisual)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let languageKey = currentLanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        
        let prompts: [String: String] = [
            "zh-Hans": """
                       # 请将以下描述优化为适用于 AI 图像生成的高质量提示词

                       # 用户当前描述：
                       \(inputPrompt)

                       # 优化要求：
                       1. 提取并扩展用户描述中的具体视觉元素（如人物、场景、物体、背景、光照、构图、风格等），避免使用模糊抽象的词汇；
                       2. 保留原始语义核心，并补充场景细节（如季节、时间、动作、颜色、材质、镜头角度等）以增强画面感；
                       3. 输出一段完整详细的图像提示词，适合用于图像生成模型，语言自然且具备画面引导力；
                       4. 参考历史聊天记录及图片\n\(recentMessages)\n。如果聊天记录包含相关上下文，可据此增强语境一致性，否则忽略；
                       5. 优化结果应呈现出一个具体可视的画面，引导模型准确理解并生成图像。
                       6. 直接给出最后的优化结果，不需要多余的解释。
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
            // 构造图片消息（支持多张图片，适配不同厂商）
            let imageMessages = try buildImageMessages(from: images,
                                                       role: "user",
                                                       company: apiConfig.company,
                                                       modelName: apiConfig.modelName,
                                                       languageIsChinese: isChinese)
            messages.append(contentsOf: imageMessages)
            // 添加单独的文本提示消息
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
        
        var request = URLRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法获取HTTP响应"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // 尝试获取详细错误信息
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
                          userInfo: [NSLocalizedDescriptionKey: "请求错误 (状态码: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "解析 API 响应失败"])
        }
        
        return optimizedContent
    }
    
    // MARK: 支持文本模型的图片解析
    func supportPhoto(inputImage: UIImage) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: true)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let languageKey = currentLanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        
        let multimodalPrompt: [String: String] = [
            "zh-Hans": """
                    你是一款先进的多模态 AI，擅长分析和详细描述图片内容。
                    
                    请从以下几个方面进行分析：
                    
                    1. **核心信息匹配**：
                       - 图片中的哪些元素与用户提问相关？请优先描述这些内容。
                       - 这些元素的形态、颜色、材质、位置关系如何？
                       - 这些内容可能与用户问题的背景或意图有什么关联？
                    
                    2. **详细图片描述**：
                       - 这是一张什么类型的图片？（照片、插画、截图等）
                       - 主要的视觉元素是什么？（人物、物体、场景等）
                       - 画面中色彩、光影、构图等视觉特点如何？
                    
                    3. **物体与细节**：
                       - 识别图片中的所有重要物体，并详细描述它们的形态、颜色、材质、相互关系。
                       - 是否有任何文字、标志、特殊符号？请准确提取并翻译（如果适用）。
                       - 是否有背景信息（时间、地点、环境）对理解图片有帮助？
                    
                    4. **人物与动作**（如果适用）：
                       - 图片中是否有人物？他们的外貌、穿着、表情、姿态如何？
                       - 他们在做什么？他们的互动、情绪、可能的意图是什么？
                       - 他们的行为与用户的问题是否相关？
                    
                    5. **推理与分析**：
                       - 这张图片可能表达了什么主题、情绪或隐含信息？
                       - 是否有文化、历史、科技等背景相关的内容可以补充？
                       - 结合用户提问，你能从中推测出哪些关键信息？
                    
                    6. **技术细节**（可选）：
                       - 图片的分辨率、清晰度、是否有模糊、噪点等问题？
                       - 如果是 AI 生成的，是否能判断它的来源或风格？
                    
                    请确保你的描述 **全面、精准、详细**，回复使用纯文本的格式。
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
                          userInfo: [NSLocalizedDescriptionKey: languageKey == "zh-Hans" ? "图片转换为 JPEG 失败" : "Failed to convert image to JPEG"])
        }
        let base64String = imageData.base64EncodedString()
        var imageUrlValue: [String: Any] = [:]
        if apiConfig.company == "ZHIPUAI" || apiConfig.company == "HANLIN" {
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
        
        var request = URLRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法获取HTTP响应"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // 尝试获取详细错误信息
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
                          userInfo: [NSLocalizedDescriptionKey: "请求错误 (状态码: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "解析 API 响应失败"])
        }
        
        return optimizedContent
    }
    
    // MARK: 自动生成群聊标题
    func autoChatName(historyMessage: String) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: false)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let languageKey = currentLanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        let systemMessages: [String: String] = [
            "zh-Hans": "请根据下面的群聊内容为群聊取一个标题，可以根据内容及场合适当添加emoji，总字符数不超过6个字。直接给出纯文本的标题即可，不用多余的解释",
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
        
        var request = URLRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法获取HTTP响应"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // 尝试获取详细错误信息
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
                          userInfo: [NSLocalizedDescriptionKey: "请求错误 (状态码: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "解析 API 响应失败"])
        }
        
        return optimizedContent
    }
    
    // MARK: 自动生成智能体设定
    func autoFillCharacterPrompt(inputName: String) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: false)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let systemPrompt: [String: String] = [
            "zh-Hans": "请根据智能体名称“\(inputName)”，写一段智能体的人物设定，包括性格、爱好、回答方式等，直接返回结果不要添加多余的解释。",
            "en": "Please write a character profile for the agent named “\(inputName)”, including personality, hobbies, and response style. Return the result directly without adding any extra explanations."
        ]
        let promptContent = systemPrompt[currentLanguage.hasPrefix("zh") ? "zh-Hans" : "en"]!
        let messages: [[String: Any]] = [
            [ "role": "user", "content": promptContent ]
        ]
        
        let requestBody: [String: Any] = [
            "model": optimizationModelName,
            "messages": messages,
            "temperature": 1.0,
            "stream": false
        ]
        
        var request = URLRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法获取HTTP响应"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // 尝试获取详细错误信息
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
                          userInfo: [NSLocalizedDescriptionKey: "请求错误 (状态码: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "解析 API 响应失败"])
        }
        
        return optimizedContent
    }
    
    // MARK: 翻译功能
    func translatePrompt(inputPrompt: String) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: false)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        let systemPrompt: [String: String] = [
            "zh-Hans": "请直接翻译以下内容，保留原意。如果输入内容是中文，则翻译为英文；如果是其他语言，则翻译为中文。直接给出翻译结果，不要添加额外信息。",
            "en": "Please translate the following content directly, keeping the original meaning. If the input is in Chinese, translate it into English; if it is in another language, translate it into Chinese. Provide the translation result directly without adding extra information."
        ]
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let promptContent = systemPrompt[currentLanguage.hasPrefix("zh") ? "zh-Hans" : "en"]!
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
        
        var request = URLRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法获取HTTP响应"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // 尝试获取详细错误信息
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
                          userInfo: [NSLocalizedDescriptionKey: "请求错误 (状态码: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "解析 API 响应失败"])
        }
        
        return optimizedContent
    }
    
    // MARK: OCR功能
    func ocrPrompt(inputImage: UIImage) async throws -> String {
        let apiConfig = try fetchAPIConfig(isVisual: true)
        let optimizationModelName = restoreBaseModelName(from: apiConfig.modelName)
        
        guard let imageData = inputImage.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "FileError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法解析图片数据"])
        }
        let base64String = imageData.base64EncodedString()
        var imageUrlValue: [String: Any] = [:]
        if apiConfig.company == "ZHIPUAI" || apiConfig.company == "HANLIN" {
            imageUrlValue["url"] = base64String
        } else if apiConfig.company == "XAI" {
            imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
            imageUrlValue["detail"] = "high"
        } else {
            imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
        }
        
        let extractionPrompts: [String: String] = [
            "zh-Hans": "请直接提取图片中所有文字内容，确保不遗漏任何信息，并整理为清晰、规范的Markdown格式纯文本文档。不要添加任何额外说明或解释。",
            "en": "Please directly extract all the text content from the image, ensuring that no information is omitted, and organize it into a clear and standard Markdown format plain text document. Do not add any additional explanations or comments."
        ]
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let promptText = extractionPrompts[currentLanguage.hasPrefix("zh") ? "zh-Hans" : "en"]!
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
        
        var request = URLRequest(url: apiConfig.url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "无法获取HTTP响应"])
        }

        guard 200...299 ~= httpResponse.statusCode else {
            // 尝试获取详细错误信息
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
                          userInfo: [NSLocalizedDescriptionKey: "请求错误 (状态码: \(httpResponse.statusCode)): \(errorDetail)"])
        }
        
        guard let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any],
              let choices = jsonObject["choices"] as? [[String: Any]],
              let optimizedPrompt = choices.first?["message"] as? [String: Any],
              let optimizedContent = optimizedPrompt["content"] as? String else {
            throw NSError(domain: "ParsingError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "解析 API 响应失败"])
        }
        
        return optimizedContent
    }
}
