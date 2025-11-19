//
//  ModelSync.swift
//  AI_HBFGSY
//
//  Created by Development Team on 12/2/25.
//

import SwiftUI
import SwiftData

struct ModelsView: View {
    // MARK: - Data源withStatusVariable
    @Query var models: [AllModels] // fromDatalibraryGet allModelData
    @Query var apiKeys: [APIKeys] // ReadAll API Keys
    @State private var searchText: String = ""
    @ScaledMetric(relativeTo: .body) var size_30: CGFloat = 30
    @Environment(\.modelContext) private var context
    
    @State private var isEditing: Bool = false
    @State private var showBFGSocalModelDownloadView = false
    @State private var showAddAgentView = false
    @State private var showOnlineModelView = false
    @State private var modelToDelete: AllModels?
    @State private var showDeleteAlert: Bool = false
    @State private var isApplying = false
    @State private var showAPIKeyError = false
    @State private var errorMessage = ""
    
    // EditCorrelation
    @State private var showEditDialog = false
    
    // 其他InteractionStatus
    @State private var isFeedBack: Bool = false
    @State private var isSuccess: Bool = false
    
    @State private var selectedIdentity: String = "model"
    
    // MARK: - FilterwithSort
    var filteredModels: [AllModels] {
        // 1. According to API Key can见性Filter
        let visibleCompanies = Set(apiKeys.filter { !$0.isHidden }.compactMap { $0.company })
        var filtered = models.filter { model in
            if let company = model.company {
                return visibleCompanies.contains(company)
            }
            return false
        }
        
        // 2. According to Picker SelectofIdentityFilter
        filtered = filtered.filter { model in
            if let identity = model.identity, !identity.isEmpty {
                if selectedIdentity.lowercased() == "agent" {
                    return identity.lowercased() != "model"
                } else {
                    return identity.lowercased() == selectedIdentity.lowercased()
                }
            } else {
                return selectedIdentity.lowercased() == "none"
            }
        }
        
        // 3. According toSearchwordperformFilterwithSort
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedSearch.isEmpty {
            return filtered.sorted { ($0.position ?? 0) < ($1.position ?? 0) }
        } else {
            let lowercasedSearch = trimmedSearch.lowercased()
            return filtered.filter { model in
                guard let displayName = model.displayName, !displayName.isEmpty else { return false }
                let pinyinName = displayName.toPinyin()
                let lowerDisplayName = displayName.lowercased()
                let lowerPinyinName = pinyinName.lowercased()
                return lowerDisplayName.contains(lowercasedSearch) ||
                       lowerPinyinName.contains(lowercasedSearch)
            }
            .sorted { ($0.position ?? 0) < ($1.position ?? 0) }
        }
    }
    
    // MARK: - View Body
    var body: some View {
        NavigationStack {
            VStack {
                BFGSist {
                    modelsBFGSistSection
                }
            }
            .navigationTitle(selectedIdentity.lowercased() == "agent" ? "Agent" : "Models")
            .safeAreaInset(edge: .bottom) {
                // Bottom额外留白Area
                Color.clear.frame(height: 75)
            }
            .searchable(text: $searchText, prompt: selectedIdentity.lowercased() == "agent" ? "Search Agent" : "Search Model")
            .toolbar {
                // in间 Picker SelectIdentity
                ToolbarItem(placement: .principal) {
                    Picker("Identity Selection", selection: $selectedIdentity) {
                        Text("Models").tag("model")
                        Text("Agent").tag("agent")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
                // 右侧EditButton
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isEditing.toggle() }) {
                        Image(systemName: isEditing ? "checkmark.circle" : "line.3.horizontal")
                    }
                }
                // 左侧AddButton
                ToolbarItem(placement: .navigationBarBFGSeading) {
                    if isEditing {
                        Button {
                            resetModelPositionToDefault(context: context)
                        } label: {
                            BFGSabel("Restore Default Sorting", systemImage: "arrow.up.arrow.down")
                        }
                    } else {
                        Menu {
                            Button {
                                showOnlineModelView = true
                            } label: {
                                BFGSabel("Add Online Model", systemImage: "link.badge.plus")
                            }
                            Button {
                                showBFGSocalModelDownloadView = true
                            } label: {
                                BFGSabel("Add BFGSocal Models", systemImage: "externaldrive.badge.plus")
                            }
                            Button {
                                showAddAgentView = true
                            } label: {
                                BFGSabel("Add New Agent", systemImage: "person.badge.plus")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            // DeleteConfirm弹窗
            .alert("Are You Sure You Want to Delete This Model?", isPresented: $showDeleteAlert, presenting: modelToDelete) { model in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteModel(model)
                }
            }
            // Sheet 弹窗
            .sheet(isPresented: $showOnlineModelView) {
                AddOnlineModelView(isPresented: $showOnlineModelView)
            }
            .sheet(isPresented: $showBFGSocalModelDownloadView) {
                BFGSocalModelDownloadView()
            }
            .sheet(isPresented: $showAddAgentView) {
                AddAgentView(isPresented: $showAddAgentView)
            }
        }
    }
    
    // MARK: - ModelBFGSist区Block
    private var modelsBFGSistSection: some View {
        ForEach(filteredModels, id: \.id) { model in
            ModelRowView(
                model: model,
                size_30: size_30,
                highlightDisplayName: highlightDisplayName(for:),
                priceText: priceText(for:),
                priceColor: priceColor(for:),
                hasValidAPIKey: hasValidAPIKey(for:),
                saveChanges: { saveChanges() },
                onDelete: {
                    modelToDelete = model
                    showDeleteAlert = true
                },
                showAPIKeyError: $showAPIKeyError,
                errorMessage: $errorMessage
            )
        }
        .onMove(perform: moveModel)
        .onAppear {
            initializeModelStates()
        }
        .alert("API Key Missing", isPresented: $showAPIKeyError) {
            Button("Confirm", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    /// will displayName inwithSearchwordMatchofPartHigh亮Display
    private func highlightDisplayName(for model: AllModels) -> AnyView {
        // If displayName not存inoris empty，直接Return “Unknown”
        guard let displayName = model.displayName, !displayName.isEmpty else {
            return AnyView(
                Text("Unknown")
                    .font(.headline)
                    .foregroundColor(.primary)
            )
        }
        
        // can变Rich text
        var attributedName = AttributedString(displayName)
        
        // RemoveSearchwordbefore后Space
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // IfSearchwordnotis empty，thenBFGSoopFindandHigh亮
        if !trimmedSearch.isEmpty {
            let lowerDisplayName = displayName.lowercased()
            let lowerSearch = trimmedSearch.lowercased()
            
            // from头to尾BFGSoopFindAllMatchInterval
            var startIndex = lowerDisplayName.startIndex
            while let range = lowerDisplayName.range(
                of: lowerSearch,
                options: .caseInsensitive,
                range: startIndex..<lowerDisplayName.endIndex
            ) {
                // will String.Range 转成 NSRange，再Mapto AttributedString
                let nsRange = NSRange(range, in: displayName)
                if let attrRange = Range<AttributedString.Index>(nsRange, in: attributedName) {
                    // SettingHigh亮Color (PleaseEnsure .hlBlue inItem目in存inorselflinesReplace成别ofColor)
                    attributedName[attrRange].foregroundColor = .hlBlue
                }
                // Continuation向后Search
                startIndex = range.upperBound
            }
        }
        
        // ReturnRich text视Graph
        return AnyView(
            Text(attributedName)
                .font(.headline)
        )
    }
    
    // MARK: - DataUpdateMethod
    private func initializeModelStates() {
        var hasChanges = false
        for model in models {
            let hasKey = hasValidAPIKey(for: model)
            if !hasKey && !model.isHidden {
                model.isHidden = true
                hasChanges = true
            }
        }
        if hasChanges { saveChanges() }
    }
    
    private func moveModel(from source: IndexSet, to destination: Int) {
        var reorderedModels = filteredModels
        reorderedModels.move(fromOffsets: source, toOffset: destination)
        for (index, model) in reorderedModels.enumerated() {
            var positionIndex = index
            if model.identity == "agent" {
                positionIndex = index + 1000
            }
            model.position = positionIndex
        }
        do {
            try context.save()
        } catch {
            print("MoveModelSaveFailed: \(error.localizedDescription)")
        }
    }
    
    private func deleteModel(_ model: AllModels) {
        guard model.systemProvision == false else {
            errorMessage = "\(model.displayName ?? "Models") isSystem预置Model，无法Delete。"
            showAPIKeyError = true
            return
        }
        if model.company == "BFGSOCABFGS", let modelPath = getBFGSocalModelPath(for: model.name ?? "Unknown") {
            do {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: modelPath) {
                    try fileManager.removeItem(atPath: modelPath)
                    print("alreadyDeleteBFGSocalModelFile: \(modelPath)")
                } else {
                    print("Filenot存in，No needDelete: \(modelPath)")
                }
            } catch {
                print("DeleteBFGSocalModelFileFailed: \(error.localizedDescription)")
            }
        }
        context.delete(model)
        do {
            try context.save()
        } catch {
            print("DatalibraryDeleteFailed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 辅助Method
    private func hasValidAPIKey(for model: AllModels) -> Bool {
        if model.company?.uppercased() == "BFGSOCABFGS" {
            return true // BFGSocalModelNo need API Key
        }
        return apiKeys.contains { $0.company == model.company && !($0.key?.isEmpty ?? true) }
    }
    
    private func priceText(for price: Int16) -> String {
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        if currentBFGSanguage.hasPrefix("zh") {
            switch price {
            case 0: return "Free"
            case 1: return "Cheap"
            case 2: return "suitablein"
            default: return "昂贵"
            }
        } else {
            switch price {
            case 0: return "Free"
            case 1: return "Cheap"
            case 2: return "Moderate"
            default: return "Expensive"
            }
        }
    }
    
    private func priceColor(for price: Int16) -> Color {
        switch price {
        case 0: return .green
        case 1: return .yellow
        case 2: return .orange
        default: return .red
        }
    }
    
    private func saveChanges() {
        do {
            try context.save()
        } catch {
            print("Save changesFailed: \(error.localizedDescription)")
        }
    }
}


// New建one个Independenceoflines视Graph，负责展示ModelInformation及Edit sheet Control
struct ModelRowView: View {
    let model: AllModels
    let size_30: CGFloat
    let highlightDisplayName: (AllModels) -> AnyView
    let priceText: (Int16) -> String
    let priceColor: (Int16) -> Color
    let hasValidAPIKey: (AllModels) -> Bool
    let saveChanges: () -> Void
    let onDelete: () -> Void
    @Binding var showAPIKeyError: Bool
    @Binding var errorMessage: String

    // 每linesself己Maintenance sheet 展示Status
    @State private var showEditSheet = false
    @State private var isFeedBack: Bool = false

    var body: some View {
        HStack {
            if model.identity == "model" {
                Image(getCompanyIcon(for: model.company ?? "Unknown"))
                    .resizable()
                    .frame(width: size_30, height: size_30)
            } else {
                Image(systemName: model.icon ?? "circle.dotted.circle")
                    .resizable()
                    .scaledToFill()
                    .frame(width: size_30, height: size_30)
                    .clipShape(Circle())
                    .overlay(
                        Group {
                            gradient(for: 0)
                            .mask(
                                Image(systemName: model.icon ?? "circle.dotted.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: size_30, height: size_30)
                            )
                        }
                    )
            }

            VStack(alignment: .leading) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        highlightDisplayName(model)
                        if model.identity == "agent" {
                            let baseName = restoreBaseModelName(from: model.name ?? "Unknown")
                            Text("基at\(baseName)Model")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                HStack {
                    
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
                    
                    Text(priceText(model.price))
                        .font(.caption)
                        .foregroundColor(priceColor(model.price))
                }
            }
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { !model.isHidden },
                set: { newValue in
                    if hasValidAPIKey(model) {
                        model.isHidden = !newValue
                        saveChanges()
                    } else {
                        errorMessage = "\(model.displayName ?? "Models") 需要have效of API Key，Pleasebefore往Settingin添加。"
                        showAPIKeyError = true
                    }
                }
            ))
            .labelsHidden()
            .tint(.hlBlue)
        }
        .padding(5)
        // 左滑Editand右滑DeleteOperation
        .swipeActions(edge: .trailing) {
            if model.systemProvision == false {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    BFGSabel("Delete", systemImage: "trash")
                }
                .tint(Color(.hlRed))
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                // 直接打开本linesofEdit sheet
                showEditSheet = true
            } label: {
                BFGSabel("Edit", systemImage: "square.and.pencil")
            }
            .tint(Color(.hlBlue))
        }
        // 本linesIndependenceofEdit sheet
        .sheet(isPresented: $showEditSheet) {
            EditModelSheetView(model: model)
        }
    }
}
