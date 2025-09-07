//
//  App.swift
//  AI_HLY
//
//  Created by zhiyuan20002 on 3/2/25.
//

import SwiftUI
import SwiftData
import AppIntents

class AppDataManager: ObservableObject {
    let modelContainer: ModelContainer
    
    init() {
        do {
            // 配置 CloudKit 数据库（.automatic 自动选择）
            let config = ModelConfiguration(isStoredInMemoryOnly: false, cloudKitDatabase: .automatic)
            modelContainer = try ModelContainer(
                for: ChatMessages.self,
                APIKeys.self,
                SearchKeys.self,
                AllModels.self,
                ChatRecords.self,
                UserInfo.self,
                PromptRepo.self,
                KnowledgeRecords.self,
                KnowledgeChunk.self,
                MemoryArchive.self,
                TranslationDic.self,
                ToolKeys.self,
                configurations: config
            )
        } catch {
            fatalError("无法初始化 ModelContainer: \(error)")
        }
    }
    
    // 异步预加载所有数据
    @MainActor func preloadDataIfNeeded() {
        let context = modelContainer.mainContext
        // 确保模型数据优先加载完成
        preloadModelDataIfNeeded(context: context)
        preloadAPIKeysIfNeeded(context: context)
        preloadSearchKeysIfNeeded(context: context)
        preloadToolKeysIfNeeded(context: context)
        preloadUserInfoIfNeeded(context: context)
        preloadPromptIfNeeded(context: context)
        clearOrphanData(context: context)
    }
}

@main
struct MyApp: App {
    @MainActor @StateObject private var appDataManager = AppDataManager()
    @State private var deepLinkTarget: String? = nil
    
    var body: some Scene {
        WindowGroup {
            MainTabView(deepLinkTarget: $deepLinkTarget)
                .modelContainer(appDataManager.modelContainer)
                .task {
                    appDataManager.preloadDataIfNeeded()
                }
                .onOpenURL { url in
                    if url.host == "openVisionView" {
                        deepLinkTarget = "vision"
                    }
                }
        }
    }
}

