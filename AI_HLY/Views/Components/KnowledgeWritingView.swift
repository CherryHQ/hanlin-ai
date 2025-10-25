//
//  KnowledgeWritingView.swift
//  AI_Hanlin
//
//  Created by 哆啦好多梦 on 28/3/25.
//

import SwiftUI
import MarkdownUI
import SwiftData

struct KnowledgeWritingView: View {
    @Environment(\.modelContext) private var modelContext
    var knowledgeRecord: KnowledgeRecords
    var fromSheet: Bool = false
    @Query var allApiKeys: [APIKeys]
    @State private var message: String
    @FocusState private var isTextFocused: Bool
        
    @ScaledMetric(relativeTo: .body) var size_30: CGFloat = 36
    @ScaledMetric(relativeTo: .body) var size_20: CGFloat = 20
        
    @State private var estimatedTokens: Int = 0
    @State private var showAlert: Bool = false
    @State private var original: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
        
    @State private var isOptimizing: Bool = false
    @State private var optimized: Bool = false
    @State private var optimizedMessage: String = ""
        
    @State private var translated: Bool = false
    @State private var isTranslating: Bool = false
    @State private var translatedMessage: String = ""
        
    @State private var ocred: Bool = false
    @State private var isOCR: Bool = false
    @State private var ocrImage: UIImage? = nil
    @State private var showPhotoSourceOptions = false // 控制 ActionSheet
    @State private var isSourceOptionsVisible = false // 控制 ActionSheet
    @State private var showImagePicker = false // 控制相册
    @State private var showCameraPicker = false // 控制相机
    
    @State private var isDocument: Bool = false
    @State private var documented: Bool = false
    @State private var selectedDocumentURL: URL?
    @State private var showDocumentPicker: Bool = false
    
    @State private var isWeb: Bool = false
    @State private var webDocumented: Bool = false
    @State private var webInput: String = ""
    @State private var showWebInput: Bool = false
    @State private var isWebInputVisible: Bool = false
    
    @State private var isFeedBack: Bool = false
    @State private var isSelect: Bool = false
    @State private var saveTask: Task<Void, Never>? = nil
    
    @State private var isViewLoaded = false
    @State private var isEditMode = true
        
    @State private var isEditingTitle: Bool = false
    @State private var newKnowledgeTitle: String = ""
    
    @State private var isEmbedding = false
    @State private var embeddingCompleted = false
    @State private var selectedEmbeddingModel: EmbeddingModel? = nil
    @State private var embeddingModels: [EmbeddingModel] = getEmbeddingModelList()
    @State private var visibleEmbeddingModels: [EmbeddingModel] = []
    
    init(knowledgeRecord: KnowledgeRecords, fromSheet: Bool = false) {
        self.knowledgeRecord = knowledgeRecord
        self.fromSheet = fromSheet
        _message = State(initialValue: knowledgeRecord.content ?? "")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: — 编辑区
            textEditorSection()
                .padding(.horizontal, 12)
                .onChange(of: message) {
                    saveTask?.cancel()
                    saveTask = Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        if Task.isCancelled { return }
                        knowledgeRecord.content = message
                        knowledgeRecord.lastEdited = Date()
                        knowledgeRecord.isEmbedding = false
                        embeddingCompleted = false
                        try? modelContext.save()
                    }
                }
            
            // MARK: — 按钮区（叠加在编辑区上方）
            VStack {
                if isEditMode {
                    buttonActions()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    VStack(spacing: 12) {
                        // 向量化构建按钮
                        Button(action: startEmbedding) {
                            Group {
                                if isEmbedding {
                                    ProgressView()
                                } else if knowledgeRecord.isEmbedding || embeddingCompleted {
                                    Label("已成功构建向量", systemImage: "checkmark.circle.fill")
                                } else {
                                    Label("构建以允许聊天召回", systemImage: "compass.drawing")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .foregroundColor((knowledgeRecord.isEmbedding || embeddingCompleted) ? .hlGreen : .hlBluefont)
                        }
                        .buttonStyle(.plain)
                        .background((knowledgeRecord.isEmbedding || embeddingCompleted)
                                    ? Color.hlGreen.opacity(0.1)
                                    : Color.hlBluefont.opacity(0.1))
                        .cornerRadius(20)
                        .disabled(isEmbedding || knowledgeRecord.isEmbedding)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        
                        // 嵌入模型滑动选择
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(visibleEmbeddingModels) { model in
                                        Button {
                                            isSelect.toggle()
                                            selectedEmbeddingModel = model
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                                                proxy.scrollTo(model.id, anchor: .center)
                                            }
                                        } label: {
                                            embeddingModelButton(for: model,
                                                                 isSelected: selectedEmbeddingModel?.id == model.id)
                                        }
                                        .sensoryFeedback(.selection, trigger: isSelect)
                                    }
                                }
                            }
                            .cornerRadius(20)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
            }
            .padding(12)
            .background(
                GlassView(style: .systemThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .shadow(color: .hlBlue, radius: 1)
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
            .offset(y: (isViewLoaded || !isEditMode) ? 0 : 60)
            .opacity((isViewLoaded || !isEditMode) ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showPhotoSourceOptions)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showWebInput)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isViewLoaded || !isEditMode)
        }
        .toolbar(.hidden, for: .tabBar)
        // MARK: — 生命周期 & 导航
        .onAppear {
            estimatedTokens = estimateTokens(for: message)
            NotificationCenter.default.post(name: .hideTabBar, object: true)
            isEditMode = message.isEmpty
            isViewLoaded = isEditMode
            embeddingCompleted = knowledgeRecord.isEmbedding
            
            visibleEmbeddingModels = embeddingModels.filter { model in
                if let key = allApiKeys.first(where: { $0.company == model.company })?.key,
                   !key.isEmpty {
                    return true
                }
                return false
            }
            selectedEmbeddingModel = selectedEmbeddingModel ?? visibleEmbeddingModels.first
        }
        .onDisappear {
            saveTask?.cancel()
            saveTask = Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                knowledgeRecord.content = message
                try? modelContext.save()
            }
            NotificationCenter.default.post(name: .hideTabBar, object: fromSheet ? true : false)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ZStack {
                    // 普通模式标题
                    Text(knowledgeRecord.name)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .opacity(isEditingTitle ? 0 : 1)
                        .onTapGesture {
                            newKnowledgeTitle = knowledgeRecord.name
                            isEditingTitle = true
                        }
                    // 编辑模式标题
                    TextField("请输入知识名称", text: $newKnowledgeTitle, onCommit: {
                        renameKnowledgeRecord(to: newKnowledgeTitle)
                        isEditingTitle = false
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: UIScreen.main.bounds.width * 0.4)
                    .multilineTextAlignment(.center)
                    .opacity(isEditingTitle ? 1 : 0)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation {
                        isEditMode.toggle()
                        isViewLoaded = isEditMode
                    }
                } label: {
                    Text(isEditMode ? "保存" : "编辑")
                        .foregroundColor(.hlBluefont)
                }
            }
        }
    }
    
    // 重命名知识文档
    private func renameKnowledgeRecord(to baseName: String) {
        guard !baseName.isEmpty,
              baseName != knowledgeRecord.name else { return }

        let predicate = #Predicate<KnowledgeRecords> { rec in
            rec.name == baseName ||
            rec.name.starts(with: "\(baseName)_")
        }
        let descriptor = FetchDescriptor<KnowledgeRecords>(predicate: predicate)
        let matches = (try? modelContext.fetch(descriptor)) ?? []
        let conflicts = matches.filter { $0.id != knowledgeRecord.id }

        var maxIndex = 0
        for rec in conflicts {
            let name = rec.name
            if name == baseName {
                maxIndex = max(maxIndex, 1)
            } else if name.hasPrefix("\(baseName)_") {
                let suffix = name.dropFirst(baseName.count + 1)
                if let num = Int(suffix) {
                    maxIndex = max(maxIndex, num + 1)
                }
            }
        }

        let finalName = maxIndex > 0
            ? "\(baseName)_\(maxIndex)"
            : baseName

        knowledgeRecord.name  = finalName
        newKnowledgeTitle     = finalName
        do {
            try modelContext.save()
        } catch {
            print("保存失败：\(error)")
        }
    }
    
    private func embeddingModelButton(for model: EmbeddingModel, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            if isSelected {
                Image(getCompanyIcon(for: model.company))
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .scaleEffect(1.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSelected)
            } else {
                Image(getCompanyIcon(for: model.company))
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .scaleEffect(1.0)
                    .foregroundColor(Color(.systemGray))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSelected)
            }

            if isSelected {
                Text(model.displayName)
                    .font(.caption)
                    .foregroundColor(.hlBluefont)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                
                if model.price > 0 {
                    Text(String(format: "¥%.4f/Ktokens", model.price))
                        .font(.caption)
                        .foregroundColor(.orange)
                        .transition(.opacity)
                } else {
                    Text("免费")
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }
        }
        .padding(10)
        .background(isSelected ? Color.hlBluefont.opacity(0.1) : Color(.systemGray).opacity(0.1))
        .cornerRadius(20)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isSelected)
    }

    // MARK: - 输入框区域
    @ViewBuilder
    private func textEditorSection() -> some View {
        if isEditMode {
            TextEditor(text: $message)
                .focused($isTextFocused)
                .scrollContentBackground(.hidden)
                .padding(.bottom, 66)
                .onChange(of: message) {
                    DispatchQueue.main.async {
                        estimatedTokens = estimateTokens(for: message)
                    }
                }
        } else {
            ScrollView {
                Markdown(message)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.bottom, 150)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - 按钮区域
    @ViewBuilder
    private func buttonActions() -> some View {
        VStack {
            if showWebInput {
                VStack {
                    Text("请输入网页 URL")
                        .font(.caption.bold())
                        .foregroundColor(.hlBluefont)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        TextField("网页地址", text: $webInput)
                            .padding(.leading, 12)
                            .frame(height: 44)
                            .submitLabel(.send)
                            .onSubmit {
                                isFeedBack.toggle()
                                if !webInput.isEmpty && !webDocumented {
                                    processWeb()
                                }
                            }
                            .disabled(isWeb)
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                            .padding(.bottom, 6)
                        
                        Button(action: {
                            if isWeb {
                                
                            } else {
                                isFeedBack.toggle()
                                if !webInput.isEmpty && !webDocumented {
                                    processWeb()
                                }
                            }
                        }) {
                            Image(systemName: "arrowtriangle.up.circle.fill")
                                .resizable()
                                .frame(width: 44, height: 44)
                                .foregroundColor(isWeb ? .gray : .hlBluefont)
                        }
                        .padding(.bottom, 6)
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            HStack {
                optimizeButton()
                translateButton()
                ocrButton()
                documentButton()
                webButton()
                clearButton()
                Spacer()
                tokenCounter()
            }
            if showPhotoSourceOptions {
                Text("选择OCR的图片来源")
                    .font(.caption.bold())
                    .foregroundColor(.hlBluefont)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
                sourceSelector
            }
        }
        .onChange(of: showPhotoSourceOptions) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isSourceOptionsVisible = showPhotoSourceOptions
            }
        }
        .onChange(of: showWebInput) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isWebInputVisible = showWebInput
            }
        }
        .sensoryFeedback(.impact, trigger: isFeedBack)
    }

    // MARK: - 优化按钮
    private func optimizeButton() -> some View {
        Button(action: optimizeMessage) {
            if isOptimizing {
                ProgressView() // 显示加载指示器
                    .frame(width: size_30, height: size_30)
                    .background(Capsule().fill(Color(.systemGray4)))
            } else if optimized {
                Image(systemName: "arrow.uturn.backward.circle")
                    .resizable()
                    .frame(width: size_30, height: size_30)
                    .foregroundColor(Color(.systemGray))
            } else {
                Image(systemName: "m.circle")
                    .resizable()
                    .frame(width: size_30, height: size_30)
                    .foregroundColor(Color(.systemGray))
            }
        }
        .disabled(isOptimizing || isTranslating)
        .frame(width: size_30, height: size_30)
        .onChange(of: message) {
            if optimized && (message != optimizedMessage) {
                optimized = false
            } else if message == optimizedMessage , !message.isEmpty {
                optimized = true
            }
        }
    }

    // MARK: - 翻译按钮
    private func translateButton() -> some View {
        Button(action: translateMessage) {
            if isTranslating {
                ProgressView() // 显示加载指示器
                    .frame(width: size_30, height: size_30)
                    .background(Capsule().fill(Color(.systemGray4)))
            } else if translated {
                Image(systemName: "arrow.uturn.backward.circle")
                    .resizable()
                    .frame(width: size_30, height: size_30)
                    .foregroundColor(Color(.systemGray))
            } else {
                Image("translate_circle")
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: size_30, height: size_30)
                    .foregroundColor(Color(.systemGray))
            }
        }
        .disabled(isOptimizing || isTranslating)
        .frame(width: size_30, height: size_30)
        .onChange(of: message) {
            if translated && (message != translatedMessage) {
                translated = false
            } else if message == translatedMessage , !message.isEmpty {
                translated = true
            }
        }
    }

    // MARK: - OCR 按钮
    private func ocrButton() -> some View {
        Button(action: {
            isFeedBack.toggle()
            if ocred {
                message = original
                ocred = false
            } else {
                showPhotoSourceOptions.toggle()
            }
        }) {
            if isOCR {
                ProgressView() // 显示加载指示器
                    .frame(width: size_30, height: size_30)
                    .background(Capsule().fill(Color(.systemGray4)))
            } else if ocred {
                Image(systemName: "arrow.uturn.backward.circle")
                    .resizable()
                    .frame(width: size_30, height: size_30)
                    .foregroundColor(Color(.systemGray))
            } else {
                Image(systemName: isSourceOptionsVisible ? "xmark.circle" :"viewfinder.circle")
                    .resizable()
                    .frame(width: size_30, height: size_30)
                    .foregroundColor(isSourceOptionsVisible ? .hlRed : Color(.systemGray))
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .disabled(isOptimizing || isTranslating)
        .frame(width: size_30, height: size_30)
        .onChange(of: ocrImage) {
            if ocrImage != nil {
                processOCR() // 进行 OCR 处理
            }
        }
    }
    
    // MARK: - 文档按钮
    private func documentButton() -> some View {
        Button(action: {
            isFeedBack.toggle()
            if documented {
                // 撤销文档解析结果
                message = original
                documented = false
            } else {
                // 打开文档选择器前，清理旧状态
                documented = false
                selectedDocumentURL = nil
                showDocumentPicker.toggle()
            }
        }) {
            if isDocument {
                ProgressView()
                    .frame(width: size_30, height: size_30)
                    .background(Capsule().fill(Color(.systemGray4)))
            } else if documented {
                Image(systemName: "arrow.uturn.backward.circle")
                    .resizable()
                    .frame(width: size_30, height: size_30)
                    .foregroundColor(Color(.systemGray))
            } else {
                Image(systemName: "document.circle")
                    .resizable()
                    .frame(width: size_30, height: size_30)
                    .foregroundColor(Color(.systemGray))
            }
        }
        .disabled(isOptimizing || isTranslating)
        .frame(width: size_30, height: size_30)
        .sheet(isPresented: $showDocumentPicker, onDismiss: {
            // 文件选择器关闭时若 selectedDocumentURL 不为 nil 且未处理则调用处理函数
            if selectedDocumentURL != nil && !documented {
                processDocument()
            }
        }) {
            SingleDocumentPicker(selectedDocumentURL: $selectedDocumentURL)
        }
        .onChange(of: selectedDocumentURL) { oldValue, newValue in
            // 当 URL 变化且不为 nil 时，自动触发处理（解决首次不解析问题）
            if newValue != nil && newValue != oldValue && !documented && !isDocument {
                processDocument()
            }
        }
    }
    
    // MARK: 网页按钮
    private func webButton() -> some View {
        Button(action: {
            isFeedBack.toggle()
            if webDocumented {
                message = original
                webDocumented = false
            } else {
                showWebInput.toggle()
            }
        }) {
            if isWeb {
                ProgressView()
                    .frame(width: size_30, height: size_30)
                    .background(Capsule().fill(Color(.systemGray4)))
            } else if webDocumented {
                Image(systemName: "arrow.uturn.backward.circle")
                    .resizable()
                    .frame(width: size_30, height: size_30)
                    .foregroundColor(Color(.systemGray))
            } else {
                Image(systemName: isWebInputVisible ? "xmark.circle" :"link.circle")
                    .resizable()
                    .frame(width: size_30, height: size_30)
                    .foregroundColor(isWebInputVisible ? .hlRed : Color(.systemGray))
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .disabled(isOptimizing || isTranslating)
        .frame(width: size_30, height: size_30)
    }

    // MARK: - 清空按钮
    private func clearButton() -> some View {
        Button(action: {
            isFeedBack.toggle()
            showAlert = true
        }) {
            Image(systemName: "trash.circle")
                .resizable()
                .frame(width: size_30, height: size_30)
                .foregroundColor(Color(.systemGray))
        }
        .alert("确认清空所有文本？", isPresented: $showAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) { message = "" }
        }
    }

    // MARK: - 计算 Token 数量
    private func tokenCounter() -> some View {
        VStack(alignment: .trailing) {
            Text("\(message.count) 字").font(.caption).foregroundColor(.gray)
            Text("约 \(estimatedTokens) tokens").font(.caption).foregroundColor(.gray)
        }
    }
    
    // MARK: 网页解析
    private func processWeb() {
        isWeb = true
        Task {
            guard !webInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "请输入有效的网页 URL"
                showErrorAlert = true
                isWeb = false
                return
            }
            original = message
            // 支持多 URL 输入：按空格或换行分隔
            let urls = webInput.components(separatedBy: CharacterSet.whitespacesAndNewlines).filter { !$0.isEmpty }
            let webPages = await fetchWebPageContent(from: urls)
            var webContentCombined = ""
            for webPage in webPages {
                webContentCombined.append("\(webPage.content.trimmingCharacters(in: .whitespacesAndNewlines))")
            }
            message.append("\n" + webContentCombined)
            webDocumented = true
            
            webInput = ""
        }
        isWeb = false
    }
    
    // MARK: 文档解析
    private func processDocument() {
        isDocument = true
        Task {
            defer {
                Task { @MainActor in
                    isDocument = false
                }
            }

            guard let fileURL = selectedDocumentURL else {
                await MainActor.run {
                    errorMessage = "请先选择文件"
                    showErrorAlert = true
                }
                return
            }

            // 检查文件大小（防止超大文件导致崩溃）
            guard let fileSize = try? FileManager.default
                .attributesOfItem(atPath: fileURL.path)[.size] as? Int64 else {
                await MainActor.run {
                    errorMessage = "无法读取文件信息"
                    showErrorAlert = true
                }
                return
            }

            let maxFileSize: Int64 = 10 * 1024 * 1024  // 10MB 限制
            if fileSize > maxFileSize {
                let sizeMB = Double(fileSize) / 1024.0 / 1024.0
                await MainActor.run {
                    errorMessage = String(format: "文件过大（%.1fMB），最大支持 10MB", sizeMB)
                    showErrorAlert = true
                }
                return
            }

            await MainActor.run {
                documented = false
                original = message
            }

            do {
                let documentContent = try await extractContent(from: fileURL)
                await MainActor.run {
                    message.append("\n" + documentContent)
                    documented = true
                    selectedDocumentURL = nil  // 清空已处理的 URL
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }

    // MARK: - 文本优化
    private func optimizeMessage() {
        isFeedBack.toggle()
        Task {
            if optimized {
                if !original.isEmpty {
                    message = original
                }
                optimized = false
            } else {
                optimized = false
                isOptimizing = true // 开始优化
                original = message // 保留原句
                if !message.isEmpty {
                    do {
                        let optimizer = SystemOptimizer(context: modelContext)
                        optimizedMessage = try await optimizer.optimizeContent(inputContent: message)
                        message = optimizedMessage
                        optimized = true
                    } catch {
                        errorMessage = error.localizedDescription // 捕获错误信息
                        showErrorAlert = true // 显示错误弹窗
                    }
                }
                knowledgeRecord.isEmbedding = false
                embeddingCompleted = false
                isOptimizing = false // 优化结束
            }
        }
    }

    // MARK: - 翻译
    private func translateMessage() {
        isFeedBack.toggle()
        Task {
            if translated {
                if !original.isEmpty {
                    message = original
                }
                translated = false
            } else {
                translated = false
                isTranslating = true // 开始优化
                original = message // 保留原句
                if !message.isEmpty {
                    do {
                        let optimizer = SystemOptimizer(context: modelContext)
                        translatedMessage = try await optimizer.translatePrompt(inputPrompt: message)
                        message = translatedMessage
                        translated = true
                    } catch {
                        errorMessage = error.localizedDescription // 捕获错误信息
                        showErrorAlert = true // 显示错误弹窗
                    }
                }
                isTranslating = false // 优化结束
            }
        }
    }

    // MARK: - Token 计算
    private func estimateTokens(for text: String) -> Int {
        let wordCount = text.split { $0.isWhitespace || $0.isPunctuation }.count
        return Int(ceil(Double(wordCount) * 1.2))
    }
    
    // MARK: OCR 扫描
    private func processOCR() {
        Task {
            guard let image = ocrImage else {
                errorMessage = "请先选择或拍摄一张图片"
                showErrorAlert = true
                isOCR = false
                return
            }
            
            ocred = false
            isOCR = true
            original = message
            
            do {
                let optimizer = SystemOptimizer(context: modelContext)
                let ocrMessage = try await optimizer.ocrPrompt(inputImage: image)
                message.append("\n")
                message.append(ocrMessage)
                ocred = true
            } catch {
                errorMessage = error.localizedDescription // 捕获错误信息
                showErrorAlert = true // 显示错误弹窗
            }
            isOCR = false // 优化结束
        }
    }
    
    // MARK: 资源选择区域
    private var sourceSelector: some View {
        HStack(spacing: 6) {
            Button(action: {
                isFeedBack.toggle()
                showCameraPicker = true
            }) {
                VStack {
                    Image(systemName: "camera.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.hlBluefont)
                        .symbolEffect(.bounce, value: showCameraPicker)
                    Text("拍摄照片")
                        .font(.caption.bold())
                        .foregroundColor(.hlBluefont)
                        .padding(.top, 3)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.hlBlue.opacity(0.1))
                .cornerRadius(size_20)
            }
            .sensoryFeedback(.impact, trigger: isFeedBack)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showPhotoSourceOptions)
            // 打开相机
            .sheet(isPresented: $showCameraPicker) {
                OCRImagePicker(ocrImage: $ocrImage, sourceType: .camera)
                    .background(.black)
            }
            
            Button(action: {
                isFeedBack.toggle()
                showImagePicker = true
            }) {
                VStack {
                    Image(systemName: "photo.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.hlBluefont)
                        .symbolEffect(.bounce, value: showImagePicker)
                    Text("相册选择")
                        .font(.caption.bold())
                        .foregroundColor(.hlBluefont)
                        .padding(.top, 3)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color.hlBlue.opacity(0.1))
                .cornerRadius(size_20)
            }
            .sensoryFeedback(.impact, trigger: isFeedBack)
            .transition(.opacity.combined(with: .move(edge: .top)))
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showPhotoSourceOptions)
            // 打开相册
            .sheet(isPresented: $showImagePicker) {
                OCRImagePicker(ocrImage: $ocrImage, sourceType: .photoLibrary)
                    .ignoresSafeArea()
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showPhotoSourceOptions)
    }
    
    private func startEmbedding() {
        guard !knowledgeRecord.isEmbedding else { return }
        isEmbedding = true

        Task {
            do {
                let content = knowledgeRecord.content ?? ""
                let lines = content.components(separatedBy: .newlines)
                var chunks: [String] = []
                var currentChunk = ""
                var currentLevel1: String? = nil
                var currentLevel2: String? = nil

                // 辅助函数：统计行首连续 '#' 数量
                func headerLevel(of line: String) -> Int {
                    var count = 0
                    for ch in line {
                        if ch == "#" { count += 1 } else { break }
                    }
                    return count
                }

                // 辅助函数：判断 chunk 是否包含正文（非标题且非空）
                func chunkHasBody(_ chunk: String) -> Bool {
                    let chunkLines = chunk.components(separatedBy: "\n")
                    if let firstLine = chunkLines.first,
                       firstLine.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                        let level = headerLevel(of: firstLine)
                        var startIndex = 1
                        if level == 1, chunkLines.count > 1,
                           chunkLines[1].trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                            startIndex = 2
                        }
                        for i in startIndex..<chunkLines.count {
                            let line = chunkLines[i].trimmingCharacters(in: .whitespaces)
                            if !line.isEmpty && !line.hasPrefix("#") {
                                return true
                            }
                        }
                        return false
                    }
                    return true
                }

                // 根据标题规则构造初步 chunk
                for line in lines {
                    let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedLine.hasPrefix("#") {
                        let level = headerLevel(of: trimmedLine)
                        if level == 1 {
                            if !currentChunk.isEmpty {
                                chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                            }
                            currentLevel1 = trimmedLine
                            currentLevel2 = nil
                            currentChunk = trimmedLine
                            continue
                        } else if level == 2 {
                            if !currentChunk.isEmpty {
                                chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                            }
                            currentLevel2 = trimmedLine
                            if let l1 = currentLevel1 {
                                currentChunk = l1 + "\n" + trimmedLine
                            } else {
                                currentChunk = trimmedLine
                            }
                            continue
                        } else if level == 3 {
                            if !currentChunk.isEmpty {
                                chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                            }
                            var headerContext = ""
                            if let l1 = currentLevel1 { headerContext += l1 + "\n" }
                            if let l2 = currentLevel2 { headerContext += l2 + "\n" }
                            headerContext += trimmedLine
                            currentChunk = headerContext
                            continue
                        }
                    }
                    if currentChunk.isEmpty {
                        currentChunk = trimmedLine
                    } else {
                        currentChunk += "\n" + trimmedLine
                    }
                }
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                }

                // 过滤掉仅包含标题但无正文的 chunk（如果存在其他正文内容）
                let bodyChunksCount = chunks.filter { chunkHasBody($0) }.count
                if bodyChunksCount > 0 {
                    chunks = chunks.filter { chunk in
                        let linesInChunk = chunk.components(separatedBy: "\n")
                        if let firstLine = linesInChunk.first,
                           firstLine.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                            let level = headerLevel(of: firstLine)
                            if (level == 1 || level == 2) && !chunkHasBody(chunk) {
                                return false
                            }
                        }
                        return true
                    }
                }

                // 针对正文超长的 chunk 进行拆分：在换行符处断开，并确保重叠部分为完整行
                let maxChunkLength = 1000
                let overlapMinLength = 200
                let refinedChunks: [String] = chunks.flatMap { chunk -> [String] in
                    if chunk.count <= maxChunkLength { return [chunk] }
                    
                    // 提取开头连续的标题行（只处理开头部分的标题，后续内容均视为正文）
                    let allLines = chunk.components(separatedBy: "\n")
                    var headerLines: [String] = []
                    var bodyLines: [String] = []
                    var reachedBody = false
                    for line in allLines {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if !reachedBody && trimmed.hasPrefix("#") {
                            headerLines.append(line)
                        } else {
                            reachedBody = true
                            bodyLines.append(line)
                        }
                    }
                    let headerText = headerLines.joined(separator: "\n")
                    
                    // 使用累积行的方式构造子段，保证在换行处分段
                    var segments: [String] = []
                    var currentSegmentLines: [String] = []
                    var currentLength = 0
                    var idx = 0
                    func flushSegment() {
                        if !currentSegmentLines.isEmpty {
                            let segmentBody = currentSegmentLines.joined(separator: "\n")
                            let segment = headerText.isEmpty ? segmentBody : headerText + "\n" + segmentBody
                            segments.append(segment.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                    }
                    while idx < bodyLines.count {
                        let line = bodyLines[idx]
                        // 计算当前行长度（包含换行符）
                        let lineLen = line.count + 1
                        if currentLength + lineLen <= maxChunkLength {
                            currentSegmentLines.append(line)
                            currentLength += lineLen
                            idx += 1
                        } else {
                            // 达到拆分要求，在当前换行处结束当前子段
                            flushSegment()
                            // 计算重叠部分：从当前段末尾向上累计足够 overlapMinLength 的完整行
                            var overlapLines: [String] = []
                            var overlapLength = 0
                            for overlapLine in currentSegmentLines.reversed() {
                                overlapLines.insert(overlapLine, at: 0)
                                overlapLength += overlapLine.count + 1
                                if overlapLength >= overlapMinLength { break }
                            }
                            currentSegmentLines = overlapLines
                            currentLength = currentSegmentLines.reduce(0) { $0 + $1.count + 1 }
                        }
                    }
                    flushSegment()
                    return segments
                }

                // 模型和 API Key 校验
                guard let model = selectedEmbeddingModel else {
                    throw NSError(domain: "EmbeddingAPI", code: -4,
                                  userInfo: [NSLocalizedDescriptionKey: "请先选择嵌入模型"])
                }
                guard let apiInfo = allApiKeys.first(where: { $0.company == selectedEmbeddingModel?.company }) else {
                    throw NSError(domain: "SummaryView", code: 404,
                                  userInfo: [NSLocalizedDescriptionKey: "无法获取 API Key"])
                }

                // 每批最多 10 个 chunk
                let batchSize = 10
                var embeddings: [[Float]] = []
                for i in stride(from: 0, to: refinedChunks.count, by: batchSize) {
                    let end = min(i + batchSize, refinedChunks.count)
                    let batch = Array(refinedChunks[i..<end])
                    let batchEmbeddings = try await generateEmbeddings(
                        for: batch,
                        modelName: model.name,
                        apiKey: apiInfo.key ?? "",
                        apiURL: model.requestURL
                    )
                    embeddings.append(contentsOf: batchEmbeddings)
                }

                // 清除旧的 chunk 并保存新的嵌入结果
                if let oldChunks = knowledgeRecord.chunks {
                    for chunk in oldChunks {
                        modelContext.delete(chunk)
                    }
                    knowledgeRecord.chunks?.removeAll()
                } else {
                    knowledgeRecord.chunks = []
                }
                for (index, chunk) in refinedChunks.enumerated() {
                    let vector = embeddings[index]
                    let chunkModel = KnowledgeChunk(
                        text: chunk,
                        vector: vector,
                        knowledgeRecord: knowledgeRecord
                    )
                    knowledgeRecord.chunks?.append(chunkModel)
                }

                knowledgeRecord.isEmbedding = true
                knowledgeRecord.lastEdited = Date()
                try modelContext.save()
                embeddingCompleted = true
            } catch {
                print("嵌入失败：\(error)")
            }
            isEmbedding = false
        }
    }
}
