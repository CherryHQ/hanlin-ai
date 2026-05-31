//
//  AIChunk.swift
//  AI_HLY
//
//  AICore —— 统一流式事件类型。
//  对标 Cherry Studio v2 `src/renderer/types/chunk.ts` 的 ChunkType / Chunk。
//
//  设计目的：把不同 provider 的原始 SSE 分片，先归一化成一组与 provider 无关的
//  语义事件（AIChunk），再由 ChunkToStreamData 映射到现有 UI 契约 StreamData。
//  这样「解析差异」被隔离在各 StreamParser，「UI 表现」被隔离在映射层。
//

import Foundation
import UIKit

/// 流式工具调用的累积态（对标 Cherry `handleToolCallChunk` 累积的结构）。
/// 与现有实现保持一致：以 OpenAI 风格的 `[index] -> {id,type,function{name,arguments}}` 累积。
struct AccumulatedToolCall {
    var index: Int
    var id: String?
    var type: String?
    var name: String?
    /// 流式拼接得到的 JSON 字符串参数
    var arguments: String = ""
}

/// 与 provider 无关的统一流式事件。
enum AIChunk {
    // MARK: 文本
    /// 正文增量
    case textDelta(String)

    // MARK: 推理
    /// 推理过程增量（reasoning_content / reasoning / 智谱 <think> 内）
    case reasoningDelta(String)

    // MARK: 工具调用（流式）
    /// 某个 tool_call 首次出现（含 index / id / name）
    case toolCallStart(index: Int, id: String?, name: String?)
    /// 某个 tool_call 的参数增量
    case toolCallArgumentsDelta(index: Int, delta: String)

    // MARK: 多模态
    /// 音频增量数据（如 QWEN 的 base64 PCM）
    case audioDelta(Data)
    /// 生成的图片
    case image([UIImage])

    // MARK: 控制 / 状态
    /// 本轮结束及其 finish_reason（"stop" / "tool_calls" / ...）
    case finished(reason: String?)
    /// 运行状态（"等待模型响应" 等，映射到 StreamData.operationalState）
    case operationalState(String)
    /// 运行描述（工具参数预览等，映射到 StreamData.operationalDescription）
    case operationalDescription(String)
    /// 错误信息
    case error(String)
}
