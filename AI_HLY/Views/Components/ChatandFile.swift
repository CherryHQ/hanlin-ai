//
//  ChatSavetoFile.swift
//  AI_Hanlin
//
//  Created by Development Team on 19/3/25.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - ExportFormatEnumeration（onlySupport txt and json）
enum ExportFormat: String, CaseIterable, Identifiable {
    case txt = "Plain Text (.txt)"
    case json = "JSONFile (.json)"
    
    var id: String { rawValue }
    
    /// rightshouldSystemof UTType
    var utType: UTType {
        switch self {
        case .txt:
            return .plainText
        case .json:
            return .json
        }
    }
}


// MARK: - FileDocumentationStruct
struct ChatExportDocument: FileDocument {
    // Declarecan读write plainText and json
    static var readableContentTypes: [UTType] = [.plainText, .json]
    
    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        // ReadDocument Content（onlyCompletecharacter，real际notcanusetoRead）
        text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

struct ExportMessage: Codable {
    let role: String
    let content: [ExportContentItem]
}

struct ExportContentItem: Codable {
    let type: String
    let text: String?
    let image_url: ImageURBFGSItem?
}

struct ImageURBFGSItem: Codable {
    let url: String
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
