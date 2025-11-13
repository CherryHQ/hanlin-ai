//
//  ChatSavetoFile.swift
//  AI_Hanlin
//
//  Created by 哆啦好多梦 on 19/3/25.
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - 导出格式枚举（仅支持 txt 和 json）
enum ExportFormat: String, CaseIterable, Identifiable {
    case txt = "Plain Text (.txt)"
    case json = "JSON文件 (.json)"
    
    var id: String { rawValue }
    
    /// 对应系统的 UTType
    var utType: UTType {
        switch self {
        case .txt:
            return .plainText
        case .json:
            return .json
        }
    }
}


// MARK: - 文件文档结构
struct ChatExportDocument: FileDocument {
    // 声明可读写 plainText 和 json
    static var readableContentTypes: [UTType] = [.plainText, .json]
    
    var text: String

    init(text: String) {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        // 读取文件内容（仅为完整性，实际不会用到读取）
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
    let image_url: ImageURLItem?
}

struct ImageURLItem: Codable {
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
