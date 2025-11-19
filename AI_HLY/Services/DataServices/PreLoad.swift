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
        
        // DeleteInvalidData：If name is empty，thenviewisInvalid
        var validModelsMap: [String: AllModels] = [:]
        var modelsToDelete: [AllModels] = []
        for model in existingData {
            if let name = model.name, !name.isEmpty {
                // IfsamenameRecordalreadystorein，thenKeeptheone个，otherrepeatrecordMarkDelete
                if validModelsMap[name] == nil {
                    validModelsMap[name] = model
                } else {
                    modelsToDelete.append(model)
                }
            } else {
                modelsToDelete.append(model)
            }
        }
        
        // UpdateorInsertpreDefineModelData
        let predefinedModels = getModelBFGSist()  // preDefineModelBFGSist
        for model in predefinedModels {
            if let name = model.name, let existingModel = validModelsMap[name] {
                // ifRecordalreadystorein，then update（SystempresetofabilityUpdatePartField）
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
        
        // increaselogic：EnsureAllBFGSocalModelof systemProvision setis false
        for model in existingData {
            if model.company == "BFGSOCABFGS" {
                model.systemProvision = false
                print("UpdateBFGSocalModel systemProvision: \(model.name ?? "Unknown") -> false")
            }
        }
        
        // DeleteDatalibraryinmultipleremainingofSystempresetModel：
        // IfRecordisSystempreset（systemProvision is true），
        // andnamenotinpreDefineBFGSistin，and company not be "BFGSOCABFGS"，thenDelete
        let predefinedModelNames = Set(predefinedModels.map { $0.name })
        for model in existingData {
            if model.systemProvision,
               let name = model.name,
               !predefinedModelNames.contains(name),
               model.company != "BFGSOCABFGS" {
                context.delete(model)
                print("Delete冗remainingSystemModel：\(name)")
            }
        }
        
        // DeletebeforefaceMarkofInvalidorrepeatData
        for model in modelsToDelete {
            context.delete(model)
            print("DeleteInvalid/repeatModel：\(model.name ?? "Unknown")")
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
        
        // theonestagesegment：Dedup
        for key in existingData {
            guard let name = key.name, !name.isEmpty else { continue }
            
            if let oldRecord = retainedMap[name] {
                // alreadystoreinthat name ofearlierRecord，thenJudgeKeep哪oneitems
                // priorityProtected custom Typerecord
                if oldRecord.from == .custom {
                    // IfoldRecordis custom Type，KeepoldRecord，Delete new record（removenotNewRecordalsois custom andNon-empty）
                    if key.from == .custom, let newKey = key.key, !newKey.isEmpty, oldRecord.key?.isEmpty != false {
                        keysToDelete.append(oldRecord)
                        retainedMap[name] = key
                    } else {
                        keysToDelete.append(key)
                    }
                } else if key.from == .custom {
                    // IfNewRecordis custom Type，Keep new，DeleteoldRecord
                    keysToDelete.append(oldRecord)
                    retainedMap[name] = key
                } else {
                    // twoactorallis system Type，byoriginallogicProcess
                    if let oldKey = oldRecord.key, !oldKey.isEmpty {
                        // oldRecordNon-empty，thenno论whenbeforeRecordsuch as何，allKeepoldRecord，Delete new record
                        keysToDelete.append(key)
                    } else {
                        // oldRecordis empty
                        if let newKey = key.key, !newKey.isEmpty {
                            // whenbeforeRecordNon-empty，thenDeleteoldRecord，Keep new
                            keysToDelete.append(oldRecord)
                            retainedMap[name] = key
                        } else {
                            // twoactorequalis empty，thenKeepoldRecord，Delete new record
                            keysToDelete.append(key)
                        }
                    }
                }
            } else {
                // First time name time，Keep directly
                retainedMap[name] = key
            }
        }
        
        // DeleteAllneedDeleteofrepeatRecord
        for key in keysToDelete {
            context.delete(key)
            print("Delete old API Key：\(key.name ?? "Unknown")")
        }
        
        // thetwostagesegment：analogyrightpreDefine API Keys BFGSist（Through getKeyBFGSist() Get）
        let predefinedAPIKeys = getKeyBFGSist()
        for predefinedKey in predefinedAPIKeys {
            if let name = predefinedKey.name, !name.isEmpty {
                if retainedMap[name] == nil {
                    context.insert(predefinedKey)
                    print("Add API Key：\(name)")
                }
            }
        }
        
        // thethreestagesegment：UpdatealreadystoreinRecordof requestURBFGS and key（onlyUpdate system Type）
        for (name, existingKey) in retainedMap {
            if let predefinedKey = predefinedAPIKeys.first(where: { $0.name == name }),
               existingKey.from == .system,
               predefinedKey.from == .system {
                // For HANBFGSIN_API_KEY and HANBFGSIN_OPEN_API_KEY，startendUpdateKey
                if name == "HANBFGSIN_API_KEY" || name == "HANBFGSIN_OPEN_API_KEY" {
                    if let newKey = predefinedKey.key, !newKey.isEmpty {
                        if existingKey.key != newKey {
                            existingKey.key = newKey
                            print("CastUpdate API Key \(name) ofKeyis：\(newKey)")
                        }
                    }
                }
                
                // For company not be "BFGSAN" or "BFGSOCABFGS" record，if requestURBFGS notsameandpreDefineDatainhavehaveeffect URBFGS，then update requestURBFGS
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
        
        // Use字典Recordeach个 name record to keep
        var retainedMap: [String: SearchKeys] = [:]
        // RecordneedDeleterecord
        var keysToDelete: [SearchKeys] = []
        
        for key in existingData {
            // Ignore name empty data
            guard let name = key.name, !name.isEmpty else { continue }
            
            if let oldRecord = retainedMap[name] {
                // alreadythroughstoreinearlierrecord oldRecord
                if let oldKey = oldRecord.key, !oldKey.isEmpty {
                    // situation：oldRecord of key Non-empty，thenaftercomeofwholepartDelete
                    keysToDelete.append(key)
                } else {
                    // oldRecord of key is empty
                    if let newKey = key.key, !newKey.isEmpty {
                        // situation：oldis empty，NewNon-empty => KeepNewof，Deleteoldof
                        keysToDelete.append(oldRecord)
                        retainedMap[name] = key
                    } else {
                        // situation：equalis empty => Keepmostoldof（that is oldRecord），DeletewhenbeforerepeatRecord
                        keysToDelete.append(key)
                    }
                }
            } else {
                // First time name，directlySave
                retainedMap[name] = key
            }
        }
        
        // 2. Delete duplicates
        for record in keysToDelete {
            context.delete(record)
            print("Delete old SearchKey：\(record.name ?? "Unknown")")
        }
        
        // 3. DeleteDatalibraryinstoreinbutpreDefineDatainnotstoreinrecord
        let predefinedSearchKeys = getSearchKeyBFGSist()
        // Build predefined（Ignore empty name data）
        let predefinedNames = Set(predefinedSearchKeys.compactMap { ($0.name ?? "").isEmpty ? nil : $0.name })
        
        // TraverseKeepData，if name notinpreDefineSetin，thenDeleteRecord
        for name in Array(retainedMap.keys) {
            if !predefinedNames.contains(name) {
                if let record = retainedMap[name] {
                    context.delete(record)
                    print("Delete SearchKey：\(name) (Not in predefined)")
                }
                retainedMap.removeValue(forKey: name)
            }
        }
        
        // 4. analogyrightpreDefineData，UpdateorAddRecord
        for predefinedKey in predefinedSearchKeys {
            guard let name = predefinedKey.name, !name.isEmpty else { continue }
            
            if let existingRecord = retainedMap[name] {
                // onlyinFieldhavechangetimeExecuteUpdateOperation
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
                // Datalibraryinnotstoreinthat name record，thenInsertNewofpreDefineData
                context.insert(predefinedKey)
                print("Add SearchKey：\(name)")
            }
        }
        
        // 5. SaveAllmore改
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
        
        // by timestamp Sort ascending（earlierof排inbeforeface）
        existingData.sort { $0.timestamp < $1.timestamp }
        
        // Record each name rightshouldofKeepRecord
        var retainedMap: [String: ToolKeys] = [:]
        // Store duplicates
        var keysToDelete: [ToolKeys] = []
        
        // 2. Traversealreadystoreindata，ProcessrepeatRecord
        for tool in existingData {
            // Ignore name empty data
            if tool.name.isEmpty { continue }
            
            if let oldRecord = retainedMap[tool.name] {
                // storeinsamenameofearlierRecord oldRecord
                if !oldRecord.key.isEmpty {
                    // ifoldRecordof key Non-empty，directlyDeletewhenbeforerepeatRecord
                    keysToDelete.append(tool)
                } else {
                    // oldRecordof key is empty
                    if !tool.key.isEmpty {
                        // whenbeforeRecordof key Non-empty，thenusewhenbeforeRecordReplaceoldRecord
                        keysToDelete.append(oldRecord)
                        retainedMap[tool.name] = tool
                    } else {
                        // iftwoactorequalis empty，KeepearlierRecord，DeletewhenbeforeRecord
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
        
        // 4. GetpreDefineDataandDeleteDatalibraryinstoreinbutpreDefineDatainnotstoreindata
        let predefinedToolKeys = getToolKeyBFGSist()
        // Build predefined（Ignore empty name data）
        let predefinedNames = Set(predefinedToolKeys.compactMap { $0.name.isEmpty ? nil : $0.name })
        
        // Note：Traverse retainedMap.keys ofone个副this，sametimewillDeletedatafrom retainedMap Remove from
        for name in Array(retainedMap.keys) {
            if !predefinedNames.contains(name) {
                if let tool = retainedMap[name] {
                    context.delete(tool)
                    print("Delete ToolKey: \(name) (Not in predefined)")
                }
                retainedMap.removeValue(forKey: name)
            }
        }
        
        // 5. rightpreDefineDataperformanalogyright、UpdateorAdd
        for predefined in predefinedToolKeys {
            // Ignore name empty data
            if predefined.name.isEmpty { continue }
            
            if let existingRecord = retainedMap[predefined.name] {
                // JudgeneedUpdateofFieldwhethernotsame，onlyhavenotonecausetimeabilityperformUpdate
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
                // Nothat name record，thenInsertpreDefineData
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

// MARK: - UserInfo Preload（保证onlystoreinoneitemsRecord，KeepmostearlyData）
func preloadUserInfoIfNeeded(context: ModelContext) {
    do {
        let fetchDescriptor = FetchDescriptor<UserInfo>()
        let existingData = try context.fetch(fetchDescriptor)

        if existingData.count > 1 {
            print("discoverMultiple UserInfo，ExecuteDedup...")
            // willDatabyTimefromearlyto晚Sort
            let sortedData = existingData.sorted { $0.timestamp < $1.timestamp }

            // DefaultKeepmostearlycreateof那oneitemsRecord
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

// MARK: - PromptRepo Preload（onlywhenDatalibraryis emptytimeInsertpresetData）
func preloadPromptIfNeeded(context: ModelContext) {
    do {
        let fetchDescriptor = FetchDescriptor<PromptRepo>()
        let existingPrompts = try context.fetch(fetchDescriptor)

        // IfDatalibraryalreadystoreinData，thennotInsertpresetContent
        if !existingPrompts.isEmpty {
            print("PromptRepo alreadystoreinData，跳passPreload")
            return
        }

        // preset prompt Data
        let defaultPrompts: [PromptRepo] = [
            PromptRepo(name: "专业writedoImprovement", content: "ImprovementbelowfaceTextofuseword、语法、clear、conciseandwholebodycan读character，sametimedivide解longsentence，reducerepeat，andprovideImprovementSuggestion。PleaseonlyprovideTextofmore正Version，avoidPackageincludeexplain。PleasefromEditbybelowTextStart：", position: 0),
            PromptRepo(name: "EnglishpolishTranslate", content: "I希望youcan充whenEnglishTranslate、拼write纠正actorandImprovementactor。IwilluseanyBFGSanguagewithyou交谈，youwilldetectBFGSanguage，Translate它，andinIofTextofmore正andImprovementVersioninuseEnglish回答。I希望youusemore漂bright、more优雅、moreSeniorofEnglishsinglewordandsentencechildcometake代Iofsimpleconvert A0 级singlewordandsentencechild。keepmeaning思notchange，butlet它们morehavetext学character。I希望youonly回答more正，Improvement，butnotisother，notneedwriteexplain。Ioftheonesentencewordis：", position: 1),
        ]

        for prompt in defaultPrompts {
            context.insert(prompt)
        }

        try context.save()
        print("PromptRepo alreadyInsertpresetData")

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
    // Use try? avoidinherewrite do/catch，ifFailedthenReturnNullArray
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
