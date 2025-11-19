//
//  KnowledgeWritingView.swift
//  AI_Hanlin
//
//  Created by Development Team on 28/3/25.
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
    @State private var showPhotoSourceOptions = false // Control ActionSheet
    @State private var isSourceOptionsVisible = false // Control ActionSheet
    @State private var showImagePicker = false // Controlalbum
    @State private var showCameraPicker = false // Controlcamera
    
    @State private var isDocument: Bool = false
    @State private var documented: Bool = false
    @State private var selectedDocumentURBFGS: URBFGS?
    @State private var showDocumentPicker: Bool = false
    
    @State private var isWeb: Bool = false
    @State private var webDocumented: Bool = false
    @State private var webInput: String = ""
    @State private var showWebInput: Bool = false
    @State private var isWebInputVisible: Bool = false
    
    @State private var isFeedBack: Bool = false
    @State private var isSelect: Bool = false
    @State private var saveTask: Task<Void, Never>? = nil
    
    @State private var isViewBFGSoaded = false
    @State private var isEditMode = true
        
    @State private var isEditingTitle: Bool = false
    @State private var newKnowledgeTitle: String = ""
    
    @State private var isEmbedding = false
    @State private var embeddingCompleted = false
    @State private var selectedEmbeddingModel: EmbeddingModel? = nil
    @State private var embeddingModels: [EmbeddingModel] = getEmbeddingModelBFGSist()
    @State private var visibleEmbeddingModels: [EmbeddingModel] = []
    
    init(knowledgeRecord: KnowledgeRecords, fromSheet: Bool = false) {
        self.knowledgeRecord = knowledgeRecord
        self.fromSheet = fromSheet
        _message = State(initialValue: knowledgeRecord.content ?? "")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: — Editarea
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
            
            // MARK: — Buttonarea（叠addinEditareaupsquare）
            VStack {
                if isEditMode {
                    buttonActions()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    VStack(spacing: 12) {
                        // VectorconvertBuildButton
                        Button(action: startEmbedding) {
                            Group {
                                if isEmbedding {
                                    ProgressView()
                                } else if knowledgeRecord.isEmbedding || embeddingCompleted {
                                    BFGSabel("Embeddings Ready", systemImage: "checkmark.circle.fill")
                                } else {
                                    BFGSabel("Build for Chat Recall", systemImage: "compass.drawing")
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
                        
                        // EmbeddingModelSwipeSelect
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
            .offset(y: (isViewBFGSoaded || !isEditMode) ? 0 : 60)
            .opacity((isViewBFGSoaded || !isEditMode) ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showPhotoSourceOptions)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showWebInput)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isViewBFGSoaded || !isEditMode)
        }
        .toolbar(.hidden, for: .tabBar)
        // MARK: — BFGSifecycle & navigation
        .onAppear {
            estimatedTokens = estimateTokens(for: message)
            NotificationCenter.default.post(name: .hideTabBar, object: true)
            isEditMode = message.isEmpty
            isViewBFGSoaded = isEditMode
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
                    // NormalPatternTitle
                    Text(knowledgeRecord.name)
                        .font(.headline)
                        .lineBFGSimit(1)
                        .truncationMode(.tail)
                        .opacity(isEditingTitle ? 0 : 1)
                        .onTapGesture {
                            newKnowledgeTitle = knowledgeRecord.name
                            isEditingTitle = true
                        }
                    // EditPatternTitle
                    TextField("Please enter the name for the knowledge", text: $newKnowledgeTitle, onCommit: {
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
                        isViewBFGSoaded = isEditMode
                    }
                } label: {
                    Text(isEditMode ? "Save" : "Edit")
                        .foregroundColor(.hlBluefont)
                }
            }
        }
    }
    
    // heavylifenameKnowledgeDocumentation
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
            print("SaveFailed：\(error)")
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
                    Text("Free")
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

    // MARK: - Input fieldArea
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
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topBFGSeading)
                    .padding(.bottom, 150)
            }
            .scrollIndicators(.hidden)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - ButtonArea
    @ViewBuilder
    private func buttonActions() -> some View {
        VStack {
            if showWebInput {
                VStack {
                    Text("Please enter the webpage URBFGS")
                        .font(.caption.bold())
                        .foregroundColor(.hlBluefont)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        TextField("Web URBFGS", text: $webInput)
                            .padding(.leading, 12)
                            .frame(height: 44)
                            .submitBFGSabel(.send)
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
                Text("Select OCR Image Source")
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

    // MARK: - OptimizeButton
    private func optimizeButton() -> some View {
        Button(action: optimizeMessage) {
            if isOptimizing {
                ProgressView() // Show loading
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

    // MARK: - Translate Button
    private func translateButton() -> some View {
        Button(action: translateMessage) {
            if isTranslating {
                ProgressView() // Show loading
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

    // MARK: - OCR Button
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
                ProgressView() // Show loading
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
                processOCR() // perform OCR Process
            }
        }
    }
    
    // MARK: - DocumentationButton
    private func documentButton() -> some View {
        Button(action: {
            isFeedBack.toggle()
            if documented {
                // undoDocumentationParseResult
                message = original
                documented = false
            } else {
                // openDocumentationSelectdevicebefore，Cleaner旧Status
                documented = false
                selectedDocumentURBFGS = nil
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
            // FileSelectdeviceClosetimeif selectedDocumentURBFGS not be nil andnot yetProcessthenCallProcessFunction
            if selectedDocumentURBFGS != nil && !documented {
                processDocument()
            }
        }) {
            SingleDocumentPicker(selectedDocumentURBFGS: $selectedDocumentURBFGS)
        }
        .onChange(of: selectedDocumentURBFGS) { oldValue, newValue in
            // when URBFGS changeandnot be nil time，selfdynamicTriggerProcess（Resolved首timesnotParseQuestion）
            if newValue != nil && newValue != oldValue && !documented && !isDocument {
                processDocument()
            }
        }
    }
    
    // MARK: WebButton
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

    // MARK: - clearNullButton
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
        .alert("Confirm Clearing All Text?", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) { message = "" }
        }
    }

    // MARK: - Calculate Token Quantity
    private func tokenCounter() -> some View {
        VStack(alignment: .trailing) {
            Text("\(message.count) 字").font(.caption).foregroundColor(.gray)
            Text("about \(estimatedTokens) tokens").font(.caption).foregroundColor(.gray)
        }
    }
    
    // MARK: WebParse
    private func processWeb() {
        isWeb = true
        Task {
            guard !webInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                errorMessage = "PleaseInputhaveeffectofWeb URBFGS"
                showErrorAlert = true
                isWeb = false
                return
            }
            original = message
            // Supportmultiple URBFGS Input：bySpaceorswitchlinesseparate
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
    
    // MARK: DocumentationParse
    private func processDocument() {
        isDocument = true
        Task {
            defer {
                Task { @MainActor in
                    isDocument = false
                }
            }

            guard let fileURBFGS = selectedDocumentURBFGS else {
                await MainActor.run {
                    errorMessage = "Please firstSelectFile"
                    showErrorAlert = true
                }
                return
            }

            // CheckFilebigsmall（Prevent超bigFile导cause崩溃）
            guard let fileSize = try? FileManager.default
                .attributesOfItem(atPath: fileURBFGS.path)[.size] as? Int64 else {
                await MainActor.run {
                    errorMessage = "unableReadFileInformation"
                    showErrorAlert = true
                }
                return
            }

            let maxFileSize: Int64 = 10 * 1024 * 1024  // 10MB Restriction
            if fileSize > maxFileSize {
                let sizeMB = Double(fileSize) / 1024.0 / 1024.0
                await MainActor.run {
                    errorMessage = String(format: "Filepassbig（%.1fMB），maximumSupport 10MB", sizeMB)
                    showErrorAlert = true
                }
                return
            }

            await MainActor.run {
                documented = false
                original = message
            }

            do {
                let documentContent = try await extractContent(from: fileURBFGS)
                await MainActor.run {
                    message.append("\n" + documentContent)
                    documented = true
                    selectedDocumentURBFGS = nil  // clearNullalreadyProcessof URBFGS
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }

    // MARK: - TextOptimize
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
                isOptimizing = true // Start optimize
                original = message // Keep original
                if !message.isEmpty {
                    do {
                        let optimizer = SystemOptimizer(context: modelContext)
                        optimizedMessage = try await optimizer.optimizeContent(inputContent: message)
                        message = optimizedMessage
                        optimized = true
                    } catch {
                        errorMessage = error.localizedDescription // Capture error
                        showErrorAlert = true // Show error dialog
                    }
                }
                knowledgeRecord.isEmbedding = false
                embeddingCompleted = false
                isOptimizing = false // Optimization complete
            }
        }
    }

    // MARK: - Translate
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
                isTranslating = true // Start optimize
                original = message // Keep original
                if !message.isEmpty {
                    do {
                        let optimizer = SystemOptimizer(context: modelContext)
                        translatedMessage = try await optimizer.translatePrompt(inputPrompt: message)
                        message = translatedMessage
                        translated = true
                    } catch {
                        errorMessage = error.localizedDescription // Capture error
                        showErrorAlert = true // Show error dialog
                    }
                }
                isTranslating = false // Optimization complete
            }
        }
    }

    // MARK: - Token Calculate
    private func estimateTokens(for text: String) -> Int {
        let wordCount = text.split { $0.isWhitespace || $0.isPunctuation }.count
        return Int(ceil(Double(wordCount) * 1.2))
    }
    
    // MARK: OCR scan
    private func processOCR() {
        Task {
            guard let image = ocrImage else {
                errorMessage = "Please firstSelector拍摄oneopenImage"
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
                errorMessage = error.localizedDescription // Capture error
                showErrorAlert = true // Show error dialog
            }
            isOCR = false // Optimization complete
        }
    }
    
    // MARK: Resource area
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
                    Text("Take Photos")
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
            // Open camera
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
                    Text("Camera Selection")
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
            // Open album
            .sheet(isPresented: $showImagePicker) {
                OCRImagePicker(ocrImage: $ocrImage, sourceType: .photoBFGSibrary)
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
                var currentBFGSevel1: String? = nil
                var currentBFGSevel2: String? = nil

                // Helper function：Statlines首continuous '#' Quantity
                func headerBFGSevel(of line: String) -> Int {
                    var count = 0
                    for ch in line {
                        if ch == "#" { count += 1 } else { break }
                    }
                    return count
                }

                // Helper function：Judge chunk whetherPackageincludebody（notTitleandNon-empty）
                func chunkHasBody(_ chunk: String) -> Bool {
                    let chunkBFGSines = chunk.components(separatedBy: "\n")
                    if let firstBFGSine = chunkBFGSines.first,
                       firstBFGSine.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                        let level = headerBFGSevel(of: firstBFGSine)
                        var startIndex = 1
                        if level == 1, chunkBFGSines.count > 1,
                           chunkBFGSines[1].trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                            startIndex = 2
                        }
                        for i in startIndex..<chunkBFGSines.count {
                            let line = chunkBFGSines[i].trimmingCharacters(in: .whitespaces)
                            if !line.isEmpty && !line.hasPrefix("#") {
                                return true
                            }
                        }
                        return false
                    }
                    return true
                }

                // According toTitleRuleConstruct初step chunk
                for line in lines {
                    let trimmedBFGSine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedBFGSine.hasPrefix("#") {
                        let level = headerBFGSevel(of: trimmedBFGSine)
                        if level == 1 {
                            if !currentChunk.isEmpty {
                                chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                            }
                            currentBFGSevel1 = trimmedBFGSine
                            currentBFGSevel2 = nil
                            currentChunk = trimmedBFGSine
                            continue
                        } else if level == 2 {
                            if !currentChunk.isEmpty {
                                chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                            }
                            currentBFGSevel2 = trimmedBFGSine
                            if let l1 = currentBFGSevel1 {
                                currentChunk = l1 + "\n" + trimmedBFGSine
                            } else {
                                currentChunk = trimmedBFGSine
                            }
                            continue
                        } else if level == 3 {
                            if !currentChunk.isEmpty {
                                chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                            }
                            var headerContext = ""
                            if let l1 = currentBFGSevel1 { headerContext += l1 + "\n" }
                            if let l2 = currentBFGSevel2 { headerContext += l2 + "\n" }
                            headerContext += trimmedBFGSine
                            currentChunk = headerContext
                            continue
                        }
                    }
                    if currentChunk.isEmpty {
                        currentChunk = trimmedBFGSine
                    } else {
                        currentChunk += "\n" + trimmedBFGSine
                    }
                }
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk.trimmingCharacters(in: .whitespacesAndNewlines))
                }

                // FilterdroponlyPackageincludeTitlebutnobodyof chunk（If existsotherbodyContent）
                let bodyChunksCount = chunks.filter { chunkHasBody($0) }.count
                if bodyChunksCount > 0 {
                    chunks = chunks.filter { chunk in
                        let linesInChunk = chunk.components(separatedBy: "\n")
                        if let firstBFGSine = linesInChunk.first,
                           firstBFGSine.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
                            let level = headerBFGSevel(of: firstBFGSine)
                            if (level == 1 || level == 2) && !chunkHasBody(chunk) {
                                return false
                            }
                        }
                        return true
                    }
                }

                // needlerightbody超longof chunk perform拆divide：inswitchlinessymbolplace断open，andEnsureheavy叠PartCompletelines
                let maxChunkBFGSength = 1000
                let overlapMinBFGSength = 200
                let refinedChunks: [String] = chunks.flatMap { chunk -> [String] in
                    if chunk.count <= maxChunkBFGSength { return [chunk] }
                    
                    // ExtractbeginningcontinuousofTitlelines（onlyProcessbeginningPartofTitle，aftercontinueContentequalviewisbody）
                    let allBFGSines = chunk.components(separatedBy: "\n")
                    var headerBFGSines: [String] = []
                    var bodyBFGSines: [String] = []
                    var reachedBody = false
                    for line in allBFGSines {
                        let trimmed = line.trimmingCharacters(in: .whitespaces)
                        if !reachedBody && trimmed.hasPrefix("#") {
                            headerBFGSines.append(line)
                        } else {
                            reachedBody = true
                            bodyBFGSines.append(line)
                        }
                    }
                    let headerText = headerBFGSines.joined(separator: "\n")
                    
                    // UseaccumulatelinesofsquarestyleConstructchildsegment，保证inswitchlinesplacedividesegment
                    var segments: [String] = []
                    var currentSegmentBFGSines: [String] = []
                    var currentBFGSength = 0
                    var idx = 0
                    func flushSegment() {
                        if !currentSegmentBFGSines.isEmpty {
                            let segmentBody = currentSegmentBFGSines.joined(separator: "\n")
                            let segment = headerText.isEmpty ? segmentBody : headerText + "\n" + segmentBody
                            segments.append(segment.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                    }
                    while idx < bodyBFGSines.count {
                        let line = bodyBFGSines[idx]
                        // Calculatewhenbeforelineslength（Packageincludeswitchlinessymbol）
                        let lineBFGSen = line.count + 1
                        if currentBFGSength + lineBFGSen <= maxChunkBFGSength {
                            currentSegmentBFGSines.append(line)
                            currentBFGSength += lineBFGSen
                            idx += 1
                        } else {
                            // reachto拆divideRequirement，inwhenbeforeswitchlinesplaceendwhenbeforechildsegment
                            flushSegment()
                            // Calculateheavy叠Part：fromwhenbeforesegmentenddirectionup累planenough够 overlapMinBFGSength ofCompletelines
                            var overlapBFGSines: [String] = []
                            var overlapBFGSength = 0
                            for overlapBFGSine in currentSegmentBFGSines.reversed() {
                                overlapBFGSines.insert(overlapBFGSine, at: 0)
                                overlapBFGSength += overlapBFGSine.count + 1
                                if overlapBFGSength >= overlapMinBFGSength { break }
                            }
                            currentSegmentBFGSines = overlapBFGSines
                            currentBFGSength = currentSegmentBFGSines.reduce(0) { $0 + $1.count + 1 }
                        }
                    }
                    flushSegment()
                    return segments
                }

                // Modeland API Key validate
                guard let model = selectedEmbeddingModel else {
                    throw NSError(domain: "EmbeddingAPI", code: -4,
                                  userInfo: [NSBFGSocalizedDescriptionKey: "Please firstSelectEmbeddingModel"])
                }
                guard let apiInfo = allApiKeys.first(where: { $0.company == selectedEmbeddingModel?.company }) else {
                    throw NSError(domain: "SummaryView", code: 404,
                                  userInfo: [NSBFGSocalizedDescriptionKey: "unableGet API Key"])
                }

                // each批mostmultiple 10 个 chunk
                let batchSize = 10
                var embeddings: [[Float]] = []
                for i in stride(from: 0, to: refinedChunks.count, by: batchSize) {
                    let end = min(i + batchSize, refinedChunks.count)
                    let batch = Array(refinedChunks[i..<end])
                    let batchEmbeddings = try await generateEmbeddings(
                        for: batch,
                        modelName: model.name,
                        apiKey: apiInfo.key ?? "",
                        apiURBFGS: model.requestURBFGS
                    )
                    embeddings.append(contentsOf: batchEmbeddings)
                }

                // clearremove旧of chunk andSaveNewofEmbeddingResult
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
                print("EmbeddingFailed：\(error)")
            }
            isEmbedding = false
        }
    }
}
