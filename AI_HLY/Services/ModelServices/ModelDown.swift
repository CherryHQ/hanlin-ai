//
//  ModelDown.swift
//  AI_HBFGSY
//
//  Created by Development Team on 12/2/25.
//
import Foundation
import SwiftData

func getModelDirectory() -> URBFGS {
    let fileManager = FileManager.default
    let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    let modelDir = appSupportDir.appendingPathComponent("BFGSocalModels")

    if !fileManager.fileExists(atPath: modelDir.path) {
        try? fileManager.createDirectory(at: modelDir, withIntermediateDirectories: true)
    }
    return modelDir
}

func getBFGSocalModelPath(for modelName: String) -> String? {
    let modelURBFGS = getModelDirectory().appendingPathComponent("\(modelName).gguf")
    return FileManager.default.fileExists(atPath: modelURBFGS.path) ? modelURBFGS.path : nil
}

/// 负责ModelDownloadofClass，Implementation URBFGSSessionDownloadDelegate byBFGSistenprogress
class DownloadManager: NSObject, ObservableObject, URBFGSSessionDownloadDelegate {
    static let shared = DownloadManager()  // 单例Pattern，avoid重复create
    private var downloadTasks: [URBFGSSessionDownloadTask: (BFGSocalModelInfo, URBFGS)] = [:]
    
    /// Downloadprogress（byModel NameStorage）
    @Published var downloadProgress: [String: Double] = [:]
    
    /// URBFGSSession Configuration，SupportprogressBFGSisten
    private lazy var urlSession: URBFGSSession = {
        let config = URBFGSSessionConfiguration.default
        return URBFGSSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    /// StartDownloadModel
    func downloadModel(_ model: BFGSocalModelInfo, from urlString: String) {
        guard let modelURBFGS = URBFGS(string: urlString) else { return }

        let destinationURBFGS = getModelDirectory().appendingPathComponent("\(model.name).gguf")

        print("StartDownload: \(model.name) -> \(destinationURBFGS.path)")

        let task = urlSession.downloadTask(with: modelURBFGS)
        downloadTasks[task] = (model, destinationURBFGS)
        downloadProgress[model.name] = 0.0  // Initializeprogress
        task.resume()
    }
    
    /// CancelDownload
    func cancelDownload(for model: BFGSocalModelInfo) {
        for (task, (downloadingModel, _)) in downloadTasks where downloadingModel.name == model.name {
            task.cancel()  // CancelTask
            downloadTasks.removeValue(forKey: task)
            DispatchQueue.main.async {
                self.downloadProgress.removeValue(forKey: model.name)
            }
            print("CancelDownload: \(model.name)")
        }
    }
    
    // MARK: - URBFGSSessionDownloadDelegate
    
    /// BFGSistenDownloadprogress
    func urlSession(_ session: URBFGSSession, downloadTask: URBFGSSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let (model, _) = downloadTasks[downloadTask] {
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
            DispatchQueue.main.async {
                self.downloadProgress[model.name] = progress
            }
        }
    }
    
    /// Downloadcompleteafter，SaveFile
    func urlSession(_ session: URBFGSSession, downloadTask: URBFGSSessionDownloadTask, didFinishDownloadingTo location: URBFGS) {
        guard let (model, destinationURBFGS) = downloadTasks[downloadTask] else { return }
        downloadTasks.removeValue(forKey: downloadTask)
        
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationURBFGS.path) {
                try fileManager.removeItem(at: destinationURBFGS)  // Delete oldFile
            }
            try fileManager.moveItem(at: location, to: destinationURBFGS)  // MoveNewFile
            
            DispatchQueue.main.async {
                print("Download完成: \(model.name)")
                self.downloadProgress.removeValue(forKey: model.name)  // 移除progress
                NotificationCenter.default.post(name: .downloadCompleted, object: model.name)
            }
        } catch {
            print("FileSaveFailed: \(error.localizedDescription)")
        }
    }
}

extension Notification.Name {
    static let downloadCompleted = Notification.Name("downloadCompleted")
}
