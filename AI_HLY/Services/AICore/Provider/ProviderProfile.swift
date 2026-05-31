//
//  ProviderProfile.swift
//  AI_HLY
//
//  AICore —— 数据驱动的「服务商差异描述」。
//  对标 Cherry Studio v2 `provider/providerConfig.ts` + `provider/factory.ts`：
//  把各家在请求构造上的差异（系统角色、图片编码、推理参数风格、音频）集中成数据/规则，
//  消除散落在 processRemoteModel 里的 `modelInfo.company == "X"` 分支。
//
//  ⚠️ 重要：此处必须【原样保留】现有实现的所有怪癖（例如 thinkingLength==3 时
//  DOUBAO/OPENROUTER 不在 reasoning_effort 组、OPENROUTER 改入 thinking_budget 组等），
//  不得在重构中「顺手改对」，以保证行为与现状完全一致。
//

import Foundation

struct ProviderProfile {

    /// 大写后的公司标识（与 modelInfo.company?.uppercased() 一致）
    let company: String

    init(company: String) {
        self.company = company
    }

    static func make(for modelInfo: AllModels) -> ProviderProfile {
        ProviderProfile(company: modelInfo.company?.uppercased() ?? "UNKNOWN")
    }

    // MARK: - 系统消息角色
    /// 来源：buildFormattedMessages —— OpenAI 用 "developer"，其余 "system"。
    var systemRole: String {
        switch company {
        case "OPENAI": return "developer"
        default: return "system"
        }
    }

    // MARK: - 多模态图片编码
    /// 来源：buildFormattedMessages 的 image_url 构造分支。
    /// 智谱/翰林：直接放裸 base64；XAI：data URL + detail=high；其余：data URL。
    func imageURLValue(base64String: String) -> [String: Any] {
        var imageUrlValue: [String: Any] = [:]
        if company == "ZHIPUAI" || company == "HANLIN" {
            imageUrlValue["url"] = base64String
        } else if company == "XAI" {
            imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
            imageUrlValue["detail"] = "high"
        } else {
            imageUrlValue["url"] = "data:image/jpeg;base64,\(base64String)"
        }
        return imageUrlValue
    }

    // MARK: - 推理开关（supportReasoningChange）
    /// 来源：processRemoteModel 中 `if modelInfo.supportReasoningChange { ... }` 分支。
    /// 注意：最后一种情况会改写 finalFormattedMessages（追加 /think 或 /no_think），
    ///       因此用 inout 传回。
    func applyReasoningToggle(to requestBody: inout [String: Any],
                             ifThink: Bool,
                             finalFormattedMessages: inout [[String: Any]]) {
        if company == "QWEN" ||
            company == "MODELSCOPE" ||
            company == "SILICONCLOUD" ||
            company == "WENXIN" {
            requestBody["enable_thinking"] = ifThink
        } else if company == "ANTHROPIC" {
            if ifThink {
                requestBody["think"] = ["type": "enabled"]
            } else {
                requestBody["think"] = ["type": "disabled"]
            }
        } else if company == "ZHIPUAI" || company == "HANLIN" || company == "DOUBAO" || company == "OPENROUTER" {
            if ifThink {
                requestBody["thinking"] = ["type": "enabled"]
            } else {
                requestBody["thinking"] = ["type": "disabled"]
            }
        } else {
            // 给最后一句话加上 /think 或 /no_think
            if var lastMessage = finalFormattedMessages.last,
               lastMessage["role"] as? String == "user",
               var content = lastMessage["content"] as? String,
               !content.contains("/think") && !content.contains("/no_think") {
                content += ifThink ? " /think" : " /no_think"
                lastMessage["content"] = content
                finalFormattedMessages[finalFormattedMessages.count - 1] = lastMessage
            }
            requestBody["messages"] = finalFormattedMessages
        }
    }

    // MARK: - 推理深度（supportsReasoning && ifThink && thinkingLength != 0）
    /// 来源：processRemoteModel 的 `switch thinkingLength`。
    /// ⚠️ 各档位的公司分组并不对称（见 case 3），此处严格照搬。
    func applyReasoningLength(to requestBody: inout [String: Any], thinkingLength: Int) {
        switch thinkingLength {
        case 1:
            // 短暂思考
            if company == "OPENAI" || company == "GOOGLE" || company == "XAI" || company == "DOUBAO" || company == "OPENROUTER" {
                requestBody["reasoning_effort"] = "low"
            } else if company == "QWEN" || company == "MODELSCOPE" || company == "SILICONCLOUD" {
                requestBody["thinking_budget"] = 1024
            }
        case 2:
            // 中等思考
            if company == "OPENAI" || company == "GOOGLE" || company == "XAI" || company == "DOUBAO" || company == "OPENROUTER" {
                requestBody["reasoning_effort"] = "medium"
            } else if company == "QWEN" || company == "MODELSCOPE" || company == "SILICONCLOUD" {
                requestBody["thinking_budget"] = 8192
            }
        case 3:
            // 深度思考
            if company == "OPENAI" || company == "GOOGLE" || company == "XAI" {
                requestBody["reasoning_effort"] = "high"
            } else if company == "QWEN" || company == "MODELSCOPE" || company == "SILICONCLOUD" || company == "OPENROUTER" {
                requestBody["thinking_budget"] = 16384
            }
        default:
            break
        }
    }

    // MARK: - 音频生成（supportsVoiceGen && ifAudio）
    /// 来源：processRemoteModel —— 仅 QWEN 支持。
    func applyAudio(to requestBody: inout [String: Any]) {
        if company == "QWEN" {
            requestBody["modalities"] = ["text", "audio"]
            requestBody["audio"] = [
                "voice": "Cherry",
                "format": "wav"
            ]
        }
    }
}
