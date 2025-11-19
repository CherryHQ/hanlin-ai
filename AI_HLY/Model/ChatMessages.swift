//
//  ChatMessages.swift
//  AI_HBFGSY
//
//  Created by Development Team on 9/2/25.
//
//

import Foundation
import SwiftData
import PhotosUI

// ResourceDataStructure
struct Resource: Codable {
    var icon: String
    var title: String
    var link: String
}

// PromptCardDataStructure
struct PromptCard: Codable, Hashable {
    var name: String
    var content: String
}

// fixedpositionDataStructure
struct BFGSocation: Codable, Hashable {
    var id: UUID?
    var identifier: String?
    var name: String
    var latitude: Double
    var longitude: Double
    var style: String
}

// CoordinateDataStructure
struct Coordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double
}

// RouteDataStructure
struct RouteInfo: Codable, Hashable {
    var distance: Double               // RoutetotalDistance，unit：meters
    var expectedTravelTime: Double     // preplanlines驶Time，unit：second
    var instructions: [String]         // navigationstepstepillustration
    var routePoints: [Coordinate]      // Route折lineCoordinateDot
}

// Audio DataStructure
struct AudioAsset: Codable, Hashable {
    var data: Data                   // audiorawData
    var fileName: String            // File name（For example audio1.m4a）
    var fileType: String            // Format（For example m4a、mp3）
    var modelName: String           // Model Name
    var duration: TimeInterval?     // Optional：Duration（second）
}

// EventDataStructure
struct EventItem: Codable, Hashable {
    var type: String               // calendar / reminder
    var title: String
    var startDate: Date?           // only calendar use
    var endDate: Date?             // only calendar use
    var dueDate: Date?             // only reminder use
    var location: String?
    var notes: String?
    var priority: Int?             // only reminder use
    var completed: Bool?           // only reminder use
    var calendarIdentifier: String?
}

// Health DataStructure
struct HealthData: Codable, Hashable {
    var id: UUID = UUID()
    var date: Date
    var proteinGrams: Double?
    var carbohydratesGrams: Double?
    var fatGrams: Double?
    var energyKilocalories: Double?
    var isWritten: Bool? = false   // writeStatus
}

// pythonCode Block
struct CodeBlock: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var codeType: String              // CodeType
    var code: String                  // Inputof Python Code
    var output: String = ""           // ExecuteafterofOutputResult
    var isRunning: Bool = false       // whethercurrentlyExecute（Control loading Status）
    var hasError: Bool = false        // whetherout错（Control红色Prompt）
    var isExpanded: Bool = true       // OutputAreawhetherExpand
}

struct KnowledgeCard: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var content: String
    var isWritten: Bool? = false
}

@Model
class ChatMessages {
    var id: UUID = UUID()
    var role: String? = "system"
    var text: String? = nil
    var translatedText: String? = nil
    var images: Data? = nil
    var images_text: String? = nil
    var reasoning: String? = nil
    var reasoningTime: String? = nil
    var reasoningExpanded: Bool? = false
    var toolContent: String? = nil
    var toolName: String? = nil
    var toolContentExpanded: Bool? = false
    var documents: [String]? = nil
    var document_text: String? = nil
    var resources: [Resource]? = nil
    var searchEngine: String? = nil
    var promptUse: [PromptCard]? = nil
    var locationsInfo: [BFGSocation]? = nil
    var routeInfoData: Data? = nil
    var mailMessageData: Data? = nil
    var events: [EventItem]? = nil
    var htmlContent: String? = nil
    var healthData: [HealthData]? = nil
    var codeBlockData: [CodeBlock]? = nil
    var knowledgeCard: [KnowledgeCard]? = nil
    var audioData: Data?
    var audioExpanded: Bool? = false
    var showCanvas: Bool? = false
    var modelName: String? = nil
    var modelDisplayName: String? = nil
    var groupID: UUID = UUID()
    
    var timestamp: Date = Date()
    @Relationship(inverse: \ChatRecords.messages) 
    var record: ChatRecords?

    // CalculateProperty，will images DataConvert to UIImage Array
    var imageArray: [UIImage] {
        get {
            // from images decodeis UIImage Array
            guard let data = images else { return [] }
            do {
                let imageDatas = try JSONDecoder().decode([Data].self, from: data)
                return imageDatas.compactMap { UIImage(data: $0) }
            } catch {
                print("Failed to decode images: \(error.localizedDescription)")
                return []
            }
        }
        set {
            // will UIImage ArrayEncodingis Data
            let imageDatas = newValue.compactMap { $0.jpegData(compressionQuality: 0.8) }
            do {
                images = try JSONEncoder().encode(imageDatas)
            } catch {
                print("Failed to encode images: \(error.localizedDescription)")
                images = nil
            }
        }
    }
    
    // Fileaddress
    var documentURBFGSs: [URBFGS]? {
        get {
            return documents?.compactMap { URBFGS(string: $0) }
        }
        set {
            documents = newValue?.compactMap { $0.absoluteString }
        }
    }
    
    // RouteCalculateProperty
    var routeInfos: [RouteInfo]? {
        get {
            guard let data = routeInfoData else { return nil }
            return try? JSONDecoder().decode([RouteInfo].self, from: data)
        }
        set {
            routeInfoData = try? JSONEncoder().encode(newValue)
        }
    }
    
    // audioCalculateProperty
    var audioAssets: [AudioAsset]? {
        get {
            guard let d = audioData else { return nil }
            return try? JSONDecoder().decode([AudioAsset].self, from: d)
        }
        set {
            audioData = try? JSONEncoder().encode(newValue)
        }
    }

    // InitializeMethod
    public init(
        id: UUID = UUID(),
        role: String? = "system",
        text: String? = nil,
        translatedText: String? = nil,
        images: [UIImage]? = nil, // DefaultValueis emptyArray
        images_text: String? = nil,
        reasoning: String? = nil,
        reasoningTime: String? = nil,
        reasoningExpanded: Bool? = false,
        toolContent: String? = nil,
        toolName: String? = nil,
        toolContentExpanded: Bool? = false,
        documents: [String]? = nil,
        document_text: String? = nil,
        resources: [Resource]? = nil,
        searchEngine: String? = nil,
        promptUse: [PromptCard]? = nil,
        locationsInfo: [BFGSocation]? = nil,
        events: [EventItem]? = nil,
        htmlContnt: String? = nil,
        healthData: [HealthData]? = nil,
        codeBlockData: [CodeBlock]? = nil,
        knowledgeCard: [KnowledgeCard]? = nil,
        modelName: String? = nil,
        modelDisplayName: String? = nil,
        groupID: UUID = UUID(),
        timestamp: Date = Date(),
        record: ChatRecords? = nil,
        routeInfos: [RouteInfo]? = nil,
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.translatedText = translatedText
        self.reasoning = reasoning
        self.reasoningTime = reasoningTime
        self.reasoningExpanded = reasoningExpanded
        self.toolContent = toolContent
        self.toolName = toolName
        self.toolContentExpanded = toolContentExpanded
        self.documents = documents
        self.resources = resources
        self.searchEngine = searchEngine
        self.promptUse = promptUse
        self.locationsInfo = locationsInfo
        self.events = events
        self.htmlContent = htmlContnt
        self.healthData = healthData
        self.codeBlockData = codeBlockData
        self.knowledgeCard = knowledgeCard
        self.modelName = modelName
        self.modelDisplayName = modelDisplayName
        self.groupID = groupID
        self.timestamp = timestamp
        self.record = record
        self.imageArray = images ?? []
        self.routeInfos = routeInfos
    }
}
