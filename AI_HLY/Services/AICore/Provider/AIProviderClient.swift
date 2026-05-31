//
//  AIProviderClient.swift
//  AI_HLY
//
//  AICore —— 「接口格式」抽象。对标 Cherry Studio v2 的 ai-sdk 各 provider 实现
//  （@ai-sdk/openai、@ai-sdk/anthropic、@ai-sdk/google）：每种原生接口格式一个 client，
//  各自负责「构造原生请求 + 执行 + 把原始流解析成统一的 AIChunk 序列」。
//
//  这样，provider 差异（endpoint / 认证头 / 消息结构 / 工具声明 / 推理参数 / 流式解析）
//  被完全封装在 client 内部；上层 AICompletionEngine 只消费 AIChunk，编排工具与递归。
//
//  路由依据：APIKeys.apiType（.openAI / .openAIResponse / .anthropic / .gemini）。
//

import Foundation
import UIKit

// MARK: - 中性工具定义

/// 与接口格式无关的工具定义。各 client 转换为各自格式：
/// - OpenAI:   { type:"function", function:{ name, description, parameters } }
/// - Anthropic:{ name, description, input_schema }
/// - Gemini:   functionDeclarations: [{ name, description, parameters }]
struct AIToolDefinition {
    let name: String
    let description: String
    /// JSON Schema 对象（type:"object" / properties / required ...）
    let parameters: [String: Any]
}

// MARK: - 请求规格（中性输入）

/// 一次"单轮"补全请求所需的、与具体格式无关的输入。
/// 由 AICompletionEngine 组装后交给 client；client 内部再做格式特定的转换。
/// 工具调用后的多轮递归，由引擎更新 messages 后重新构造 spec 实现。
struct AIRequestSpec {

    // 模型与端点
    let modelInfo: AllModels
    /// 经 restoreBaseModelName 还原后的真实模型名（请求体里的 "model"）
    let baseModelName: String
    let apiKey: String
    let requestURL: String

    // 会话内容（中性，尚未格式化）
    /// 中性会话消息（含历史；system 文本另由 resolvedSystemMessage 提供）
    let messages: [RequestMessage]
    /// 已解析（Default / 自定义）后的系统提示文本
    let resolvedSystemMessage: String

    // 采样参数
    let temperature: Double
    let topP: Double
    let maxTokens: Int

    // 能力开关
    let ifThink: Bool
    let thinkingLength: Int
    let ifAudio: Bool
    let ifToolUse: Bool

    // 工具（中性定义，各 client 自行转格式）
    let toolDefinitions: [AIToolDefinition]

    // 杂项
    let currentLanguage: String
    /// 该模型对应服务商的差异描述
    let profile: ProviderProfile
}

// MARK: - Client 协议

/// 单轮补全的统一接口：输入中性 spec，输出与 provider 无关的 AIChunk 流。
///
/// 注意：client 只负责「一轮」请求/响应。工具调用编排、递归续聊、planning/observation
/// 重分类、StreamData 映射等都在引擎/插件层处理，client 保持格式纯粹。
protocol AIProviderClient {
    /// 该 client 对应的接口格式
    var apiFormat: APIType { get }

    /// 执行一轮流式补全，产出统一的 AIChunk 序列。
    func streamCompletion(_ spec: AIRequestSpec) -> AsyncThrowingStream<AIChunk, Error>
}
