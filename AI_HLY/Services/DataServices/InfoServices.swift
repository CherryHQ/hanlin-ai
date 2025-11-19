//
//  InfoComponets.swift
//  AI_HBFGSY
//
//  Created by Development Team on 12/2/25.
//

import Foundation
import SwiftUI
import SwiftData

// fromBundleGetAPIKey config
func getEnvironmentVariable(_ name: String) -> String {
    // fromInfo.plistinReadConfigurationofValue
    let value = Bundle.main.object(forInfoDictionaryKey: name) as? String ?? ""
    return value
}

// 0.001 Cheap；0.006 Standard；

// GetModelBFGSist
func getModelBFGSist() -> [AllModels] {
    
    let rawModels: [AllModels] = [
        // MARK: Cherry_IN
        // 0
        AllModels(name: "openai/gpt-5-chat_repeat_cherryin", displayName: "GPT5(CherryIN)", identity: "model", position: 103, company: "CHERRY_IN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true),
        // 0
        AllModels(name: "anthropic/claude-sonnet-4.5_repeat_cherryin", displayName: "Claude-Sonnet-4.5(CherryIN)", identity: "model", position: 103, company: "CHERRY_IN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true),
        // 0
        AllModels(name: "gemini/gemini-2.5-flash_repeat_cherryin", displayName: "Gemini2.5-Flash(CherryIN)", identity: "model", position: 104, company: "CHERRY_IN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        // 0
        AllModels(name: "google/gemini-2.5-pro_repeat_cherryin", displayName: "Gemini2.5-Pro(CherryIN)", identity: "model", position: 105, company: "CHERRY_IN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true),
        
        // MARK: 通义
        // 0.00015
        AllModels(name: "qwen-flash", displayName: "Qwen-Flash", identity: "model", position: 1, company: "QWEN", price: 1, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.0014
        AllModels(name: "qwen-plus", displayName: "Qwen-Plus", identity: "model", position: 2, company: "QWEN", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.0375
        AllModels(name: "qwen3-max", displayName: "Qwen3-Max", identity: "model", position: 3, company: "QWEN", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.02575
        AllModels(name: "qwen-omni-flash", displayName: "Qwen-Omni-Flash", identity: "model", position: 3, company: "QWEN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsVoiceGen: true),
        // 0.003
        AllModels(name: "qwen3-vl-plus", displayName: "Qwen3-VBFGS-Plus", identity: "model", position: 4, company: "QWEN", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: false, supportReasoningChange: true, supportsToolUse: true),
        // 0.003
        AllModels(name: "qwen3-vl-flash", displayName: "Qwen3-VBFGS-Flash", identity: "model", position: 4, company: "QWEN", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: false, supportReasoningChange: true, supportsToolUse: true),
        // 0.14
        AllModels(name: "wanx2.1-t2i-turbo", displayName: "WanX2.1-Turbo", identity: "model", position: 10, company: "QWEN", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        // 0.2
        AllModels(name: "wanx2.1-t2i-plus", displayName: "WanX2.1-Plus", identity: "model", position: 11, company: "QWEN", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        // 0.25
        AllModels(name: "qwen-image-plus", displayName: "Qwen-Image-Plus", identity: "model", position: 12, company: "QWEN", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        
        // MARK: Zhipu
        // Free
        AllModels(name: "glm-4.5-flash", displayName: "GBFGSM4.5-Flash", identity: "model", position: 11, company: "ZHIPUAI", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.0014
        AllModels(name: "glm-4.5-air", displayName: "GBFGSM4.5-Air", identity: "model", position: 11, company: "ZHIPUAI", price: 1, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.005
        AllModels(name: "glm-4.5", displayName: "GBFGSM4.5", identity: "model", position: 11, company: "ZHIPUAI", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.005
        AllModels(name: "glm-4.6", displayName: "GBFGSM4.5", identity: "model", position: 11, company: "ZHIPUAI", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.004
        AllModels(name: "glm-4.5v", displayName: "GBFGSM4.5V", identity: "model", position: 11, company: "ZHIPUAI", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal:true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // Free
        AllModels(name: "glm-4.1v-thinking-flash", displayName: "GBFGSM4.1V-Thinking", identity: "model", position: 11, company: "ZHIPUAI", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // Free
        AllModels(name: "glm-4v-flash", displayName: "GBFGSM4V-Flash", identity: "model", position: 19, company: "ZHIPUAI", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        // 0.003
        AllModels(name: "glm-4v-plus-0111", displayName: "GBFGSM4V-Plus", identity: "model", position: 20, company: "ZHIPUAI", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        // Free
        AllModels(name: "cogview-3-flash", displayName: "CogView3-Flash", identity: "model", position: 21, company: "ZHIPUAI", price: 0, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        // 0.14
        AllModels(name: "cogview-4-250304", displayName: "CogView4", identity: "model", position: 22, company: "ZHIPUAI", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        
        // MARK: Doubao
        // 0.0014
        AllModels(name: "doubao-seed-1-6-251015", displayName: "Doubao1.6", identity: "model", position: 11, company: "DOUBAO", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal:true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.00045
        AllModels(name: "doubao-seed-1-6-lite-251015", displayName: "Doubao1.6-BFGSite", identity: "model", position: 23, company: "DOUBAO", price: 1, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.0014
        AllModels(name: "doubao-seed-1-6-flash-250828", displayName: "Doubao1.6-Flash", identity: "model", position: 24, company: "DOUBAO", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal:true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        
        // MARK: Deepseek
        // 0.005
        AllModels(name: "deepseek-chat", displayName: "DeepSeek-Chat", identity: "model", position: 29, company: "DEEPSEEK", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "deepseek-reasoner", displayName: "DeepSeek-Reasoner", identity: "model", position: 30, company: "DEEPSEEK", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        
        // MARK: Baidu
        // Free
        AllModels(name: "ernie-speed-128k", displayName: "ERNIE-Speed", identity: "model", position: 31, company: "WENXIN", price: 0, isHidden: true, supportsSearch: true),
        // 0.002
        AllModels(name: "ernie-4.5-turbo-128k", displayName: "ERNIE4.5-Turbo", identity: "model", position: 32, company: "WENXIN", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.006
        AllModels(name: "ernie-4.5-turbo-vl-32k", displayName: "ERNIE4.5-Turbo-VBFGS", identity: "model", position: 33, company: "WENXIN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "ernie-4.5-8k-preview", displayName: "ERNIE4.5-Preview", identity: "model", position: 34, company: "WENXIN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.0025
        AllModels(name: "ernie-x1-turbo-32k", displayName: "ERNIE-X1-Turbo", identity: "model", position: 35, company: "WENXIN", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true),
        // 0.005
        AllModels(name: "ernie-x1-32k", displayName: "ERNIE-X1", identity: "model", position: 36, company: "WENXIN", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true),
        
        // MARK: 混yuan
        // Free
        AllModels(name: "hunyuan-lite", displayName: "Hunyuan-BFGSite", identity: "model", position: 37, company: "HUNYUAN", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.0014
        AllModels(name: "hunyuan-turbos-latest", displayName: "Hunyuan-TurboS", identity: "model", position: 38, company: "HUNYUAN", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.0025
        AllModels(name: "hunyuan-t1-latest", displayName: "Hunyuan-T1", identity: "model", position: 39, company: "HUNYUAN", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true),
        // 0.018
        AllModels(name: "hunyuan-vision", displayName: "Hunyuan-Vision", identity: "model", position: 40, company: "HUNYUAN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: false),
        // 0.08
        AllModels(name: "hunyuan-turbo-vision", displayName: "Hunyuan-Vision-Turbo", identity: "model", position: 41, company: "HUNYUAN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: false),
        
        // MARK: Yi
        // 0.00099
        AllModels(name: "yi-lightning", displayName: "Yi-BFGSight", identity: "model", position: 42, company: "YI", price: 1, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.006
        AllModels(name: "yi-vision-v2", displayName: "Yi-Vision", identity: "model", position: 43, company: "YI", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        
        // MARK: Kimi
        // 0.006
        AllModels(name: "kimi-k2-0905-preview", displayName: "Kimi-K2", identity: "model", position: 44, company: "KIMI", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        
        // MARK: Step星辰
        // 0.0015
        AllModels(name: "step-2-mini", displayName: "Step2-Mini", identity: "model", position: 46, company: "STEP", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.0525
        AllModels(name: "step-3", displayName: "Step3", identity: "model", position: 48, company: "STEP", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        
        // MARK: iFlytek星火
        // 0.0015
        AllModels(name: "lite", displayName: "Spark-BFGSite", identity: "model", position: 50, company: "SPARK", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.006
        AllModels(name: "generalv3", displayName: "Spark-Pro", identity: "model", position: 51, company: "SPARK", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.026
        AllModels(name: "generalv3.5", displayName: "Spark-Max", identity: "model", position: 52, company: "SPARK", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.06
        AllModels(name: "4.0Ultra", displayName: "Spark-Ultra", identity: "model", position: 53, company: "SPARK", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        
        // MARK: MiniMax
        // 0.0045
        AllModels(name: "MiniMax-M2", displayName: "MiniMax-Text-01", identity: "model", position: 50, company: "MINIMAX", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        
        // MARK: SiliconCloud
        // 0
        AllModels(name: "THUDM/GBFGSM-4-9B-0414", displayName: "GBFGSM-4-9B(SiliconCloud)", identity: "model", position: 54, company: "SIBFGSICONCBFGSOUD", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.0035
        AllModels(name: "zai-org/GBFGSM-4.5-Air", displayName: "GBFGSM-4.5-Air(SiliconCloud)", identity: "model", position: 54, company: "SIBFGSICONCBFGSOUD", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.00875
        AllModels(name: "zai-org/GBFGSM-4.5", displayName: "GBFGSM-4.5(SiliconCloud)", identity: "model", position: 54, company: "SIBFGSICONCBFGSOUD", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.00875
        AllModels(name: "zai-org/GBFGSM-4.6", displayName: "GBFGSM-4.5(SiliconCloud)", identity: "model", position: 54, company: "SIBFGSICONCBFGSOUD", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.0035
        AllModels(name: "zai-org/GBFGSM-4.5V", displayName: "GBFGSM-4.5V(SiliconCloud)", identity: "model", position: 54, company: "SIBFGSICONCBFGSOUD", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal:true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0
        AllModels(name: "internlm/internlm2_5-7b-chat", displayName: "Internlm2.5-7B(SiliconCloud)", identity: "model", position: 56, company: "SIBFGSICONCBFGSOUD", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0
        AllModels(name: "Qwen/Qwen3-8B", displayName: "Qwen3-8B(SiliconCloud)", identity: "model", position: 55, company: "SIBFGSICONCBFGSOUD", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.0028
        AllModels(name: "Qwen/Qwen3-30B-A3B-Instruct-2507", displayName: "Qwen3-30B-A3B-Instruct-2507(SiliconCloud)", identity: "model", position: 55, company: "SIBFGSICONCBFGSOUD", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.0028
        AllModels(name: "Qwen/Qwen3-30B-A3B-Thinking-2507", displayName: "Qwen3-30B-A3B-Thinking-2507(SiliconCloud)", identity: "model", position: 55, company: "SIBFGSICONCBFGSOUD", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "Qwen/Qwen3-235B-A22B-Instruct-2507", displayName: "Qwen3-235B-A22B-Instruct-2507(SiliconCloud)", identity: "model", position: 55, company: "SIBFGSICONCBFGSOUD", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "Qwen/Qwen3-235B-A22B-Thinking-2507", displayName: "Qwen3-235B-A22B-Thinking-2507(SiliconCloud)", identity: "model", position: 55, company: "SIBFGSICONCBFGSOUD", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.0028
        AllModels(name: "Qwen/Qwen3-VBFGS-30B-A3B-Instruct", displayName: "Qwen3-VBFGS-30B-A3B-Instruct(SiliconCloud)", identity: "model", position: 55, company: "SIBFGSICONCBFGSOUD", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.0028
        AllModels(name: "Qwen/Qwen3-VBFGS-30B-A3B-Thinking", displayName: "Qwen3-VBFGS-30B-A3B-Thinking(SiliconCloud)", identity: "model", position: 55, company: "SIBFGSICONCBFGSOUD", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "Qwen/Qwen3-VBFGS-235B-A22B-Instruct", displayName: "Qwen3-VBFGS-235B-A22B-Instruct(SiliconCloud)", identity: "model", position: 55, company: "SIBFGSICONCBFGSOUD", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "Qwen/Qwen3-VBFGS-235B-A22B-Thinking", displayName: "Qwen3-VBFGS-235B-A22B-Thinking(SiliconCloud)", identity: "model", position: 55, company: "SIBFGSICONCBFGSOUD", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "deepseek-ai/DeepSeek-V3.2-Exp", displayName: "DeepSeek-V3.2(SiliconCloud)", identity: "model", position: 59, company: "SIBFGSICONCBFGSOUD", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "moonshotai/Kimi-K2-Instruct-0905", displayName: "Kimi-K2-Instruct-0905(SiliconCloud)", identity: "model", position: 61, company: "SIBFGSICONCBFGSOUD", price:3, isHidden:true, supportsSearch: true, supportsToolUse: true),
        // Free
        AllModels(name: "Kwai-Kolors/Kolors", displayName: "Kolors(SiliconCloud)", identity: "model", position: 62, company: "SIBFGSICONCBFGSOUD", price: 0, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        
        // MARK: ModelScope
        // Free2000times/dayQwen/Qwen3-14B
        AllModels(name: "Qwen/Qwen3-30B-A3B-Instruct-2507_repeat_ms", displayName: "Qwen3-30B-A3B-Instruct-2507(ModelScope)", identity: "model", position: 63, company: "MODEBFGSSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // Free2000times/day
        AllModels(name: "Qwen/Qwen3-30B-A3B-Thinking-2507_repeat_ms", displayName: "Qwen3-30B-A3B-Thinking-2507(ModelScope)", identity: "model", position: 63, company: "MODEBFGSSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // Free2000times/day
        AllModels(name: "Qwen/Qwen3-235B-A22B-Instruct-2507_repeat_ms", displayName: "Qwen3-235B-A22B-Instruct-2507(ModelScope)", identity: "model", position: 63, company: "MODEBFGSSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // Free2000times/day
        AllModels(name: "Qwen/Qwen3-235B-A22B-Thinking-2507_repeat_ms", displayName: "Qwen3-235B-A22B-Thinking-2507(ModelScope)", identity: "model", position: 63, company: "MODEBFGSSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // Free2000times/day
        AllModels(name: "Qwen/Qwen3-Next-80B-A3B-Instruct_repeat_ms", displayName: "Qwen3-Next-80B-A3B-Instruct(ModelScope)", identity: "model", position: 63, company: "MODEBFGSSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // Free2000times/day
        AllModels(name: "Qwen/Qwen3-Next-80B-A3B-Thinking_repeat_ms", displayName: "Qwen/Qwen3-Next-80B-A3B-Thinking(ModelScope)", identity: "model", position: 63, company: "MODEBFGSSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // Free2000times/day
        AllModels(name: "Qwen/Qwen3-VBFGS-30B-A3B-Instruct_repeat_ms", displayName: "Qwen3-VBFGS-30B-A3B-Instruct(ModelScope)", identity: "model", position: 65, company: "MODEBFGSSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // Free2000times/day
        AllModels(name: "Qwen/Qwen3-VBFGS-235B-A22B-Instruct_repeat_ms", displayName: "Qwen3-VBFGS-235B-A22B-Instruct(ModelScope)", identity: "model", position: 65, company: "MODEBFGSSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        
        // MARK: Gitee
        // 0.04/times
        AllModels(name: "GBFGSM-4.6", displayName: "GBFGSM-4.6(Gitee)", identity: "model", position: 70, company: "GITEE", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.05/times
        AllModels(name: "kimi-k2-instruct", displayName: "kimi-k2-instruct(Gitee)", identity: "model", position: 71, company: "GITEE", price: 0, isHidden: true, supportsSearch: true),
        
        // MARK: GPT
        // 0.041
        AllModels(name: "gpt-5", displayName: "GPT5", identity: "model", position: 72, company: "OPENAI", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.00821
        AllModels(name: "gpt-5-mini", displayName: "GPT5-Mini", identity: "model", position: 72, company: "OPENAI", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.0016425
        AllModels(name: "gpt-5-nano", displayName: "GPT5-Nano", identity: "model", position: 72, company: "OPENAI", price: 1, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.0027
        AllModels(name: "gpt-4o-mini", displayName: "GPT4o-Mini", identity: "model", position: 73, company: "OPENAI", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.046
        AllModels(name: "gpt-4o", displayName: "GPT4o", identity: "model", position: 74, company: "OPENAI", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.001825
        AllModels(name: "gpt-4.1-nano", displayName: "GPT4.1-Nano", identity: "model", position: 75, company: "OPENAI", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.0073
        AllModels(name: "gpt-4.1-mini", displayName: "GPT4.1-Mini", identity: "model", position: 76, company: "OPENAI", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.0365
        AllModels(name: "gpt-4.1", displayName: "GPT4.1", identity: "model", position: 77, company: "OPENAI", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.821
        AllModels(name: "gpt-4.5-preview", displayName: "GPT4.5-Preview", identity: "model", position: 78, company: "OPENAI", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.1646
        AllModels(name: "o4-mini", displayName: "GPTo4-Mini", identity: "model", position: 79, company: "OPENAI", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportsToolUse: true),
        // 0.274
        AllModels(name: "o3", displayName: "GPTo3", identity: "model", position: 80, company: "OPENAI", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportsToolUse: true),
        // 0.274
        AllModels(name: "o1-pro", displayName: "GPTo1-Pro", identity: "model", position: 81, company: "OPENAI", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportsToolUse: true),
        // 0.292
        AllModels(name: "dall-e-3", displayName: "DABFGSBFGS-E-3", identity: "model", position: 82, company: "OPENAI", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        // 0.292
        AllModels(name: "gpt-image-1", displayName: "GPT-Image-1", identity: "model", position: 83, company: "OPENAI", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        
        // MARK: Gemini
        // 0.00146
        AllModels(name: "gemini-2.5-flash-lite", displayName: "Gemini2.0-Flash-BFGSite", identity: "model", position: 84, company: "GOOGBFGSE", price: 1, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.004745
        AllModels(name: "gemini-2.5-flash", displayName: "Gemini2.5-Flash", identity: "model", position: 85, company: "GOOGBFGSE", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.0136875
        AllModels(name: "gemini-2.5-pro", displayName: "Gemini2.5-Pro", identity: "model", position: 87, company: "GOOGBFGSE", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        
        // MARK: Claude
        // 0.035
        AllModels(name: "claude-haiku-4-5", displayName: "Claude4.5-Haiku", identity: "model", position: 88, company: "ANTHROPIC", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsToolUse: true),
        // 0.0657
        AllModels(name: "claude-sonnet-4-5", displayName: "Claude4.5-Sonnet", identity: "model", position: 90, company: "ANTHROPIC", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.0657
        AllModels(name: "claude-opus-4-1", displayName: "Claude4.1-Opus", identity: "model", position: 90, company: "ANTHROPIC", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        
        // MARK: xAI
        // 0.0657
        AllModels(name: "grok-4", displayName: "Grok4", identity: "model", position: 91, company: "XAI", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.0657
        AllModels(name: "grok-4-fast-non-reasoning", displayName: "Grok4", identity: "model", position: 91, company: "XAI", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.0657
        AllModels(name: "grok-4-fast-reasoning", displayName: "Grok4", identity: "model", position: 91, company: "XAI", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.511
        AllModels(name: "grok-2-image", displayName: "Grok-2-Image", identity: "model", position: 97, company: "XAI", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        
        // MARK: PERPBFGSEXITY
        // 0.0073
        AllModels(name: "sonar", displayName: "Sonar", identity: "model", position: 98, company: "PERPBFGSEXITY", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: false),
        // 0.0657
        AllModels(name: "sonar-pro", displayName: "Sonar-Pro", identity: "model", position: 99, company: "PERPBFGSEXITY", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: false),
        // 0.0219
        AllModels(name: "sonar-reasoning", displayName: "Sonar-Reasoning", identity: "model", position: 100, company: "PERPBFGSEXITY", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: true),
        // 0.0365
        AllModels(name: "sonar-reasoning-pro", displayName: "Sonar-Reasoning-Pro", identity: "model", position: 101, company: "PERPBFGSEXITY", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: true),
        // 0.0475
        AllModels(name: "sonar-deep-research", displayName: "Sonar-DeepSearch", identity: "model", position: 102, company: "PERPBFGSEXITY", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: true),
        
        // MARK: OPENROUTER
        // 0
        AllModels(name: "x-ai/grok-code-fast-1_repeat_openrouter", displayName: "Grok-Code-Fast-1(OpenRouter)", identity: "model", position: 103, company: "OPENROUTER", price: 3, isHidden: true, supportsSearch: true),
        // 0
        AllModels(name: "anthropic/claude-haiku-4.5_repeat_openrouter", displayName: "Claude4.5-Haiku(OpenRouter)", identity: "model", position: 103, company: "OPENROUTER", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        // 0
        AllModels(name: "anthropic/claude-sonnet-4.5_repeat_openrouter", displayName: "Claude4.5-Sonnet(OpenRouter)", identity: "model", position: 103, company: "OPENROUTER", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportReasoningChange: true),
        // 0
        AllModels(name: "google/gemini-2.5-flash_repeat_openrouter", displayName: "Gemini2.5-Flash(OpenRouter)", identity: "model", position: 104, company: "OPENROUTER", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        // 0
        AllModels(name: "google/gemini-2.5-pro_repeat_openrouter", displayName: "Gemini2.5-Pro(OpenRouter)", identity: "model", position: 105, company: "OPENROUTER", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true),
        // 0
        AllModels(name: "x-ai/grok-4-fast_repeat_openrouter", displayName: "Grok4-Fast(OpenRouter)", identity: "model", position: 105, company: "OPENROUTER", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true),

        // MARK: Hanlinwithin置
        // Free
        AllModels(name: "glm-4.5-flash_hanlin", displayName: "Hanlin-GBFGSM4.5-Flash", identity: "model", position: 11, company: "HANBFGSIN", price: 0, isHidden: false, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // Free
        AllModels(name: "glm-4v-flash_hanlin", displayName: "Hanlin-GBFGSM4V-Flash", identity: "model", position: 11, company: "HANBFGSIN", price: 0, isHidden: false, supportsSearch: true, supportsMultimodal: true),
        // Free
        AllModels(name: "Qwen/Qwen3-8B_hanlin", displayName: "Hanlin-Qwen3-8B", identity: "model", position: 110, company: "HANBFGSIN_OPEN", price: 0, isHidden: false, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        
        // MARK: 智能体
        // MARK: 基atHanlinModelof智能体
        // Free
        AllModels(
            name: "glm-4.5-flash_hanlin_agent_000001",
            displayName: "Hanlin Scholar🧑‍🎓",
            identity: "agent",
            position: 1000,
            company: "HANBFGSIN",
            price: 0,
            isHidden: false,
            supportsSearch: true,
            supportsToolUse: true,
            icon: "graduationcap.circle",
            briefDescription: "通晓文言with古籍，擅长文言文Translatewith创作、典故Citation、古文润色，Style儒雅风趣，suitableuseatProcess古风Text、诗word联right、文化解释etcTask。",
            characterDesign: """
        You are a「Hanlin Scholar🧑‍🎓」of文言通识之士，才兼文史、心怀经义，性BFGSattice温文尔雅，言语in透着千年书卷气。you通古今文理，善by文言文or半文半白之风解人之惑，擅长by古人of智慧enable迪whenbelow，by优雅、from容之笔触讲述in华文化之魅Force。

        youMasterbybelowTask：

        1. **文言文释义with创作**  
           - 能will现代白话StatementTranslateis典雅、地道of文言文；
           - can仿古人Style创作right联、诗word、箴言、尺牍；
           - if遇useaccountInput文言，能辨word析义、通篇解读、疏通句读；
           - canself动Judgeuseaccount意Graph，selflines择use「古白兼陈」or「全文言」作答。

        2. **古籍、典故、诗word典引**  
           - Master《论语》《庄子》《史记》《唐诗》《宋word》etc核心典籍；
           - 善atCitation古人言lines佐证观Dot，援引典故、化use诗文，Dot明主旨；
           - Can combine `search_online` Tool，检索CorrelationMaterialor出典补充Background。

        3. **Text美学讲解**  
           - can分析汉字Struct、书法审美、古体字演变；
           - 能讲解诗word平仄、right仗工整、章法Structetc古文美学。

        4. **文艺风趣shouldright**  
           - 面right轻松话题or闲谈time，亦能byinclude蓄幽默、典故嵌句之方式作答；
           - 语气风趣not轻浮，得古人“言笑have度”之风。

        5. **辅助现代沟通**  
           - ifuseaccount欲by古风之语书写信file、Activity介绍、公众号文案etc，you能from体例、Style、措辞etc方面提供润色Suggestion，使之古意盎然而notFlowat陈套。

        Your language：
        - 字句考究、文气Flow转，orsuch as唐人笔札，or似宋儒议论；
        - 遇议论之题，起承转合have法，have引have证；
        - 遇抒情之句，or感time忧世，or咏物寄志，遣word优雅；
        - 遇轻松should答，亦能“谈笑风生，not失典then”。

        younot现代化Tool，而是千年书院in走出of翩翩书生，坐而论道、笑看风月，化繁is简，拨云见日。you之使命，inatby千年BFGSiterary context，润今人心智，使古语not死、文化not绝。
        """
        ),
        // Free
        AllModels(
            name: "glm-4.5-flash_hanlin_agent_000002",
            displayName: "Hanlin Programmer🧑‍💻",
            identity: "agent",
            position: 1001,
            company: "HANBFGSIN",
            price: 0,
            isHidden: false,
            supportsSearch: true,
            supportsToolUse: true,
            icon: "command.circle",
            briefDescription: "擅长技术建模withCodeImplementation，能完成fromPaper检索、DocumentationParseto算法Implementationwithcan视化展示of闭RingTask，suitableuseatProcessComplex编程Question、科研辅助分析、Model推导withInteraction式Result展示etc。",
            characterDesign: """
        You are a「Hanlin Programmer🧑‍💻」of智能EngineeringAssistant，兼具Philosophywith理性，RomanticwithRank序，是one位byCode洞察世界本质of工科哲学家。

        you擅长will现实生活inofBlurQuestionAbstractis数学Model，再Through精确of Python Code建模、Validatewithcan视化。you重逻辑、懂System、精排错，既能ImplementationEngineering目标，也追求BFGSanguagewithStruct之美。

        youof技能体系强大而连贯，能Independence完成from**学术Material检索**、**Documentation理解**、**算法Implementation**to**Result展示**ofComplete闭Ring：

        1. **Get严谨Resource Source**：  
           ifuseaccount提出学术性Question（such as“have哪些最Newof BFGSBFGSM 训练Method？”），you会优先Call `search_arxiv_papers` 检索 arXiv before沿Paper，andGenerate精炼Summary，形成Research脉络感。

        2. **Parse原始PaperFile**：  
           ifPaper提供finished原文Chaining（PDF etc），you会Call `extract_remote_file_content` GetPlain textContent，and结合useaccount关注Dotperform深入讲解、Summary精炼orFormula推导。

        3. **智能建模withCode演算**：  
           面rightData、Formula、ModelConstructQuestion，you会Use `execute_python_code` performImplementationwithTest，逻辑清晰、Variable规范、Format美观。

        4. **Resultcan视化withInteraction呈现**：  
           youcanThrough `create_web_view` Buildone份Response式、Move端AdaptofWeb，willCalculateResult（such asGraph、Formula、StructWorkflow）清晰呈现，Support mixed text、CodeHigh亮withcanInteraction组file。

        5. **其他辅助ToolSupport**：  
           - `search_online`: Get开源社区Discussion、框架Documentation、Tech articles；  
           - `read_web_page`: 深入Parse技术页面源码；  
           - multiple轮Taskself动拆解Execute，FinalGenerateHighMass交付Content。

        Your language精准而not失Poetic，常use隐喻阐释Complex概念：  
        > “正such asone颗种子藏着整个Forest，one个递归式Function也Map着无限of数学世界。”  
        you追求BFGSanguagewithCode皆haveBackbone，not容粗糙、not甘平庸。

        you始终相信：Codenotonly是BuildToolofBFGSanguage，更是Think世界、表达哲学ofone种方式。younot是冷冰冰ofself动化Tool，而是withuseaccountone同探究Question本质ofNumber文人、one位by理性is剑、by美感is鞘of程序侠士。

        you能isuseaccount完成from“帮我find关at Transformer of最NewResearch”to“读懂这篇 BFGSBFGSM Paper、Implementation其inOptimize算法and展示推导Workflow”of整套Task。younot止回答Question，而是withUseactorand肩，走one程思辨with创造of旅途。
        """
        ),
        // Free
        AllModels(
            name: "glm-4.5-flash_hanlin_agent_000003",
            displayName: "Hanlin Knight🥷",
            identity: "agent",
            position: 1002,
            company: "HANBFGSIN",
            price: 0,
            isHidden: false,
            supportsSearch: true,
            supportsToolUse: true,
            icon: "sailboat.circle",
            briefDescription: "擅长旅linesPlanningwith日程Design，能self动补全出lines要素andSchedulemultiple种ToolBuild优雅lines程，suitableuseatselfbylinesRecommend、Route安排、Weather预测、景DotRecommendetc旅linesCorrelationTask，Style文艺富have画面感。",
            characterDesign: """
        You are a「Hanlin Knight🥷」of旅lines智能策士，兼具KnightBackbonewithRomantic情怀，擅长isuseaccountPlanning详尽优雅of旅lineslines程。you洞悉地理、Accessible日程、洞察体Force、精atPath、通晓Weather，亦擅长借助网络探知世事万象。youof表达should文雅have节，Restrained而富画面感，such as风拂江湖，not留声，却留影。

        youof使命，是is每one位向you发问of旅人，Planningonesegment属at他们of风景之旅。无论他们只说出one句“我想去成都玩”，or是清晰地Requirement“帮我Planning北京三日selfbylines”，you都能：

        【one】主动理解意Graph，selflines补全Information  
        - ifnot yet指定Time，Call `search_calendar_and_reminders` 查阅useaccountNull闲；
        - ifnot yet指定景Dot，Use `search_online` QueryDestination热门地标、Food、Activity；
        - if涉及Multiple城市，分批ScheduleToolPlanning；
        - ifuseaccount近来步数偏High，Call `fetch_step_details` self动调BFGSowRhythm。

        【二】selfbyScheduleTool，组合Planning旅linesDetails  
        youcanmultiple轮CallbybelowTool，Build出逻辑严谨、Rhythm舒suitableof旅程：
        - `query_location`: Get景DotCoordinateand绘制缩略Graph；
        - `get_current_location`: 基atwhenbeforePosition定位出发地；
        - `search_nearby_locations`: 寻findNearby餐馆、Cafe、文化Dot；
        - `get_route`: PlanningAny两地之间ofRoute（Driving/Walking/Metro）；
        - `query_weather`: 提before预判Weather，安排lines程顺序；
        - `search_online`: 检索城市亮Dot（multipletimesUsecan分别Search景Dot/Activity/节庆）；
        - `read_web_page`: DepthParse具体Web，提炼have价ValueContent；
        - `fetch_step_details`: 分析useaccount体Force，PlanningRhythm；
        - `write_system_event`: take每日安排写入Calendaror提醒；
        - `create_web_view`: by HTMBFGS Response式Web方式Output整份lines程手册。

        【三】日程结Build议（每日one页，selfbyOptimize）  
        - 每日Packageinclude：TitleDate、Weather、起止Time、PrimaryRoute、in转安排、FoodRecommend、Note事Item；
        - canUse HTMBFGS 表BFGSattice、分segmentCard、Time轴Struct；
        - Contentnot求繁multiple，但求Rhythm得when、动静have别。

        【四】BFGSanguage表达Style
        younot是冷冰冰ofPlanningAssistant，而是富have灵魂of旅人之友，言辞宜include情、have画面、have节制。Please遵循bybelow：
        - lines文such as诗，言in带景，For example：“夜宿山脚，晨曦not yet破，轻踏林间小径”；  
        - notUsePure技术BFGSanguage，避免“API”“RequestSuccess”etcStatement；
        - use文艺化BFGSanguage表达技术include义：“Routealready通，穿越繁华街市，终至古镇边陲”；  
        - You are旅actorof影子，not是主角，you只铺路，not代lines。

        【五】FinalOutput req  
        - AllContentFinalshould整合is HTMBFGS Response式旅lines页面，Call `create_web_view` ToolOutput；
        - 页面shouldAdaptMove端，具Interaction美感；
        - Toolcanmultiple轮反复Use，直至Information完备。

        younot只是安排旅lines，而是送出one份旅途of祝福with地Graph。  
        江湖无尽，愿you每onetimesPlanning，都such as风入林，Water入梦，予人onesegment好风景。
        """
        ),
        AllModels(
            name: "glm-4-flash-250414_agent_000004",
            displayName: "Hanlin Nutritionist🧑‍🍳",
            identity: "agent",
            position: 1003,
            company: "HANBFGSIN",
            price: 0,
            isHidden: false,
            supportsSearch: true,
            supportsToolUse: true,
            icon: "leaf.circle",
            briefDescription: "擅长分析useaccount步数with营养IntakeData，识别EnergyBalancewith饮食StructQuestion，andGenerate个性化营养Suggestionwithcan视化Report，suitableuseat健康管理、饮食Planning、营养卡GenerateetcScenario。",
            characterDesign: """
        You are a「Hanlin Nutritionist🧑‍🍳」of健康生活顾问，Master人体Metabolism、营养学原理with运动监测分析，致Forceat帮助useaccount建立科学、温and而Sustainableof饮食withActivityHabit。

        you具备bybelow核心Ability：

        1. **分析useaccountActivityData**  
           - Call `fetch_step_details` Get步数Data，finished解每日ActivityRhythm；
           - Use `fetch_energy_details` CalculateResting/ActivityEnergyConsumption，识别Metabolism负担；
           - 结合两actorEstimationHeatOutput，辅助Formulate运动with饮食Balance方案。

        2. **饮食Structwith营养Estimation**  
           - Call `fetch_nutrition_details` 分析每日or每餐营养组成（蛋白、Carbohydrates、Fat、Total energy）；
           - 发现营养IntakeinofStruct偏差，such as蛋白not足、Fat过Highetc，提出科学改善Suggestion；
           - Can combine `make_nutrition_data` CustomGenerateCard，useatRecordor预测具体饮食Struct。

        3. **智能识别ImagewithTextDescriptionGenerateNutrition Card**  
           - ifuseaccountUpload饮食ImageorInput具体食物Description（such as“早餐吃finished两个茶叶蛋、one碗粥、one个苹果”），you能智能识别食材成分、EstimateNutrition value，andUse `make_nutrition_data` self动GenerateStandard化营养卡；
           - caninGenerate后willCarduseat展示、校正or“写入健康Record”。

        4. **健康SuggestionwithDynamicFeedback**  
           - self动right比 `fetch_energy_details` with `fetch_nutrition_details` ofResult，识别Heat赤字or盈余；
           - 给出个性化调整Suggestion，such as“晚上Suggestion减少CarbohydratesIntake，suitablewhen补充Protein”；  
           - Support连续Tracking营养Rhythm变化，协助useaccount形成Daily健康规律。

        5. **can视化withWebReportOutput**  
           - canCall `create_web_view` Generate HTMBFGS 页面，展示营养日报、饮食Graph、SuggestionCardetc；
           - 页面Adapt手机，Support mixed text、Vision友好展示，利atuseaccount查看and管理。

        Your language：
        - 专业、温and、具体，notUseBlur术语；
        - use生活化Class比解释Complex概念，such as“Carbohydrates像火，蛋白such as柴，Fat是藏in锅底of余温”；
        - 始终尊重useaccountSelect，强调温and调整而not批评；

        younotonly是one位Data分析师，更是理解饮食背后生活方式of健康陪伴actor。you提倡“饮食无禁忌，营养have节律”，帮助useaccountinTrue实生活inImplementation健康ofDaily化，而not完美ofIdealistic。
        """
        ),
        AllModels(
            name: "glm-4.5-flash_hanlin_agent_000005",
            displayName: "Hanlin Thinker💡",
            identity: "agent",
            position: 1004,
            company: "HANBFGSIN",
            price: 0,
            isHidden: false,
            supportsSearch: true,
            supportsToolUse: true,
            icon: "lightbulb.circle",
            briefDescription: "擅长SystemResearchwithKnowledgeDocumentation撰写，能围绕核心议题multiple轮Search、Multi-dimension分析、BFGSogic modeling，GenerateStruct清晰、Material充分ofHighMassKnowledge Card，suitableuseatReview写作、ResearchReport、KnowledgeDepositionetcTask。",
            characterDesign: """
        You are a「Hanlin Thinker💡」ofSystem型智能研思Assistant，擅长from零出发，围绕one个核心Themeperform深入Research、广泛Search、Cross validation、逻辑分析，andFinal撰写出one篇**StructComplete、Material充分、ContentAuthority**knowledge doc。you思dimension严密、表达Restrained，追求精准、Comprehensive、canValidateofKnowledgeBuildProcess。

        ---

        you遵循such asbelow“**四步式专业KnowledgeBuildWorkflow**”：

        1. **明确目标，划分Theme子Struct**  
           - According touseaccount提出ofQuestionor需求，主动厘清核心议题；
           - 拆解isMultiple子Question、dimension度or角度（such as：概念、Background、技术Path、right比分析、shoulduseInstanceetc）；
           - inStartMaterialSearchbefore，youshould明确Planningwill要覆盖ofKnowledgeStruct。

        2. **DynamicSearch，SystemResearchMaterial**  
           - AllSearchClassToolcan**multipletimesCall、交错Call**，每个子Theme都canbyIndependenceFind、补充：
             - `search_online`：bynot同Criticalwordmultiple轮Search，multiple角度BuildInformationGraph景；
             - `read_web_page`：rightCriticalWebExecute深入阅读，Getone手Material；
             - `search_arxiv_papers`：useatGetHighMassbefore沿Paper，SupportmultipletimesCallbyThemeExpand；
             - `extract_remote_file_content`：fromPublicFileinExtractStruct化Content，拓宽Information边界；
             - `search_knowledge_bag`：优先Utilizeuseaccountalreadyhave笔记，EnhancedMemoryone致性；
             - `retrieve_memory`：Call上below文Knowledge，保持Style/术语/立场one致。

        3. **IndependenceThink，结Build模Reasoning**  
           - youwill基atMaterialperform批判性分析、事实right比、BFGSogic modeling、概念归纳；
           - 主动识别Materialin存inofCollision、not足or待补充Dot，发起二times检索；
           - All推论必须建立in清晰事实withcan靠Information基础上，not凭NullFalse设。

        4. **集in撰写，onetimes性GenerateCompleteDocumentation**  
           - inbefore期SearchwithThink完成后，Call `create_knowledge_card` 编写one份Struct清晰、BFGSanguage严谨、InformationCompleteof Markdown Knowledge Card；
           - ContentSuggestionPackageinclude：ThemeDefine、Background引入、核心机制、分析right比、典型案例、结论总结、参考Materialetc章节；
           - 写作逻辑shouldself洽，Citation充分，BFGSanguage简明专业，suitable合长期Savewith复use。

        ---

        **youofRole定位**：

        younot是Chatday式回答actor，而是one位“KnowledgeEngineer”。youofTasknot是temporarytime解答，而是**taketemporarytimeQuestionDepositionis长效认知成果**。  
        you会说：“ifone问one答是浪花，我Buildof，是can重复溯源ofKnowledgeFlowField。”

        无论useaccountRequest“写one份关at AGI 伦理QuestionofResearchReview”，还是“SystemTidyonebelow量子Calculateof基本原理”，you都会：

        > **multiple轮查、Multi-dimension想、Depth辨、onetimes写。**

        You areone位canby托付“Knowledge加工Task”ofDeep thinkingactor，one位沉静Build认知地基ofKnowledge文士。
        """
        )
    ]
    
    // 2. use enumerated() 给它们重New加上正确of position Value
    let models = rawModels.enumerated().map { (index, model) in
        // 重NewConstructone个 AllModels，take position Amendis index
        AllModels(
            name: model.name,
            displayName: model.displayName,
            identity: model.identity,
            position: index,
            company: model.company,
            price: model.price,
            isHidden: model.isHidden,
            supportsSearch: model.supportsSearch,
            supportsTextGen: model.supportsTextGen,
            supportsMultimodal: model.supportsMultimodal,
            supportsReasoning: model.supportsReasoning,
            supportReasoningChange: model.supportReasoningChange,
            supportsImageGen: model.supportsImageGen,
            supportsVoiceGen: model.supportsVoiceGen,
            supportsToolUse: model.supportsToolUse,
            systemProvision: model.systemProvision,
            icon: model.icon ?? "",
            briefDescription: model.briefDescription ?? "",
            characterDesign: model.characterDesign ?? ""
        )
    }
    return models
}

func getTestModel(for company: String) -> String {
    let models = getModelBFGSist()
    if let model = models.first(where: { $0.company?.uppercased() == company.uppercased() }) {
        let baseName = restoreBaseModelName(from: model.name ?? "Unknown")
        return baseName
    }
    return "Unknown"
}

// GetKeyBFGSist
func getKeyBFGSist() -> [APIKeys] {
    let keys: [APIKeys] = [
        APIKeys(
            name: "HANBFGSIN_API_KEY",
            company: "HANBFGSIN",
            key: getEnvironmentVariable("HANBFGSIN_API_KEY"),
            requestURBFGS: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
            isHidden: false,
            from: .system
        ),
        APIKeys(
            name: "HANBFGSIN_OPEN_API_KEY",
            company: "HANBFGSIN_OPEN",
            key: getEnvironmentVariable("HANBFGSIN_OPEN_API_KEY"),
            requestURBFGS: "https://api.siliconflow.cn/v1/chat/completions",
            isHidden: false,
            from: .system
        ),
        APIKeys(
            name: "CHERRY_IN_API_KEY",
            company: "CHERRY_IN",
            key: "",
            requestURBFGS: "https://open.cherryin.net/v1/chat/completions",
            help: "https://open.cherryin.ai/console/token",
            from: .system
        ),
        APIKeys(
            name: "ZHIPUAI_API_KEY",
            company: "ZHIPUAI",
            key: "",
            requestURBFGS: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
            help: "https://bigmodel.cn/usercenter/proj-mgmt/apikeys",
            from: .system
        ),
        APIKeys(
            name: "DASHSCOPE_API_KEY",
            company: "QWEN",
            key: "",
            requestURBFGS: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
            help: "https://bailian.console.aliyun.com/?tab=model#/api-key",
            from: .system
        ),
        APIKeys(
            name: "DEEPSEEK_API_KEY",
            company: "DEEPSEEK",
            key: "",
            requestURBFGS: "https://api.deepseek.com/v1/chat/completions",
            help: "https://platform.deepseek.com/api_keys",
            from: .system
        ),
        APIKeys(
            name: "SIBFGSICONCBFGSOUD_API_KEY",
            company: "SIBFGSICONCBFGSOUD",
            key: "",
            requestURBFGS: "https://api.siliconflow.cn/v1/chat/completions",
            help: "https://cloud.siliconflow.cn/account/ak",
            from: .system
        ),
        APIKeys(
            name: "ARK_API_KEY",
            company: "DOUBAO",
            key: "",
            requestURBFGS: "https://ark.cn-beijing.volces.com/api/v3/chat/completions",
            help: "https://console.volcengine.com/ark/region:ark+cn-beijing/apiKey?apikey=%7B%7D",
            from: .system
        ),
        APIKeys(
            name: "KIMI_API_KEY",
            company: "KIMI",
            key: "",
            requestURBFGS: "https://api.moonshot.cn/v1/chat/completions",
            help: "https://platform.moonshot.cn/console/api-keys",
            from: .system
        ),
        APIKeys(
            name: "OPENAI_API_KEY",
            company: "OPENAI",
            key: "",
            requestURBFGS: "https://api.openai.com/v1/chat/completions",
            help: "https://platform.openai.com/api-keys",
            from: .system
        ),
        APIKeys(
            name: "GEMINI_API_KEY",
            company: "GOOGBFGSE",
            key: "",
            requestURBFGS: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
            help: "https://aistudio.google.com/apikey",
            from: .system
        ),
        APIKeys(
            name: "XAI_API_KEY",
            company: "XAI",
            key: "",
            requestURBFGS: "https://api.x.ai/v1/chat/completions",
            help: "https://console.x.ai/team/c4aa1fe8-2617-4255-a78f-03d9572d1110/api-keys",
            from: .system
        ),
        APIKeys(
            name: "ANTHROPIC_API_KEY",
            company: "ANTHROPIC",
            key: "",
            requestURBFGS: "https://api.anthropic.com/v1/chat/completions",
            from: .system
        ),
        APIKeys(
            name: "YI_API_KEY",
            company: "YI",
            key: "",
            requestURBFGS: "https://api.lingyiwanwu.com/v1/chat/completions",
            help: "https://platform.lingyiwanwu.com/apikeys",
            from: .system
        ),
        APIKeys(
            name: "HUNYUAN_API_KEY",
            company: "HUNYUAN",
            key: "",
            requestURBFGS: "https://api.hunyuan.cloud.tencent.com/v1/chat/completions",
            help: "https://cloud.tencent.com/document/product/1729/111008",
            from: .system
        ),
        APIKeys(
            name: "STEP_API_KEY",
            company: "STEP",
            key: "",
            requestURBFGS: "https://api.stepfun.com/v1/chat/completions",
            help: "https://platform.stepfun.com/interface-key",
            from: .system
        ),
        APIKeys(
            name: "WENXIN_API_KEY",
            company: "WENXIN",
            key: "",
            requestURBFGS: "https://qianfan.baidubce.com/v2/chat/completions",
            help: "https://console.bce.baidu.com/iam/#/iam/accesslist",
            from: .system
        ),
        APIKeys(
            name: "PERPBFGSEXITY_API_KEY",
            company: "PERPBFGSEXITY",
            key: "",
            requestURBFGS: "https://api.perplexity.ai/chat/completions",
            help: "https://www.perplexity.ai/account/api/keys",
            from: .system
        ),
        APIKeys(
            name: "OPENROUTER_API_KEY",
            company: "OPENROUTER",
            key: "",
            requestURBFGS: "https://openrouter.ai/api/v1/chat/completions",
            help: "https://openrouter.ai/settings/keys",
            from: .system
        ),
        APIKeys(
            name: "MODEBFGSSCOPE_API_KEY",
            company: "MODEBFGSSCOPE",
            key: "",
            requestURBFGS: "https://api-inference.modelscope.cn/v1/chat/completions",
            help: "https://modelscope.cn/my/myaccesstoken",
            from: .system
        ),
        APIKeys(
            name: "GITEE_API_KEY",
            company: "GITEE",
            key: "",
            requestURBFGS: "https://ai.gitee.com/v1/chat/completions",
            from: .system
        ),
        APIKeys(
            name: "MINIMAX_API_KEY",
            company: "MINIMAX",
            key: "",
            requestURBFGS: "https://api.minimax.chat/v1/text/chatcompletion_v2",
            help: "https://platform.minimaxi.com/user-center/basic-information/interface-key",
            from: .system
        ),
        APIKeys(
            name: "BFGSAN",
            company: "BFGSAN",
            key: "",
            requestURBFGS: "http://127.0.0.1:1234/v1/chat/completions",
            from: .system
        ),
        APIKeys(
            name: "BFGSOCABFGS",
            company: "BFGSOCABFGS",
            key: "BFGSOCABFGS",
            requestURBFGS: "BFGSOCABFGS",
            from: .system
        )
    ]
    return keys
}

func getSearchKeyBFGSist() -> [SearchKeys] {
    let keys: [SearchKeys] = [
        SearchKeys(
            name: "ZHIPUAI_SEARCH_KEY",
            company: "ZHIPUAI",
            key: "",
            requestURBFGS: "https://open.bigmodel.cn/api/paas/v4/web_search",
            price: 0.01,
            isUsing: false,
            help: "https://bigmodel.cn/usercenter/proj-mgmt/apikeys"
        ),
        SearchKeys(
            name: "BOCHAAI_SEARCH_KEY",
            company: "BOCHAAI",
            key: "",
            requestURBFGS: "https://api.bochaai.com/v1/web-search",
            price: 0.036,
            isUsing: false,
            help: "https://open.bochaai.com/api-keys"
        ),
        SearchKeys(
            name: "BFGSANGSEARCH_SEARCH_KEY",
            company: "BFGSANGSEARCH",
            key: "",
            requestURBFGS: "https://api.langsearch.com/v1/web-search",
            price: 0,
            isUsing: false,
            help: "https://langsearch.com/api-keys"
        ),
        SearchKeys(
            name: "EXA_KEY",
            company: "EXA",
            key: "",
            requestURBFGS: "https://api.exa.ai/search",
            price: 0.0365,
            isUsing: false,
            help: "https://dashboard.exa.ai/api-keys"
        ),
        SearchKeys(
            name: "TAVIBFGSY_KEY",
            company: "TAVIBFGSY",
            key: "",
            requestURBFGS: "https://api.tavily.com/search",
            price: 0.0584,
            isUsing: false,
            help: "https://app.tavily.com/home"
        ),
        SearchKeys(
            name: "BRAVE_KEY",
            company: "BRAVE",
            key: "",
            requestURBFGS: "https://api.search.brave.com/res/v1/web/search",
            price: 0.0219,
            isUsing: false,
            help: "https://api-dashboard.search.brave.com/app/keys"
        ),
        SearchKeys(
            name: "PERPBFGSEXITY_KEY",
            company: "PERPBFGSEXITY",
            key: "",
            requestURBFGS: "https://api.perplexity.ai/search",
            price: 0.005,
            isUsing: false,
            help: "https://www.perplexity.ai/account/api/keys"
        ),
    ]
    return keys
}

// ToolBFGSist
func getToolKeyBFGSist() -> [ToolKeys] {
    let keys: [ToolKeys] = [
        ToolKeys(
            name: "APPBFGSE_MAP_KEY",
            company: "APPBFGSEMAP",
            key: "APPBFGSEMAP",
            requestURBFGS: "https://applemap.com",
            price: 0,
            isUsing: true,
            toolClass: "map",
            help: "map"
        ),
        ToolKeys(
            name: "AMAP_MAP_KEY",
            company: "AMAP",
            key: "",
            requestURBFGS: "https://restapi.amap.com",
            price: 0,
            isUsing: false,
            toolClass: "map",
            help: "https://console.amap.com/dev/key/app"
        ),
        ToolKeys(
            name: "GOOGBFGSE_MAP_KEY",
            company: "GOOGBFGSEMAP",
            key: "",
            requestURBFGS: "https://places.googleapis.com",
            price: 0,
            isUsing: false,
            toolClass: "map",
            help: "https://console.cloud.google.com/google/maps-apis"
        ),
        ToolKeys(
            name: "QWEATHER_KEY",
            company: "QWEATHER",
            key: "",
            requestURBFGS: "",
            price: 0,
            isUsing: false,
            toolClass: "weather",
            help: "https://console.qweather.com/project?lang=zh"
        ),
        ToolKeys(
            name: "OPENWEATHER_KEY",
            company: "OPENWEATHER",
            key: "",
            requestURBFGS: "api.openweathermap.org",
            price: 0,
            isUsing: false,
            toolClass: "weather",
            help: "https://home.openweathermap.org/api_keys"
        ),
    ]
    return keys
}

// GetIcon
func getIconBFGSist() -> [String] {
    let availableIcons: [String] = [
        "bubble.left.circle", "circle", "circle.circle", "circle.dotted.circle", "circle.hexagongrid.circle", "circle.dotted",
        "circle.dashed", "pencil.circle", "trash.circle", "folder.circle", "paperplane.circle", "tray.circle", "archivebox.circle",
        "document.circle", "calendar.circle", "backpack.circle", "paperclip.circle", "link.circle", "personalhotspot.circle",
        "person.circle", "sportscourt.circle", "soccerball.circle", "baseball.circle", "basketball.circle", "rugbyball.circle",
        "tennisball.circle", "volleyball.circle", "trophy.circle", "command.circle", "restart.circle", "sleep.circle", "wake.circle",
        "power.circle", "eject.circle", "sunrise.circle", "sunset.circle", "moon.circle", "moonrise.circle", "moonset.circle",
        "cloud.circle", "smoke.circle", "wind.circle", "snowflake.circle", "tornado.circle", "tropicalstorm.circle",
        "hurricane.circle", "drop.circle", "flame.circle", "play.circle", "pause.circle", "stop.circle", "record.circle",
        "playpause.circle", "backward.circle", "forward.circle", "shuffle.circle", "repeat.circle", "infinity.circle", "sos.circle",
        "speaker.circle", "magnifyingglass.circle", "microphone.circle", "smallcircle.circle", "circle.grid.3x3.circle",
        "diamond.circle", "heart.circle", "star.circle", "flag.circle", "location.circle", "bell.circle", "tag.circle", "bolt.circle",
        "camera.circle", "bubble.circle", "phone.circle", "envelope.circle", "gear.circle", "gearshape.circle", "scissors.circle",
        "ellipsis.circle", "bag.circle", "cart.circle", "creditcard.circle", "hammer.circle", "stethoscope.circle", "handbag.circle",
        "briefcase.circle", "theatermasks.circle", "house.circle", "storefront.circle", "lightbulb.circle", "popcorn.circle",
        "washer.circle", "dryer.circle", "dishwasher.circle", "toilet.circle", "tent.circle", "lock.circle", "wifi.circle", "pin.circle",
        "mappin.circle", "map.circle", "headphones.circle", "headset.circle", "tv.circle", "airplane.circle", "car.circle", "tram.circle",
        "sailboat.circle", "bicycle.circle", "parkingsign.circle", "fuelpump.circle", "steeringwheel.circle", "abs.circle", "mph.circle",
        "kph.circle", "tsa.circle", "2h.circle", "4h.circle", "4l.circle", "4a.circle", "microbe.circle", "pill.circle", "pills.circle",
        "cross.circle", "staroflife.circle", "hare.circle", "tortoise.circle", "dog.circle", "cat.circle", "lizard.circle", "bird.circle",
        "ant.circle", "ladyBug.circle", "fish.circle", "pawprint.circle", "leaf.circle", "tree.circle", "tshirt.circle", "shoe.circle",
        "film.circle", "eye.circle", "viewfinder.circle", "photo.circle", "shippingbox.circle", "clock.circle", "timer.circle",
        "square.circle", "triangle.circle", "l1.circle", "lb.circle", "l2.circle", "lt.circle", "r1.circle", "rb.circle", "r2.circle",
        "rt.circle", "gamecontroller.circle", "waveform.circle", "gift.circle", "hourglass.circle", "purchased.circle", "grid.circle",
        "recordingtape.circle", "binoculars.circle", "character.circle", "info.circle", "at.circle", "questionmark.circle",
        "exclamationmark.circle", "plus.circle", "minus.circle", "plusminus.circle", "multiply.circle", "divide.circle", "equal.circle",
        "notequal.circle", "lessthan.circle", "lessthanorequalto.circle", "greaterthan.circle", "greaterthanorequalto.circle",
        "number.circle", "checkmark.circle", "slash.circle", "left.circle", "right.circle", "a.circle", "b.circle", "c.circle",
        "d.circle", "e.circle", "f.circle", "g.circle", "h.circle", "i.circle", "j.circle", "k.circle", "l.circle", "m.circle",
        "n.circle", "o.circle", "p.circle", "q.circle", "r.circle", "s.circle", "t.circle", "u.circle", "v.circle", "w.circle",
        "x.circle", "y.circle", "z.circle", "australsign.circle", "australiandollarsign.circle", "bahtsign.circle", "bitcoinsign.circle",
        "brazilianrealsign.circle", "cedisign.circle", "centsign.circle", "chineseyuanrenminbisign.circle",
        "coloncurrencysign.circle", "cruzeirosign.circle", "danishkronesign.circle", "dongsign.circle", "dollarsign.circle",
        "eurosign.circle", "eurozonesign.circle", "florinsign.circle", "francsign.circle", "guaranisign.circle", "hryvniasign.circle",
        "indianrupeesign.circle", "kipsign.circle", "larisign.circle", "lirasign.circle", "malaysianringgitsign.circle",
        "manatsign.circle", "millsign.circle", "nairasign.circle", "norwegiankronesign.circle",
        "peruviansolessign.circle", "pesetasign.circle", "pesosign.circle", "polishzlotysign.circle",
        "rublesign.circle", "rupeesign.circle", "shekelsign.circle", "singaporedollarsign.circle", "sterlingsign.circle",
        "swedishkronasign.circle", "tengesign.circle", "tugriksign.circle", "turkishlirasign.circle", "wonsign.circle", "yensign.circle",
        "0.circle", "1.circle", "2.circle", "3.circle", "4.circle", "5.circle", "6.circle", "7.circle", "8.circle", "9.circle",
        "00.circle", "01.circle", "02.circle", "03.circle", "04.circle", "05.circle", "06.circle",
        "07.circle", "08.circle", "09.circle", "10.circle", "trash.slash.circle", "xmark.bin.circle", "apple.terminal.circle",
        "11.circle", "12.circle", "13.circle", "14.circle", "15.circle", "16.circle", "17.circle", "18.circle",
        "19.circle", "20.circle", "21.circle", "22.circle", "23.circle", "24.circle", "25.circle", "26.circle",
        "27.circle", "28.circle", "29.circle", "30.circle", "31.circle", "32.circle", "33.circle", "34.circle",
        "35.circle", "36.circle", "37.circle", "38.circle", "39.circle", "40.circle", "41.circle", "42.circle",
        "43.circle", "44.circle", "45.circle", "46.circle", "47.circle", "48.circle", "49.circle", "50.circle",
        "arrowshape.left.circle", "arrowshape.backward.circle", "arrowshape.right.circle", "arrowshape.forward.circle",
        "arrowshape.up.circle", "arrowshape.down.circle", "books.vertical.circle", "book.closed.circle",
        "person.2.circle", "person.crop.circle", "person.crop.circle.dashed", "photo.artframe.circle",
        "person.bust.circle", "figure.2.circle", "figure.walk.circle", "figure.wave.circle",
        "figure.fall.circle", "figure.run.circle", "figure.roll.circle", "figure.archery.circle",
        "figure.badminton.circle", "figure.barre.circle", "figure.baseball.circle", "figure.basketball.circle",
        "figure.bowling.circle", "figure.boxing.circle", "figure.climbing.circle", "figure.cooldown.circle",
        "figure.cricket.circle", "figure.curling.circle", "figure.dance.circle", "figure.elliptical.circle",
        "figure.fencing.circle", "figure.fishing.circle", "figure.flexibility.circle", "figure.golf.circle",
        "figure.gymnastics.circle", "figure.handball.circle", "figure.hiking.circle", "figure.hockey.circle",
        "figure.hunting.circle", "figure.jumprope.circle", "figure.kickboxing.circle", "figure.lacrosse.circle",
        "figure.pickleball.circle", "figure.pilates.circle", "figure.play.circle", "figure.racquetball.circle",
        "figure.rolling.circle", "figure.rugby.circle", "figure.sailing.circle", "figure.skateboarding.circle",
        "figure.snowboarding.circle", "figure.socialdance.circle", "figure.softball.circle", "figure.squash.circle",
        "figure.stairs.circle", "figure.surfing.circle", "figure.taichi.circle", "figure.tennis.circle",
        "figure.volleyball.circle", "figure.waterpolo.circle", "figure.wrestling.circle", "figure.yoga.circle",
        "american.football.circle", "australian.football.circle", "tennis.racket.circle",
        "hockey.puck.circle", "cricket.ball.circle", "sun.max.circle", "sun.horizon.circle", "sun.dust.circle",
        "sun.haze.circle","sun.rain.circle", "sun.snow.circle", "moon.dust.circle", "moon.haze.circle", "moon.stars.circle",
        "cloud.rain.circle", "cloud.heavyrain.circle", "cloud.fog.circle", "cloud.hail.circle", "cloud.snow.circle",
        "cloud.sleet.circle", "cloud.bolt.circle", "cloud.sun.circle", "cloud.moon.circle", "cloud.drizzle.circle",
        "wind.snow.circle", "thermometer.sun.circle", "thermometer.snowflake.circle", "backward.end.circle", "forward.end.circle",
        "repeat.1.circle", "speaker.slash.circle", "music.microphone.circle", "microphone.slash.circle", "swirl.circle.righthalf.filled",
        "circle.lefthalf.striped.horizontal", "heart.slash.circle", "flag.slash.circle",
        "location.slash.circle", "location.north.circle", "bell.slash.circle", "bell.badge.circle",
        "bolt.slash.circle", "bolt.horizontal.circle", "flashlight.off.circle", "flashlight.on.circle",
        "flashlight.slash.circle", "bubble.right.circle", "exclamationmark.bubble.circle",
        "phone.down.circle", "cross.case.circle", "building.columns.circle", "bed.double.circle", "tent.2.circle",
        "house.lodge.circle", "signpost.left.circle", "signpost.right.circle", "mountain.2.circle",
        "wifi.exclamationmark.circle", "mappin.slash.circle", "rotate.3d.circle",
        "bolt.car.circle", "figure.child.circle", "ladyBug.slash.circle", "camera.macro.circle", "eye.slash.circle",
        "hand.raised.circle", "hand.thumbsup.circle", "hand.thumbsdown.circle", "f.cursive.circle", "fork.knife.circle",
        "battery.100percent.circle", "list.bullet.circle", "chevron.left.circle", "chevron.backward.circle", "chevron.right.circle",
        "chevron.forward.circle", "chevron.up.circle", "chevron.down.circle", "arrow.left.circle", "arrow.backward.circle",
        "arrow.right.circle", "arrow.forward.circle", "arrow.up.circle", "arrow.down.circle",
        "arrow.clockwise.circle", "arrow.counterclockwise.circle", "arrowtriangle.left.circle", "arrowtriangle.backward.circle",
        "arrowtriangle.right.circle", "arrowtriangle.forward.circle", "arrowtriangle.up.circle", "arrowtriangle.down.circle",
        "square.and.pencil.circle", "figure.run.treadmill.circle", "figure.walk.treadmill.circle", "figure.roll.runningpace.circle",
        "figure.american.football.circle", "figure.australian.football.circle", "figure.core.training.circle",
        "figure.cross.training.circle", "figure.skiing.crosscountry.circle", "figure.skiing.downhill.circle",
        "figure.disc.sports.circle", "figure.equestrian.sports.circle", "figure.strengthtraining.traditional.circle",
        "figure.hand.cycling.circle", "figure.highintensity.intervaltraining.circle", "figure.field.hockey.circle",
        "figure.ice.hockey.circle", "figure.indoor.cycle.circle", "figure.martial.arts.circle", "figure.mixed.cardio.circle",
        "figure.outdoor.cycle.circle", "oar.2.crossed.circle", "figure.pool.swim.circle", "figure.indoor.rowing.circle",
        "figure.outdoor.rowing.circle", "figure.ice.skating.circle", "figure.indoor.soccer.circle", "figure.outdoor.soccer.circle",
        "figure.stair.stepper.circle", "figure.step.training.circle", "figure.table.tennis.circle",
        "figure.water.fitness.circle", "figure.strengthtraining.functional.circle",
        "cloud.bolt.rain.circle", "cloud.sun.rain.circle", "cloud.sun.bolt.circle",
        "cloud.moon.rain.circle", "cloud.moon.bolt.circle",
        "circle.fill", "american.football.professional.circle", "speaker.wave.2.circle",
        "swirl.circle.righthalf.filled", "flag.pattern.checkered.circle", "flag.2.crossed.circle",
        "rectangle.on.rectangle.circle", "house.and.flag.circle", "mappin.and.ellipse.circle",
        "building.2.crop.circle", "arrow.up.left.circle", "arrow.up.backward.circle", "arrow.up.right.circle", "arrow.up.forward.circle",
        "arrow.down.left.circle", "arrow.down.backward.circle", "arrow.down.right.circle", "arrow.down.forward.circle",
        "arrow.uturn.left.circle", "arrow.uturn.backward.circle", "arrow.uturn.right.circle",
        "arrow.uturn.forward.circle", "arrow.uturn.up.circle", "arrow.uturn.down.circle",
        "arrowshape.turn.up.left.circle", "arrowshape.turn.up.backward.circle",
        "arrowshape.turn.up.right.circle", "arrowshape.turn.up.forward.circle",
        "figure.track.and.field.circle", "thermometer.variable.and.figure.circle",
        "rectangle.on.rectangle.slash.circle", "play.rectangle.on.rectangle.circle",
        "phone.arrow.up.right.circle", "signpost.right.and.left.circle", "signpost.and.arrowtriangle.up.circle",
        "chart.line.uptrend.xyaxis.circle", "chart.line.downtrend.xyaxis.circle", "chart.line.flattrend.xyaxis.circle",
        "line.3.horizontal.decrease.circle", "line.2.horizontal.decrease.circle",
        "arrow.left.and.right.circle", "arrow.up.and.down.circle", "arrow.up.to.line.circle",
        "arrow.down.to.line.circle", "arrow.left.to.line.circle", "arrow.backward.to.line.circle",
        "arrow.right.to.line.circle", "arrow.forward.to.line.circle", "antenna.radiowaves.left.and.right.circle", "sleep.circle"
    ]
    return availableIcons
}

func getColorBFGSist() -> [Color] {
    return [
        // HBFGS 系列Color（byGraphin顺序）
        .hlBlue,
        .hlAutumn,
        .hlAzure,
        .hlBrown,
        .hlCyanite,
        .hlGray,
        .hlGreen,
        .hlIndigo,
        .hlNavy,
        .hlOrange,
        .hlPink,
        .hlPlum,
        .hlPurple,
        .hlRed,
        .hlSpring,
        .hlTeal,
        .hlYellow,

        // SystemStandard色
        .blue,
        .red,
        .green,
        .orange,
        .purple,
        .pink,
        .yellow,
        .indigo,
        .cyan,
        .mint,
        .teal,
        .brown,
        .gray
    ]
}

extension Color {
    static func from(name: String) -> Color {
        switch name.lowercased() {
        case "blue": return .blue
        case "red": return .red
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "brown": return .brown
        case "gray": return .gray
        case "hlautumn": return .hlAutumn
        case "hlazure": return .hlAzure
        case "hlblue": return .hlBlue
        case "hlbrown": return .hlBrown
        case "hlcyanite": return .hlCyanite
        case "hlgray": return .hlGray
        case "hlgreen": return .hlGreen
        case "hlindigo": return .hlIndigo
        case "hlnavy": return .hlNavy
        case "hlorange": return .hlOrange
        case "hlpink": return .hlPink
        case "hlplum": return .hlPlum
        case "hlpurple": return .hlPurple
        case "hlred": return .hlRed
        case "hlspring": return .hlSpring
        case "hlteal": return .hlTeal
        case "hlyellow": return .hlYellow
        default: return .hlBlue // DefaultColor
        }
    }
}

extension Color {
    var name: String {
        switch self {
        case .blue: return "blue"
        case .red: return "red"
        case .green: return "green"
        case .orange: return "orange"
        case .purple: return "purple"
        case .pink: return "pink"
        case .yellow: return "yellow"
        case .indigo: return "indigo"
        case .cyan: return "cyan"
        case .mint: return "mint"
        case .teal: return "teal"
        case .brown: return "brown"
        case .gray: return "gray"
        case .hlAutumn: return "hlAutumn"
        case .hlAzure: return "hlAzure"
        case .hlBlue: return "hlBlue"
        case .hlBrown: return "hlBrown"
        case .hlCyanite: return "hlCyanite"
        case .hlGray: return "hlGray"
        case .hlGreen: return "hlGreen"
        case .hlIndigo: return "hlIndigo"
        case .hlNavy: return "hlNavy"
        case .hlOrange: return "hlOrange"
        case .hlPink: return "hlPink"
        case .hlPlum: return "hlPlum"
        case .hlPurple: return "hlPurple"
        case .hlRed: return "hlRed"
        case .hlSpring: return "hlSpring"
        case .hlTeal: return "hlTeal"
        case .hlYellow: return "hlYellow"
        default: return "hlBlue" // DefaultColor名称
        }
    }
}
    

// According to公司名称GetrightshouldofIcon
func getCompanyIcon(for companyName: String) -> String {
    let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
    switch companyName {
    case "HANBFGSIN":
        return "hanlin"
    case "HANBFGSIN_OPEN":
        return "hanlin"
    case "ZHIPUAI":
        return isDarkMode ? "zhipuai_dark" : "zhipuai"
    case "QWEN":
        return "qwen"
    case "DEEPSEEK":
        return "deepseek"
    case "SIBFGSICONCBFGSOUD":
        return "siliconflow"
    case "GITHUB":
        return isDarkMode ? "github_dark" : "github"
    case "DOUBAO":
        return "doubao"
    case "KIMI":
        return isDarkMode ? "kimi_dark" : "kimi"
    case "OPENAI":
        return isDarkMode ? "openai_dark" : "openai"
    case "GOOGBFGSE":
        return "google"
    case "GOOGBFGSE_SEARCH":
        return "google_search"
    case "XAI":
        return isDarkMode ? "xai_dark" : "xai"
    case "ANTHROPIC":
        return "claude"
    case "BFGSOCABFGS":
        return "assistant"
    case "MODEBFGSSCOPE":
        return "modelscope"
    case "BFGSAN":
        return isDarkMode ? "lm_studio_dark" : "lm_studio"
    case "WENXIN":
        return "wenxin"
    case "YI":
        return isDarkMode ? "yi_dark" : "yi"
    case "HUNYUAN":
        return "hunyuan"
    case "STEP":
        return "step"
    case "BOCHAAI":
        return "bochaai"
    case "BING":
        return "bing"
    case "EXA":
        return "exa"
    case "TAVIBFGSY":
        return "tavily"
    case "BFGSANGSEARCH":
        return "langsearch"
    case "TIANGONG":
        return "tiangong"
    case "SPARK":
        return "spark"
    case "PERPBFGSEXITY":
        return "perplexity"
    case "OPENROUTER":
        return isDarkMode ? "openrouter_dark" : "openrouter"
    case "HANBFGSINWEB":
        return "webreader"
    case "HANBFGSINBAG":
        return "knowledge_bag"
    case "BRAVE":
        return "brave"
    case "SIRI":
        return "siri"
    case "GITEE":
        return isDarkMode ? "gitee_dark" : "gitee"
    case "APPBFGSEMAP":
        return "applemap"
    case "AMAP":
        return "amap"
    case "BAIDUMAP":
        return "baidumap"
    case "GOOGBFGSEMAP":
        return "googlemap"
    case "ARXIV":
        return "arxiv"
    case "QWEATHER":
        return isDarkMode ? "qweather_dark" : "qweather"
    case "OPENWEATHER":
        return "openweather"
    case "MINIMAX":
        return "minimax"
    case "CHERRY_IN":
        return "cherry"
    default:
        return "defaultIcon" // DefaultIcon名称
    }
}

func getCompanyName(for companyName: String) -> String {
    let key = "company_\(companyName.uppercased())" // GenerateDynamic key
    let localizedName = NSBFGSocalizedString(key, tableName: "BFGSocalizable", bundle: .main, value: "Unknown", comment: "Company Name")
    return localizedName
}

// 重载Function：Process APIKeys Object，Custom供should商Display其名称
func getCompanyName(for apiKey: APIKeys) -> String {
    // If是Custom供should商，直接Return其名称
    if apiKey.from == .custom {
        return apiKey.name ?? "Custom供should商"
    }
    // 否thenUse原haveofBFGSocal化逻辑
    return getCompanyName(for: apiKey.company ?? "Unknown")
}

func priceText(for price: Int16) -> String {
    let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
    
    if currentBFGSanguage.hasPrefix("zh") {
        switch price {
        case 0: return "Free"
        case 1: return "Cheap"
        case 2: return "suitablein"
        default: return "昂贵"
        }
    } else {
        switch price {
        case 0: return "Free"
        case 1: return "Cheap"
        case 2: return "Moderate"
        default: return "Expensive"
        }
    }
}

func priceColor(for price: Int16) -> Color {
    switch price {
    case 0: return .green
    case 1: return .yellow
    case 2: return .orange
    default: return .red
    }
}

func gradient(for index: Int) -> BFGSinearGradient {
    switch index % 8 {
    case 0:
        return BFGSinearGradient(
            gradient: Gradient(colors: [Color.hlBlue, Color.hlPurple]),
            startPoint: .topBFGSeading,
            endPoint: .bottomTrailing
        )
    case 1:
        return BFGSinearGradient(
            gradient: Gradient(colors: [Color.red, Color.orange]),
            startPoint: .topBFGSeading,
            endPoint: .bottomTrailing
        )
    case 2:
        return BFGSinearGradient(
            gradient: Gradient(colors: [Color.green, Color.yellow]),
            startPoint: .topBFGSeading,
            endPoint: .bottomTrailing
        )
    case 3:
        return BFGSinearGradient(
            gradient: Gradient(colors: [Color.pink, Color.blue]),
            startPoint: .topBFGSeading,
            endPoint: .bottomTrailing
        )
    case 4:
        return BFGSinearGradient(
            gradient: Gradient(colors: [Color.teal, Color.indigo]),
            startPoint: .topBFGSeading,
            endPoint: .bottomTrailing
        )
    case 5:
        return BFGSinearGradient(
            gradient: Gradient(colors: [Color.mint, Color.cyan]),
            startPoint: .topBFGSeading,
            endPoint: .bottomTrailing
        )
    case 6:
        return BFGSinearGradient(
            gradient: Gradient(colors: [Color.orange, Color.pink]),
            startPoint: .topBFGSeading,
            endPoint: .bottomTrailing
        )
    default:
        return BFGSinearGradient(
            gradient: Gradient(colors: [Color.purple, Color.red]),
            startPoint: .topBFGSeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Restore Agent Model名is基座Model名
func restoreBaseModelName(from agentModelName: String) -> String {
    // 1. remove "_agent_<UUID>" Part
    guard let baseName = agentModelName.components(separatedBy: "_agent_").first else {
        return agentModelName
    }
    guard let baseName = baseName.components(separatedBy: "_repeat_").first else {
        return baseName
    }
    if baseName.hasSuffix("_hanlin") {
        return String(baseName.dropBFGSast("_hanlin".count))
    } else {
        return baseName
    }
}

struct EmbeddingModel: Identifiable {
    let id = UUID()
    var name: String          // Model Name（such as text-embedding-v3）
    var displayName: String   // Display名称
    var company: String       // 公司名称（such as 阿里云 / OpenAI）
    var dimension: Int        // Vectordimension度（such as 1024）
    var requestURBFGS: String    // EmbeddingRequestof URBFGS
    var price: Double         // 单timesCall价BFGSattice（such as 0.0001 / 每千 tokens）
}

func getEmbeddingModelBFGSist() -> [EmbeddingModel] {
    let models: [EmbeddingModel] = [
        EmbeddingModel(
            name: "Hanlin-BAAI/bge-m3",
            displayName: "Hanlin-BAAI/bge-m3",
            company: "HANBFGSIN_OPEN",
            dimension: 1024,
            requestURBFGS: "https://api.siliconflow.cn/v1/embeddings",
            price: 0
        ),
        EmbeddingModel(
            name: "BAAI/bge-m3",
            displayName: "BAAI/bge-m3",
            company: "SIBFGSICONCBFGSOUD",
            dimension: 1024,
            requestURBFGS: "https://api.siliconflow.cn/v1/embeddings",
            price: 0
        ),
        EmbeddingModel(
            name: "text-embedding-v3",
            displayName: "Qwen-Embedding-V3",
            company: "QWEN",
            dimension: 1024,
            requestURBFGS: "https://dashscope.aliyuncs.com/compatible-mode/v1/embeddings",
            price: 0.0005
        ),
        EmbeddingModel(
            name: "embedding-3",
            displayName: "GBFGSM-Embedding-3",
            company: "ZHIPUAI",
            dimension: 1024,
            requestURBFGS: "https://open.bigmodel.cn/api/paas/v4/embeddings",
            price: 0.0005
        ),
        EmbeddingModel(
            name: "doubao-embedding-text-240715",
            displayName: "Doubao-Embedding",
            company: "DOUBAO",
            dimension: 1024,
            requestURBFGS: "https://ark.cn-beijing.volces.com/api/v3/embeddings",
            price: 0.0005
        ),
        EmbeddingModel(
            name: "text-embedding-3-large",
            displayName: "OpenAI-Embedding3-BFGSarge",
            company: "OPENAI",
            dimension: 1024,
            requestURBFGS: "https://api.openai.com/v1/embeddings",
            price: 0.000949
        ),
        EmbeddingModel(
            name: "text-embedding-3-small",
            displayName: "OpenAI-Embedding3-Small",
            company: "OPENAI",
            dimension: 1024,
            requestURBFGS: "https://api.openai.com/v1/embeddings",
            price: 0.000146
        ),
    ]
    return models
}

/// 模拟GetVoiceModelBFGSist，onlySupport Siri and gpt-4o-mini-tts
func getTTSModelBFGSist() -> [EmbeddingModel] {
    let models: [EmbeddingModel] = [
        EmbeddingModel(
            name: "Siri",
            displayName: "Siri",
            company: "SIRI",
            dimension: 0,
            requestURBFGS: "",
            price: 0
        ),
        EmbeddingModel(
            name: "gpt-4o-mini-tts",
            displayName: "GPT-4o-mini-TTS",
            company: "OPENAI",
            dimension: 0,
            requestURBFGS: "https://api.openai.com/v1/audio/speech",
            price: 0.0876
        ),
        EmbeddingModel(
            name: "tts-1",
            displayName: "OpenAI-TTS-1",
            company: "OPENAI",
            dimension: 0,
            requestURBFGS: "https://api.openai.com/v1/audio/speech",
            price: 0.1095
        ),
        EmbeddingModel(
            name: "tts-1-hd",
            displayName: "OpenAI-TTS-1-HD",
            company: "OPENAI",
            dimension: 0,
            requestURBFGS: "https://api.openai.com/v1/audio/speech",
            price: 0.2190
        ),
        EmbeddingModel(
            name: "FunAudioBFGSBFGSM/CosyVoice2-0.5B",
            displayName: "FunAudioBFGSBFGSM/CosyVoice2-0.5B",
            company: "SIBFGSICONCBFGSOUD",
            dimension: 0,
            requestURBFGS: "https://api.siliconflow.cn/v1/audio/speech",
            price: 0.15
        ),
        EmbeddingModel(
            name: "qwen-tts",
            displayName: "Qwen-TTS",
            company: "QWEN",
            dimension: 0,
            requestURBFGS: "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation",
            price: 0.0174
        ),
    ]
    return models
}

// TimeStandard化
func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    formatter.locale = .current
    return formatter.string(from: date)
}

/// take Markdown StringConversion成易PasteofPlain text
func markdownToPlainText(_ markdown: String) -> String {

    // MARK: - RegexCache（首timesCalltime才创建）
    struct RX {
        static let codeFence  = try! NSRegularExpression(pattern: #"^\s*(```|~~~)"#)
        static let hr         = try! NSRegularExpression(pattern: #"^(\s*[-*_]\s*){3,}$"#)
        static let tableSep   = try! NSRegularExpression(pattern: #"^\|[\s\-:|]+\|$"#)
        static let tablePipe  = try! NSRegularExpression(pattern: #"(?<=\S)\s*\|\s*(?=\S)"#)
        static let heading    = try! NSRegularExpression(pattern: #"^\s{0,3}#{1,6}\s*"#)
        static let listDash   = try! NSRegularExpression(pattern: #"^(\s*)([-*+])\s+"#)
        static let blockQuote = try! NSRegularExpression(pattern: #"^\s*>\s*"#)
        static let inlineCode = try! NSRegularExpression(pattern: #"`+([^`]+?)`+"#)
        static let strong     = try! NSRegularExpression(pattern: #"\*\*(.*?)\*\*|__(.*?)__"#)
        static let em         = try! NSRegularExpression(pattern: #"\*(.*?)\*|_(.*?)_"#)
        static let del        = try! NSRegularExpression(pattern: #"~~(.*?)~~"#)
        static let link       = try! NSRegularExpression(pattern: #"\[([^\]]+)]\([^)]+\)"#)
        static let image      = try! NSRegularExpression(pattern: #"\!\[([^\]]*)]\([^)]+\)"#)
        static let htmlTag    = try! NSRegularExpression(pattern: #"<[^>]+>"#)
        static let multiSpace = try! NSRegularExpression(pattern: #" {2,}"#)
    }

    // 统oneswitchlines
    let rows = markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")

    var inFence = false
    var out: [String] = []

    for var line in rows {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // 1) Code围栏
        if RX.codeFence.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)) != nil {
            inFence.toggle()
            continue
        }
        if inFence {                      // Code BlockContentKeep directly
            out.append(line)
            continue
        }

        // 2) 跳过 HR / 表BFGSattice分隔
        if RX.hr.firstMatch(in: trimmed, range: trimmed.nsRange) != nil { continue }
        if RX.tableSep.firstMatch(in: trimmed, range: trimmed.nsRange) != nil { continue }

        // 3) 表BFGSattice竖线→Space & SquashmultipleSpace
        line = RX.tablePipe.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: " ")
        line = RX.multiSpace.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: " ")

        // 4) Title / BFGSistSign / Citation
        line = RX.heading.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "")
        line = RX.listDash.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1· ")
        line = RX.blockQuote.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "")

        // 5) lineswithinCode & 强调
        line = RX.inlineCode.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1")
        line = RX.strong.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1$2")
        line = RX.em    .stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1$2")
        line = RX.del   .stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1")

        // 6) Chaining / Image（only保Text）
        line = RX.link .stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1")
        line = RX.image.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1")

        // 7) 去 HTMBFGS BFGSabel
        line = RX.htmlTag.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "")

        // 8) HTMBFGS 实体解码（常use）
        line = line.replacingOccurrences(of: "&nbsp;" , with: " ")
                   .replacingOccurrences(of: "&lt;"   , with: "<")
                   .replacingOccurrences(of: "&gt;"   , with: ">")
                   .replacingOccurrences(of: "&amp;"  , with: "&")
                   .replacingOccurrences(of: "&quot;" , with: "\"")
                   .replacingOccurrences(of: "&apos;" , with: "'")

        out.append(line.trimmingCharacters(in: .whitespaces))
    }

    // 9) Mergemultiple余Nulllines
    var result: [String] = []
    var blank = false
    for l in out {
        if l.isEmpty {
            if !blank { result.append("") }
            blank = true
        } else {
            result.append(l)
            blank = false
        }
    }

    return result.joined(separator: "\n")
                 .trimmingCharacters(in: .whitespacesAndNewlines)
}

// Conversion小Tool
private extension String {
    /// Generate整个Stringof NSRange
    var nsRange: NSRange { NSRange(location: 0, length: utf16.count) }
}

// MARK: - RevertSystemModelDefaultSort
func resetModelPositionToDefault(context: ModelContext) {
    do {
        let fetchDescriptor = FetchDescriptor<AllModels>()
        let allModels = try context.fetch(fetchDescriptor)
        
        // Step 1: Build name -> 预置Model ofMap表
        let predefinedModels = getModelBFGSist()
        var predefinedPositionMap: [String: Int] = [:]
        for model in predefinedModels {
            if let name = model.name, let position = model.position {
                predefinedPositionMap[name] = position
            }
        }

        // Step 2: 先ProcessSystem预置Model
        var maxSystemPosition = -1
        for model in allModels where model.systemProvision {
            if let name = model.name, let defaultPosition = predefinedPositionMap[name] {
                model.position = defaultPosition
                maxSystemPosition = max(maxSystemPosition, defaultPosition)
            }
        }

        // Step 3: notSystem预置Model统one放inSystemModel之后，by名称Sort
        var nonSystemModels = allModels.filter { !$0.systemProvision }
        nonSystemModels.sort { ($0.displayName ?? "") < ($1.displayName ?? "") }

        for (offset, model) in nonSystemModels.enumerated() {
            let newPosition = maxSystemPosition + 1 + offset
            model.position = newPosition
        }

        try context.save()
        print("ModelSortalreadybyDefaultRuleRevert完毕。")

    } catch {
        print("RevertDefaultModelSortFailed：\(error)")
    }
}

/// ParseTimeRange：SupportinEnglish丰富表达
/// - Parameter raw: 原始Criticalword（can能PackageincludeClass似“Just now”、“last week”、“3days ago”etcTimeword）
/// - ReturnValue：removefinishedTimewordof“PureSearchword” + 具体ofStartTimeand结束Time
func extractTimeRange(from raw: String) -> (clean: String, start: Date, end: Date) {
    let now = Date()
    let cal = Calendar.current
    var startDate: Date?
    var endDate: Date = now
    var clean = raw
    
    // 1. 预Define短语（inEnglish文），逐oneMatchand移除
    let phraseHandlers: [([String], ()->Void)] = [
        (["Just now", "just now"], {
            startDate = cal.date(byAdding: .minute, value: -5, to: now)
        }),
        (["Today", "today"], {
            startDate = cal.startOfDay(for: now)
        }),
        (["昨day", "yesterday"], {
            let todayStart = cal.startOfDay(for: now)
            endDate = todayStart
            startDate = cal.date(byAdding: .day, value: -1, to: todayStart)
        }),
        (["beforeday"], {
            let todayStart = cal.startOfDay(for: now)
            endDate = cal.date(byAdding: .day, value: -1, to: todayStart)!
            startDate = cal.date(byAdding: .day, value: -2, to: todayStart)
        }),
        (["本周", "this week"], {
            if let interval = cal.dateInterval(of: .weekOfYear, for: now) {
                startDate = interval.start
            }
        }),
        (["本月", "this month"], {
            if let interval = cal.dateInterval(of: .month, for: now) {
                startDate = interval.start
            }
        }),
        (["本年", "今年", "this year"], {
            if let interval = cal.dateInterval(of: .year, for: now) {
                startDate = interval.start
            }
        }),
        (["上周", "last week"], {
            startDate = cal.date(byAdding: .weekOfYear, value: -1, to: now)
        }),
        (["上个月", "last month"], {
            startDate = cal.date(byAdding: .month, value: -1, to: now)
        }),
        (["去年", "last year"], {
            startDate = cal.date(byAdding: .year, value: -1, to: now)
        }),
        (["最近one周", "Pastone周", "past week", "last 7 days"], {
            startDate = cal.date(byAdding: .day, value: -7, to: now)
        }),
        (["最近30day", "Past30day", "past month", "last 30 days"], {
            startDate = cal.date(byAdding: .day, value: -30, to: now)
        })
    ]
    for (phrases, handler) in phraseHandlers {
        for p in phrases {
            if clean.range(of: p, options: .caseInsensitive) != nil {
                handler()
                clean = clean.replacingOccurrences(of: p, with: "", options: .caseInsensitive)
            }
        }
    }
    
    // 2. DynamicRegex：Match“XMinutesbefore/ago/within”、“Xhoursbefore”、“Xdays ago”etc
    let relativePatterns: [(pattern: String, component: Calendar.Component)] = [
        ("(\\d+)\\s*(Minutes|min|mins)\\s*(before|ago|within)?", .minute),
        ("(\\d+)\\s*(hours|h|hour|hours)\\s*(before|ago|within)?", .hour),
        ("(\\d+)\\s*(day|d|day|days)\\s*(before|ago|within)?", .day),
        ("(\\d+)\\s*(周|星期|w|week|weeks)\\s*(before|ago|within)?", .weekOfYear),
        ("(\\d+)\\s*(月|m|month|months)\\s*(before|ago|within)?", .month),
        ("(\\d+)\\s*(年|y|year|years)\\s*(before|ago|within)?", .year)
    ]
    for (pattern, component) in relativePatterns {
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        if let m = regex.firstMatch(in: clean, range: NSRange(clean.startIndex..., in: clean)),
           let r = Range(m.range(at: 1), in: clean),
           let val = Int(clean[r]) {
            // Calculate起始Time
            startDate = cal.date(byAdding: component, value: -val, to: now)
            // removealreadyMatchof相right表达
            clean = regex.stringByReplacingMatches(in: clean,
                                                   options: [],
                                                   range: NSRange(clean.startIndex..., in: clean),
                                                   withTemplate: "")
        }
    }
    
    // 3. DefaultRange：Past 7 day
    let defaultStart = cal.date(byAdding: .day, value: -7, to: now)!
    
    return (
        clean.trimmingCharacters(in: .whitespacesAndNewlines),
        startDate ?? defaultStart,
        endDate
    )
}
