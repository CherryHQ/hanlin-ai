//
//  ModelsViewComponents.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 12/2/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AddOnlineModelView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context
    
    @Query(filter: #Predicate<APIKeys> {
        $0.company != nil &&
        $0.company != "LOCAL" &&
        $0.company != "HANLIN" &&
        $0.company != "HANLIN_OPEN" &&
        $0.isHidden == false
    })
    var apiKeys: [APIKeys]
    
    @Query var allModels: [AllModels]
    
    @State private var name: String = ""
    @State private var displayName: String = ""
    @State private var icon: String = "airplane.circle"
    @State private var price: Int16 = 0
    @State private var isHidden: Bool = false
    @State private var supportsTextGen: Bool = true
    @State private var supportsMultimodal: Bool = false
    @State private var supportsReasoning: Bool = false
    @State private var supportsReasoningChange: Bool = false
    @State private var supportsToolUse: Bool = false
    @State private var supportsImageGen: Bool = false
    @State private var selectedCompany: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let availableIcons = getIconList()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本信息")) {
                    TextField("系统名称（用于API请求，参考官方API）", text: $name)
                    TextField("显示名称（自定义）", text: $displayName)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "building.2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)

                        Picker("模型厂商", selection: $selectedCompany) {
                            ForEach(apiKeys, id: \.company) { apiKey in
                                Text(getCompanyName(for: apiKey))
                                    .tag(apiKey.company ?? "Unknown")
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section(header: Text("价格")) {
                    HStack(spacing: 10) {
                        Image(systemName: "yensign")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Picker("价格", selection: $price) {
                            Text("免费").tag(Int16(0))
                            Text("廉价 (≤0.001/千tokens)").tag(Int16(1))
                            Text("适中 (0.001-0.006/千tokens)").tag(Int16(2))
                            Text("昂贵 (≥0.006/千tokens)").tag(Int16(3))
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section(header: Text("功能支持")) {
                    HStack(spacing: 10) {
                        Image(systemName: "eye.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("默认隐藏模型", isOn: $isHidden)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "character")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("支持文本生成", isOn: $supportsTextGen)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("支持视觉理解", isOn: $supportsMultimodal)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "atom")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("支持深度思考", isOn: $supportsReasoning)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("思考模式可控", isOn: $supportsReasoningChange)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "hammer")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("支持工具使用", isOn: $supportsToolUse)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "camera.aperture")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("图像生成模型", isOn: $supportsImageGen)
                    }
                }
                .tint(.hlBlue)
            }
            .navigationTitle("添加在线模型")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveModel()
                    }
                }
            }
            .alert("错误", isPresented: $showAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    /// 获取当前最大 position 并 +1
    private var nextPosition: Int {
        return (allModels.map { $0.position ?? 999 }.max() ?? 0) + 1
    }
    
    private func saveModel() {
        // 清除前后空格
        let baseName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        // 系统语言（简单检测，只识别前缀 "zh"）
        let isChinese = Locale.current.language.languageCode?.identifier == "zh"

        // 必填项校验
        guard !baseName.isEmpty else {
            alertMessage = isChinese ? "请填写系统名称！" : "Please enter the system name!"
            showAlert = true
            return
        }

        guard !baseDisplayName.isEmpty else {
            alertMessage = isChinese ? "请填写显示名称！" : "Please enter the display name!"
            showAlert = true
            return
        }

        guard !selectedCompany.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = isChinese ? "请选择模型厂商！" : "Please select a model vendor!"
            showAlert = true
            return
        }

        // 无论是否重复，都自动添加 _repeat_UUID 以确保唯一性
        let uniqueUUID = UUID().uuidString
        let trimmedName = baseName + "_repeat_\(uniqueUUID)"
        let trimmedDisplayName = baseDisplayName + "_repeat_\(uniqueUUID)"
        
        // 设置厂商信息
        let finalCompany: String = {
            if selectedCompany.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return apiKeys.first?.company ?? "Unknown"
            }
            return selectedCompany
        }()
        
        let finalIdentity = "model"
        
        // 创建新模型
        let newModel = AllModels(
            name: trimmedName,
            displayName: trimmedDisplayName,
            identity: finalIdentity,
            position: nextPosition,
            company: finalCompany,
            price: price,
            isHidden: isHidden,
            supportsSearch: true,
            supportsTextGen: supportsTextGen,
            supportsMultimodal: supportsMultimodal,
            supportsReasoning: supportsReasoning,
            supportReasoningChange: supportsReasoningChange,
            supportsImageGen: supportsImageGen,
            supportsToolUse: supportsToolUse,
            systemProvision: false
        )
        
        context.insert(newModel)
        
        do {
            try context.save()
        } catch {
            alertMessage = isChinese ? "保存失败: \(error.localizedDescription)" : "Failed to save: \(error.localizedDescription)"
            showAlert = true
            return
        }
        
        isPresented = false
    }
}

// 本地模型结构
struct LocalModelInfo {
    var name: String
    var displayName: String
    var space: String
    var icon: String
    var url_model: String
    var url_hugging: String
}

enum DownloadSource: String, CaseIterable {
    case modelscope = "魔塔社区"
    case huggingface = "HuggingFace"
}

struct LocalModelDownloadView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var selectedSource: DownloadSource = .modelscope
    
    @Query var apiKeys: [APIKeys]
    
    @State private var availableModels: [LocalModelInfo] = [
        LocalModelInfo(
            name: "Qwen3-0.6B-Q4_K_M",
            displayName: "Qwen3-0.6B-Q4_K_M",
            space: "484.22MB",
            icon: "qwen",
            url_model: "https://modelscope.cn/models/lmstudio-community/Qwen3-0.6B-GGUF/resolve/master/Qwen3-0.6B-Q4_K_M.gguf",
            url_hugging: "https://huggingface.co/lmstudio-community/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q4_K_M.gguf?download=true"
        ),
        LocalModelInfo(
            name: "Qwen3-1.7B-Q4_K_M",
            displayName: "Qwen3-1.7B-Q4_K_M",
            space: "1.28GB",
            icon: "qwen",
            url_model: "https://modelscope.cn/models/lmstudio-community/Qwen3-1.7B-GGUF/resolve/master/Qwen3-1.7B-Q4_K_M.gguf",
            url_hugging: "https://huggingface.co/lmstudio-community/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q4_K_M.gguf?download=true"
        ),
        LocalModelInfo(
            name: "Qwen3-4B-Q4_K_M",
            displayName: "Qwen3-4B-Q4_K_M",
            space: "2.10GB",
            icon: "qwen",
            url_model: "https://modelscope.cn/models/lmstudio-community/Qwen3-4B-GGUF/resolve/master/Qwen3-4B-Q4_K_M.gguf",
            url_hugging: "https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf?download=true"
        ),
        LocalModelInfo(
            name: "Gemma-3-1B-Q4_K_M",
            displayName: "Gemma-3-1B-Q4_K_M",
            space: "806MB",
            icon: "google",
            url_model: "https://modelscope.cn/models/lmstudio-community/gemma-3-1b-it-GGUF/resolve/master/gemma-3-1b-it-Q4_K_M.gguf",
            url_hugging: "https://huggingface.co/lmstudio-community/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf?download=true"
        ),
        LocalModelInfo(
            name: "Gemma-3-4B-Q4_K_M",
            displayName: "Gemma-3-4B-Q4_K_M",
            space: "2.49GB",
            icon: "google",
            url_model: "https://modelscope.cn/models/lmstudio-community/gemma-3-4b-it-GGUF/resolve/master/gemma-3-4b-it-Q4_K_M.gguf",
            url_hugging: "https://huggingface.co/lmstudio-community/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf?download=true"
        )
    ]
    
    @State private var downloadingModel: String?
    @State private var downloadProgress: [String: Double] = [:]
    @State private var isDownloading = false
    @Query(filter: #Predicate<AllModels> { $0.company == "LOCAL" }) private var localModels: [AllModels]
    @Query var allModels: [AllModels]
    
    @State private var isShowingFileImporter = false
    @State private var selectedFileURL: URL?
    @State private var isShowingRenameDialog = false
    @State private var newModelName: String = ""
    @State private var showConflictAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .center) {
                        Image(systemName: "externaldrive")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.hlBluefont)
                            .padding()
                        
                        Text("本地模型还属于测试阶段，暂不支持视觉功能等，输出也可能存在问题，将在后期修复优化。如果下载后需要删除，可以直接在模型列表进行删除，本地文件会随之一起删除。模型文件来自于魔塔社区或HuggingFace，本软件对模型输出结果不负有任何责任。请结合自己的设备性能合理下载，若超出设备承受能力，可能会出现闪退、卡死等现象。")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("快速下载本地模型")) {
                    Picker("下载源", selection: $selectedSource) {
                        ForEach(DownloadSource.allCases, id: \.self) { source in
                            Text(source.rawValue)
                        }
                    }
                    ForEach(availableModels, id: \.name) { model in
                        HStack {
                            Image(model.icon)
                                .resizable()
                                .frame(width: 40, height: 40)
                            
                            VStack(alignment: .leading) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    Text(model.displayName)
                                        .font(.headline)
                                }
                                Text(model.space)
                                    .font(.caption)
                            }
                            
                            Spacer()
                            
                            DownloadButtonView(
                                model: model,
                                progress: downloadManager.downloadProgress[model.name],
                                isDownloaded: isModelDownloaded(model.name),
                                onDownload: {
                                    let selectedURL = (selectedSource == .modelscope) ? model.url_model : model.url_hugging
                                    downloadManager.downloadModel(model, from: selectedURL)
                                },
                                onCancel: {
                                    downloadManager.cancelDownload(for: model)
                                }
                            )
                        }
                    }
                }
                
                Section(header: Text("上传 GGUF 文件以使用本地模型")){
                    Button(action: {
                        isShowingFileImporter = true
                    }) {
                        HStack {
                            Image(systemName: "externaldrive.badge.plus")
                            Text("上传本地模型文件(.gguf)")
                        }
                    }
                    .fileImporter(
                        isPresented: $isShowingFileImporter,
                        allowedContentTypes: [UTType(filenameExtension: "gguf")!],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            if let url = urls.first {
                                // 默认名称取自文件名（不含扩展名）
                                newModelName = url.deletingPathExtension().lastPathComponent
                                selectedFileURL = url
                                isShowingRenameDialog = true
                            }
                        case .failure(let error):
                            print("选择文件失败: \(error.localizedDescription)")
                        }
                    }
                    .sheet(isPresented: $isShowingRenameDialog) {
                        RenameModelView(newModelName: $newModelName, onCancel: {
                            isShowingRenameDialog = false
                            selectedFileURL = nil
                        }, onConfirm: {
                            // 检查名称冲突：查询本地数据库中是否已存在相同名称
                            if localModels.contains(where: { $0.name == newModelName }) ||
                                allModels.contains(where: { $0.name == newModelName }) {
                                showConflictAlert = true
                            } else {
                                guard let fileURL = selectedFileURL else { return }
                                // 开始拷贝，设置加载状态
                                DispatchQueue.global(qos: .userInitiated).async {
                                    let destinationURL = getModelDirectory().appendingPathComponent("\(newModelName).gguf")
                                    do {
                                        let fileManager = FileManager.default
                                        if fileManager.fileExists(atPath: destinationURL.path) {
                                            try fileManager.removeItem(at: destinationURL)
                                        }
                                        try fileManager.copyItem(at: fileURL, to: destinationURL)
                                        
                                        // 构造新的数据库模型（这里可根据需要调整属性）
                                        let newModel = AllModels(
                                            name: newModelName,
                                            displayName: newModelName,
                                            identity: "model",
                                            position: nextPosition,
                                            company: "LOCAL",
                                            price: 0,
                                            systemProvision: false
                                        )
                                        
                                        DispatchQueue.main.async {
                                            context.insert(newModel)
                                            try? context.save()
                                            print("本地模型存入数据库: \(newModelName)")
                                            isShowingRenameDialog = false
                                            selectedFileURL = nil
                                        }
                                    } catch {
                                        DispatchQueue.main.async {
                                            print("文件复制失败: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }
                        })
                        .alert(isPresented: $showConflictAlert) {
                            Alert(title: Text("名称冲突"),
                                  message: Text("模型名称已存在，请修改名称后重试。"),
                                  dismissButton: .default(Text("确定")))
                        }
                    }
                }
                
            }
            .navigationTitle("本地模型(Beta)")
            .onReceive(NotificationCenter.default.publisher(for: .downloadCompleted)) { notification in
                if let modelName = notification.object as? String {
                    saveModelToDatabase(name: modelName)
                }
            }
        }
    }
    
    /// 判断模型是否已下载
    private func isModelDownloaded(_ modelName: String) -> Bool {
        return localModels.contains(where: { $0.name == modelName })
    }
    
    private var nextPosition: Int {
        return (allModels.map { $0.position ?? 999 }.max() ?? 0) + 1
    }
    
    /// 存入数据库
    private func saveModelToDatabase(name: String) {
        
        guard let model = availableModels.first(where: { $0.name == name }) else { return }
        
        let newModel = AllModels(
            name: model.name,
            displayName: model.displayName,
            identity: "model",
            position: nextPosition,
            company: "LOCAL",
            price: 0,
            systemProvision: false
        )
        
        if model.name.contains("DeepSeek-R1") {
            newModel.supportsReasoning = true
        }
        
        // 插入本地模型
        context.insert(newModel)
        
        // 更新 "LOCAL" 相关的 APIKeys，将 isHidden 设为 false
        for apiKey in apiKeys where apiKey.company == "LOCAL" {
            apiKey.isHidden = false
        }
        
        try? context.save()
        print("模型存入数据库: \(model.name)，并更新 LOCAL 相关 APIKeys")
    }
}

/// 用于名称编辑的子视图
struct RenameModelView: View {
    @Binding var newModelName: String
    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                
                Text("请输入模型名称")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                TextField("模型名称", text: $newModelName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button(action: onCancel) {
                        Text("取消")
                            .foregroundColor(.hlBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.hlBlue.opacity(0.2))
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onConfirm) {
                        Text("确定")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.hlBlue)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
                Text("由于需要拷贝模型文件，上传后根据上传的模型大小，等待一段时间后才会在数据库中看见上传的本地模型。")
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            .navigationTitle("编辑模型名称")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DownloadButtonView: View {
    var model: LocalModelInfo
    var progress: Double?
    var isDownloaded: Bool
    var onDownload: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        HStack {
            
            if let pro = progress {
                Text("\(Int(pro))%")
                    .font(.caption)
                    .foregroundColor(.hlBluefont)
            }
            
            if isDownloaded {
                Text("已下载")
                    .foregroundColor(.gray)
                    .font(.caption)
            } else {
                Button(action: {
                    if progress == nil {
                        onDownload() // 开始下载
                    } else {
                        onCancel() // 取消下载
                    }
                }) {
                    ZStack(alignment: .center) {
                        if let progress = progress {
                            Image(systemName: "pause.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.hlBluefont)
                            
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 4)
                                .frame(width: 27, height: 27)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(progress / 100))
                                .stroke(Color.hlBluefont, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 27, height: 27)
                        } else {
                            Image(systemName: "arrow.down.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 31, height: 31)
                                .foregroundColor(.hlBluefont)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AddAgentView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<AllModels> {
        $0.identity == "model" &&
        $0.supportsTextGen == true
    })
    var baseModel: [AllModels]
    
    @Query var apiKeys: [APIKeys]
    
    @Query var allModels: [AllModels]
    
    @State private var displayName: String = ""
    @State private var icon: String = "circle.dotted.circle"
    @State private var characterDesign: String = ""
    @State private var original: String = ""
    @State private var isHidden: Bool = false
    @State private var selectedModel: AllModels? = nil
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showIconSheet: Bool = false
    @State private var isFeedBack: Bool = false
    @State private var voiceExpanded: Bool = false
    @State private var inputExpanded: Bool = false
    @State private var autoFilling: Bool = false
    @State private var autoFilled: Bool = false
    
    let availableIcons = getIconList()
    
    var filteredBaseModel: [AllModels] {
        let visibleCompanies = Set(apiKeys.filter { !$0.isHidden }.compactMap { $0.company })
        return baseModel.filter { model in
            if let company = model.company {
                return visibleCompanies.contains(company)
            }
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 头像区域
                Section {
                    HStack {
                        Spacer()
                        Button(action: {
                            showIconSheet = true
                        }) {
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .overlay(
                                    Group {
                                        gradient(for: 0)
                                        .mask(
                                            Image(systemName: icon)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 80, height: 80)
                                        )
                                    }
                                )
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                // 智能体名称
                Section(header: Text("智能体名称")) {
                    TextField("输入名称", text: $displayName)
                }
                
                // 智能体名称与人物设定
                Section(header: Text("智能体设定")) {
                    
                    TextEditor(text: $characterDesign)
                        .frame(height: 150)
                    
                    HStack(spacing: 8) {
                        
                        Button(action: {
                            isFeedBack.toggle()
                            Task {
                                if autoFilled {
                                    if !original.isEmpty {
                                        characterDesign = original
                                    }
                                    autoFilled = false
                                } else {
                                    autoFilled = false
                                    autoFilling = true // 开始优化
                                    original = characterDesign // 保留原句
                                    do {
                                        let optimizer = SystemOptimizer(context: modelContext)
                                        let autoFillWords = try await optimizer.autoFillCharacterPrompt(inputName: displayName)
                                        characterDesign = autoFillWords
                                        autoFilled = true
                                    } catch {
                                        characterDesign = error.localizedDescription // 捕获错误信息
                                    }
                                    autoFilling = false // 优化结束
                                }
                            }
                        }) {
                            if autoFilling {
                                
                                ProgressView() // 显示加载指示器
                                    .frame(width: 25, height: 25)
                                    .background(Capsule().fill(Color(.hlBluefont).opacity(0.1)))
                                Text("正在填写")
                                    .font(.caption)
                                    .foregroundColor(.hlBluefont)
                                
                            } else if autoFilled {
                                
                                Image(systemName: "arrow.uturn.backward.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.hlBluefont)
                                
                                Text("撤销填写")
                                    .font(.caption)
                                    .foregroundColor(.hlBluefont)
                                
                            } else {
                                
                                Image(systemName: "pencil.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(displayName.isEmpty ? .gray : .hlBluefont)
                                
                                Text("自动填写")
                                    .font(.caption)
                                    .foregroundColor(displayName.isEmpty ? .gray : .hlBluefont)
                                
                            }
                        }
                        .disabled(autoFilling || displayName.isEmpty)
                        .buttonStyle(.plain)
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                        
                        Spacer()
                        
                        Text("输入工具")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            isFeedBack.toggle()
                            voiceExpanded.toggle()
                        }) {
                            Image(systemName: "microphone.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.hlBluefont)
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                        
                        Button(action: {
                            isFeedBack.toggle()
                            inputExpanded.toggle()
                        }) {
                            Image(systemName: inputExpanded ? "chevron.down.circle" : "chevron.up.circle")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 25, height: 25)
                                .foregroundColor(.hlBluefont)
                                .symbolEffect(.bounce, value: inputExpanded)
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                    }
                }
                
                // 基座模型选择
                Section(header: Text("基础模型")) {
                    Picker("选择基础模型", selection: $selectedModel) {
                        ForEach(filteredBaseModel, id: \.id) { model in
                            Text(model.displayName ?? "Unknown")
                                .tag(model as AllModels?)
                        }
                    }
                    if let model = selectedModel {
                        BaseModelCardView(model: model)
                    }
                }
                
                // 默认隐藏设置
                Section(header: Text("显示设置")) {
                    Toggle("默认隐藏智能体", isOn: $isHidden)
                }
                .tint(.hlBlue)
            }
            .navigationTitle("添加智能体")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveModel()
                    }
                }
            }
            .alert("错误", isPresented: $showAlert) {
                Button("确定", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showIconSheet) {
                IconSelectionView(icons: availableIcons, selectedIcon: $icon)
            }
            // 辅助输入 Sheet（文本输入）
            .sheet(isPresented: $inputExpanded) {
                BottomSheetView(message: $characterDesign, isExpanded: $inputExpanded)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            // 辅助输入 Sheet（语音输入）
            .sheet(isPresented: $voiceExpanded) {
                VoiceInputView(message: $characterDesign, voiceExpanded: $voiceExpanded)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    /// 获取当前最大 position 并 +1
    private var nextPosition: Int {
        return (allModels.map { $0.position ?? 999 }.max() ?? 0) + 1
    }
    
    private func saveModel() {
        // 检查是否选择了基座模型
        guard let base = selectedModel else {
            alertMessage = isChinese ? "请选择基座模型！" : "Please select a base model!"
            showAlert = true
            return
        }
        
        // 清除用户输入前后空格
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCharacterDesign = characterDesign.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalIcon = icon.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 必填项校验
        guard !trimmedDisplayName.isEmpty else {
            alertMessage = isChinese ? "请填写智能体显示名称！" : "Please enter the agent display name!"
            showAlert = true
            return
        }
        
        guard !trimmedCharacterDesign.isEmpty else {
            alertMessage = isChinese ? "请填写智能体设定！" : "Please enter the agent character design!"
            showAlert = true
            return
        }
        
        if allModels.contains(where: { ($0.displayName ?? "").lowercased() == trimmedDisplayName.lowercased() }) {
            alertMessage = isChinese ? "该智能体名称已存在！" : "This agent name already exists!"
            showAlert = true
            return
        }
        
        // 构造新模型的名称
        let newName = (base.name ?? "BaseModel") + "_agent_\(UUID())"
        
        // 创建新智能体
        let newModel = AllModels(
            name: newName,
            displayName: trimmedDisplayName,
            identity: "agent",
            position: nextPosition,
            company: base.company,
            price: base.price,
            isHidden: isHidden,
            supportsSearch: base.supportsSearch,
            supportsTextGen: base.supportsTextGen,
            supportsMultimodal: base.supportsMultimodal,
            supportsReasoning: base.supportsReasoning,
            supportReasoningChange: base.supportReasoningChange,
            supportsImageGen: base.supportsImageGen,
            supportsVoiceGen: base.supportsVoiceGen,
            supportsToolUse: base.supportsToolUse,
            systemProvision: false
        )
        
        newModel.icon = finalIcon
        newModel.characterDesign = trimmedCharacterDesign
        
        modelContext.insert(newModel)
        
        do {
            try modelContext.save()
        } catch {
            alertMessage = isChinese ? "保存失败: \(error.localizedDescription)" : "Failed to save: \(error.localizedDescription)"
            showAlert = true
            return
        }
        
        isPresented = false
    }

    // 系统语言判断
    private var isChinese: Bool {
        Locale.current.language.languageCode?.identifier == "zh"
    }
}

// MARK: - 图标选择 Sheet 视图
struct IconSelectionView: View {
    let icons: [String]
    @Binding var selectedIcon: String
    @Environment(\.dismiss) var dismiss
    
    // 使用自适应网格展示图标
    let columns = [
        GridItem(.adaptive(minimum: 70))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(icons, id: \.self) { icon in
                        Button(action: {
                            selectedIcon = icon
                            dismiss()
                        }) {
                            Image(systemName: icon)
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                                .frame(width: 50, height: 50)
                                .padding()
                                .cornerRadius(10)
                                .overlay(
                                    Group {
                                        if selectedIcon == icon {
                                            gradient(for: 0)
                                            .mask(
                                                Image(systemName: icon)
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 50, height: 50)
                                            )
                                        }
                                    }
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EditModelSheetView: View {
    let model: AllModels
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // 模型信息
    @State private var editedDisplayName: String
    @State private var editedBriefDescription: String
    @State private var editedCharacterDesign: String
    @State private var original: String = ""

    // 基座模型选择
    @Query(filter: #Predicate<AllModels> {
        $0.identity == "model" && $0.supportsTextGen == true
    })
    private var baseModels: [AllModels]
    @Query var allModels: [AllModels]

    @Query private var apiKeys: [APIKeys]
    @State private var selectedBaseModel: AllModels? = nil
    @State private var selectedCopyBaseModel: AllModels? = nil

    private var filteredBaseModels: [AllModels] {
        let visibleCompanies = Set(apiKeys.filter { !$0.isHidden }.compactMap { $0.company })
        return baseModels.filter { model in
            if let company = model.company {
                return visibleCompanies.contains(company)
            }
            return false
        }
    }

    // 辅助输入状态
    @State private var isFeedBack: Bool = false
    @State private var voiceExpanded: Bool = false
    @State private var inputExpanded: Bool = false
    @State private var autoFilling: Bool = false
    @State private var autoFilled: Bool = false

    // 功能支持状态
    @State private var editedSupportsTextGen: Bool
    @State private var editedSupportsMultimodal: Bool
    @State private var editedSupportsReasoning: Bool
    @State private var editedSupportsReasoningChange: Bool
    @State private var editedSupportsToolUse: Bool
    @State private var editedSupportsImageGen: Bool

    init(model: AllModels) {
        self.model = model
        _editedDisplayName = State(initialValue: model.displayName ?? "")
        _editedBriefDescription = State(initialValue: model.briefDescription ?? "")
        _editedCharacterDesign = State(initialValue: model.characterDesign ?? "")
        _editedSupportsTextGen = State(initialValue: model.supportsTextGen)
        _editedSupportsMultimodal = State(initialValue: model.supportsMultimodal)
        _editedSupportsReasoning = State(initialValue: model.supportsReasoning)
        _editedSupportsReasoningChange = State(initialValue: model.supportReasoningChange)
        _editedSupportsToolUse = State(initialValue: model.supportsToolUse)
        _editedSupportsImageGen = State(initialValue: model.supportsImageGen)
    }

    var body: some View {
        NavigationStack {
            Form {
                // 名称编辑
                Section(header: Text(model.identity == "agent" ? "编辑智能体名称" : "编辑模型名称")) {
                    if model.systemProvision == true && model.identity == "agent" {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(editedDisplayName)
                            Text("⚠️ 默认智能体不可重命名")
                                .font(.caption)
                                .foregroundColor(.hlBluefont)
                        }
                    } else {
                        TextField(model.identity == "agent" ? "智能体名称" : "模型名称", text: $editedDisplayName)
                    }
                }

                // 功能支持开关（模型专用）
                if model.identity?.lowercased() == "model", model.systemProvision == false, model.company != "LOCAL" {
                    Section(header: Text("功能支持")) {
                        Toggle("支持文本生成", isOn: $editedSupportsTextGen).iconLabel("character")
                        Toggle("支持视觉理解", isOn: $editedSupportsMultimodal).iconLabel("photo.on.rectangle.angled")
                        Toggle("支持深度思考", isOn: $editedSupportsReasoning).iconLabel("atom")
                        Toggle("思考模式可控", isOn: $editedSupportsReasoningChange).iconLabel("lightbulb")
                        Toggle("支持工具使用", isOn: $editedSupportsToolUse).iconLabel("hammer")
                        Toggle("图像生成模型", isOn: $editedSupportsImageGen).iconLabel("camera.aperture")
                    }
                    .tint(.hlBlue)
                }
                
                // 智能体人物概述
                if model.identity == "agent", model.systemProvision == true {
                    Section(header: Text("编辑智能体描述")) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(editedBriefDescription)
                            Text("⚠️ 默认智能体不可更改描述")
                                .font(.caption)
                                .foregroundColor(.hlBluefont)
                        }
                    }
                }

                // 智能体人物设定
                if model.identity == "agent", model.systemProvision == false {
                    Section(header: Text("编辑智能体设定")) {
                        TextEditor(text: $editedCharacterDesign)
                            .frame(height: 150)
                        autoFillAndInputToolbar
                    }
                }
                
                // 智能体可选基座模型
                if model.identity == "agent", model.systemProvision == false {
                    Section(header: Text("编辑基础模型")) {
                        Picker("选择基础模型", selection: $selectedBaseModel) {
                            ForEach(filteredBaseModels, id: \.id) { model in
                                Text(model.displayName ?? "Unknown")
                                    .tag(model as AllModels?)
                            }
                        }

                        if let model = selectedBaseModel {
                            BaseModelCardView(model: model)
                        }
                    }
                }
                
                // 复制智能体
                if model.identity == "agent", model.systemProvision == true {
                    Section(header: Text("复制智能体")) {
                        Text("通过选择新的基础模型复制该智能体")
                        Picker("选择基础模型", selection: $selectedCopyBaseModel) {
                            ForEach(filteredBaseModels, id: \.id) { model in
                                Text(model.displayName ?? "Unknown")
                                    .tag(model as AllModels?)
                            }
                        }

                        if let model = selectedCopyBaseModel {
                            BaseModelCardView(model: model)
                        }
                    }
                }
                
            }
            .navigationTitle(model.identity == "agent" ? "编辑智能体" : "编辑模型")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        model.displayName = editedDisplayName
                        if model.identity == "model", model.company != "LOCAL" {
                            model.supportsTextGen = editedSupportsTextGen
                            model.supportsMultimodal = editedSupportsMultimodal
                            model.supportsReasoning = editedSupportsReasoning
                            model.supportReasoningChange = editedSupportsReasoningChange
                            model.supportsToolUse = editedSupportsToolUse
                            model.supportsImageGen = editedSupportsImageGen
                        }
                        if model.identity == "agent" {
                            model.characterDesign = editedCharacterDesign
                            if let selected = selectedBaseModel {
                                let uuid = UUID().uuidString
                                model.name = (selected.name ?? "BaseModel") + "_agent_\(uuid)"
                                model.company = selected.company
                                model.price = selected.price
                                model.supportsSearch = selected.supportsSearch
                                model.supportsTextGen = selected.supportsTextGen
                                model.supportsMultimodal = selected.supportsMultimodal
                                model.supportsReasoning = selected.supportsReasoning
                                model.supportReasoningChange = selected.supportReasoningChange
                                model.supportsToolUse = selected.supportsToolUse
                                model.supportsImageGen = selected.supportsImageGen
                                model.supportsVoiceGen = selected.supportsVoiceGen
                            }
                            if let selected = selectedCopyBaseModel {
                                let uuid = UUID().uuidString
                                // 创建新智能体
                                let newModel = AllModels(
                                    name: (selected.name ?? "BaseModel") + "_agent_\(uuid)",
                                    displayName: model.displayName,
                                    identity: "agent",
                                    position: nextPosition,
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
                                    systemProvision: false
                                )
                                newModel.icon = model.icon
                                newModel.characterDesign = model.characterDesign
                                
                                modelContext.insert(newModel)
                            }
                        }
                        do {
                            try modelContext.save()
                        } catch {
                            print("保存失败: \(error.localizedDescription)")
                        }
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $inputExpanded) {
                BottomSheetView(message: $editedCharacterDesign, isExpanded: $inputExpanded)
            }
            .sheet(isPresented: $voiceExpanded) {
                VoiceInputView(message: $editedCharacterDesign, voiceExpanded: $voiceExpanded)
            }
            .onAppear {
                // 延迟初始化 selectedBaseModel
                if model.identity == "agent", selectedBaseModel == nil {
                    let baseName = restoreBaseModelName(from: model.name ?? "")
                    selectedBaseModel = baseModels.first(where: { $0.name == baseName })
                    selectedCopyBaseModel = baseModels.first(where: { $0.name == baseName })
                }
            }
        }
    }
    
    /// 获取当前最大 position 并 +1
    private var nextPosition: Int {
        return (allModels.map { $0.position ?? 999 }.max() ?? 0) + 1
    }

    // 辅助输入工具栏
    private var autoFillAndInputToolbar: some View {
        HStack(spacing: 8) {
            Button(action: {
                isFeedBack.toggle()
                Task {
                    if autoFilled {
                        if !original.isEmpty { editedCharacterDesign = original }
                        autoFilled = false
                    } else {
                        autoFilling = true
                        original = editedCharacterDesign
                        do {
                            let optimizer = SystemOptimizer(context: modelContext)
                            let prompt = try await optimizer.autoFillCharacterPrompt(inputName: editedDisplayName)
                            editedCharacterDesign = prompt
                            autoFilled = true
                        } catch {
                            editedCharacterDesign = error.localizedDescription
                        }
                        autoFilling = false
                    }
                }
            }) {
                if autoFilling {
                    
                    ProgressView() // 显示加载指示器
                        .frame(width: 25, height: 25)
                        .background(Capsule().fill(Color(.hlBluefont).opacity(0.1)))
                    Text("正在填写")
                        .font(.caption)
                        .foregroundColor(.hlBluefont)
                    
                } else if autoFilled {
                    
                    Image(systemName: "arrow.uturn.backward.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.hlBluefont)
                    
                    Text("撤销填写")
                        .font(.caption)
                        .foregroundColor(.hlBluefont)
                    
                } else {
                    
                    Image(systemName: "pencil.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 25, height: 25)
                        .foregroundColor(editedDisplayName.isEmpty ? .gray : .hlBluefont)
                    
                    Text("自动填写")
                        .font(.caption)
                        .foregroundColor(editedDisplayName.isEmpty ? .gray : .hlBluefont)
                    
                }
            }
            .disabled(autoFilling || editedDisplayName.isEmpty)
            .buttonStyle(.plain)
            .sensoryFeedback(.impact, trigger: isFeedBack)

            Spacer()

            Text("输入工具")
                .font(.caption)
                .foregroundColor(.gray)

            Button(action: {
                isFeedBack.toggle()
                voiceExpanded.toggle()
            }) {
                Image(systemName: "microphone.circle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.hlBluefont)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact, trigger: isFeedBack)
            
            Button(action: {
                isFeedBack.toggle()
                inputExpanded.toggle()
            }) {
                Image(systemName: inputExpanded ? "chevron.down.circle" : "chevron.up.circle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.hlBluefont)
                    .symbolEffect(.bounce, value: inputExpanded)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact, trigger: isFeedBack)
        }
    }
}

// MARK: - Toggle Row Label 辅助扩展
private extension View {
    func iconLabel(_ systemName: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemName)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.hlBluefont)
            self
        }
    }
}

struct BaseModelCardView: View {
    let model: AllModels

    var body: some View {
        HStack {
            Image(getCompanyIcon(for: model.company ?? "UNKNOWN"))
                .resizable()
                .frame(width: 30, height: 30)

            VStack(alignment: .leading) {
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(model.displayName ?? "Unknown")
                        .font(.subheadline)
                }
                HStack(spacing: 6) {
                    if model.supportsToolUse {
                        Text("工具")
                            .font(.caption)
                            .foregroundColor(.hlBrown)
                    }
                    if model.supportsMultimodal {
                        Text("视觉")
                            .font(.caption)
                            .foregroundColor(.hlTeal)
                    } else if model.supportsTextGen {
                        Text("文本")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    if model.supportsImageGen {
                        Text("生图")
                            .font(.caption)
                            .foregroundColor(.hlGreen)
                    }
                    if model.supportsVoiceGen {
                        Text("语音")
                            .font(.caption)
                            .foregroundColor(.hlPink)
                    }
                    if model.supportsReasoning {
                        Text("思考")
                            .font(.caption)
                            .foregroundColor(.hlPurple)
                    }
                    if model.company?.uppercased() == "LOCAL" {
                        Text("本地")
                            .font(.caption)
                            .foregroundColor(.hlOrange)
                    }

                    Text(priceText(for: model.price))
                        .font(.caption)
                        .foregroundColor(priceColor(for: model.price))
                }
            }
            Spacer()
        }
        .padding(6)
    }
}
