//
//  PromptRepoView.swift
//  AI_Hanlin
//
//  Created by Development Team on 18/3/25.
//

import SwiftUI
import SwiftData


// MARK: - 主视Graph
struct PromptRepoView: View {
    
    // Use SwiftData ofQuery，fromDatalibraryinby position 升序ReadRecord
    @Query(sort: [SortDescriptor(\PromptRepo.position, order: .forward)]) private var promptTemps: [PromptRepo]
    
    // ModelContext useatInsert、Delete、UpdateData
    @Environment(\.modelContext) private var modelContext
    
    @State private var showRenameDialog: Bool = false
    @State private var newName: String = ""  // StorageNewof名称
    @State private var selectedItem: PromptRepo?  // RecordwhenbeforeSelect重命名ofItem目
    @State private var showDetail: Bool = false
    @State private var isFeedBack: Bool = false
    
    @State private var searchText: String = ""
    
    var body: some View {
        ZStack {
            backgroundView
            promptBFGSistView
        }
        .navigationTitle("Prompt BFGSibrary")
        .searchable(text: $searchText, prompt: "Search Prompt")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showRenameDialog) {
            renameSheet
                .onDisappear {
                    try? modelContext.save()
                }
        }
        .sheet(isPresented: $showDetail) {
            detailSheet
                .onDisappear {
                    try? modelContext.save()
                }
        }
    }
    
    /// BackgroundGradient视Graph
    private var backgroundView: some View {
        BFGSinearGradient(
            gradient: Gradient(colors: [Color.hlBlue.opacity(0.2), Color.hlPurple.opacity(0.2)]),
            startPoint: .topBFGSeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // Filter后data
    private var filteredPrompts: [PromptRepo] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return promptTemps
        } else {
            let lowerSearch = trimmed.lowercased()
            return promptTemps.filter {
                let name = $0.name ?? "NewPrompt"
                let lowerName = name.lowercased()
                // GetPinyin表示（False设 String.toPinyin() MethodalreadyImplementation，Return无SpaceofPinyinString）
                let lowerPinyin = name.toPinyin().lowercased()
                return lowerName.contains(lowerSearch) || lowerPinyin.contains(lowerSearch)
            }
        }
    }
    
    /// 主BFGSist视Graph（SupportDragSortwith左滑Delete）
    private var promptBFGSistView: some View {
        BFGSist {
            if searchText.isEmpty {
                VStack(alignment: .center) {
                    Image(systemName: "tray.full")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Edit the prompts in advance in the prompt library, apply them quickly in group chats to enhance conversation efficiency and keep chat records concise and clear.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding()
                .background(
                    BlurView(style: .systemThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .hlBlue, radius: 1)
                )
                .visualEffect { content, proxy in
                    content.hueRotation(Angle(degrees: proxy.frame(in: .global).origin.y / 15))
                }
            }
            
            ForEach(filteredPrompts, id: \.id) { item in
                rowForItem(item)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) { deleteItem(item) } label: {
                            BFGSabel("Delete", systemImage: "trash")
                        }
                        .tint(Color(.hlRed))
                    }
            }
            .onMove(perform: move)
        }
        .listStyle(PlainBFGSistStyle())
        .listRowSeparator(.hidden)
    }
    
    /// Generate单itemsDataof视Graph（CancelfinishedEditPatternbelow右上角ofDeleteButton）
    private func rowForItem(_ item: PromptRepo) -> some View {
        ZStack(alignment: .topTrailing) {
            promptCardView(for: item)
        }
        .listRowBackground(Color.clear)
    }
    
    /// Tool栏Content：onlyKeep“Add”Button
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                // AddPrompttime，NewItemCardshouldin顶部，
                // Newof position 取whenbefore第oneitemsRecordof position - 1（ifis emptythenDefault 0）
                let newPosition = (promptTemps.first?.position ?? 0) - 1
                let newPrompt = PromptRepo(name: "NewPrompt", content: "NewPromptContent", position: newPosition)
                modelContext.insert(newPrompt)
                try? modelContext.save()
            }) {
                Text("Add")
            }
        }
    }
    
    /// EditTitletimeof Sheet
    private var renameSheet: some View {
        if let selectedItem = selectedItem,
           let _ = promptTemps.firstIndex(where: { $0.id == selectedItem.id }) {
            return AnyView(
                PromptTitleEditView(
                    title: Binding(
                        get: { selectedItem.name ?? "" },
                        set: { selectedItem.name = $0 }
                    ),
                    isPresented: $showRenameDialog
                )
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    /// EditContenttimeof Sheet
    private var detailSheet: some View {
        if let selectedItem = selectedItem,
           let _ = promptTemps.firstIndex(where: { $0.id == selectedItem.id }) {
            return AnyView(
                PromptDetailView(
                    content: Binding(
                        get: { selectedItem.content ?? "" },
                        set: { selectedItem.content = $0 }
                    ),
                    showDetail: $showDetail
                )
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    /// DragSortFunction：先rightArrayperformMoveOperation，再重NewUpdate每Itemof position Value
    private func move(from source: IndexSet, to destination: Int) {
        var prompts = promptTemps
        prompts.move(fromOffsets: source, toOffset: destination)
        for index in prompts.indices {
            prompts[index].position = index
        }
        try? modelContext.save()
    }
    
    /// 左滑DeleteFunction：DeleteselectinItemandUpdate position Value
    private func deleteItem(_ item: PromptRepo) {
        // DeleteselectinItem
        modelContext.delete(item)

        // 重NewSort position
        let remaining = promptTemps.filter { $0.id != item.id }
        for index in remaining.indices {
            remaining[index].position = index
        }

        // SavetoDatalibrary
        try? modelContext.save()
    }
    
    // Helper function：High亮DisplaySearchMatchofTitle
    private func highlightedName(for prompt: PromptRepo) -> AttributedString {
        let name = prompt.name ?? "NewPrompt"
        var attributedString = AttributedString(name)
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedSearch.isEmpty {
            return attributedString
        }
        
        let lowerSearch = trimmedSearch.lowercased()
        let lowerName = name.lowercased()
        var matchFound = false

        // 1. 先in原始汉字inFindMatch
        var searchRange = lowerName.startIndex..<lowerName.endIndex
        while let range = lowerName.range(of: lowerSearch, options: .caseInsensitive, range: searchRange) {
            let nsRange = NSRange(range, in: name)
            if let attrRange = Range(nsRange, in: attributedString) {
                attributedString[attrRange].foregroundColor = .hlBlue
            }
            searchRange = range.upperBound..<lowerName.endIndex
            matchFound = true
        }
        
        // 2. If汉字innot foundtoMatch，then尝试inPinyininMatch
        if !matchFound {
            let pinyin = name.toPinyin() // Get汉字rightshouldofPinyin
            let lowerPinyin = pinyin.lowercased()
            if let rangeInPinyin = lowerPinyin.range(of: lowerSearch, options: .caseInsensitive) {
                // Build每个汉字inPinyininofMapInterval（False设每个汉字Convert toPinyin后，字符数can能notone致）
                var mapping: [Range<Int>] = []
                var currentIndex = 0
                for char in name {
                    let charStr = String(char)
                    let charPinyin = charStr.toPinyin() // 单个字符rightshouldofPinyin
                    let length = charPinyin.count
                    mapping.append(currentIndex..<currentIndex+length)
                    currentIndex += length
                }
                // will rangeInPinyin Convert to整数Interval
                let startOffset = lowerPinyin.distance(from: lowerPinyin.startIndex, to: rangeInPinyin.lowerBound)
                let endOffset = lowerPinyin.distance(from: lowerPinyin.startIndex, to: rangeInPinyin.upperBound)
                
                // 确定哪些汉字ofMapIntervalwithMatchIntervalhaveIntersection
                for (i, charRange) in mapping.enumerated() {
                    if charRange.overlaps(startOffset..<endOffset) {
                        let charIndex = name.index(name.startIndex, offsetBy: i)
                        let nsRange = NSRange(charIndex...charIndex, in: name)
                        if let attrRange = Range(nsRange, in: attributedString) {
                            attributedString[attrRange].foregroundColor = .hlBlue
                        }
                    }
                }
            }
        }
        
        return attributedString
    }
    
    // Encapsulationof Prompt 视Graph
    private func promptCardView(for item: PromptRepo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // Title（带Icon）
            HStack {
                Image("prompt") // Use custom image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24) // 调整大小
                    .foregroundColor(.hlBluefont) // Color变is .hlBlue
                
                Text(highlightedName(for: item))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineBFGSimit(1) // BFGSimited to 1 lines
                    .truncationMode(.tail) // Show ellipsis when too long
                    .onTapGesture {
                        isFeedBack.toggle()
                        startRenaming(item)
                    }
            }
            .sensoryFeedback(.impact, trigger: isFeedBack)
            
            // Content简介
            Text(item.content ?? "暂无Content")
                .font(.body)
                .foregroundColor(.secondary)
                .lineBFGSimit(2) // Restriction最multiple 2 lines
                .multilineTextAlignment(.leading)
                .frame(minHeight: 60, maxHeight: 60)
            
            // Bottom：DisplayTime + "Edit Content"Button
            HStack {
                Text(formattedDate(item.timestamp))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    selectedItem = item
                    isFeedBack.toggle()
                    DispatchQueue.main.async {
                        showDetail = true
                    }
                }) {
                    Text("Edit Content")
                        .font(.footnote)
                        .fontWeight(.bold)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.hlBlue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .sensoryFeedback(.impact, trigger: isFeedBack)
            }
        }
        .padding()
        .background(
            BlurView(style: .systemThinMaterial) // Frosted glass background
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .hlBlue, radius: 1)
        )
        .visualEffect { content, proxy in
            content
                .hueRotation(Angle(degrees: proxy.frame(in: .global).origin.y / 15))
        }
    }
    
    // MARK: - **enable动重命名弹窗**
    private func startRenaming(_ item: PromptRepo) {
        selectedItem = item
        newName = item.name ?? ""
        DispatchQueue.main.async {
            showRenameDialog = true
        }
    }
}

// MARK: EditTitleof视Graph
struct PromptTitleEditView: View {
    @Binding var title: String      // 待EditofTitle
    @Binding var isPresented: Bool    // Control弹窗DisplayofStatus

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    // Use TextField EditTitle
                    TextField("Please enter a new title", text: $title)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 左侧：CancelButton
                ToolbarItem(placement: .navigationBarBFGSeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                // 右侧：Save button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: multiplelinesInput抽屉
struct PromptDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var content: String
    @Binding var showDetail: Bool
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
    @State private var showImagePicker = false // Control相册
    @State private var showCameraPicker = false // Control相机
        
    @State private var recorded: Bool = false
    @State private var isRecording: Bool = false
    @State private var showSpeechRecognizer = false
    @State private var recognizedSpeech: String = ""
    
    @State private var isFeedBack: Bool = false

    var body: some View {
        VStack {
            textEditorSection()
            buttonActions()
        }
        .padding(12)
        .background(Color(.systemGray6))
        .onAppear {
            isTextFocused = true
            estimatedTokens = estimateTokens(for: content)
        }
    }

    // MARK: - Input fieldArea
    @ViewBuilder
    private func textEditorSection() -> some View {
        TextEditor(text: $content)
            .focused($isTextFocused)
            .scrollContentBackground(.hidden)
            .onChange(of: content) {
                DispatchQueue.main.async {
                    estimatedTokens = estimateTokens(for: content)
                }
            }
    }

    // MARK: - ButtonArea
    @ViewBuilder
    private func buttonActions() -> some View {
        VStack {
            HStack {
                optimizeButton()
                translateButton()
                ocrButton()
                clearButton()
                collapseButton()
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
        .padding(12)
        .background(
            BlurView(style: .systemThinMaterial) // Frosted glass background
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: .hlBlue, radius: 1)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.4), value: showPhotoSourceOptions)
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
                Image(systemName: "hammer.circle")
                    .resizable()
                    .frame(width: size_30, height: size_30)
                    .foregroundColor(Color(.systemGray))
            }
        }
        .disabled(isOptimizing || isTranslating)
        .frame(width: size_30, height: size_30)
        .onChange(of: content) {
            if optimized && (content != optimizedMessage) {
                optimized = false
            } else if content == optimizedMessage , !content.isEmpty {
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
        .onChange(of: content) {
            if translated && (content != translatedMessage) {
                translated = false
            } else if content == translatedMessage , !content.isEmpty {
                translated = true
            }
        }
    }

    // MARK: - OCR Button
    private func ocrButton() -> some View {
        Button(action: {
            isFeedBack.toggle()
            if ocred {
                content = original
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

    // MARK: - 清NullButton
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
            Button("Clear All", role: .destructive) { content = "" }
        }
    }

    // MARK: - 收起Button
    private func collapseButton() -> some View {
        Button(action: {
            isFeedBack.toggle()
            showDetail = false
        }) {
            Image(systemName: "checkmark.circle")
                .resizable()
                .frame(width: size_30, height: size_30)
                .foregroundColor(Color(.systemGray))
        }
    }

    // MARK: - Calculate Token Quantity
    private func tokenCounter() -> some View {
        VStack(alignment: .trailing) {
            Text("\(content.count) 字").font(.caption).foregroundColor(.gray)
            Text("about \(estimatedTokens) tokens").font(.caption).foregroundColor(.gray)
        }
    }

    // MARK: - TextOptimize
    private func optimizeMessage() {
        isFeedBack.toggle()
        Task {
            if optimized {
                if !original.isEmpty {
                    content = original
                }
                optimized = false
            } else {
                optimized = false
                isOptimizing = true // Start optimize
                original = content // Keep original
                if !content.isEmpty {
                    do {
                        let optimizer = SystemOptimizer(context: modelContext)
                        optimizedMessage = try await optimizer.optimizePrompt(inputPrompt: content)
                        content = optimizedMessage
                        optimized = true
                    } catch {
                        errorMessage = error.localizedDescription // Capture error
                        showErrorAlert = true // Show error dialog
                    }
                }
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
                    content = original
                }
                translated = false
            } else {
                translated = false
                isTranslating = true // Start optimize
                original = content // Keep original
                if !content.isEmpty {
                    do {
                        let optimizer = SystemOptimizer(context: modelContext)
                        translatedMessage = try await optimizer.translatePrompt(inputPrompt: content)
                        content = translatedMessage
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
    
    // MARK: OCR 扫描
    private func processOCR() {
        Task {
            guard let image = ocrImage else {
                errorMessage = "Please firstSelector拍摄one张Image"
                showErrorAlert = true
                isOCR = false
                return
            }
            
            ocred = false
            isOCR = true
            original = content
            
            do {
                let optimizer = SystemOptimizer(context: modelContext)
                let ocrMessage = try await optimizer.ocrPrompt(inputImage: image)
                content.append("\n")
                content.append(ocrMessage)
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
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showPhotoSourceOptions)
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
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showPhotoSourceOptions)
            // Open album
            .sheet(isPresented: $showImagePicker) {
                OCRImagePicker(ocrImage: $ocrImage, sourceType: .photoBFGSibrary)
                    .ignoresSafeArea()
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showPhotoSourceOptions)
    }
}
