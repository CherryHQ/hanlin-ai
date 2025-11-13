//
//  PromptRepoView.swift
//  AI_Hanlin
//
//  Created by 哆啦好多梦 on 18/3/25.
//

import SwiftUI
import SwiftData


// MARK: - 主视图
struct PromptRepoView: View {
    
    // 使用 SwiftData 的查询，从数据库中按 position 升序读取记录
    @Query(sort: [SortDescriptor(\PromptRepo.position, order: .forward)]) private var promptTemps: [PromptRepo]
    
    // ModelContext 用于插入、删除、更新数据
    @Environment(\.modelContext) private var modelContext
    
    @State private var showRenameDialog: Bool = false
    @State private var newName: String = ""  // 存储新的名称
    @State private var selectedItem: PromptRepo?  // 记录当前选择重命名的项目
    @State private var showDetail: Bool = false
    @State private var isFeedBack: Bool = false
    
    @State private var searchText: String = ""
    
    var body: some View {
        ZStack {
            backgroundView
            promptListView
        }
        .navigationTitle("Prompt Library")
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
    
    /// 背景渐变视图
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.hlBlue.opacity(0.2), Color.hlPurple.opacity(0.2)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // 过滤后的数据
    private var filteredPrompts: [PromptRepo] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return promptTemps
        } else {
            let lowerSearch = trimmed.lowercased()
            return promptTemps.filter {
                let name = $0.name ?? "新提示词"
                let lowerName = name.lowercased()
                // 获取拼音表示（假设 String.toPinyin() 方法已实现，返回无空格的拼音字符串）
                let lowerPinyin = name.toPinyin().lowercased()
                return lowerName.contains(lowerSearch) || lowerPinyin.contains(lowerSearch)
            }
        }
    }
    
    /// 主列表视图（支持拖拽排序与左滑删除）
    private var promptListView: some View {
        List {
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
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(Color(.hlRed))
                    }
            }
            .onMove(perform: move)
        }
        .listStyle(PlainListStyle())
        .listRowSeparator(.hidden)
    }
    
    /// 生成单条数据的视图（取消了编辑模式下右上角的删除按钮）
    private func rowForItem(_ item: PromptRepo) -> some View {
        ZStack(alignment: .topTrailing) {
            promptCardView(for: item)
        }
        .listRowBackground(Color.clear)
    }
    
    /// 工具栏内容：仅保留“新增”按钮
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                // 新增提示词时，新项卡片应在顶部，
                // 新的 position 取当前第一条记录的 position - 1（若为空则默认 0）
                let newPosition = (promptTemps.first?.position ?? 0) - 1
                let newPrompt = PromptRepo(name: "新提示词", content: "新提示内容", position: newPosition)
                modelContext.insert(newPrompt)
                try? modelContext.save()
            }) {
                Text("Add")
            }
        }
    }
    
    /// 编辑标题时的 Sheet
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
    
    /// 编辑内容时的 Sheet
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
    
    /// 拖拽排序函数：先对数组进行移动操作，再重新更新每项的 position 值
    private func move(from source: IndexSet, to destination: Int) {
        var prompts = promptTemps
        prompts.move(fromOffsets: source, toOffset: destination)
        for index in prompts.indices {
            prompts[index].position = index
        }
        try? modelContext.save()
    }
    
    /// 左滑删除函数：删除选中项并更新 position 值
    private func deleteItem(_ item: PromptRepo) {
        // 删除选中项
        modelContext.delete(item)

        // 重新排序 position
        let remaining = promptTemps.filter { $0.id != item.id }
        for index in remaining.indices {
            remaining[index].position = index
        }

        // 保存到数据库
        try? modelContext.save()
    }
    
    // 辅助函数：高亮显示搜索匹配的标题
    private func highlightedName(for prompt: PromptRepo) -> AttributedString {
        let name = prompt.name ?? "新提示词"
        var attributedString = AttributedString(name)
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedSearch.isEmpty {
            return attributedString
        }
        
        let lowerSearch = trimmedSearch.lowercased()
        let lowerName = name.lowercased()
        var matchFound = false

        // 1. 先在原始汉字中查找匹配
        var searchRange = lowerName.startIndex..<lowerName.endIndex
        while let range = lowerName.range(of: lowerSearch, options: .caseInsensitive, range: searchRange) {
            let nsRange = NSRange(range, in: name)
            if let attrRange = Range(nsRange, in: attributedString) {
                attributedString[attrRange].foregroundColor = .hlBlue
            }
            searchRange = range.upperBound..<lowerName.endIndex
            matchFound = true
        }
        
        // 2. 如果汉字中未找到匹配，则尝试在拼音中匹配
        if !matchFound {
            let pinyin = name.toPinyin() // 获取汉字对应的拼音
            let lowerPinyin = pinyin.lowercased()
            if let rangeInPinyin = lowerPinyin.range(of: lowerSearch, options: .caseInsensitive) {
                // 构建每个汉字在拼音中的映射区间（假设每个汉字转换为拼音后，字符数可能不一致）
                var mapping: [Range<Int>] = []
                var currentIndex = 0
                for char in name {
                    let charStr = String(char)
                    let charPinyin = charStr.toPinyin() // 单个字符对应的拼音
                    let length = charPinyin.count
                    mapping.append(currentIndex..<currentIndex+length)
                    currentIndex += length
                }
                // 将 rangeInPinyin 转换为整数区间
                let startOffset = lowerPinyin.distance(from: lowerPinyin.startIndex, to: rangeInPinyin.lowerBound)
                let endOffset = lowerPinyin.distance(from: lowerPinyin.startIndex, to: rangeInPinyin.upperBound)
                
                // 确定哪些汉字的映射区间与匹配区间有交集
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
    
    // 封装的 Prompt 视图
    private func promptCardView(for item: PromptRepo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            
            // 标题（带图标）
            HStack {
                Image("prompt") // 使用自定义图片
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24) // 调整大小
                    .foregroundColor(.hlBluefont) // 颜色变为 .hlBlue
                
                Text(highlightedName(for: item))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1) // 限制为 1 行
                    .truncationMode(.tail) // 文字过长时显示省略号
                    .onTapGesture {
                        isFeedBack.toggle()
                        startRenaming(item)
                    }
            }
            .sensoryFeedback(.impact, trigger: isFeedBack)
            
            // 内容简介
            Text(item.content ?? "暂无内容")
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2) // 限制最多 2 行
                .multilineTextAlignment(.leading)
                .frame(minHeight: 60, maxHeight: 60)
            
            // 底部：显示时间 + "Edit Content"按钮
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
            BlurView(style: .systemThinMaterial) // 毛玻璃背景
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .hlBlue, radius: 1)
        )
        .visualEffect { content, proxy in
            content
                .hueRotation(Angle(degrees: proxy.frame(in: .global).origin.y / 15))
        }
    }
    
    // MARK: - **启动重命名弹窗**
    private func startRenaming(_ item: PromptRepo) {
        selectedItem = item
        newName = item.name ?? ""
        DispatchQueue.main.async {
            showRenameDialog = true
        }
    }
}

// MARK: 编辑标题的视图
struct PromptTitleEditView: View {
    @Binding var title: String      // 待编辑的标题
    @Binding var isPresented: Bool    // 控制弹窗显示的状态

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    // 使用 TextField 编辑标题
                    TextField("Please enter a new title", text: $title)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 左侧：取消按钮
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                // 右侧：保存按钮
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: 多行输入抽屉
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
    @State private var showPhotoSourceOptions = false // 控制 ActionSheet
    @State private var isSourceOptionsVisible = false // 控制 ActionSheet
    @State private var showImagePicker = false // 控制相册
    @State private var showCameraPicker = false // 控制相机
        
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

    // MARK: - 输入框区域
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

    // MARK: - 按钮区域
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
            BlurView(style: .systemThinMaterial) // 毛玻璃背景
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: .hlBlue, radius: 1)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0.4), value: showPhotoSourceOptions)
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
        .onChange(of: content) {
            if translated && (content != translatedMessage) {
                translated = false
            } else if content == translatedMessage , !content.isEmpty {
                translated = true
            }
        }
    }

    // MARK: - OCR 按钮
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
        .alert("Confirm Clearing All Text?", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) { content = "" }
        }
    }

    // MARK: - 收起按钮
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

    // MARK: - 计算 Token 数量
    private func tokenCounter() -> some View {
        VStack(alignment: .trailing) {
            Text("\(content.count) 字").font(.caption).foregroundColor(.gray)
            Text("约 \(estimatedTokens) tokens").font(.caption).foregroundColor(.gray)
        }
    }

    // MARK: - 文本优化
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
                isOptimizing = true // 开始优化
                original = content // 保留原句
                if !content.isEmpty {
                    do {
                        let optimizer = SystemOptimizer(context: modelContext)
                        optimizedMessage = try await optimizer.optimizePrompt(inputPrompt: content)
                        content = optimizedMessage
                        optimized = true
                    } catch {
                        errorMessage = error.localizedDescription // 捕获错误信息
                        showErrorAlert = true // 显示错误弹窗
                    }
                }
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
                    content = original
                }
                translated = false
            } else {
                translated = false
                isTranslating = true // 开始优化
                original = content // 保留原句
                if !content.isEmpty {
                    do {
                        let optimizer = SystemOptimizer(context: modelContext)
                        translatedMessage = try await optimizer.translatePrompt(inputPrompt: content)
                        content = translatedMessage
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
            original = content
            
            do {
                let optimizer = SystemOptimizer(context: modelContext)
                let ocrMessage = try await optimizer.ocrPrompt(inputImage: image)
                content.append("\n")
                content.append(ocrMessage)
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
            // 打开相册
            .sheet(isPresented: $showImagePicker) {
                OCRImagePicker(ocrImage: $ocrImage, sourceType: .photoLibrary)
                    .ignoresSafeArea()
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showPhotoSourceOptions)
    }
}
