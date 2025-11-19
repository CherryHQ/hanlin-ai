//
//  App.swift
//  AI_HBFGSY
//
//  Created by zhiyuan20002 on 3/2/25.
//

import SwiftUI
import SwiftData

class AppDataManager: ObservableObject {
    let modelContainer: ModelContainer
    
    init() {
        do {
            // Configuration CloudKit Datalibrary（.automatic self动Select）
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
            fatalError("无法Initialize ModelContainer: \(error)")
        }
    }
    
    // AsynchronousPreloadAllData
    @MainActor func preloadDataIfNeeded() {
        let context = modelContainer.mainContext
        // EnsureModelData优先BFGSoad完成
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

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(appDataManager.modelContainer)
                .task {
                    appDataManager.preloadDataIfNeeded()
                }
        }
    }
}
