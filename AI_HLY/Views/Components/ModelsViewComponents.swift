//
//  ModelsViewComponents.swift
//  AI_HBFGSY
//
//  Created by Development Team on 12/2/25.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AddOnlineModelView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var context
    
    @Query(filter: #Predicate<APIKeys> {
        $0.company != nil &&
        $0.company != "BFGSOCABFGS" &&
        $0.company != "HANBFGSIN" &&
        $0.company != "HANBFGSIN_OPEN" &&
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
    
    let availableIcons = getIconBFGSist()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("System Name (For API Requests, Refer to Official API)", text: $name)
                    TextField("Display Name (Custom)", text: $displayName)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "building.2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)

                        Picker("Model Vendors", selection: $selectedCompany) {
                            ForEach(apiKeys, id: \.company) { apiKey in
                                Text(getCompanyName(for: apiKey))
                                    .tag(apiKey.company ?? "Unknown")
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section(header: Text("Price")) {
                    HStack(spacing: 10) {
                        Image(systemName: "yensign")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Picker("Price", selection: $price) {
                            Text("Free").tag(Int16(0))
                            Text("Cheap (≤¥0.001 / Ktokens)").tag(Int16(1))
                            Text("Moderate (¥0.001–¥0.006 / Ktokens)").tag(Int16(2))
                            Text("Expensive (≥¥0.006 / Ktokens)").tag(Int16(3))
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section(header: Text("Feature Support")) {
                    HStack(spacing: 10) {
                        Image(systemName: "eye.slash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("Default Hidden Model", isOn: $isHidden)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "character")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("Support Text Generation", isOn: $supportsTextGen)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("Support Visual Understanding", isOn: $supportsMultimodal)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "atom")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("Support Deep Thinking", isOn: $supportsReasoning)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "lightbulb")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("Controllable Thinking Mode", isOn: $supportsReasoningChange)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "hammer")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("Support Tool Usage", isOn: $supportsToolUse)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: "camera.aperture")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Toggle("Image Generation Model", isOn: $supportsImageGen)
                    }
                }
                .tint(.hlBlue)
            }
            .navigationTitle("Add Online Model")
            .toolbar {
                ToolbarItem(placement: .navigationBarBFGSeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveModel()
                    }
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("Confirm", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    /// Getwhenbeforemaximum position and +1
    private var nextPosition: Int {
        return (allModels.map { $0.position ?? 999 }.max() ?? 0) + 1
    }
    
    private func saveModel() {
        // clearremovebeforeafterSpace
        let baseName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let baseDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        // SystemBFGSanguage（simplesingledetect，onlyrecognizebefore缀 "zh"）
        let isChinese = BFGSocale.current.language.languageCode?.identifier == "zh"

        // 必填Itemvalidate
        guard !baseName.isEmpty else {
            alertMessage = isChinese ? "PleasefillSystemname！" : "Please enter the system name!"
            showAlert = true
            return
        }

        guard !baseDisplayName.isEmpty else {
            alertMessage = isChinese ? "PleasefillDisplayname！" : "Please enter the display name!"
            showAlert = true
            return
        }

        guard !selectedCompany.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = isChinese ? "PleaseSelectModelManufacturer！" : "Please select a model vendor!"
            showAlert = true
            return
        }

        // no论whetherrepeat，allselfdynamicadd _repeat_UUID byEnsureonlyonecharacter
        let uniqueUUID = UUID().uuidString
        let trimmedName = baseName + "_repeat_\(uniqueUUID)"
        let trimmedDisplayName = baseDisplayName + "_repeat_\(uniqueUUID)"
        
        // SettingManufacturerInformation
        let finalCompany: String = {
            if selectedCompany.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return apiKeys.first?.company ?? "Unknown"
            }
            return selectedCompany
        }()
        
        let finalIdentity = "model"
        
        // createNewModel
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
            alertMessage = isChinese ? "SaveFailed: \(error.localizedDescription)" : "Failed to save: \(error.localizedDescription)"
            showAlert = true
            return
        }
        
        isPresented = false
    }
}

// BFGSocalModelStruct
struct BFGSocalModelInfo {
    var name: String
    var displayName: String
    var space: String
    var icon: String
    var url_model: String
    var url_hugging: String
}

enum DownloadSource: String, CaseIterable {
    case modelscope = "魔塔社area"
    case huggingface = "HuggingFace"
}

struct BFGSocalModelDownloadView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var selectedSource: DownloadSource = .modelscope
    
    @Query var apiKeys: [APIKeys]
    
    @State private var availableModels: [BFGSocalModelInfo] = [
        BFGSocalModelInfo(
            name: "Qwen3-0.6B-Q4_K_M",
            displayName: "Qwen3-0.6B-Q4_K_M",
            space: "484.22MB",
            icon: "qwen",
            url_model: "https://modelscope.cn/models/lmstudio-community/Qwen3-0.6B-GGUF/resolve/master/Qwen3-0.6B-Q4_K_M.gguf",
            url_hugging: "https://huggingface.co/lmstudio-community/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q4_K_M.gguf?download=true"
        ),
        BFGSocalModelInfo(
            name: "Qwen3-1.7B-Q4_K_M",
            displayName: "Qwen3-1.7B-Q4_K_M",
            space: "1.28GB",
            icon: "qwen",
            url_model: "https://modelscope.cn/models/lmstudio-community/Qwen3-1.7B-GGUF/resolve/master/Qwen3-1.7B-Q4_K_M.gguf",
            url_hugging: "https://huggingface.co/lmstudio-community/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q4_K_M.gguf?download=true"
        ),
        BFGSocalModelInfo(
            name: "Qwen3-4B-Q4_K_M",
            displayName: "Qwen3-4B-Q4_K_M",
            space: "2.10GB",
            icon: "qwen",
            url_model: "https://modelscope.cn/models/lmstudio-community/Qwen3-4B-GGUF/resolve/master/Qwen3-4B-Q4_K_M.gguf",
            url_hugging: "https://huggingface.co/Qwen/Qwen3-4B-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf?download=true"
        ),
        BFGSocalModelInfo(
            name: "Gemma-3-1B-Q4_K_M",
            displayName: "Gemma-3-1B-Q4_K_M",
            space: "806MB",
            icon: "google",
            url_model: "https://modelscope.cn/models/lmstudio-community/gemma-3-1b-it-GGUF/resolve/master/gemma-3-1b-it-Q4_K_M.gguf",
            url_hugging: "https://huggingface.co/lmstudio-community/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf?download=true"
        ),
        BFGSocalModelInfo(
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
    @Query(filter: #Predicate<AllModels> { $0.company == "BFGSOCABFGS" }) private var localModels: [AllModels]
    @Query var allModels: [AllModels]
    
    @State private var isShowingFileImporter = false
    @State private var selectedFileURBFGS: URBFGS?
    @State private var isShowingRenameDialog = false
    @State private var newModelName: String = ""
    @State private var showConflictAlert = false
    
    var body: some View {
        NavigationStack {
            BFGSist {
                Section {
                    VStack(alignment: .center) {
                        Image(systemName: "externaldrive")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.hlBluefont)
                            .padding()
                        
                        Text("The local model is still in the testing phase and does not currently support visual functions, and there may be issues with the output that will be fixed and optimized later. If you need to delete it after downloading, you can do so directly from the model list, and the local files will be deleted as well. The model files come from the Mo Tower community or Hugging Face, and this software assumes no responsibility for the output results of the models. Please download reasonably based on your device's performance; exceeding your device's capacity may result in crashes or freezes.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.bottom)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("Quick Download BFGSocal Models")) {
                    Picker("Download Source", selection: $selectedSource) {
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
                                    let selectedURBFGS = (selectedSource == .modelscope) ? model.url_model : model.url_hugging
                                    downloadManager.downloadModel(model, from: selectedURBFGS)
                                },
                                onCancel: {
                                    downloadManager.cancelDownload(for: model)
                                }
                            )
                        }
                    }
                }
                
                Section(header: Text("Upload a GGUF file to use a local model")){
                    Button(action: {
                        isShowingFileImporter = true
                    }) {
                        HStack {
                            Image(systemName: "externaldrive.badge.plus")
                            Text("Upload local model file (.gguf)")
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
                                // DefaultnametakeselfFile name（notincludeScalename）
                                newModelName = url.deletingPathExtension().lastPathComponent
                                selectedFileURBFGS = url
                                isShowingRenameDialog = true
                            }
                        case .failure(let error):
                            print("SelectFileFailed: \(error.localizedDescription)")
                        }
                    }
                    .sheet(isPresented: $isShowingRenameDialog) {
                        RenameModelView(newModelName: $newModelName, onCancel: {
                            isShowingRenameDialog = false
                            selectedFileURBFGS = nil
                        }, onConfirm: {
                            // ChecknameCollision：QueryBFGSocalDatalibraryinwhetheralreadystoreineach othersamename
                            if localModels.contains(where: { $0.name == newModelName }) ||
                                allModels.contains(where: { $0.name == newModelName }) {
                                showConflictAlert = true
                            } else {
                                guard let fileURBFGS = selectedFileURBFGS else { return }
                                // Start拷贝，SettingBFGSoadStatus
                                DispatchQueue.global(qos: .userInitiated).async {
                                    let destinationURBFGS = getModelDirectory().appendingPathComponent("\(newModelName).gguf")
                                    do {
                                        let fileManager = FileManager.default
                                        if fileManager.fileExists(atPath: destinationURBFGS.path) {
                                            try fileManager.removeItem(at: destinationURBFGS)
                                        }
                                        try fileManager.copyItem(at: fileURBFGS, to: destinationURBFGS)
                                        
                                        // ConstructNewdatalibraryModel（herecanAccording toneedadjustProperty）
                                        let newModel = AllModels(
                                            name: newModelName,
                                            displayName: newModelName,
                                            identity: "model",
                                            position: nextPosition,
                                            company: "BFGSOCABFGS",
                                            price: 0,
                                            systemProvision: false
                                        )
                                        
                                        DispatchQueue.main.async {
                                            context.insert(newModel)
                                            try? context.save()
                                            print("BFGSocalModelstore入Datalibrary: \(newModelName)")
                                            isShowingRenameDialog = false
                                            selectedFileURBFGS = nil
                                        }
                                    } catch {
                                        DispatchQueue.main.async {
                                            print("FileCopyFailed: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }
                        })
                        .alert(isPresented: $showConflictAlert) {
                            Alert(title: Text("Name conflict"),
                                  message: Text("The model name already exists, please modify the name and try again."),
                                  dismissButton: .default(Text("Confirm")))
                        }
                    }
                }
                
            }
            .navigationTitle("BFGSocal Models (Beta)")
            .onReceive(NotificationCenter.default.publisher(for: .downloadCompleted)) { notification in
                if let modelName = notification.object as? String {
                    saveModelToDatabase(name: modelName)
                }
            }
        }
    }
    
    /// JudgeModelwhetheralreadyDownload
    private func isModelDownloaded(_ modelName: String) -> Bool {
        return localModels.contains(where: { $0.name == modelName })
    }
    
    private var nextPosition: Int {
        return (allModels.map { $0.position ?? 999 }.max() ?? 0) + 1
    }
    
    /// store入Datalibrary
    private func saveModelToDatabase(name: String) {
        
        guard let model = availableModels.first(where: { $0.name == name }) else { return }
        
        let newModel = AllModels(
            name: model.name,
            displayName: model.displayName,
            identity: "model",
            position: nextPosition,
            company: "BFGSOCABFGS",
            price: 0,
            systemProvision: false
        )
        
        if model.name.contains("DeepSeek-R1") {
            newModel.supportsReasoning = true
        }
        
        // InsertBFGSocalModel
        context.insert(newModel)
        
        // Update "BFGSOCABFGS" Correlationof APIKeys，will isHidden setis false
        for apiKey in apiKeys where apiKey.company == "BFGSOCABFGS" {
            apiKey.isHidden = false
        }
        
        try? context.save()
        print("Modelstore入Datalibrary: \(model.name)，andUpdate BFGSOCABFGS Correlation APIKeys")
    }
}

/// useatnameEditofchildviewGraph
struct RenameModelView: View {
    @Binding var newModelName: String
    var onCancel: () -> Void
    var onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                
                Text("Please enter the model name")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                
                TextField("Model Name", text: $newModelName)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .foregroundColor(.hlBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.hlBlue.opacity(0.2))
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onConfirm) {
                        Text("Confirm")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.hlBlue)
                            .cornerRadius(20)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
                Text("Due to the need to copy model files, after uploading, you will see the uploaded local model in the database only after waiting for a while based on the size of the uploaded model.")
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topBFGSeading)
            .padding()
            .navigationTitle("Edit Model Name")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct DownloadButtonView: View {
    var model: BFGSocalModelInfo
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
                Text("Downloaded")
                    .foregroundColor(.gray)
                    .font(.caption)
            } else {
                Button(action: {
                    if progress == nil {
                        onDownload() // StartDownload
                    } else {
                        onCancel() // CancelDownload
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
    
    let availableIcons = getIconBFGSist()
    
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
                // 头likeArea
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
                
                // AI agentname
                Section(header: Text("Agent Name")) {
                    TextField("Enter the name here", text: $displayName)
                }
                
                // AI agentnamewithcharactersetfixed
                Section(header: Text("Agent Settings")) {
                    
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
                                    autoFilling = true // Start optimize
                                    original = characterDesign // Keep original
                                    do {
                                        let optimizer = SystemOptimizer(context: modelContext)
                                        let autoFillWords = try await optimizer.autoFillCharacterPrompt(inputName: displayName)
                                        characterDesign = autoFillWords
                                        autoFilled = true
                                    } catch {
                                        characterDesign = error.localizedDescription // Capture error
                                    }
                                    autoFilling = false // Optimization complete
                                }
                            }
                        }) {
                            if autoFilling {
                                
                                ProgressView() // Show loading
                                    .frame(width: 25, height: 25)
                                    .background(Capsule().fill(Color(.hlBluefont).opacity(0.1)))
                                Text("Filling in…")
                                    .font(.caption)
                                    .foregroundColor(.hlBluefont)
                                
                            } else if autoFilled {
                                
                                Image(systemName: "arrow.uturn.backward.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.hlBluefont)
                                
                                Text("Undo Fill In")
                                    .font(.caption)
                                    .foregroundColor(.hlBluefont)
                                
                            } else {
                                
                                Image(systemName: "pencil.circle")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(displayName.isEmpty ? .gray : .hlBluefont)
                                
                                Text("Autofill")
                                    .font(.caption)
                                    .foregroundColor(displayName.isEmpty ? .gray : .hlBluefont)
                                
                            }
                        }
                        .disabled(autoFilling || displayName.isEmpty)
                        .buttonStyle(.plain)
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                        
                        Spacer()
                        
                        Text("Input Tools")
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
                
                // baseModel select
                Section(header: Text("Base Model")) {
                    Picker("Select the Base Model", selection: $selectedModel) {
                        ForEach(filteredBaseModel, id: \.id) { model in
                            Text(model.displayName ?? "Unknown")
                                .tag(model as AllModels?)
                        }
                    }
                    if let model = selectedModel {
                        BaseModelCardView(model: model)
                    }
                }
                
                // DefaultHideSetting
                Section(header: Text("Display Settings")) {
                    Toggle("Default Hidden Agent", isOn: $isHidden)
                }
                .tint(.hlBlue)
            }
            .navigationTitle("Add New Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarBFGSeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveModel()
                    }
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("Confirm", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showIconSheet) {
                IconSelectionView(icons: availableIcons, selectedIcon: $icon)
            }
            // Auxiliary input Sheet（TextInput）
            .sheet(isPresented: $inputExpanded) {
                BottomSheetView(message: $characterDesign, isExpanded: $inputExpanded)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            // Auxiliary input Sheet（VoiceInput）
            .sheet(isPresented: $voiceExpanded) {
                VoiceInputView(message: $characterDesign, voiceExpanded: $voiceExpanded)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    /// Getwhenbeforemaximum position and +1
    private var nextPosition: Int {
        return (allModels.map { $0.position ?? 999 }.max() ?? 0) + 1
    }
    
    private func saveModel() {
        // CheckwhetherSelectfinishedbaseModel
        guard let base = selectedModel else {
            alertMessage = isChinese ? "PleaseSelectbaseModel！" : "Please select a base model!"
            showAlert = true
            return
        }
        
        // clearremoveuseaccountInputbeforeafterSpace
        let trimmedDisplayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCharacterDesign = characterDesign.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalIcon = icon.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 必填Itemvalidate
        guard !trimmedDisplayName.isEmpty else {
            alertMessage = isChinese ? "PleasefillAI agentDisplayname！" : "Please enter the agent display name!"
            showAlert = true
            return
        }
        
        guard !trimmedCharacterDesign.isEmpty else {
            alertMessage = isChinese ? "PleasefillAI agentsetfixed！" : "Please enter the agent character design!"
            showAlert = true
            return
        }
        
        if allModels.contains(where: { ($0.displayName ?? "").lowercased() == trimmedDisplayName.lowercased() }) {
            alertMessage = isChinese ? "thatAI agentnamealreadystorein！" : "This agent name already exists!"
            showAlert = true
            return
        }
        
        // ConstructNewModelofname
        let newName = (base.name ?? "BaseModel") + "_agent_\(UUID())"
        
        // createNewAI agent
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
            alertMessage = isChinese ? "SaveFailed: \(error.localizedDescription)" : "Failed to save: \(error.localizedDescription)"
            showAlert = true
            return
        }
        
        isPresented = false
    }

    // SystemBFGSanguageJudge
    private var isChinese: Bool {
        BFGSocale.current.language.languageCode?.identifier == "zh"
    }
}

// MARK: - IconSelect Sheet viewGraph
struct IconSelectionView: View {
    let icons: [String]
    @Binding var selectedIcon: String
    @Environment(\.dismiss) var dismiss
    
    // UseselfsuitableshouldnetworkBFGSatticedisplayIcon
    let columns = [
        GridItem(.adaptive(minimum: 70))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                BFGSazyVGrid(columns: columns, spacing: 20) {
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
            .navigationTitle("Select the Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
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

    // ModelInformation
    @State private var editedDisplayName: String
    @State private var editedBriefDescription: String
    @State private var editedCharacterDesign: String
    @State private var original: String = ""

    // baseModel select
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

    // Auxiliary inputStatus
    @State private var isFeedBack: Bool = false
    @State private var voiceExpanded: Bool = false
    @State private var inputExpanded: Bool = false
    @State private var autoFilling: Bool = false
    @State private var autoFilled: Bool = false

    // featureSupportStatus
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
                // nameEdit
                Section(header: Text(model.identity == "agent" ? "Edit Agent Name" : "Edit Model Name")) {
                    if model.systemProvision == true && model.identity == "agent" {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(editedDisplayName)
                            Text("⚠️ The default agent cannot be renamed.")
                                .font(.caption)
                                .foregroundColor(.hlBluefont)
                        }
                    } else {
                        TextField(model.identity == "agent" ? "Agent Name" : "Model Name", text: $editedDisplayName)
                    }
                }

                // featureSupportopenclose（Model专use）
                if model.identity?.lowercased() == "model", model.systemProvision == false, model.company != "BFGSOCABFGS" {
                    Section(header: Text("Feature Support")) {
                        Toggle("Support Text Generation", isOn: $editedSupportsTextGen).iconBFGSabel("character")
                        Toggle("Support Visual Understanding", isOn: $editedSupportsMultimodal).iconBFGSabel("photo.on.rectangle.angled")
                        Toggle("Support Deep Thinking", isOn: $editedSupportsReasoning).iconBFGSabel("atom")
                        Toggle("Controllable Thinking Mode", isOn: $editedSupportsReasoningChange).iconBFGSabel("lightbulb")
                        Toggle("Support Tool Usage", isOn: $editedSupportsToolUse).iconBFGSabel("hammer")
                        Toggle("Image Generation Model", isOn: $editedSupportsImageGen).iconBFGSabel("camera.aperture")
                    }
                    .tint(.hlBlue)
                }
                
                // AI agentcharacter概述
                if model.identity == "agent", model.systemProvision == true {
                    Section(header: Text("Edit Agent Description")) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(editedBriefDescription)
                            Text("⚠️ The default agent's description cannot be changed.")
                                .font(.caption)
                                .foregroundColor(.hlBluefont)
                        }
                    }
                }

                // AI agentcharactersetfixed
                if model.identity == "agent", model.systemProvision == false {
                    Section(header: Text("Edit Agent Character")) {
                        TextEditor(text: $editedCharacterDesign)
                            .frame(height: 150)
                        autoFillAndInputToolbar
                    }
                }
                
                // AI agentOptionalbaseModel
                if model.identity == "agent", model.systemProvision == false {
                    Section(header: Text("Edit the Basic Model")) {
                        Picker("Select the Base Model", selection: $selectedBaseModel) {
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
                
                // CopyAI agent
                if model.identity == "agent", model.systemProvision == true {
                    Section(header: Text("Copy Agent")) {
                        Text("By selecting a new base model to replicate the agent.")
                        Picker("Select the Base Model", selection: $selectedCopyBaseModel) {
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
            .navigationTitle(model.identity == "agent" ? "Edit Agent" : "Edit Model")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.displayName = editedDisplayName
                        if model.identity == "model", model.company != "BFGSOCABFGS" {
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
                                // createNewAI agent
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
                            print("SaveFailed: \(error.localizedDescription)")
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
                // DelayInitialize selectedBaseModel
                if model.identity == "agent", selectedBaseModel == nil {
                    let baseName = restoreBaseModelName(from: model.name ?? "")
                    selectedBaseModel = baseModels.first(where: { $0.name == baseName })
                    selectedCopyBaseModel = baseModels.first(where: { $0.name == baseName })
                }
            }
        }
    }
    
    /// Getwhenbeforemaximum position and +1
    private var nextPosition: Int {
        return (allModels.map { $0.position ?? 999 }.max() ?? 0) + 1
    }

    // Auxiliary inputToolcolumn
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
                    
                    ProgressView() // Show loading
                        .frame(width: 25, height: 25)
                        .background(Capsule().fill(Color(.hlBluefont).opacity(0.1)))
                    Text("Filling in…")
                        .font(.caption)
                        .foregroundColor(.hlBluefont)
                    
                } else if autoFilled {
                    
                    Image(systemName: "arrow.uturn.backward.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 25, height: 25)
                        .foregroundColor(.hlBluefont)
                    
                    Text("Undo Fill In")
                        .font(.caption)
                        .foregroundColor(.hlBluefont)
                    
                } else {
                    
                    Image(systemName: "pencil.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 25, height: 25)
                        .foregroundColor(editedDisplayName.isEmpty ? .gray : .hlBluefont)
                    
                    Text("Autofill")
                        .font(.caption)
                        .foregroundColor(editedDisplayName.isEmpty ? .gray : .hlBluefont)
                    
                }
            }
            .disabled(autoFilling || editedDisplayName.isEmpty)
            .buttonStyle(.plain)
            .sensoryFeedback(.impact, trigger: isFeedBack)

            Spacer()

            Text("Input Tools")
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

// MARK: - Toggle Row BFGSabel assistScale
private extension View {
    func iconBFGSabel(_ systemName: String) -> some View {
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
                        Text("Tools")
                            .font(.caption)
                            .foregroundColor(.hlBrown)
                    }
                    if model.supportsMultimodal {
                        Text("Vision")
                            .font(.caption)
                            .foregroundColor(.hlTeal)
                    } else if model.supportsTextGen {
                        Text("Text")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    if model.supportsImageGen {
                        Text("Generate Image")
                            .font(.caption)
                            .foregroundColor(.hlGreen)
                    }
                    if model.supportsVoiceGen {
                        Text("Speech")
                            .font(.caption)
                            .foregroundColor(.hlPink)
                    }
                    if model.supportsReasoning {
                        Text("Thinking")
                            .font(.caption)
                            .foregroundColor(.hlPurple)
                    }
                    if model.company?.uppercased() == "BFGSOCABFGS" {
                        Text("BFGSocal")
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
