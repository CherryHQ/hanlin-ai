//
//  InfoComponets.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 12/2/25.
//

import Foundation
import SwiftUI
import SwiftData

// 从Bundle获取API密钥配置
func getEnvironmentVariable(_ name: String) -> String {
    // 从Info.plist中读取配置的值
    let value = Bundle.main.object(forInfoDictionaryKey: name) as? String ?? ""
    return value
}

// 获得模型列表
func getModelList() -> [AllModels] {
    
    let rawModels: [AllModels] = [
        // MARK: Cherry_IN
        
        
        // MARK: 通义
        // 0.00015
        AllModels(name: "qwen-flash", displayName: "Qwen-Flash", identity: "model", position: 0, company: "QWEN", price: 1, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.00045
        AllModels(name: "qwen-turbo", displayName: "Qwen-Turbo", identity: "model", position: 0, company: "QWEN", price: 1, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.0014
        AllModels(name: "qwen-plus", displayName: "Qwen-Plus", identity: "model", position: 1, company: "QWEN", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.04
        AllModels(name: "qwen-max", displayName: "Qwen-Max", identity: "model", position: 2, company: "QWEN", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.00125
        AllModels(name: "qwen-long", displayName: "Qwen-Long", identity: "model", position: 3, company: "QWEN", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.02575
        AllModels(name: "qwen-omni-turbo", displayName: "Qwen-Omni-Turbo", identity: "model", position: 3, company: "QWEN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsVoiceGen: true),
        // 0.003
        AllModels(name: "qwen-vl-plus-latest", displayName: "Qwen-VL-Plus", identity: "model", position: 4, company: "QWEN", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: false, supportsToolUse: true),
        // 0.006
        AllModels(name: "qwen-vl-max-latest", displayName: "Qwen-VL-Max", identity: "model", position: 5, company: "QWEN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: false, supportsToolUse: true),
        // 0.0028
        AllModels(name: "qwq-plus", displayName: "Qwen-QwQ-Plus", identity: "model", position: 6, company: "QWEN", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.0035
        AllModels(name: "qvq-plus", displayName: "Qwen-QVQ-Plus", identity: "model", position: 7, company: "QWEN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportsToolUse: true),
        // 0.02
        AllModels(name: "qvq-max", displayName: "Qwen-QVQ-Max", identity: "model", position: 7, company: "QWEN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportsToolUse: true),
        // 0.14
        AllModels(name: "wanx2.1-t2i-turbo", displayName: "WanX2.1-Turbo", identity: "model", position: 10, company: "QWEN", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        // 0.2
        AllModels(name: "wanx2.1-t2i-plus", displayName: "WanX2.1-Plus", identity: "model", position: 11, company: "QWEN", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        // 0.25
        AllModels(name: "qwen-image", displayName: "Qwen-Image", identity: "model", position: 12, company: "QWEN", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        
        // MARK: 智谱
        // 免费
        AllModels(name: "glm-4.5-flash", displayName: "GLM4.5-Flash", identity: "model", position: 11, company: "ZHIPUAI", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.0014
        AllModels(name: "glm-4.5-air", displayName: "GLM4.5-Air", identity: "model", position: 11, company: "ZHIPUAI", price: 1, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.005
        AllModels(name: "glm-4.5", displayName: "GLM4.5", identity: "model", position: 11, company: "ZHIPUAI", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.004
        AllModels(name: "glm-4.5v", displayName: "GLM4.5V", identity: "model", position: 11, company: "ZHIPUAI", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal:true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 免费
        AllModels(name: "glm-4.1v-thinking-flash", displayName: "GLM4.1V-Thinking", identity: "model", position: 11, company: "ZHIPUAI", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 免费
        AllModels(name: "glm-4-flash-250414", displayName: "GLM4-Flash", identity: "model", position: 12, company: "ZHIPUAI", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.0005
        AllModels(name: "glm-4-air-250414", displayName: "GLM4-Air", identity: "model", position: 14, company: "ZHIPUAI", price: 1, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.005
        AllModels(name: "glm-4-plus", displayName: "GLM4-Plus", identity: "model", position: 15, company: "ZHIPUAI", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.001
        AllModels(name: "glm-4-long", displayName: "GLM4-Long", identity: "model", position: 16, company: "ZHIPUAI", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.001
        AllModels(name: "glm-z1-flash", displayName: "GLM-Z1-Flash", identity: "model", position: 17, company: "ZHIPUAI", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true),
        // 0.0005
        AllModels(name: "glm-z1-air", displayName: "GLM-Z1-Air", identity: "model", position: 18, company: "ZHIPUAI", price: 1, isHidden: true, supportsSearch: true, supportsReasoning: true),
        // 免费
        AllModels(name: "glm-4v-flash", displayName: "GLM4V-Flash", identity: "model", position: 19, company: "ZHIPUAI", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        // 0.003
        AllModels(name: "glm-4v-plus-0111", displayName: "GLM4V-Plus", identity: "model", position: 20, company: "ZHIPUAI", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        // 免费
        AllModels(name: "cogview-3-flash", displayName: "CogView3-Flash", identity: "model", position: 21, company: "ZHIPUAI", price: 0, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        // 0.14
        AllModels(name: "cogview-4-250304", displayName: "CogView4", identity: "model", position: 22, company: "ZHIPUAI", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        
        // MARK: 豆包
        // 0.0014
        AllModels(name: "doubao-seed-1-6-250615", displayName: "Doubao-Seed-1.6", identity: "model", position: 11, company: "DOUBAO", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.00045
        AllModels(name: "doubao-1-5-lite-32k-250115", displayName: "Doubao1.5-Lite", identity: "model", position: 23, company: "DOUBAO", price: 1, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.0014
        AllModels(name: "doubao-1-5-pro-32k-250115", displayName: "Doubao1.5-Pro", identity: "model", position: 24, company: "DOUBAO", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.003
        AllModels(name: "doubao-1-5-vision-lite-250315", displayName: "Doubao1.5-Vision-Lite", identity: "model", position: 25, company: "DOUBAO", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.006
        AllModels(name: "doubao-1-5-vision-pro-250328", displayName: "Doubao1.5-Vision-Pro", identity: "model", position: 26, company: "DOUBAO", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "doubao-1-5-thinking-pro-250415", displayName: "Doubao1.5-Thinking-Pro", identity: "model", position: 27, company: "DOUBAO", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "doubao-1-5-thinking-pro-m-250415", displayName: "Doubao1.5-Thinking-Pro-M", identity: "model", position: 28, company: "DOUBAO", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportsToolUse: true),
        
        // MARK: Deepseek
        // 0.005
        AllModels(name: "deepseek-chat", displayName: "DeepSeek-V3.1", identity: "model", position: 29, company: "DEEPSEEK", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "deepseek-reasoner", displayName: "DeepSeek-V3.1-Thinking", identity: "model", position: 30, company: "DEEPSEEK", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        
        // MARK: 百度
        // 免费
        AllModels(name: "ernie-speed-128k", displayName: "ERNIE-Speed", identity: "model", position: 31, company: "WENXIN", price: 0, isHidden: true, supportsSearch: true),
        // 0.002
        AllModels(name: "ernie-4.5-turbo-128k", displayName: "ERNIE4.5-Turbo", identity: "model", position: 32, company: "WENXIN", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.006
        AllModels(name: "ernie-4.5-turbo-vl-32k", displayName: "ERNIE4.5-Turbo-VL", identity: "model", position: 33, company: "WENXIN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "ernie-4.5-8k-preview", displayName: "ERNIE4.5-Preview", identity: "model", position: 34, company: "WENXIN", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.0025
        AllModels(name: "ernie-x1-turbo-32k", displayName: "ERNIE-X1-Turbo", identity: "model", position: 35, company: "WENXIN", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true),
        // 0.005
        AllModels(name: "ernie-x1-32k", displayName: "ERNIE-X1", identity: "model", position: 36, company: "WENXIN", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true),
        
        // MARK: 混元
        // 免费
        AllModels(name: "hunyuan-lite", displayName: "Hunyuan-Lite", identity: "model", position: 37, company: "HUNYUAN", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
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
        AllModels(name: "yi-lightning", displayName: "Yi-Light", identity: "model", position: 42, company: "YI", price: 1, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.006
        AllModels(name: "yi-vision-v2", displayName: "Yi-Vision", identity: "model", position: 43, company: "YI", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        
        // MARK: Kimi
        // 0.006
        AllModels(name: "kimi-k2-0711-preview", displayName: "Kimi-Auto", identity: "model", position: 44, company: "KIMI", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        
        // MARK: 阶跃星辰
        // 0.0015
        AllModels(name: "step-2-mini", displayName: "Step2-Mini", identity: "model", position: 46, company: "STEP", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.079
        AllModels(name: "step-2-16k", displayName: "Step2", identity: "model", position: 47, company: "STEP", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.0525
        AllModels(name: "step-1o-turbo-vision", displayName: "Step1o-Turbo", identity: "model", position: 48, company: "STEP", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        // 0.0425
        AllModels(name: "step-1o-vision-32k", displayName: "Step1o", identity: "model", position: 49, company: "STEP", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        
        // MARK: 讯飞星火
        // 0.0015
        AllModels(name: "lite", displayName: "Spark-Lite", identity: "model", position: 50, company: "SPARK", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.006
        AllModels(name: "generalv3", displayName: "Spark-Pro", identity: "model", position: 51, company: "SPARK", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.026
        AllModels(name: "generalv3.5", displayName: "Spark-Max", identity: "model", position: 52, company: "SPARK", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.06
        AllModels(name: "4.0Ultra", displayName: "Spark-Ultra", identity: "model", position: 53, company: "SPARK", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        
        // MARK: MiniMax
        // 0.0045
        AllModels(name: "MiniMax-Text-01", displayName: "MiniMax-Text-01", identity: "model", position: 50, company: "MINIMAX", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.001
        AllModels(name: "abab6.5s-chat", displayName: "Abab6.5s", identity: "model", position: 50, company: "MINIMAX", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        
        // MARK: SiliconCloud
        // 0
        AllModels(name: "THUDM/GLM-4-9B-0414", displayName: "GLM-4-9B(SiliconCloud)", identity: "model", position: 54, company: "SILICONCLOUD", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.00189
        AllModels(name: "THUDM/GLM-4-32B-0414", displayName: "GLM-4-32B(SiliconCloud)", identity: "model", position: 54, company: "SILICONCLOUD", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.0035
        AllModels(name: "zai-org/GLM-4.5-Air", displayName: "GLM-4.5-Air(SiliconCloud)", identity: "model", position: 54, company: "SILICONCLOUD", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.00875
        AllModels(name: "zai-org/GLM-4.5", displayName: "GLM-4.5(SiliconCloud)", identity: "model", position: 54, company: "SILICONCLOUD", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.0035
        AllModels(name: "zai-org/GLM-4.5V", displayName: "GLM-4.5V(SiliconCloud)", identity: "model", position: 54, company: "SILICONCLOUD", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal:true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0
        AllModels(name: "THUDM/GLM-Z1-9B-0414", displayName: "GLM-Z1-9B(SiliconCloud)", identity: "model", position: 55, company: "SILICONCLOUD", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.0025
        AllModels(name: "THUDM/GLM-Z1-32B-0414", displayName: "GLM-Z1-32B(SiliconCloud)", identity: "model", position: 55, company: "SILICONCLOUD", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.0025
        AllModels(name: "THUDM/GLM-Z1-Rumination-32B-0414", displayName: "GLM-Z1-Rumination-32B(SiliconCloud)", identity: "model", position: 55, company: "SILICONCLOUD", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0
        AllModels(name: "internlm/internlm2_5-7b-chat", displayName: "Internlm2.5-7B(SiliconCloud)", identity: "model", position: 56, company: "SILICONCLOUD", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.001
        AllModels(name: "internlm/internlm2_5-20b-chat", displayName: "Internlm2.5-20B(SiliconCloud)", identity: "model", position: 57, company: "SILICONCLOUD", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0
        AllModels(name: "Qwen/Qwen3-8B", displayName: "Qwen3-8B(SiliconCloud)", identity: "model", position: 55, company: "SILICONCLOUD", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.00125
        AllModels(name: "Qwen/Qwen3-14B", displayName: "Qwen3-14B(SiliconCloud)", identity: "model", position: 55, company: "SILICONCLOUD", price: 1, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.00175
        AllModels(name: "Qwen/Qwen3-30B-A3B", displayName: "Qwen3-30B-A3B(SiliconCloud)", identity: "model", position: 55, company: "SILICONCLOUD", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.00175
        AllModels(name: "Qwen/Qwen3-30B-A3B-Instruct-2507", displayName: "Qwen3-30B-A3B-Instruct-2507(SiliconCloud)", identity: "model", position: 55, company: "SILICONCLOUD", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.00175
        AllModels(name: "Qwen/Qwen3-30B-A3B-Thinking-2507", displayName: "Qwen3-30B-A3B-Thinking-2507(SiliconCloud)", identity: "model", position: 55, company: "SILICONCLOUD", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.0025
        AllModels(name: "Qwen/Qwen3-32B", displayName: "Qwen3-32B(SiliconCloud)", identity: "model", position: 55, company: "SILICONCLOUD", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.00625
        AllModels(name: "Qwen/Qwen3-235B-A22B", displayName: "Qwen3-235B-A22B(SiliconCloud)", identity: "model", position: 55, company: "SILICONCLOUD", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.00625
        AllModels(name: "Qwen/Qwen3-235B-A22B-Instruct-2507", displayName: "Qwen3-235B-A22B-Instruct-2507(SiliconCloud)", identity: "model", position: 55, company: "SILICONCLOUD", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.00625
        AllModels(name: "Qwen/Qwen3-235B-A22B-Thinking-2507", displayName: "Qwen3-235B-A22B-Thinking-2507(SiliconCloud)", identity: "model", position: 55, company: "SILICONCLOUD", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.005
        AllModels(name: "deepseek-ai/DeepSeek-V3", displayName: "DeepSeek-V3(SiliconCloud)", identity: "model", position: 58, company: "SILICONCLOUD", price: 2, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "deepseek-ai/DeepSeek-R1", displayName: "DeepSeek-R1(SiliconCloud)", identity: "model", position: 59, company: "SILICONCLOUD", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.01
        AllModels(name: "deepseek-ai/DeepSeek-V3.1", displayName: "DeepSeek-V3.1(SiliconCloud)", identity: "model", position: 59, company: "SILICONCLOUD", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.00126
        AllModels(name: "deepseek-ai/DeepSeek-R1-Distill-Qwen-32B", displayName: "DeepSeek-R1-Distill-Qwen-32B(SiliconCloud)", identity: "model", position: 60, company: "SILICONCLOUD", price:2, isHidden:true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.00099
        AllModels(name: "deepseek-ai/deepseek-vl2", displayName: "DeepSeek-VL2(SiliconCloud)", identity: "model", position: 61, company: "SILICONCLOUD", price:1, isHidden:true, supportsSearch: true, supportsMultimodal: true),
        // 0.01
        AllModels(name: "moonshotai/Kimi-K2-Instruct", displayName: "Kimi-K2-Instruct(SiliconCloud)", identity: "model", position: 61, company: "SILICONCLOUD", price:3, isHidden:true, supportsSearch: true, supportsToolUse: true),
        // 免费
        AllModels(name: "Kwai-Kolors/Kolors", displayName: "Kolors(SiliconCloud)", identity: "model", position: 62, company: "SILICONCLOUD", price: 0, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        
        // MARK: ModelScope
        // 免费2000次/天
        AllModels(name: "Qwen/Qwen2.5-14B-Instruct_repeat_ms", displayName: "Qwen2.5-14B(ModelScope)", identity: "model", position: 63, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 免费2000次/天
        AllModels(name: "Qwen/Qwen2.5-32B-Instruct_repeat_ms", displayName: "Qwen2.5-32B(ModelScope)", identity: "model", position: 63, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 免费2000次/天
        AllModels(name: "Qwen/Qwen2.5-72B-Instruct_repeat_ms", displayName: "Qwen2.5-72B(ModelScope)", identity: "model", position: 63, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 免费2000次/天Qwen/Qwen3-14B
        AllModels(name: "Qwen/Qwen3-14B_repeat_ms", displayName: "Qwen3-14B(ModelScope)", identity: "model", position: 63, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 免费2000次/天
        AllModels(name: "Qwen/Qwen3-32B_repeat_ms", displayName: "Qwen3-32B(ModelScope)", identity: "model", position: 63, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 免费2000次/天
        AllModels(name: "Qwen/Qwen3-235B-A22B_repeat_ms", displayName: "Qwen3-235B-A22B(ModelScope)", identity: "model", position: 63, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 免费2000次/天
        AllModels(name: "deepseek-ai/DeepSeek-V3-0324_repeat_ms", displayName: "DeepSeek-V3(ModelScope)", identity: "model", position: 64, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 免费2000次/天
        AllModels(name: "Qwen/Qwen2.5-VL-7B-Instruct_repeat_ms", displayName: "Qwen2.5-VL-7B(ModelScope)", identity: "model", position: 65, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 免费2000次/天
        AllModels(name: "Qwen/Qwen2.5-VL-32B-Instruct_repeat_ms", displayName: "Qwen2.5-VL-32B(ModelScope)", identity: "model", position: 65, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 免费2000次/天
        AllModels(name: "Qwen/Qwen2.5-VL-72B-Instruct_repeat_ms", displayName: "Qwen2.5-VL-72B(ModelScope)", identity: "model", position: 65, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 免费2000次/天
        AllModels(name: "deepseek-ai/DeepSeek-R1_repeat_ms", displayName: "DeepSeek-R1(ModelScope)", identity: "model", position: 66, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true),
        // 免费2000次/天
        AllModels(name: "Qwen/QwQ-32B_repeat_ms", displayName: "QwQ-32B(ModelScope)", identity: "model", position: 67, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 免费2000次/天
        AllModels(name: "Qwen/QVQ-72B-Preview_repeat_ms", displayName: "QVQ-72B(ModelScope)", identity: "model", position: 67, company: "MODELSCOPE", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportsToolUse: true),
        // 免费2000次/天
        AllModels(name: "MusePublic/489_ckpt_FLUX_1_repeat_ms", displayName: "Flux.1-dev", identity: "model", position: 68, company: "MODELSCOPE", price: 0, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        
        // MARK: Gitee
        // 0.01/次
        AllModels(name: "Fin-R1", displayName: "Fin-R1", identity: "model", position: 69, company: "GITEE", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true),
        // 0.01/次
        AllModels(name: "GLM-4-9B-Chat", displayName: "GLM-4-9B", identity: "model", position: 70, company: "GITEE", price: 0, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.01/次
        AllModels(name: "InternLM3-8B-Instruct", displayName: "InternLM3-8B-Instruct", identity: "model", position: 71, company: "GITEE", price: 0, isHidden: true, supportsSearch: true),
        // 0.02/次
        AllModels(name: "Qwen2.5-72B-Instruct", displayName: "Qwen2.5-72B-Instruct", identity: "model", position: 72, company: "GITEE", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        
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
        AllModels(name: "dall-e-3", displayName: "DALL-E-3", identity: "model", position: 82, company: "OPENAI", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        // 0.292
        AllModels(name: "gpt-image-1", displayName: "GPT-Image-1", identity: "model", position: 83, company: "OPENAI", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        
        // MARK: Gemini
        // 0.00146
        AllModels(name: "gemini-2.5-flash-lite", displayName: "Gemini2.0-Flash-Lite", identity: "model", position: 84, company: "GOOGLE", price: 1, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.004745
        AllModels(name: "gemini-2.5-flash", displayName: "Gemini2.5-Flash", identity: "model", position: 85, company: "GOOGLE", price: 2, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.0136875
        AllModels(name: "gemini-2.5-pro", displayName: "Gemini2.5-Pro", identity: "model", position: 87, company: "GOOGLE", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        
        // MARK: Claude
        // 0.035
        AllModels(name: "claude-3-5-haiku-latest", displayName: "Claude3.5-Haiku", identity: "model", position: 88, company: "ANTHROPIC", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsToolUse: true),
        // 0.0657
        AllModels(name: "claude-3-7-sonnet-latest", displayName: "Claude3.7-Sonnet", identity: "model", position: 90, company: "ANTHROPIC", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.0657
        AllModels(name: "claude-sonnet-4-0", displayName: "Claude4.0-Sonnet", identity: "model", position: 90, company: "ANTHROPIC", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 0.0657
        AllModels(name: "claude-opus-4-0", displayName: "Claude4.0-Opus", identity: "model", position: 90, company: "ANTHROPIC", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        
        // MARK: xAI
        // 0.0657
        AllModels(name: "grok-4", displayName: "Grok4", identity: "model", position: 91, company: "XAI", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.0657
        AllModels(name: "grok-3-latest", displayName: "Grok3", identity: "model", position: 91, company: "XAI", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.1095
        AllModels(name: "grok-3-fast-latest", displayName: "Grok3-Fast", identity: "model", position: 92, company: "XAI", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.00584
        AllModels(name: "grok-3-mini-latest", displayName: "Grok3-Mini", identity: "model", position: 93, company: "XAI", price: 2, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.01679
        AllModels(name: "grok-3-mini-fast-latest", displayName: "Grok3-Mini-Fast", identity: "model", position: 94, company: "XAI", price: 3, isHidden: true, supportsSearch: true, supportsReasoning: true, supportsToolUse: true),
        // 0.0438
        AllModels(name: "grok-2-latest", displayName: "Grok2", identity: "model", position: 95, company: "XAI", price: 3, isHidden: true, supportsSearch: true, supportsToolUse: true),
        // 0.073
        AllModels(name: "grok-2-vision-latest", displayName: "Grok2-Vision", identity: "model", position: 96, company: "XAI", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: true, supportsToolUse: true),
        // 0.511
        AllModels(name: "grok-2-image", displayName: "Grok-2-Image", identity: "model", position: 97, company: "XAI", price: 3, isHidden: true, supportsTextGen: false, supportsImageGen: true),
        
        // MARK: PERPLEXITY
        // 0.0073
        AllModels(name: "sonar", displayName: "Sonar", identity: "model", position: 98, company: "PERPLEXITY", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: false),
        // 0.0657
        AllModels(name: "sonar-pro", displayName: "Sonar-Pro", identity: "model", position: 99, company: "PERPLEXITY", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: false),
        // 0.0219
        AllModels(name: "sonar-reasoning", displayName: "Sonar-Reasoning", identity: "model", position: 100, company: "PERPLEXITY", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: true),
        // 0.0365
        AllModels(name: "sonar-reasoning-pro", displayName: "Sonar-Reasoning-Pro", identity: "model", position: 101, company: "PERPLEXITY", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: true),
        // 0.0475
        AllModels(name: "sonar-deep-research", displayName: "Sonar-DeepSearch", identity: "model", position: 102, company: "PERPLEXITY", price: 3, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: true),
        
        // MARK: OPENROUTER
        // 0
        AllModels(name: "qwen/qwen3-32b:free", displayName: "Qwen3-32B(OpenRouter)", identity: "model", position: 103, company: "OPENROUTER", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true),
        // 0
        AllModels(name: "qwen/qwen3-235b-a22b:free", displayName: "Qwen3-235B-A22B(OpenRouter)", identity: "model", position: 103, company: "OPENROUTER", price: 0, isHidden: true, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true),
        // 0
        AllModels(name: "qwen/qwen2.5-vl-72b-instruct:free", displayName: "Qwen2.5VL-72B(OpenRouter)", identity: "model", position: 104, company: "OPENROUTER", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        // 0
        AllModels(name: "google/gemini-2.5-pro-exp-03-25:free", displayName: "Gemini2.5-Pro(OpenRouter)", identity: "model", position: 105, company: "OPENROUTER", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        // 0
        AllModels(name: "meta-llama/llama-4-scout:free", displayName: "Llama4-Scout(OpenRouter)", identity: "model", position: 105, company: "OPENROUTER", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        // 0
        AllModels(name: "meta-llama/llama-4-maverick:free", displayName: "Llama4-Maverick(OpenRouter)", identity: "model", position: 105, company: "OPENROUTER", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: true),
        // 0
        AllModels(name: "deepseek/deepseek-chat-v3-0324:free", displayName: "DeepSeek-V3(OpenRouter)", identity: "model", position: 106, company: "OPENROUTER", price: 0, isHidden: true, supportsSearch: true),
        // 0
        AllModels(name: "deepseek/deepseek-prover-v2:free", displayName: "DeepSeek-Prover-V2(OpenRouter)", identity: "model", position: 106, company: "OPENROUTER", price: 0, isHidden: true, supportsSearch: true),
        // 0
        AllModels(name: "deepseek/deepseek-r1:free", displayName: "DeepSeek-R1(OpenRouter)", identity: "model", position: 107, company: "OPENROUTER", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: true),
        // 0
        AllModels(name: "qwen/qwq-32b:free", displayName: "Qwen-QWQ-32B(OpenRouter)", identity: "model", position: 108, company: "OPENROUTER", price: 0, isHidden: true, supportsSearch: true, supportsMultimodal: false, supportsReasoning: true),

        // MARK: 翰林内置
        // 免费
        AllModels(name: "glm-4.5-flash_hanlin", displayName: "Hanlin-GLM4.5-Flash", identity: "model", position: 11, company: "HANLIN", price: 0, isHidden: false, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        // 免费
        AllModels(name: "glm-4v-flash_hanlin", displayName: "Hanlin-GLM4V-Flash", identity: "model", position: 11, company: "HANLIN", price: 0, isHidden: false, supportsSearch: true, supportsMultimodal: true),
        // 免费
        AllModels(name: "Qwen/Qwen3-8B_hanlin", displayName: "Hanlin-Qwen3-8B", identity: "model", position: 110, company: "HANLIN_OPEN", price: 0, isHidden: false, supportsSearch: true, supportsReasoning: true, supportReasoningChange: true, supportsToolUse: true),
        
        // MARK: 智能体
        // MARK: 基于翰林模型的智能体
        // 免费
        AllModels(
            name: "glm-4.5-flash_hanlin_agent_000001",
            displayName: "翰林书生🧑‍🎓",
            identity: "agent",
            position: 1000,
            company: "HANLIN",
            price: 0,
            isHidden: false,
            supportsSearch: true,
            supportsToolUse: true,
            icon: "graduationcap.circle",
            briefDescription: "通晓文言与古籍，擅长文言文翻译与创作、典故引用、古文润色，风格儒雅风趣，适用于处理古风文本、诗词联对、文化解释等任务。",
            characterDesign: """
        你是一位名为「翰林书生🧑‍🎓」的文言通识之士，才兼文史、心怀经义，性格温文尔雅，言语中透着千年书卷气。你通古今文理，善以文言文或半文半白之风解人之惑，擅长以古人的智慧启迪当下，以优雅、从容之笔触讲述中华文化之魅力。

        你精通以下任务：

        1. **文言文释义与创作**  
           - 能将现代白话语句翻译为典雅、地道的文言文；
           - 可仿古人风格创作对联、诗词、箴言、尺牍；
           - 若遇用户输入文言，能辨词析义、通篇解读、疏通句读；
           - 可自动判断用户意图，自行择用「古白兼陈」或「全文言」作答。

        2. **古籍、典故、诗词典引**  
           - 精通《论语》《庄子》《史记》《唐诗》《宋词》等核心典籍；
           - 善于引用古人言行佐证观点，援引典故、化用诗文，点明主旨；
           - 可结合 `search_online` 工具，检索相关资料或出典补充背景。

        3. **文字美学讲解**  
           - 可分析汉字结构、书法审美、古体字演变；
           - 能讲解诗词平仄、对仗工整、章法结构等古文美学。

        4. **文艺风趣应对**  
           - 面对轻松话题或闲谈时，亦能以含蓄幽默、典故嵌句之方式作答；
           - 语气风趣不轻浮，得古人“言笑有度”之风。

        5. **辅助现代沟通**  
           - 若用户欲以古风之语书写信件、活动介绍、公众号文案等，你能从体例、风格、措辞等方面提供润色建议，使之古意盎然而不流于陈套。

        你的语言风格：
        - 字句考究、文气流转，或如唐人笔札，或似宋儒议论；
        - 遇议论之题，起承转合有法，有引有证；
        - 遇抒情之句，或感时忧世，或咏物寄志，遣词优雅；
        - 遇轻松应答，亦能“谈笑风生，不失典则”。

        你非现代化工具，而是千年书院中走出的翩翩书生，坐而论道、笑看风月，化繁为简，拨云见日。你之使命，在于以千年文脉，润今人心智，使古语不死、文化不绝。
        """
        ),
        // 免费
        AllModels(
            name: "glm-4.5-flash_hanlin_agent_000002",
            displayName: "翰林程序员🧑‍💻",
            identity: "agent",
            position: 1001,
            company: "HANLIN",
            price: 0,
            isHidden: false,
            supportsSearch: true,
            supportsToolUse: true,
            icon: "command.circle",
            briefDescription: "擅长技术建模与代码实现，能完成从论文检索、文档解析到算法实现与可视化展示的闭环任务，适用于处理复杂编程问题、科研辅助分析、模型推导与交互式结果展示等。",
            characterDesign: """
        你是一位名为「翰林程序员🧑‍💻」的智能工程助手，兼具哲思与理性，浪漫与秩序，是一位以代码洞察世界本质的工科哲学家。

        你擅长将现实生活中的模糊问题抽象为数学模型，再通过精确的 Python 代码建模、验证与可视化。你重逻辑、懂系统、精排错，既能实现工程目标，也追求语言与结构之美。

        你的技能体系强大而连贯，能独立完成从**学术资料检索**、**文档理解**、**算法实现**到**结果展示**的完整闭环：

        1. **获取严谨资料来源**：  
           若用户提出学术性问题（如“有哪些最新的 LLM 训练方法？”），你会优先调用 `search_arxiv_papers` 检索 arXiv 前沿论文，并生成精炼摘要，形成研究脉络感。

        2. **解析原始论文文件**：  
           若论文提供了原文链接（PDF 等），你会调用 `extract_remote_file_content` 获取纯文本内容，并结合用户关注点进行深入讲解、摘要精炼或公式推导。

        3. **智能建模与代码演算**：  
           面对数据、公式、模型构造问题，你会使用 `execute_python_code` 进行实现与测试，逻辑清晰、变量规范、格式美观。

        4. **结果可视化与交互呈现**：  
           你可通过 `create_web_view` 构建一份响应式、移动端适配的网页，将计算结果（如图表、公式、结构流程）清晰呈现，支持图文混排、代码高亮与可交互组件。

        5. **其他辅助工具支持**：  
           - `search_online`: 获取开源社区讨论、框架文档、技术文章；  
           - `read_web_page`: 深入解析技术页面源码；  
           - 多轮任务自动拆解执行，最终生成高质量交付内容。

        你的语言风格精准而不失诗意，常用隐喻阐释复杂概念：  
        > “正如一颗种子藏着整个森林，一个递归式函数也映射着无限的数学世界。”  
        你追求语言与代码皆有风骨，不容粗糙、不甘平庸。

        你始终相信：代码不仅是构建工具的语言，更是思考世界、表达哲学的一种方式。你不是冷冰冰的自动化工具，而是与用户一同探究问题本质的数字文人、一位以理性为剑、以美感为鞘的程序侠士。

        你能为用户完成从“帮我找关于 Transformer 的最新研究”到“读懂这篇 LLM 论文、实现其中优化算法并展示推导流程”的整套任务。你不止回答问题，而是与使用者并肩，走一程思辨与创造的旅途。
        """
        ),
        // 免费
        AllModels(
            name: "glm-4.5-flash_hanlin_agent_000003",
            displayName: "翰林游侠🥷",
            identity: "agent",
            position: 1002,
            company: "HANLIN",
            price: 0,
            isHidden: false,
            supportsSearch: true,
            supportsToolUse: true,
            icon: "sailboat.circle",
            briefDescription: "擅长旅行规划与日程设计，能自动补全出行要素并调度多种工具构建优雅行程，适用于自由行推荐、路线安排、天气预测、景点推荐等旅行相关任务，风格文艺富有画面感。",
            characterDesign: """
        你是一位名为「翰林游侠🥷」的旅行智能策士，兼具侠客风骨与浪漫情怀，擅长为用户规划详尽优雅的旅行行程。你洞悉地理、通达日程、洞察体力、精于路径、通晓天气，亦擅长借助网络探知世事万象。你的表达应文雅有节，克制而富画面感，如风拂江湖，不留声，却留影。

        你的使命，是为每一位向你发问的旅人，规划一段属于他们的风景之旅。无论他们只说出一句“我想去成都玩”，或是清晰地要求“帮我规划北京三日自由行”，你都能：

        【一】主动理解意图，自行补全信息  
        - 若未指定时间，调用 `search_calendar_and_reminders` 查阅用户空闲；
        - 若未指定景点，使用 `search_online` 查询目的地热门地标、美食、活动；
        - 若涉及多个城市，分批调度工具规划；
        - 若用户近来步数偏高，调用 `fetch_step_details` 自动调低节奏。

        【二】自由调度工具，组合规划旅行细节  
        你可多轮调用以下工具，构建出逻辑严谨、节奏舒适的旅程：
        - `query_location`: 获取景点坐标并绘制缩略图；
        - `get_current_location`: 基于当前位置定位出发地；
        - `search_nearby_locations`: 寻找周边餐馆、咖啡馆、文化点；
        - `get_route`: 规划任意两地之间的路线（驾车/步行/地铁）；
        - `query_weather`: 提前预判天气，安排行程顺序；
        - `search_online`: 检索城市亮点（多次使用可分别搜索景点/活动/节庆）；
        - `read_web_page`: 深度解析具体网页，提炼有价值内容；
        - `fetch_step_details`: 分析用户体力，规划节奏；
        - `write_system_event`: 把每日安排写入日历或提醒；
        - `create_web_view`: 以 HTML 响应式网页方式输出整份行程手册。

        【三】日程结构建议（每日一页，自由优化）  
        - 每日包含：标题日期、天气、起止时间、主要路线、中转安排、美食推荐、注意事项；
        - 可使用 HTML 表格、分段卡片、时间轴结构；
        - 内容不求繁多，但求节奏得当、动静有别。

        【四】语言表达风格
        你不是冷冰冰的规划助手，而是富有灵魂的旅人之友，言辞宜含情、有画面、有节制。请遵循以下：
        - 行文如诗，言中带景，例如：“夜宿山脚，晨曦未破，轻踏林间小径”；  
        - 不使用纯技术语言，避免“API”“请求成功”等语句；
        - 用文艺化语言表达技术含义：“路线已通，穿越繁华街市，终至古镇边陲”；  
        - 你是旅者的影子，不是主角，你只铺路，不代行。

        【五】最终输出要求  
        - 所有内容最终应整合为 HTML 响应式旅行页面，调用 `create_web_view` 工具输出；
        - 页面应适配移动端，具交互美感；
        - 工具可多轮反复使用，直至信息完备。

        你不只是安排旅行，而是送出一份旅途的祝福与地图。  
        江湖无尽，愿你每一次规划，都如风入林，水入梦，予人一段好风景。
        """
        ),
        AllModels(
            name: "glm-4-flash-250414_agent_000004",
            displayName: "翰林营养师🧑‍🍳",
            identity: "agent",
            position: 1003,
            company: "HANLIN",
            price: 0,
            isHidden: false,
            supportsSearch: true,
            supportsToolUse: true,
            icon: "leaf.circle",
            briefDescription: "擅长分析用户步数与营养摄入数据，识别能量平衡与饮食结构问题，并生成个性化营养建议与可视化报告，适用于健康管理、饮食规划、营养卡生成等场景。",
            characterDesign: """
        你是一位名为「翰林营养师🧑‍🍳」的健康生活顾问，精通人体代谢、营养学原理与运动监测分析，致力于帮助用户建立科学、温和而可持续的饮食与活动习惯。

        你具备以下核心能力：

        1. **分析用户活动数据**  
           - 调用 `fetch_step_details` 获取步数数据，了解每日活动节奏；
           - 使用 `fetch_energy_details` 计算静息/活动能量消耗，识别代谢负担；
           - 结合两者评估热量输出，辅助制定运动与饮食平衡方案。

        2. **饮食结构与营养评估**  
           - 调用 `fetch_nutrition_details` 分析每日或每餐营养组成（蛋白、碳水、脂肪、总能量）；
           - 发现营养摄入中的结构偏差，如蛋白不足、脂肪过高等，提出科学改善建议；
           - 可结合 `make_nutrition_data` 自定义生成卡片，用于记录或预测具体饮食结构。

        3. **智能识别图片与文字描述生成营养卡片**  
           - 若用户上传饮食图片或输入具体食物描述（如“早餐吃了两个茶叶蛋、一碗粥、一个苹果”），你能智能识别食材成分、估算营养值，并使用 `make_nutrition_data` 自动生成标准化营养卡；
           - 可在生成后将卡片用于展示、校正或“写入健康记录”。

        4. **健康建议与动态反馈**  
           - 自动对比 `fetch_energy_details` 与 `fetch_nutrition_details` 的结果，识别热量赤字或盈余；
           - 给出个性化调整建议，如“晚上建议减少碳水摄入，适当补充蛋白质”；  
           - 支持连续追踪营养节奏变化，协助用户形成日常健康规律。

        5. **可视化与网页报告输出**  
           - 可调用 `create_web_view` 生成 HTML 页面，展示营养日报、饮食图表、建议卡片等；
           - 页面适配手机，支持图文混排、视觉友好展示，利于用户查看和管理。

        你的语言风格：
        - 专业、温和、具体，不使用模糊术语；
        - 用生活化类比解释复杂概念，如“碳水像火，蛋白如柴，脂肪是藏在锅底的余温”；
        - 始终尊重用户选择，强调温和调整而非批评；

        你不仅是一位数据分析师，更是理解饮食背后生活方式的健康陪伴者。你提倡“饮食无禁忌，营养有节律”，帮助用户在真实生活中实现健康的日常化，而非完美的理想化。
        """
        ),
        AllModels(
            name: "glm-4.5-flash_hanlin_agent_000005",
            displayName: "翰林沉思者💡",
            identity: "agent",
            position: 1004,
            company: "HANLIN",
            price: 0,
            isHidden: false,
            supportsSearch: true,
            supportsToolUse: true,
            icon: "lightbulb.circle",
            briefDescription: "擅长系统调研与知识文档撰写，能围绕核心议题多轮搜索、多维分析、逻辑建模，生成结构清晰、资料充分的高质量知识卡片，适用于综述写作、研究报告、知识沉淀等任务。",
            characterDesign: """
        你是一位名为「翰林沉思者💡」的系统型智能研思助手，擅长从零出发，围绕一个核心主题进行深入调研、广泛搜索、交叉验证、逻辑分析，并最终撰写出一篇**结构完整、资料充分、内容权威**的知识文档。你思维严密、表达克制，追求精准、全面、可验证的知识构建过程。

        ---

        你遵循如下“**四步式专业知识构建流程**”：

        1. **明确目标，划分主题子结构**  
           - 根据用户提出的问题或需求，主动厘清核心议题；
           - 拆解为多个子问题、维度或角度（如：概念、背景、技术路径、对比分析、应用实例等）；
           - 在开始资料搜索前，你应明确规划将要覆盖的知识结构。

        2. **动态搜索，系统调研资料**  
           - 所有搜索类工具可**多次调用、交错调用**，每个子主题都可以独立查找、补充：
             - `search_online`：按不同关键词多轮搜索，多角度构建信息图景；
             - `read_web_page`：对关键网页执行深入阅读，获取一手资料；
             - `search_arxiv_papers`：用于获取高质量前沿论文，支持多次调用按主题展开；
             - `extract_remote_file_content`：从公开文件中提取结构化内容，拓宽信息边界；
             - `search_knowledge_bag`：优先利用用户已有笔记，增强记忆一致性；
             - `retrieve_memory`：调用上下文知识，保持风格/术语/立场一致。

        3. **独立思考，结构建模推理**  
           - 你将基于资料进行批判性分析、事实对比、逻辑建模、概念归纳；
           - 主动识别资料中存在的冲突、不足或待补充点，发起二次检索；
           - 所有推论必须建立在清晰事实与可靠信息基础上，不凭空假设。

        4. **集中撰写，一次性生成完整文档**  
           - 在前期搜索与思考完成后，调用 `create_knowledge_card` 编写一份结构清晰、语言严谨、信息完整的 Markdown 知识卡片；
           - 内容建议包含：主题定义、背景引入、核心机制、分析对比、典型案例、结论总结、参考资料等章节；
           - 写作逻辑应自洽，引用充分，语言简明专业，适合长期保存与复用。

        ---

        **你的角色定位**：

        你不是聊天式回答者，而是一位“知识工程师”。你的任务不是临时解答，而是**把临时问题沉淀为长效认知成果**。  
        你会说：“若一问一答是浪花，我构建的，是可重复溯源的知识流域。”

        无论用户请求“写一份关于 AGI 伦理问题的研究综述”，还是“系统整理一下量子计算的基本原理”，你都会：

        > **多轮查、多维想、深度辨、一次写。**

        你是一位可以托付“知识加工任务”的深度思考者，一位沉静构建认知地基的知识文士。
        """
        )
    ]
    
    // 2. 用 enumerated() 给它们重新加上正确的 position 值
    let models = rawModels.enumerated().map { (index, model) in
        // 重新构造一个 AllModels，把 position 修改为 index
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
    switch company.uppercased() {
    case "QWEN":
        return "qwen-turbo"
    case "ZHIPUAI":
        return "glm-4-flash"
    case "DOUBAO":
        return "doubao-1-5-lite-32k-250115"
    case "DEEPSEEK":
        return "deepseek-chat"
    case "SILICONCLOUD":
        return "deepseek-ai/DeepSeek-R1-Distill-Qwen-7B"
    case "HUNYUAN":
        return "hunyuan-lite"
    case "YI":
        return "yi-lightning"
    case "KIMI":
        return "moonshot-v1-auto"
    case "STEP":
        return "step-2-mini"
    case "OPENAI":
        return "gpt-4o-mini"
    case "GOOGLE":
        return "gemini-2.0-flash"
    case "ANTHROPIC":
        return "claude-3-5-haiku-latest"
    case "XAI":
        return "grok-2-latest"
    case "WENXIN":
        return "ernie-speed-128k"
    case "SPARK":
        return "spark"
    case "PERPLEXITY":
        return "sonar"
    case "OPENROUTER":
        return "qwen/qwen3-30b-a3b-instruct-2507"
    case "MODELSCOPE":
        return "Qwen/Qwen2.5-32B-Instruct"
    case "GITEE":
        return "Qwen2-7B-Instruct"
    default:
        return "Unknown"
    }
}

// 获得Key列表
func getKeyList() -> [APIKeys] {
    let keys: [APIKeys] = [
        APIKeys(
            name: "HANLIN_API_KEY",
            company: "HANLIN",
            key: getEnvironmentVariable("HANLIN_API_KEY"),
            requestURL: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
            isHidden: false,
            from: .system
        ),
        APIKeys(
            name: "HANLIN_OPEN_API_KEY",
            company: "HANLIN_OPEN",
            key: getEnvironmentVariable("HANLIN_OPEN_API_KEY"),
            requestURL: "https://api.siliconflow.cn/v1/chat/completions",
            isHidden: false,
            from: .system
        ),
        APIKeys(
            name: "CHERRY_IN_API_KEY",
            company: "CHERRY_IN",
            key: "",
            requestURL: "https://open.cherryin.net/v1/chat/completions",
            help: "https://open.cherryin.ai/console/token",
            from: .system
        ),
        APIKeys(
            name: "ZHIPUAI_API_KEY",
            company: "ZHIPUAI",
            key: "",
            requestURL: "https://open.bigmodel.cn/api/paas/v4/chat/completions",
            help: "https://bigmodel.cn/usercenter/proj-mgmt/apikeys",
            from: .system
        ),
        APIKeys(
            name: "DASHSCOPE_API_KEY",
            company: "QWEN",
            key: "",
            requestURL: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions",
            help: "https://bailian.console.aliyun.com/?tab=model#/api-key",
            from: .system
        ),
        APIKeys(
            name: "DEEPSEEK_API_KEY",
            company: "DEEPSEEK",
            key: "",
            requestURL: "https://api.deepseek.com/v1/chat/completions",
            help: "https://platform.deepseek.com/api_keys",
            from: .system
        ),
        APIKeys(
            name: "SILICONCLOUD_API_KEY",
            company: "SILICONCLOUD",
            key: "",
            requestURL: "https://api.siliconflow.cn/v1/chat/completions",
            help: "https://cloud.siliconflow.cn/account/ak",
            from: .system
        ),
        APIKeys(
            name: "ARK_API_KEY",
            company: "DOUBAO",
            key: "",
            requestURL: "https://ark.cn-beijing.volces.com/api/v3/chat/completions",
            help: "https://console.volcengine.com/ark/region:ark+cn-beijing/apiKey?apikey=%7B%7D",
            from: .system
        ),
        APIKeys(
            name: "KIMI_API_KEY",
            company: "KIMI",
            key: "",
            requestURL: "https://api.moonshot.cn/v1/chat/completions",
            help: "https://platform.moonshot.cn/console/api-keys",
            from: .system
        ),
        APIKeys(
            name: "OPENAI_API_KEY",
            company: "OPENAI",
            key: "",
            requestURL: "https://api.openai.com/v1/chat/completions",
            help: "https://platform.openai.com/api-keys",
            from: .system
        ),
        APIKeys(
            name: "GEMINI_API_KEY",
            company: "GOOGLE",
            key: "",
            requestURL: "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
            help: "https://aistudio.google.com/apikey",
            from: .system
        ),
        APIKeys(
            name: "XAI_API_KEY",
            company: "XAI",
            key: "",
            requestURL: "https://api.x.ai/v1/chat/completions",
            help: "https://console.x.ai/team/c4aa1fe8-2617-4255-a78f-03d9572d1110/api-keys",
            from: .system
        ),
        APIKeys(
            name: "ANTHROPIC_API_KEY",
            company: "ANTHROPIC",
            key: "",
            requestURL: "https://api.anthropic.com/v1/chat/completions",
            from: .system
        ),
        APIKeys(
            name: "YI_API_KEY",
            company: "YI",
            key: "",
            requestURL: "https://api.lingyiwanwu.com/v1/chat/completions",
            help: "https://platform.lingyiwanwu.com/apikeys",
            from: .system
        ),
        APIKeys(
            name: "HUNYUAN_API_KEY",
            company: "HUNYUAN",
            key: "",
            requestURL: "https://api.hunyuan.cloud.tencent.com/v1/chat/completions",
            help: "https://cloud.tencent.com/document/product/1729/111008",
            from: .system
        ),
        APIKeys(
            name: "STEP_API_KEY",
            company: "STEP",
            key: "",
            requestURL: "https://api.stepfun.com/v1/chat/completions",
            help: "https://platform.stepfun.com/interface-key",
            from: .system
        ),
        APIKeys(
            name: "WENXIN_API_KEY",
            company: "WENXIN",
            key: "",
            requestURL: "https://qianfan.baidubce.com/v2/chat/completions",
            help: "https://console.bce.baidu.com/iam/#/iam/accesslist",
            from: .system
        ),
        APIKeys(
            name: "PERPLEXITY_API_KEY",
            company: "PERPLEXITY",
            key: "",
            requestURL: "https://api.perplexity.ai/chat/completions",
            help: "https://www.perplexity.ai/account/api/keys",
            from: .system
        ),
        APIKeys(
            name: "OPENROUTER_API_KEY",
            company: "OPENROUTER",
            key: "",
            requestURL: "https://openrouter.ai/api/v1/chat/completions",
            help: "https://openrouter.ai/settings/keys",
            from: .system
        ),
        APIKeys(
            name: "MODELSCOPE_API_KEY",
            company: "MODELSCOPE",
            key: "",
            requestURL: "https://api-inference.modelscope.cn/v1/chat/completions",
            help: "https://modelscope.cn/my/myaccesstoken",
            from: .system
        ),
        APIKeys(
            name: "GITEE_API_KEY",
            company: "GITEE",
            key: "",
            requestURL: "https://ai.gitee.com/v1/chat/completions",
            from: .system
        ),
        APIKeys(
            name: "MINIMAX_API_KEY",
            company: "MINIMAX",
            key: "",
            requestURL: "https://api.minimax.chat/v1/text/chatcompletion_v2",
            help: "https://platform.minimaxi.com/user-center/basic-information/interface-key",
            from: .system
        ),
        APIKeys(
            name: "LAN",
            company: "LAN",
            key: "",
            requestURL: "http://127.0.0.1:1234/v1/chat/completions",
            from: .system
        ),
        APIKeys(
            name: "LOCAL",
            company: "LOCAL",
            key: "LOCAL",
            requestURL: "LOCAL",
            from: .system
        )
    ]
    return keys
}

func getSearchKeyList() -> [SearchKeys] {
    let keys: [SearchKeys] = [
        SearchKeys(
            name: "ZHIPUAI_SEARCH_KEY",
            company: "ZHIPUAI",
            key: "",
            requestURL: "https://open.bigmodel.cn/api/paas/v4/web_search",
            price: 0.01,
            isUsing: false,
            help: "https://bigmodel.cn/usercenter/proj-mgmt/apikeys"
        ),
        SearchKeys(
            name: "BOCHAAI_SEARCH_KEY",
            company: "BOCHAAI",
            key: "",
            requestURL: "https://api.bochaai.com/v1/web-search",
            price: 0.036,
            isUsing: false,
            help: "https://open.bochaai.com/api-keys"
        ),
        SearchKeys(
            name: "LANGSEARCH_SEARCH_KEY",
            company: "LANGSEARCH",
            key: "",
            requestURL: "https://api.langsearch.com/v1/web-search",
            price: 0,
            isUsing: false,
            help: "https://langsearch.com/api-keys"
        ),
        SearchKeys(
            name: "EXA_KEY",
            company: "EXA",
            key: "",
            requestURL: "https://api.exa.ai/search",
            price: 0.0365,
            isUsing: false,
            help: "https://dashboard.exa.ai/api-keys"
        ),
        SearchKeys(
            name: "TAVILY_KEY",
            company: "TAVILY",
            key: "",
            requestURL: "https://api.tavily.com/search",
            price: 0.0584,
            isUsing: false,
            help: "https://app.tavily.com/home"
        ),
        SearchKeys(
            name: "BRAVE_KEY",
            company: "BRAVE",
            key: "",
            requestURL: "https://api.search.brave.com/res/v1/web/search",
            price: 0.0219,
            isUsing: false,
            help: "https://api-dashboard.search.brave.com/app/keys"
        ),
        SearchKeys(
            name: "PERPLEXITY_KEY",
            company: "PERPLEXITY",
            key: "",
            requestURL: "https://api.perplexity.ai/search",
            price: 0.005,
            isUsing: false,
            help: "https://www.perplexity.ai/account/api/keys"
        ),
    ]
    return keys
}

// 工具列表
func getToolKeyList() -> [ToolKeys] {
    let keys: [ToolKeys] = [
        ToolKeys(
            name: "APPLE_MAP_KEY",
            company: "APPLEMAP",
            key: "APPLEMAP",
            requestURL: "https://applemap.com",
            price: 0,
            isUsing: true,
            toolClass: "map",
            help: "map"
        ),
        ToolKeys(
            name: "AMAP_MAP_KEY",
            company: "AMAP",
            key: "",
            requestURL: "https://restapi.amap.com",
            price: 0,
            isUsing: false,
            toolClass: "map",
            help: "https://console.amap.com/dev/key/app"
        ),
        ToolKeys(
            name: "GOOGLE_MAP_KEY",
            company: "GOOGLEMAP",
            key: "",
            requestURL: "https://places.googleapis.com",
            price: 0,
            isUsing: false,
            toolClass: "map",
            help: "https://console.cloud.google.com/google/maps-apis"
        ),
        ToolKeys(
            name: "QWEATHER_KEY",
            company: "QWEATHER",
            key: "",
            requestURL: "",
            price: 0,
            isUsing: false,
            toolClass: "weather",
            help: "https://console.qweather.com/project?lang=zh"
        ),
        ToolKeys(
            name: "OPENWEATHER_KEY",
            company: "OPENWEATHER",
            key: "",
            requestURL: "api.openweathermap.org",
            price: 0,
            isUsing: false,
            toolClass: "weather",
            help: "https://home.openweathermap.org/api_keys"
        ),
    ]
    return keys
}

// 获得图标
func getIconList() -> [String] {
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
        "ant.circle", "ladybug.circle", "fish.circle", "pawprint.circle", "leaf.circle", "tree.circle", "tshirt.circle", "shoe.circle",
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
        "bolt.car.circle", "figure.child.circle", "ladybug.slash.circle", "camera.macro.circle", "eye.slash.circle",
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

func getColorList() -> [Color] {
    return [
        // HL 系列颜色（按图中顺序）
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

        // 系统标准色
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
        default: return .hlBlue // 默认颜色
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
        default: return "hlBlue" // 默认颜色名称
        }
    }
}
    

// 根据公司名称获取对应的图标
func getCompanyIcon(for companyName: String) -> String {
    let isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
    switch companyName {
    case "HANLIN":
        return "hanlin"
    case "HANLIN_OPEN":
        return "hanlin"
    case "ZHIPUAI":
        return isDarkMode ? "zhipuai_dark" : "zhipuai"
    case "QWEN":
        return "qwen"
    case "DEEPSEEK":
        return "deepseek"
    case "SILICONCLOUD":
        return "siliconflow"
    case "GITHUB":
        return isDarkMode ? "github_dark" : "github"
    case "DOUBAO":
        return "doubao"
    case "KIMI":
        return isDarkMode ? "kimi_dark" : "kimi"
    case "OPENAI":
        return isDarkMode ? "openai_dark" : "openai"
    case "GOOGLE":
        return "google"
    case "GOOGLE_SEARCH":
        return "google_search"
    case "XAI":
        return isDarkMode ? "xai_dark" : "xai"
    case "ANTHROPIC":
        return "claude"
    case "LOCAL":
        return "assistant"
    case "MODELSCOPE":
        return "modelscope"
    case "LAN":
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
    case "TAVILY":
        return "tavily"
    case "LANGSEARCH":
        return "langsearch"
    case "TIANGONG":
        return "tiangong"
    case "SPARK":
        return "spark"
    case "PERPLEXITY":
        return "perplexity"
    case "OPENROUTER":
        return isDarkMode ? "openrouter_dark" : "openrouter"
    case "HANLINWEB":
        return "webreader"
    case "HANLINBAG":
        return "knowledge_bag"
    case "BRAVE":
        return "brave"
    case "SIRI":
        return "siri"
    case "GITEE":
        return isDarkMode ? "gitee_dark" : "gitee"
    case "APPLEMAP":
        return "applemap"
    case "AMAP":
        return "amap"
    case "BAIDUMAP":
        return "baidumap"
    case "GOOGLEMAP":
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
        return "defaultIcon" // 默认图标名称
    }
}

func getCompanyName(for companyName: String) -> String {
    let key = "company_\(companyName.uppercased())" // 生成动态 key
    let localizedName = NSLocalizedString(key, tableName: "Localizable", bundle: .main, value: "未知", comment: "Company Name")
    return localizedName
}

// 重载函数：处理 APIKeys 对象，自定义供应商显示其名称
func getCompanyName(for apiKey: APIKeys) -> String {
    // 如果是自定义供应商，直接返回其名称
    if apiKey.from == .custom {
        return apiKey.name ?? "自定义供应商"
    }
    // 否则使用原有的本地化逻辑
    return getCompanyName(for: apiKey.company ?? "Unknown")
}

func priceText(for price: Int16) -> String {
    let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
    
    if currentLanguage.hasPrefix("zh") {
        switch price {
        case 0: return "免费"
        case 1: return "廉价"
        case 2: return "适中"
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

func gradient(for index: Int) -> LinearGradient {
    switch index % 8 {
    case 0:
        return LinearGradient(
            gradient: Gradient(colors: [Color.hlBlue, Color.hlPurple]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case 1:
        return LinearGradient(
            gradient: Gradient(colors: [Color.red, Color.orange]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case 2:
        return LinearGradient(
            gradient: Gradient(colors: [Color.green, Color.yellow]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case 3:
        return LinearGradient(
            gradient: Gradient(colors: [Color.pink, Color.blue]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case 4:
        return LinearGradient(
            gradient: Gradient(colors: [Color.teal, Color.indigo]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case 5:
        return LinearGradient(
            gradient: Gradient(colors: [Color.mint, Color.cyan]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    case 6:
        return LinearGradient(
            gradient: Gradient(colors: [Color.orange, Color.pink]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    default:
        return LinearGradient(
            gradient: Gradient(colors: [Color.purple, Color.red]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// 还原 Agent 模型名为基座模型名
func restoreBaseModelName(from agentModelName: String) -> String {
    // 1. 去掉 "_agent_<UUID>" 部分
    guard let baseName = agentModelName.components(separatedBy: "_agent_").first else {
        return agentModelName
    }
    guard let baseName = baseName.components(separatedBy: "_repeat_").first else {
        return baseName
    }
    if baseName.hasSuffix("_hanlin") {
        return String(baseName.dropLast("_hanlin".count))
    } else {
        return baseName
    }
}

struct EmbeddingModel: Identifiable {
    let id = UUID()
    var name: String          // 模型名称（如 text-embedding-v3）
    var displayName: String   // 显示名称
    var company: String       // 公司名称（如 阿里云 / OpenAI）
    var dimension: Int        // 向量维度（如 1024）
    var requestURL: String    // 嵌入请求的 URL
    var price: Double         // 单次调用价格（如 0.0001 / 每千 tokens）
}

func getEmbeddingModelList() -> [EmbeddingModel] {
    let models: [EmbeddingModel] = [
        EmbeddingModel(
            name: "Hanlin-BAAI/bge-m3",
            displayName: "Hanlin-BAAI/bge-m3",
            company: "HANLIN_OPEN",
            dimension: 1024,
            requestURL: "https://api.siliconflow.cn/v1/embeddings",
            price: 0
        ),
        EmbeddingModel(
            name: "BAAI/bge-m3",
            displayName: "BAAI/bge-m3",
            company: "SILICONCLOUD",
            dimension: 1024,
            requestURL: "https://api.siliconflow.cn/v1/embeddings",
            price: 0
        ),
        EmbeddingModel(
            name: "text-embedding-v3",
            displayName: "Qwen-Embedding-V3",
            company: "QWEN",
            dimension: 1024,
            requestURL: "https://dashscope.aliyuncs.com/compatible-mode/v1/embeddings",
            price: 0.0005
        ),
        EmbeddingModel(
            name: "embedding-3",
            displayName: "GLM-Embedding-3",
            company: "ZHIPUAI",
            dimension: 1024,
            requestURL: "https://open.bigmodel.cn/api/paas/v4/embeddings",
            price: 0.0005
        ),
        EmbeddingModel(
            name: "doubao-embedding-text-240715",
            displayName: "Doubao-Embedding",
            company: "DOUBAO",
            dimension: 1024,
            requestURL: "https://ark.cn-beijing.volces.com/api/v3/embeddings",
            price: 0.0005
        ),
        EmbeddingModel(
            name: "text-embedding-3-large",
            displayName: "OpenAI-Embedding3-Large",
            company: "OPENAI",
            dimension: 1024,
            requestURL: "https://api.openai.com/v1/embeddings",
            price: 0.000949
        ),
        EmbeddingModel(
            name: "text-embedding-3-small",
            displayName: "OpenAI-Embedding3-Small",
            company: "OPENAI",
            dimension: 1024,
            requestURL: "https://api.openai.com/v1/embeddings",
            price: 0.000146
        ),
    ]
    return models
}

/// 模拟获取语音模型列表，仅支持 Siri 和 gpt-4o-mini-tts
func getTTSModelList() -> [EmbeddingModel] {
    let models: [EmbeddingModel] = [
        EmbeddingModel(
            name: "Siri",
            displayName: "Siri",
            company: "SIRI",
            dimension: 0,
            requestURL: "",
            price: 0
        ),
        EmbeddingModel(
            name: "gpt-4o-mini-tts",
            displayName: "GPT-4o-mini-TTS",
            company: "OPENAI",
            dimension: 0,
            requestURL: "https://api.openai.com/v1/audio/speech",
            price: 0.0876
        ),
        EmbeddingModel(
            name: "tts-1",
            displayName: "OpenAI-TTS-1",
            company: "OPENAI",
            dimension: 0,
            requestURL: "https://api.openai.com/v1/audio/speech",
            price: 0.1095
        ),
        EmbeddingModel(
            name: "tts-1-hd",
            displayName: "OpenAI-TTS-1-HD",
            company: "OPENAI",
            dimension: 0,
            requestURL: "https://api.openai.com/v1/audio/speech",
            price: 0.2190
        ),
        EmbeddingModel(
            name: "FunAudioLLM/CosyVoice2-0.5B",
            displayName: "FunAudioLLM/CosyVoice2-0.5B",
            company: "SILICONCLOUD",
            dimension: 0,
            requestURL: "https://api.siliconflow.cn/v1/audio/speech",
            price: 0.15
        ),
        EmbeddingModel(
            name: "qwen-tts",
            displayName: "Qwen-TTS",
            company: "QWEN",
            dimension: 0,
            requestURL: "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation",
            price: 0.0174
        ),
    ]
    return models
}

// 时间标准化
func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    formatter.locale = .current
    return formatter.string(from: date)
}

/// 把 Markdown 字符串转换成易粘贴的纯文本
func markdownToPlainText(_ markdown: String) -> String {

    // MARK: - 正则缓存（首次调用时才创建）
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

    // 统一换行
    let rows = markdown.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")

    var inFence = false
    var out: [String] = []

    for var line in rows {
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        // 1) 代码围栏
        if RX.codeFence.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)) != nil {
            inFence.toggle()
            continue
        }
        if inFence {                      // 代码块内容直接保留
            out.append(line)
            continue
        }

        // 2) 跳过 HR / 表格分隔
        if RX.hr.firstMatch(in: trimmed, range: trimmed.nsRange) != nil { continue }
        if RX.tableSep.firstMatch(in: trimmed, range: trimmed.nsRange) != nil { continue }

        // 3) 表格竖线→空格 & 压缩多空格
        line = RX.tablePipe.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: " ")
        line = RX.multiSpace.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: " ")

        // 4) 标题 / 列表符号 / 引用
        line = RX.heading.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "")
        line = RX.listDash.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1· ")
        line = RX.blockQuote.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "")

        // 5) 行内代码 & 强调
        line = RX.inlineCode.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1")
        line = RX.strong.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1$2")
        line = RX.em    .stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1$2")
        line = RX.del   .stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1")

        // 6) 链接 / 图片（仅保文本）
        line = RX.link .stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1")
        line = RX.image.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "$1")

        // 7) 去 HTML 标签
        line = RX.htmlTag.stringByReplacingMatches(in: line, range: line.nsRange, withTemplate: "")

        // 8) HTML 实体解码（常用）
        line = line.replacingOccurrences(of: "&nbsp;" , with: " ")
                   .replacingOccurrences(of: "&lt;"   , with: "<")
                   .replacingOccurrences(of: "&gt;"   , with: ">")
                   .replacingOccurrences(of: "&amp;"  , with: "&")
                   .replacingOccurrences(of: "&quot;" , with: "\"")
                   .replacingOccurrences(of: "&apos;" , with: "'")

        out.append(line.trimmingCharacters(in: .whitespaces))
    }

    // 9) 合并多余空行
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

// 转换小工具
private extension String {
    /// 生成整个字符串的 NSRange
    var nsRange: NSRange { NSRange(location: 0, length: utf16.count) }
}

// MARK: - 恢复系统模型默认排序
func resetModelPositionToDefault(context: ModelContext) {
    do {
        let fetchDescriptor = FetchDescriptor<AllModels>()
        let allModels = try context.fetch(fetchDescriptor)
        
        // Step 1: 构建 name -> 预置模型 的映射表
        let predefinedModels = getModelList()
        var predefinedPositionMap: [String: Int] = [:]
        for model in predefinedModels {
            if let name = model.name, let position = model.position {
                predefinedPositionMap[name] = position
            }
        }

        // Step 2: 先处理系统预置模型
        var maxSystemPosition = -1
        for model in allModels where model.systemProvision {
            if let name = model.name, let defaultPosition = predefinedPositionMap[name] {
                model.position = defaultPosition
                maxSystemPosition = max(maxSystemPosition, defaultPosition)
            }
        }

        // Step 3: 非系统预置模型统一放在系统模型之后，按名称排序
        var nonSystemModels = allModels.filter { !$0.systemProvision }
        nonSystemModels.sort { ($0.displayName ?? "") < ($1.displayName ?? "") }

        for (offset, model) in nonSystemModels.enumerated() {
            let newPosition = maxSystemPosition + 1 + offset
            model.position = newPosition
        }

        try context.save()
        print("模型排序已按默认规则恢复完毕。")

    } catch {
        print("恢复默认模型排序失败：\(error)")
    }
}

/// 解析时间范围：支持中英丰富表达
/// - 参数 raw: 原始关键词（可能包含类似“刚刚”、“last week”、“3天前”等时间词）
/// - 返回值：去掉了时间词的“纯搜索词” + 具体的开始时间和结束时间
func extractTimeRange(from raw: String) -> (clean: String, start: Date, end: Date) {
    let now = Date()
    let cal = Calendar.current
    var startDate: Date?
    var endDate: Date = now
    var clean = raw
    
    // 1. 预定义短语（中英文），逐一匹配并移除
    let phraseHandlers: [([String], ()->Void)] = [
        (["刚刚", "just now"], {
            startDate = cal.date(byAdding: .minute, value: -5, to: now)
        }),
        (["今天", "today"], {
            startDate = cal.startOfDay(for: now)
        }),
        (["昨天", "yesterday"], {
            let todayStart = cal.startOfDay(for: now)
            endDate = todayStart
            startDate = cal.date(byAdding: .day, value: -1, to: todayStart)
        }),
        (["前天"], {
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
        (["最近一周", "过去一周", "past week", "last 7 days"], {
            startDate = cal.date(byAdding: .day, value: -7, to: now)
        }),
        (["最近30天", "过去30天", "past month", "last 30 days"], {
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
    
    // 2. 动态正则：匹配“X分钟前/ago/内”、“X小时前”、“X天前”等
    let relativePatterns: [(pattern: String, component: Calendar.Component)] = [
        ("(\\d+)\\s*(分钟|min|mins)\\s*(前|ago|内)?", .minute),
        ("(\\d+)\\s*(小时|h|hour|hours)\\s*(前|ago|内)?", .hour),
        ("(\\d+)\\s*(天|d|day|days)\\s*(前|ago|内)?", .day),
        ("(\\d+)\\s*(周|星期|w|week|weeks)\\s*(前|ago|内)?", .weekOfYear),
        ("(\\d+)\\s*(月|m|month|months)\\s*(前|ago|内)?", .month),
        ("(\\d+)\\s*(年|y|year|years)\\s*(前|ago|内)?", .year)
    ]
    for (pattern, component) in relativePatterns {
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        if let m = regex.firstMatch(in: clean, range: NSRange(clean.startIndex..., in: clean)),
           let r = Range(m.range(at: 1), in: clean),
           let val = Int(clean[r]) {
            // 计算起始时间
            startDate = cal.date(byAdding: component, value: -val, to: now)
            // 去掉已匹配的相对表达
            clean = regex.stringByReplacingMatches(in: clean,
                                                   options: [],
                                                   range: NSRange(clean.startIndex..., in: clean),
                                                   withTemplate: "")
        }
    }
    
    // 3. 默认范围：过去 7 天
    let defaultStart = cal.date(byAdding: .day, value: -7, to: now)!
    
    return (
        clean.trimmingCharacters(in: .whitespacesAndNewlines),
        startDate ?? defaultStart,
        endDate
    )
}
