//
//  ModelSync.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 12/2/25.
//

import SwiftUI
import SwiftData

struct ModelsView: View {
    // MARK: - 数据源与状态变量
    @Query var models: [AllModels] // 从数据库获取所有模型数据
    @Query var apiKeys: [APIKeys] // 读取所有 API Keys
    @State private var searchText: String = ""
    @ScaledMetric(relativeTo: .body) var size_30: CGFloat = 30
    @Environment(\.modelContext) private var context
    
    @State private var isEditing: Bool = false
    @State private var showLocalModelDownloadView = false
    @State private var showAddAgentView = false
    @State private var showOnlineModelView = false
    @State private var modelToDelete: AllModels?
    @State private var showDeleteAlert: Bool = false
    @State private var isApplying = false
    @State private var showAPIKeyError = false
    @State private var errorMessage = ""
    
    // 编辑相关
    @State private var showEditDialog = false
    
    // 其他交互状态
    @State private var isFeedBack: Bool = false
    @State private var isSuccess: Bool = false
    
    @State private var selectedIdentity: String = "model"
    
    // MARK: - 筛选与排序
    var filteredModels: [AllModels] {
        // 1. 根据 API Key 可见性筛选
        let visibleCompanies = Set(apiKeys.filter { !$0.isHidden }.compactMap { $0.company })
        var filtered = models.filter { model in
            if let company = model.company {
                return visibleCompanies.contains(company)
            }
            return false
        }
        
        // 2. 根据 Picker 选择的身份过滤
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
        
        // 3. 根据搜索词进行筛选与排序
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
                List {
                    modelsListSection
                }
            }
            .navigationTitle(selectedIdentity.lowercased() == "agent" ? "Agent" : "Models")
            .safeAreaInset(edge: .bottom) {
                // 底部额外留白区域
                Color.clear.frame(height: 75)
            }
            .searchable(text: $searchText, prompt: selectedIdentity.lowercased() == "agent" ? "Search Agent" : "Search Model")
            .toolbar {
                // 中间 Picker 选择身份
                ToolbarItem(placement: .principal) {
                    Picker("Identity Selection", selection: $selectedIdentity) {
                        Text("Models").tag("model")
                        Text("Agent").tag("agent")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
                // 右侧编辑按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isEditing.toggle() }) {
                        Image(systemName: isEditing ? "checkmark.circle" : "line.3.horizontal")
                    }
                }
                // 左侧新增按钮
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button {
                            resetModelPositionToDefault(context: context)
                        } label: {
                            Label("Restore Default Sorting", systemImage: "arrow.up.arrow.down")
                        }
                    } else {
                        Menu {
                            Button {
                                showOnlineModelView = true
                            } label: {
                                Label("Add Online Model", systemImage: "link.badge.plus")
                            }
                            Button {
                                showLocalModelDownloadView = true
                            } label: {
                                Label("Add Local Models", systemImage: "externaldrive.badge.plus")
                            }
                            Button {
                                showAddAgentView = true
                            } label: {
                                Label("Add New Agent", systemImage: "person.badge.plus")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(isEditing ? .active : .inactive))
            // 删除确认弹窗
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
            .sheet(isPresented: $showLocalModelDownloadView) {
                LocalModelDownloadView()
            }
            .sheet(isPresented: $showAddAgentView) {
                AddAgentView(isPresented: $showAddAgentView)
            }
        }
    }
    
    // MARK: - 模型列表区块
    private var modelsListSection: some View {
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
    
    /// 将 displayName 中与搜索词匹配的部分高亮显示
    private func highlightDisplayName(for model: AllModels) -> AnyView {
        // 如果 displayName 不存在或为空，直接返回 “Unknown”
        guard let displayName = model.displayName, !displayName.isEmpty else {
            return AnyView(
                Text("Unknown")
                    .font(.headline)
                    .foregroundColor(.primary)
            )
        }
        
        // 可变富文本
        var attributedName = AttributedString(displayName)
        
        // 去除搜索词前后空格
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果搜索词不为空，则循环查找并高亮
        if !trimmedSearch.isEmpty {
            let lowerDisplayName = displayName.lowercased()
            let lowerSearch = trimmedSearch.lowercased()
            
            // 从头到尾循环查找所有匹配区间
            var startIndex = lowerDisplayName.startIndex
            while let range = lowerDisplayName.range(
                of: lowerSearch,
                options: .caseInsensitive,
                range: startIndex..<lowerDisplayName.endIndex
            ) {
                // 将 String.Range 转成 NSRange，再映射到 AttributedString
                let nsRange = NSRange(range, in: displayName)
                if let attrRange = Range<AttributedString.Index>(nsRange, in: attributedName) {
                    // 设置高亮颜色 (请确保 .hlBlue 在项目中存在或自行替换成别的颜色)
                    attributedName[attrRange].foregroundColor = .hlBlue
                }
                // 继续向后搜索
                startIndex = range.upperBound
            }
        }
        
        // 返回富文本视图
        return AnyView(
            Text(attributedName)
                .font(.headline)
        )
    }
    
    // MARK: - 数据更新方法
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
            print("移动模型保存失败: \(error.localizedDescription)")
        }
    }
    
    private func deleteModel(_ model: AllModels) {
        guard model.systemProvision == false else {
            errorMessage = "\(model.displayName ?? "Models") 为系统预置模型，无法删除。"
            showAPIKeyError = true
            return
        }
        if model.company == "LOCAL", let modelPath = getLocalModelPath(for: model.name ?? "Unknown") {
            do {
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: modelPath) {
                    try fileManager.removeItem(atPath: modelPath)
                    print("已删除本地模型文件: \(modelPath)")
                } else {
                    print("文件不存在，无需删除: \(modelPath)")
                }
            } catch {
                print("删除本地模型文件失败: \(error.localizedDescription)")
            }
        }
        context.delete(model)
        do {
            try context.save()
        } catch {
            print("数据库删除失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 辅助方法
    private func hasValidAPIKey(for model: AllModels) -> Bool {
        if model.company?.uppercased() == "LOCAL" {
            return true // 本地模型无需 API Key
        }
        return apiKeys.contains { $0.company == model.company && !($0.key?.isEmpty ?? true) }
    }
    
    private func priceText(for price: Int16) -> String {
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        if currentLanguage.hasPrefix("zh") {
            switch price {
            case 0: return "Free"
            case 1: return "廉价"
            case 2: return "适中"
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
            print("保存更改失败: \(error.localizedDescription)")
        }
    }
}


// 新建一个独立的行视图，负责展示模型信息及编辑 sheet 控制
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

    // 每行自己维护 sheet 展示状态
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
                            Text("基于\(baseName)模型")
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
                    
                    if model.company?.uppercased() == "LOCAL" {
                        Text("Local")
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
                        errorMessage = "\(model.displayName ?? "Models") 需要有效的 API Key，请前往设置中添加。"
                        showAPIKeyError = true
                    }
                }
            ))
            .labelsHidden()
            .tint(.hlBlue)
        }
        .padding(5)
        // 左滑编辑和右滑删除操作
        .swipeActions(edge: .trailing) {
            if model.systemProvision == false {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(Color(.hlRed))
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                // 直接打开本行的编辑 sheet
                showEditSheet = true
            } label: {
                Label("Edit", systemImage: "square.and.pencil")
            }
            .tint(Color(.hlBlue))
        }
        // 本行独立的编辑 sheet
        .sheet(isPresented: $showEditSheet) {
            EditModelSheetView(model: model)
        }
    }
}
