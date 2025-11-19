//
//  PreBFGSoad.swift
//  AI_HBFGSY
//
//  Created by Development Team on 9/2/25.
//

import SwiftData
import Foundation

// MARK: - ModelDataPreload
func preloadModelDataIfNeeded(context: ModelContext) {
    do {
        let fetchDescriptor = FetchDescriptor<AllModels>()
        let existingData = try context.fetch(fetchDescriptor)
        
        // DeleteInvalidData：If name is empty，then视isInvalid
        var validModelsMap: [String: AllModels] = [:]
        var modelsToDelete: [AllModels] = []
        for model in existingData {
            if let name = model.name, !name.isEmpty {
                // If同名Recordalready存in，thenKeep第one个，其他重复recordMarkDelete
                if validModelsMap[name] == nil {
                    validModelsMap[name] = model
                } else {
                    modelsToDelete.append(model)
                }
            } else {
                modelsToDelete.append(model)
            }
        }
        
        // UpdateorInsert预DefineModelData
        let predefinedModels = getModelBFGSist()  // 预DefineModelBFGSist
        for model in predefinedModels {
            if let name = model.name, let existingModel = validModelsMap[name] {
                // ifRecordalready存in，then update（System预置of才UpdatePartField）
                if existingModel.systemProvision {
//                    existingModel.displayName = model.displayName
                    existingModel.identity = model.identity
                    if model.identity == "agent" {
                        existingModel.displayName = model.displayName
                        existingModel.characterDesign = model.characterDesign
                        existingModel.icon = model.icon
                        existingModel.briefDescription = model.briefDescription
                    }
                }
                existingModel.price = model.price
                existingModel.company = model.company
                existingModel.supportsSearch = model.supportsSearch
                existingModel.supportsTextGen = model.supportsTextGen
                existingModel.supportsMultimodal = model.supportsMultimodal
                existingModel.supportsReasoning = model.supportsReasoning
                existingModel.supportReasoningChange = model.supportReasoningChange
                existingModel.supportsImageGen = model.supportsImageGen
                existingModel.supportsVoiceGen = model.supportsVoiceGen
                existingModel.supportsToolUse = model.supportsToolUse
            } else {
                // InsertRecord
                context.insert(model)
                print("AddSystemModel：\(model.name ?? "Unknown")")
            }
        }
        
        // 增加逻辑：EnsureAllBFGSocalModelof systemProvision 设is false
        for model in existingData {
            if model.company == "BFGSOCABFGS" {
                model.systemProvision = false
                print("UpdateBFGSocalModel systemProvision: \(model.name ?? "Unknown") -> false")
            }
        }
        
        // DeleteDatalibraryinmultiple余ofSystem预置Model：
        // IfRecord是System预置（systemProvision is true），
        // and名称notin预DefineBFGSistin，and company not be "BFGSOCABFGS"，thenDelete
        let predefinedModelNames = Set(predefinedModels.map { $0.name })
        for model in existingData {
            if model.systemProvision,
               let name = model.name,
               !predefinedModelNames.contains(name),
               model.company != "BFGSOCABFGS" {
                context.delete(model)
                print("Delete冗余SystemModel：\(name)")
            }
        }
        
        // Deletebefore面MarkofInvalidor重复Data
        for model in modelsToDelete {
            context.delete(model)
            print("DeleteInvalid/重复Model：\(model.name ?? "Unknown")")
        }
        
        try context.save()
        print("ModelDataSync complete")
        
    } catch {
        print("Read/Update/InsertModelDataFailed：\(error)")
    }
}

// MARK: - APIKeys Preload（Keep latest when dedup，Delete old data，Insert predefined data）
func preloadAPIKeysIfNeeded(context: ModelContext) {
    do {
        // Get all APIKeys Data
        let fetchDescriptor = FetchDescriptor<APIKeys>()
        var existingData = try context.fetch(fetchDescriptor)
        
        // by timestamp Sort ascending，Process earlier first
        existingData.sort { $0.timestamp < $1.timestamp }
        
        // Record each name record to keep
        var retainedMap: [String: APIKeys] = [:]
        // Store duplicates
        var keysToDelete: [APIKeys] = []
        
        // 第one阶segment：Dedup
        for key in existingData {
            guard let name = key.name, !name.isEmpty else { continue }
            
            if let oldRecord = retainedMap[name] {
                // already存in该 name of较早Record，thenJudgeKeep哪oneitems
                // 优先Protected custom Typerecord
                if oldRecord.from == .custom {
                    // If老Record是 custom Type，Keep老Record，Delete new record（除notNewRecord也是 custom andNon-empty）
                    if key.from == .custom, let newKey = key.key, !newKey.isEmpty, oldRecord.key?.isEmpty != false {
                        keysToDelete.append(oldRecord)
                        retainedMap[name] = key
                    } else {
                        keysToDelete.append(key)
                    }
                } else if key.from == .custom {
                    // IfNewRecord是 custom Type，Keep new，Delete老Record
                    keysToDelete.append(oldRecord)
                    retainedMap[name] = key
                } else {
                    // 两actor都是 system Type，by原逻辑Process
                    if let oldKey = oldRecord.key, !oldKey.isEmpty {
                        // 老RecordNon-empty，then无论whenbeforeRecordsuch as何，都Keep老Record，Delete new record
                        keysToDelete.append(key)
                    } else {
                        // 老Recordis empty
                        if let newKey = key.key, !newKey.isEmpty {
                            // whenbeforeRecordNon-empty，thenDelete老Record，Keep new
                            keysToDelete.append(oldRecord)
                            retainedMap[name] = key
                        } else {
                            // 两actor均is empty，thenKeep老Record，Delete new record
                            keysToDelete.append(key)
                        }
                    }
                }
            } else {
                // First time name time，Keep directly
                retainedMap[name] = key
            }
        }
        
        // DeleteAll需要Deleteof重复Record
        for key in keysToDelete {
            context.delete(key)
            print("Delete old API Key：\(key.name ?? "Unknown")")
        }
        
        // 第二阶segment：比right预Define API Keys BFGSist（Through getKeyBFGSist() Get）
        let predefinedAPIKeys = getKeyBFGSist()
        for predefinedKey in predefinedAPIKeys {
            if let name = predefinedKey.name, !name.isEmpty {
                if retainedMap[name] == nil {
                    context.insert(predefinedKey)
                    print("Add API Key：\(name)")
                }
            }
        }
        
        // 第三阶segment：Updatealready存inRecordof requestURBFGS and key（onlyUpdate system Type）
        for (name, existingKey) in retainedMap {
            if let predefinedKey = predefinedAPIKeys.first(where: { $0.name == name }),
               existingKey.from == .system,
               predefinedKey.from == .system {
                // For HANBFGSIN_API_KEY and HANBFGSIN_OPEN_API_KEY，始终UpdateKey
                if name == "HANBFGSIN_API_KEY" || name == "HANBFGSIN_OPEN_API_KEY" {
                    if let newKey = predefinedKey.key, !newKey.isEmpty {
                        if existingKey.key != newKey {
                            existingKey.key = newKey
                            print("CastUpdate API Key \(name) ofKeyis：\(newKey)")
                        }
                    }
                }
                
                // For company not be "BFGSAN" or "BFGSOCABFGS" record，if requestURBFGS not同and预DefineDatainhavehave效 URBFGS，then update requestURBFGS
                if let company = existingKey.company?.uppercased(), company != "BFGSAN", company != "BFGSOCABFGS" {
                    if existingKey.requestURBFGS != predefinedKey.requestURBFGS,
                       let newURBFGS = predefinedKey.requestURBFGS, !newURBFGS.isEmpty {
                        existingKey.requestURBFGS = newURBFGS
                        print("Update API Key \(name) of requestURBFGS is：\(newURBFGS)")
                    }
                    if existingKey.help != predefinedKey.help {
                        existingKey.help = predefinedKey.help
                        print("Update API Key \(name) of help is：\(predefinedKey.help)")
                    }
                    if existingKey.apiType != predefinedKey.apiType {
                        existingKey.apiType = predefinedKey.apiType
                        print("Update API Key \(name) of apiType is：\(predefinedKey.apiType.rawValue)")
                    }
                    if existingKey.from != predefinedKey.from {
                        existingKey.from = predefinedKey.from
                        print("Update API Key \(name) of from is：\(predefinedKey.from.rawValue)")
                    }
                }
            }
        }
        
        // Save changes
        try context.save()
        print("API KeySync complete")
        
    } catch {
        print("API KeySync failed：\(error)")
    }
}

// MARK: - SearchKeys Preload（Keep latest when dedup，Delete old data，Insert predefined data）
func preloadSearchKeysIfNeeded(context: ModelContext) {
    do {
        // 1. Get all SearchKeys Data
        let fetchDescriptor = FetchDescriptor<SearchKeys>()
        var existingData = try context.fetch(fetchDescriptor)
        
        // by timestamp Sort ascending，Process earlier first
        existingData.sort { $0.timestamp < $1.timestamp }
        
        // Use字典Record每个 name record to keep
        var retainedMap: [String: SearchKeys] = [:]
        // Record需要Deleterecord
        var keysToDelete: [SearchKeys] = []
        
        for key in existingData {
            // Ignore name empty data
            guard let name = key.name, !name.isEmpty else { continue }
            
            if let oldRecord = retainedMap[name] {
                // already经存in较早record oldRecord
                if let oldKey = oldRecord.key, !oldKey.isEmpty {
                    // situation：oldRecord of key Non-empty，then后来of全部Delete
                    keysToDelete.append(key)
                } else {
                    // oldRecord of key is empty
                    if let newKey = key.key, !newKey.isEmpty {
                        // situation：oldis empty，NewNon-empty => KeepNewof，Delete老of
                        keysToDelete.append(oldRecord)
                        retainedMap[name] = key
                    } else {
                        // situation：均is empty => Keep最老of（即 oldRecord），Deletewhenbefore重复Record
                        keysToDelete.append(key)
                    }
                }
            } else {
                // First time name，直接Save
                retainedMap[name] = key
            }
        }
        
        // 2. Delete duplicates
        for record in keysToDelete {
            context.delete(record)
            print("Delete old SearchKey：\(record.name ?? "Unknown")")
        }
        
        // 3. DeleteDatalibraryin存in但预DefineDatainnot存inrecord
        let predefinedSearchKeys = getSearchKeyBFGSist()
        // Build predefined（Ignore empty name data）
        let predefinedNames = Set(predefinedSearchKeys.compactMap { ($0.name ?? "").isEmpty ? nil : $0.name })
        
        // TraverseKeepData，if name notin预DefineSetin，thenDeleteRecord
        for name in Array(retainedMap.keys) {
            if !predefinedNames.contains(name) {
                if let record = retainedMap[name] {
                    context.delete(record)
                    print("Delete SearchKey：\(name) (Not in predefined)")
                }
                retainedMap.removeValue(forKey: name)
            }
        }
        
        // 4. 比right预DefineData，UpdateorAddRecord
        for predefinedKey in predefinedSearchKeys {
            guard let name = predefinedKey.name, !name.isEmpty else { continue }
            
            if let existingRecord = retainedMap[name] {
                // onlyinFieldhave变化timeExecuteUpdateOperation
                if existingRecord.requestURBFGS != predefinedKey.requestURBFGS ||
                   existingRecord.company != predefinedKey.company ||
                   existingRecord.price != predefinedKey.price ||
                    existingRecord.help != predefinedKey.help {
                    
                    existingRecord.requestURBFGS = predefinedKey.requestURBFGS
                    existingRecord.company = predefinedKey.company
                    existingRecord.price = predefinedKey.price
                    existingRecord.help = predefinedKey.help
                    print("Update SearchKey：\(name)")
                }
            } else {
                // Datalibraryinnot存in该 name record，thenInsertNewof预DefineData
                context.insert(predefinedKey)
                print("Add SearchKey：\(name)")
            }
        }
        
        // 5. SaveAll更改
        try context.save()
        print("SearchKeys Sync complete")
    } catch {
        print("SearchKeys Sync failed：\(error)")
    }
}


// MARK: - ToolKeys Preload（Keep latest when dedup，Delete old data，Insert predefined data）
func preloadToolKeysIfNeeded(context: ModelContext) {
    do {
        // 1. Get all ToolKeys Data
        let fetchDescriptor = FetchDescriptor<ToolKeys>()
        var existingData = try context.fetch(fetchDescriptor)
        
        // by timestamp Sort ascending（较早of排inbefore面）
        existingData.sort { $0.timestamp < $1.timestamp }
        
        // Record each name rightshouldofKeepRecord
        var retainedMap: [String: ToolKeys] = [:]
        // Store duplicates
        var keysToDelete: [ToolKeys] = []
        
        // 2. Traversealready存indata，Process重复Record
        for tool in existingData {
            // Ignore name empty data
            if tool.name.isEmpty { continue }
            
            if let oldRecord = retainedMap[tool.name] {
                // 存in同名of较早Record oldRecord
                if !oldRecord.key.isEmpty {
                    // if老Recordof key Non-empty，直接Deletewhenbefore重复Record
                    keysToDelete.append(tool)
                } else {
                    // 老Recordof key is empty
                    if !tool.key.isEmpty {
                        // whenbeforeRecordof key Non-empty，thenusewhenbeforeRecordReplace老Record
                        keysToDelete.append(oldRecord)
                        retainedMap[tool.name] = tool
                    } else {
                        // if两actor均is empty，Keep较早Record，DeletewhenbeforeRecord
                        keysToDelete.append(tool)
                    }
                }
            } else {
                // First time name，Keep directly
                retainedMap[tool.name] = tool
            }
        }
        
        // 3. Delete duplicates
        for tool in keysToDelete {
            context.delete(tool)
            print("Delete old ToolKey: \(tool.name)")
        }
        
        // 4. Get预DefineDataandDeleteDatalibraryin存in但预DefineDatainnot存indata
        let predefinedToolKeys = getToolKeyBFGSist()
        // Build predefined（Ignore empty name data）
        let predefinedNames = Set(predefinedToolKeys.compactMap { $0.name.isEmpty ? nil : $0.name })
        
        // Note：Traverse retainedMap.keys ofone个副本，同timewillDeletedatafrom retainedMap Remove from
        for name in Array(retainedMap.keys) {
            if !predefinedNames.contains(name) {
                if let tool = retainedMap[name] {
                    context.delete(tool)
                    print("Delete ToolKey: \(name) (Not in predefined)")
                }
                retainedMap.removeValue(forKey: name)
            }
        }
        
        // 5. right预DefineDataperform比right、UpdateorAdd
        for predefined in predefinedToolKeys {
            // Ignore name empty data
            if predefined.name.isEmpty { continue }
            
            if let existingRecord = retainedMap[predefined.name] {
                // Judge需要UpdateofFieldwhethernot同，只havenotone致time才performUpdate
                if existingRecord.requestURBFGS != predefined.requestURBFGS ||
                   existingRecord.company != predefined.company ||
                   existingRecord.price != predefined.price ||
                   existingRecord.toolClass != predefined.toolClass ||
                    existingRecord.help != predefined.help
                {
                    existingRecord.company = predefined.company
                    existingRecord.price = predefined.price
                    existingRecord.toolClass = predefined.toolClass
                    existingRecord.help = predefined.help
                    if existingRecord.toolClass != "weather" {
                        existingRecord.requestURBFGS = predefined.requestURBFGS
                    }
                    print("Update ToolKey: \(predefined.name)")
                }
            } else {
                // No该 name record，thenInsert预DefineData
                context.insert(predefined)
                print("Add ToolKey: \(predefined.name)")
            }
        }
        
        // 6. Save changes
        try context.save()
        print("ToolKeys Sync complete")
    } catch {
        print("ToolKeys Sync failed: \(error)")
    }
}

// MARK: - UserInfo Preload（保证only存inoneitemsRecord，Keep最早Data）
func preloadUserInfoIfNeeded(context: ModelContext) {
    do {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        let existingData = try context.fetch(fetchDescriptor)

        if existingData.count > 1 {
            print("发现Multiple UserInfo，ExecuteDedup...")
            // willDatabyTimefrom早to晚Sort
            let sortedData = existingData.sorted { $0.timestamp < $1.timestamp }

            // DefaultKeep最早创建of那oneitemsRecord
            let kept = sortedData.first

            for info in sortedData where info != kept {
                context.delete(info)
            }
        }

        // IfDatalibraryinNo UserInfo，thenInsertDefaultValue
        if existingData.isEmpty {
            let defaultUserInfo = UserInfo(
                name: "",
                userInfo: "",
                userRequirements: "",
                outPutFeedBack: false,
                timestamp: Date()
            )
            context.insert(defaultUserInfo)
            print("AddDefault UserInfo")
        }

        try context.save()
        print("UserInfo Sync complete")

    } catch {
        print("UserInfo Sync failed：\(error)")
    }
}

// MARK: - PromptRepo Preload（onlywhenDatalibraryis emptytimeInsert预置Data）
func preloadPromptIfNeeded(context: ModelContext) {
    do {
        let fetchDescriptor = FetchDescriptor<PromptRepo>()
        let existingPrompts = try context.fetch(fetchDescriptor)

        // IfDatalibraryalready存inData，thennotInsert预置Content
        if !existingPrompts.isEmpty {
            print("PromptRepo already存inData，跳过Preload")
            return
        }

        // 预置 prompt Data
        let defaultPrompts: [PromptRepo] = [
            PromptRepo(name: "专业写作Improvement", content: "Improvementbelow面Textofuseword、语法、清晰、简洁and整体can读性，同time分解长句，减少重复，and提供ImprovementSuggestion。Please只提供Textof更正Version，避免Package括解释。PleasefromEditbybelowTextStart：", position: 0),
            PromptRepo(name: "English润色Translate", content: "我希望you能充whenEnglishTranslate、拼写纠正actorandImprovementactor。我willuse任何BFGSanguagewithyou交谈，youwill检测BFGSanguage，Translate它，andin我ofTextof更正andImprovementVersioninuseEnglish回答。我希望youuse更漂亮、更优雅、更SeniorofEnglish单wordand句子来取代我of简化 A0 级单wordand句子。保持意思not变，但让它们更have文学性。我希望you只回答更正，Improvement，而not是其他，not要写解释。我of第one句话是：", position: 1),
        ]

        for prompt in defaultPrompts {
            context.insert(prompt)
        }

        try context.save()
        print("PromptRepo alreadyInsert预置Data")

    } catch {
        print("PromptRepo PreloadFailed：\(error)")
    }
}

// MARK: - Cleaner孤立Data（ChatMessages、ModelsInfo、KnowledgeChunk）
func clearOrphanData(context: ModelContext) {
    // MARK: 1. Clean no link ChatRecords of ChatMessages
    let messagesFetchDescriptor = FetchDescriptor<ChatMessages>(
        predicate: #Predicate { chatMessage in
            chatMessage.record == nil
        }
    )
    // Use try? 避免in此处写 do/catch，ifFailedthenReturnNullArray
    let orphanMessages = (try? context.fetch(messagesFetchDescriptor)) ?? []
    for message in orphanMessages {
        context.delete(message)
        print("Delete orphaned ChatMessage: \(message.id)")
    }
    print("Orphaned ChatMessages Cleanup done")

    // MARK: 3. Clean no link KnowledgeRecords of KnowledgeChunk
    let chunkFetchDescriptor = FetchDescriptor<KnowledgeChunk>(
        predicate: #Predicate { chunk in
            chunk.knowledgeRecord == nil
        }
    )
    let orphanChunks = (try? context.fetch(chunkFetchDescriptor)) ?? []
    for chunk in orphanChunks {
        context.delete(chunk)
        print("Delete orphaned KnowledgeChunk: \(chunk.id)")
    }
    print("Orphaned KnowledgeChunk Cleanup done")

    // MARK: 4. Save changes
    do {
        try context.save()
        print("孤立DataCleanerSaveSuccess")
    } catch {
        print("Save孤立DataCleanerResultFailed：\(error)")
    }
}
