//
//  AISettingsStore.swift
//  AI_HLY
//
//  AICore —— 统一的「设置 / 凭据」读取入口（封装 SwiftData ModelContext）。
//  对标 Cherry Studio v2 在 providerConfig 里集中读取 provider 凭据 + 用户开关的角色。
//
//  把原先散落在 APIManager 里的一堆 `private func isXxxEnabled()` / `getAPIKey` 等
//  数据库查询收敛到一个值类型里，引擎与各工具通过它读取配置，逻辑与现状逐字一致。
//

import Foundation
import SwiftData

struct AISettingsStore {

    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - 凭据
    /// 查询模型密钥
    func apiKey(for company: String) -> String? {
        let predicate = #Predicate<APIKeys> { $0.company == company }
        let fetchDescriptor = FetchDescriptor<APIKeys>(predicate: predicate)
        return (try? context.fetch(fetchDescriptor).first)?.key
    }

    /// 查询模型请求地址
    func requestURL(for company: String) -> String? {
        let predicate = #Predicate<APIKeys> { $0.company == company }
        let fetchDescriptor = FetchDescriptor<APIKeys>(predicate: predicate)
        return (try? context.fetch(fetchDescriptor).first)?.requestURL
    }

    /// 查询该公司 API Key 的接口格式（OpenAI / OpenAI-Response / Anthropic / Gemini）。
    /// 新引擎据此把聊天请求路由到对应的原生 client。
    /// 找不到记录时回退 .openAI（与现有"全部按 OpenAI 兼容"的默认行为一致）。
    func apiType(for company: String) -> APIType {
        let predicate = #Predicate<APIKeys> { $0.company == company }
        let fetchDescriptor = FetchDescriptor<APIKeys>(predicate: predicate)
        return (try? context.fetch(fetchDescriptor).first)?.apiType ?? .openAI
    }

    // MARK: - 功能开关（UserInfo）
    private func userInfo() -> UserInfo? {
        try? context.fetch(FetchDescriptor<UserInfo>()).first
    }

    /// 双语检索是否启用
    var isBilingualSearchEnabled: Bool { userInfo()?.bilingualSearch ?? false }
    /// 记忆功能是否启用
    var isMemoryEnabled: Bool { userInfo()?.useMemory ?? false }
    /// 跨聊天记忆功能是否启用
    var isCrossMemoryEnabled: Bool { userInfo()?.useCrossMemory ?? false }
    /// 地图功能是否启用
    var isMapEnabled: Bool { userInfo()?.useMap ?? false }
    /// 日历功能是否启用
    var isCalendarEnabled: Bool { userInfo()?.useCalendar ?? false }
    /// 健康功能是否启用
    var isHealthEnabled: Bool { userInfo()?.useHealth ?? false }
    /// 代码功能是否启用
    var isCodeEnabled: Bool { userInfo()?.useCode ?? false }
    /// 搜索功能是否启用
    var isSearchEnabled: Bool { userInfo()?.useSearch ?? false }
    /// 知识功能是否启用
    var isKnowledgeEnabled: Bool { userInfo()?.useKnowledge ?? false }
    /// 天气查询是否启用
    var isWeatherEnabled: Bool { userInfo()?.useWeather ?? false }
    /// 画布功能是否启用
    var isCanvasEnabled: Bool { userInfo()?.useCanvas ?? false }

    // MARK: - 数量 / 阈值
    /// 搜索数量
    var searchCount: Int { userInfo()?.searchCount ?? 10 }
    /// 知识数量
    var knowledgeCount: Int { userInfo()?.knowledgeCount ?? 10 }
    /// 知识相似度
    var knowledgeSimilarity: Double { userInfo()?.knowledgeSimilarity ?? 0.5 }

    // MARK: - 工具服务（ToolKeys）
    /// 检查使用的地图
    func findUseMap() -> (company: String, apiKey: String)? {
        let fetchRequest = FetchDescriptor<ToolKeys>(predicate: #Predicate {
            $0.toolClass == "map" && $0.isUsing == true
        })
        do {
            let mapKeys = try context.fetch(fetchRequest)
            if let activeMap = mapKeys.first {
                return (activeMap.company, activeMap.key)
            }
        } catch {
            print("获取地图服务失败: \(error.localizedDescription)")
        }
        return nil
    }

    /// 检查使用的天气
    func findUseWeather() -> (company: String, apiKey: String, requestURL: String)? {
        let fetchRequest = FetchDescriptor<ToolKeys>(predicate: #Predicate {
            $0.toolClass == "weather" && $0.isUsing == true
        })
        do {
            let mapKeys = try context.fetch(fetchRequest)
            if let activeMap = mapKeys.first {
                return (activeMap.company, activeMap.key, activeMap.requestURL)
            }
        } catch {
            print("获取天气服务失败: \(error.localizedDescription)")
        }
        return nil
    }

    // MARK: - 搜索引擎（SearchKeys）
    /// 激活的搜索引擎
    func getActiveSearchEngine() -> (engine: SearchEngine, apiKey: String?, requestURL: String)? {
        let fetchRequest = FetchDescriptor<SearchKeys>(predicate: #Predicate { $0.isUsing == true })
        do {
            let searchKeys = try context.fetch(fetchRequest)
            if let activeKey = searchKeys.first,
               let engine = SearchEngine(rawValue: activeKey.company?.uppercased() ?? "Unknown") {
                return (engine, activeKey.key, activeKey.requestURL) as? (engine: SearchEngine, apiKey: String?, requestURL: String)
            }
        } catch {
            print("获取搜索引擎失败: \(error.localizedDescription)")
        }
        return nil
    }
}
