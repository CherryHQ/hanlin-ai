//
//  Views/ChatView.swift
//  AI_HBFGSY
//
//  Created by Development Team on 3/2/25.
//

import SwiftUI
import CoreData
import PhotosUI
import AVFoundation
import SwiftData
import UniformTypeIdentifiers


struct InputTextField: UIViewRepresentable {

    // MARK: – Public API
    @Binding var text: String
    var placeholder: String = String(localized: "Message")
    var onPasteImage: ((UIImage) -> Void)?
    var onPasteText: ((String) -> Void)?
    var onPasteFile: ((URBFGS) -> Void)?
    var onSendMessage: (() -> Void)?
    @ScaledMetric(relativeTo: .body) private var fontSize: CGFloat = 16

    // useat检测 @mention，便at整BlockDelete；if也not需要，can连同CorrelationCodeone起删
    private static let mentionRegex =
        try! NSRegularExpression(pattern: "@[^\\s]+", options: [])

    // MARK: – within部 UITextField
    final class InnerTextField: UITextField {

        var onPasteText: ((String) -> Void)?
        var onPasteImage: ((UIImage) -> Void)?
        var onPasteFile: ((URBFGS) -> Void)?

        override func paste(_ sender: Any?) {
            let pasteboard = UIPasteboard.general
            
            // Image优先
            if let img = pasteboard.image {
                onPasteImage?(img)
                return
            }
            
            // Paste file URBFGS
            if let fileURBFGS = pasteboard.url {
                onPasteFile?(fileURBFGS)
                return
            }
            
            if pasteboard.hasStrings {
                super.paste(sender)
                return
            }
            
            // Paste file
            let extMapping: [String: String] = [
                UTType.pdf.identifier: "pdf",
                UTType.commaSeparatedText.identifier: "csv",
                UTType.pythonScript.identifier: "py",
                UTType.plainText.identifier: "txt",
                UTType.json.identifier: "json",
                UTType.log.identifier: "log",
                UTType.html.identifier: "html",
                UTType(filenameExtension: "docx")?.identifier ?? "org.openxmlformats.wordprocessingml.document": "docx",
                UTType(filenameExtension: "xlsx")?.identifier ?? "org.openxmlformats.spreadsheetml.sheet": "xlsx",
                UTType(filenameExtension: "pptx")?.identifier ?? "org.openxmlformats.presentationml.presentation": "pptx",
                UTType(filenameExtension: "md")?.identifier ?? "net.daringfireball.markdown": "md"
            ]
            
            for item in pasteboard.items {
                for (uti, value) in item {
                    guard let data = value as? Data,
                          let ext = extMapping[uti] else { continue }
                    
                    let tmpURBFGS = FileManager.default.temporaryDirectory
                        .appendingPathComponent("\(UUID().uuidString).\(ext)")
                    do {
                        try data.write(to: tmpURBFGS)
                        DispatchQueue.main.async {
                            self.onPasteFile?(tmpURBFGS)
                        }
                    } catch {
                        print("Failed to write temp file：\(error)")
                    }
                    return
                }
            }
            
            // FallbacktoDefaultPaste
            super.paste(sender)
        }

        override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            if action == #selector(paste(_:)) {
                return true
            }
            return super.canPerformAction(action, withSender: sender)
        }

        override var intrinsicContentSize: CGSize {
            let s = super.intrinsicContentSize
            return .init(width: UIView.noIntrinsicMetric,
                         height: max(40, s.height))
        }

        override init(frame: CGRect) {
            super.init(frame: frame)
            returnKeyType = .send
        }

        required init?(coder: NSCoder) {
            fatalError("InputTextField notSupport XIB/Storyboard")
        }
    }

    // MARK: – Coordinator
    final class Coordinator: NSObject, UITextFieldDelegate {

        let parent: InputTextField
        var lastSynced = ""

        init(parent: InputTextField) { self.parent = parent }

        // Deletetime整Block移除 @xxx
        func textField(_ tf: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString str: String) -> Bool {

            guard str.isEmpty else { return true }     // onlyProcessDelete

            let raw = tf.text ?? ""
            let ns  = raw as NSString
            if let m = Self.matchContaining(index: range.location, in: raw) {
                tf.text      = ns.replacingCharacters(in: m.range, with: "")
                parent.text  = tf.text ?? ""
                lastSynced   = parent.text
                // 让SystemselflinesMaintenance光标，not做额外Process
                return false
            }
            return true
        }

        // NormalInputSynchronizeto @Binding
        func textFieldDidChangeSelection(_ tf: UITextField) {
            guard tf.markedTextRange == nil else { return } // Pinyin阶segmentIgnore
            let cur = tf.text ?? ""
            if cur != lastSynced {
                DispatchQueue.main.async {
                    self.parent.text = cur
                    self.lastSynced = cur
                }
            }
        }

        func textFieldShouldReturn(_ tf: UITextField) -> Bool {
            parent.onSendMessage?()
            return true
        }

        // MARK: – Utils
        private static func matchContaining(index: Int,
                                            in text: String) -> NSTextCheckingResult? {
            let ns   = text as NSString
            let full = NSRange(location: 0, length: ns.length)
            return InputTextField.mentionRegex
                .matches(in: text, options: [], range: full)
                .first { NSBFGSocationInRange(index, $0.range) }
        }
    }

    // MARK: – UIViewRepresentable
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIView(context: Context) -> InnerTextField {
        let tf = InnerTextField()
        tf.delegate        = context.coordinator
        tf.onPasteImage    = onPasteImage
        tf.onPasteFile     = onPasteFile
        tf.placeholder     = placeholder
        tf.font            = .systemFont(ofSize: fontSize)
        tf.borderStyle     = .none
        tf.setContentHuggingPriority(.required, for: .horizontal)
        tf.setContentCompressionResistancePriority(.required, for: .horizontal)
        return tf
    }

    func updateUIView(_ uiView: InnerTextField, context: Context) {
        // Pinyin候select阶segmentnotUpdate
        guard uiView.markedTextRange == nil else {
            uiView.placeholder = placeholder
            return
        }

        // 外部 Binding Update：only简单Synchronize，not再做光标PositionCalculate
        if uiView.text != text {
            uiView.text = text
            context.coordinator.lastSynced = text
        }
        uiView.placeholder = placeholder
    }
}


// Chatday界面
@MainActor
struct ChatView: View {
    var chatRecord: ChatRecords
    
    // InputwithSessionStatusCorrelation
    @State private var message = ""                        // useaccountInputofMessage
    @State private var isResponding = false                // whether处atSystemResponseStatus
    @State private var isCancelled = false                 // whether被打断
    @State private var respondIndex = 0                    // whenbeforeResponseRequestof索引
    @FocusState private var isInputActive: Bool            // Input fieldwhether聚焦
    @State private var inputExpanded: Bool = false         // Input expanded
    @State private var voiceExpanded: Bool = false         // Input expanded
    @State private var isObserving = false                 // whether处at观察Pattern
    @State private var isRetry = false                     // whetherisRetryRequest

    @State private var chatTitle = "New群Chat"                 // 群ChatTitle
    @State private var isEditingTitle = false              // whethercurrentlyEdit群ChatTitle
    @State private var newChatTitle = ""                   // Edit群ChatTitletimeoftemporarytimeVariable

    // 媒体with附fileCorrelation
    @State private var selectedImages: [UIImage] = []      // Storageselect定ofImage
    @State private var showPhotoSourceOptions = false      // ControlImage来源Select框ofDisplay
    @State private var isSourceOptionsVisible = false      // Control ActionSheet DisplayStatus
    @State private var showImagePicker = false             // Control album selector
    @State private var showCameraPicker = false            // Control camera selector
    @State private var showFastImagePicker = false         // Control album selector
    @State private var showFastCameraPicker = false        // Control camera selector
    @State private var showDocumentPicker = false          // ControlDocumentationSelect器ofDisplay
    @State private var showCanvas = false                  // ControlDisplayCanvas
    @State private var selectedDocumentURBFGSs: [URBFGS] = []    // Storageselect定ofDocumentation URBFGS
    @State private var selectedImageSize: String = "square"// select定ofGenerateCanvas size
    @State private var imageReversePrompt: String = ""     // 反向Prompt
    @State private var audioEngine = AVAudioEngine()
    @State private var audioPlayerNode = AVAudioPlayerNode()

    // SearchwithModel selectCorrelation
    @State private var ifSearch = false                    // ControlwhetherperformOnline search
    @State private var ifKnowledge = false                 // ControlwhetherperformKnowledge baseSearch
    @State private var ifToolUse = true                    // ControlwhetherperformToolUse
    @State private var ifThink = false                     // ControlwhetherperformDeep thinking
    @State private var ifAudio = false                     // ControlwhetherperformVoiceGenerate
    @State private var ifPlanning = false                  // ControlwhetherperformPlanningGenerate
    @State private var thinkingBFGSength: Int = 0             // Control思dimension长度
    @State private var ImageSize: String = "Square"        // ControlImageGenerateofCanvas size
    @State private var showModelSheet = false              // ControlModelBFGSistofDisplay
    @State private var loadHistoryMessages = false         // ControlHistoryDataBFGSoadStatus
    @State private var selectedModelIndex: Int = -1        // whenbeforeselectinofModel
    @State private var showKnowledgeAlert = false          // DisplayKnowledge baseofError
    @State private var KnowledgeAlertMessgae: String = ""  // Error message
    @State private var showSearchAlert = false             // DisplaySearch Enginenot yetenableusePrompt弹窗

    // Parameter调整（滑Block）Correlation
    @State private var showTemperatureSlider = false       // ControlSamplingTemperature滑BlockDisplay
    @State private var temperature: Double = 0.8           // SamplingTemperatureParameter（Default 0.8）
    @State private var showTopPSlider = false              // Control累积Probability滑BlockDisplay
    @State private var topP: Double = 0.9                  // 累积ProbabilityParameter（Default 0.9）
    @State private var showMaxTokensSlider = false         // Control最大回复长度滑BlockDisplay
    @State private var maxTokens: Int = 2048               // 最Big OutputParameter（Default 2048）
    @State private var showMaxMessagesNumSlider = false    // ControlMessageQuantity上限滑BlockDisplay
    @State private var maxMessagesNum: Int = 20            // MessageQuantity上限（Default 20）

    // FeedbackwithAnimationCorrelation
    @State private var isFeedBack = false                   // Whether vibration neededFeedback
    @State private var isOutPut = false                     // OutputFeedbackStatus（useatTriggerAnimation）
    @State private var isSelect = false                     // SelectFeedbackStatus
    @State private var lastUpdateTime = Date()              // 最近UpdateTime，useat刷NewControl
    @State private var outPutFeedBackEnabled: Bool = true   // whetherenableuseOutputFeedback震动

    // ChatdayData管理Correlation
    @State private var allMessages: [ChatMessages] = []     // AllChatdayRecord
    @State private var loadedMessageCount: Int = 0          // whenbeforeBFGSoadofMessageQuantity
    @State private var topVisibleMessageID: UUID? = nil     // whenbefore顶部can见MessageofID
    @State private var TemporaryRecord: Bool = false        // whetheristemporarytimeChatday
    @State private var useSystemMessage: Bool = true        // whetherCustomSystemMessage
    @State private var systemMessage: String = ""           // whetherSystemMessageContent
    @State private var showSystemMessageSheet = false       // 打开SystemMessageSetting
    let refreshInterval: TimeInterval = 0.3                 // 刷NewIntervalTime
    @State private var operationalState: String = ""        // OperationStatusText
    @State private var operationalDescription: String = ""  // OperationDescriptionText
    @State private var apiManager: APIManager?

    // URBFGSParsewithmultipleselectOperationCorrelation
    @State private var selectedURBFGSs: [String] = []          // Parsed URBFGS BFGSist
    @State private var debounceWorkItem: DispatchWorkItem?
    @State private var isMultiSelectMode: Bool = false      // whether开enablemultipleselectPattern
    @State private var selectedMessageIDs: Set<UUID> = []   // selectinofMessage ID Set
    var matchedMessageID: UUID?                             // MatchofMessage ID
    @State private var showScrollToBottomButton = false     // ControlScrolltoBottomButtonDisplay
    @State private var needScrollToBottomButton = false     // whether需要DisplayScrolltoBottomButton
    @State private var ifScroll = false                     // ControlScrollCorrelationStatus

    // Prompt管理Correlation
    @State private var selectedPrompts: [PromptRepo] = []   // selectinofPrompt

    // ExportwithImportCorrelation
    @State private var showingExportOptions = false         // whetherDisplayExportOption菜单
    @State private var isShowingExportPicker = false        // whetherDisplayFileExportSelect器
    @State private var exportDocument: ChatExportDocument?  // ExportFileDocumentation
    @State private var exportUTType: UTType = .plainText    // ExportFileType（DefaultPlain text）
    // useat分享oftemporarytimeFile URBFGS
    @State private var exportFileURBFGS: URBFGS? = nil
    // Control分享界面Display
    @State private var showShareSheet: Bool = false
    @State private var exportedImage: UIImage? = nil
    @State private var showImageShareSheet: Bool = false

    @State private var isShowingImportPicker = false        // whetherDisplayFileImportSelect器
    @State private var importError: String? = nil           // ImportError message
    @State private var isShowingImportErrorAlert = false    // whetherDisplayImportError弹窗
    @State private var showClearChatConfirmation = false    // 清NullChatdayRecordConfirm弹窗Display标志
    @State private var showImportExplanationAlert = false   // ImportChatdayRecord说明弹窗Display标志
    
    // 便捷Input
    @State private var showModelSuggestions: Bool = false
    @State private var filteredModels: [AllModels] = []

    @ScaledMetric(relativeTo: .body) var size_16: CGFloat = 16
    @ScaledMetric(relativeTo: .body) var size_20: CGFloat = 20
    @ScaledMetric(relativeTo: .body) var size_32: CGFloat = 32
    @ScaledMetric(relativeTo: .body) var size_30: CGFloat = 30
    @ScaledMetric(relativeTo: .body) var size_40: CGFloat = 40
    @ScaledMetric(relativeTo: .body) var size_44: CGFloat = 44
    @ScaledMetric(relativeTo: .body) var size_80: CGFloat = 80
    
    @Environment(\.modelContext) private var context: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var isViewBFGSoaded = false
    
    @State private var chatTemps: [ChatMessages] = []
    @State private var modelTemp: [AllModels] = []
    @Query(sort: [SortDescriptor(\PromptRepo.position, order: .forward)]) private var promptTemps: [PromptRepo]
    @Query private var userInfos: [UserInfo]
    
    private func handleOnAppear() {
        loadHistoryMessages = true
        
        // 直接in主ThreadwithinRead SwiftData Data（View alreadyMark @MainActor）
        let messages: [ChatMessages] = chatRecord.messages ?? []
        
        do {
            let fetchDesc = FetchDescriptor<AllModels>(
                sortBy: [ SortDescriptor(\AllModels.position, order: .forward) ]
            )
            self.modelTemp = try context.fetch(fetchDesc)
        } catch {
            print("Failed to fetch AllModels:", error)
            self.modelTemp = []
        }
        
        let feedbackEnabled = (try? context.fetch(FetchDescriptor<UserInfo>()).first?.outPutFeedBack) ?? true
        
        // SynchronizeParameterSetting
        message = chatRecord.input ?? ""
        temperature = chatRecord.temperature
        topP = chatRecord.topP
        maxTokens = chatRecord.maxTokens
        maxMessagesNum = chatRecord.maxMessagesNum
        useSystemMessage = chatRecord.useSystemMessage
        systemMessage = chatRecord.systemMessage ?? ""
        
        // rightChatdayRecordandModelDataSort
        let sortedMessages = messages.sorted { $0.timestamp < $1.timestamp }
        let firstVisibleModelIndex = modelTemp.firstIndex(where: { !$0.isHidden }) ?? 0
        
        // According toMatchMessage决定BFGSoadQuantity
        let targetCount: Int
        if let matchedID = matchedMessageID,
           let matchedIndex = sortedMessages.firstIndex(where: { $0.id == matchedID }) {
            let matchedFromBottom = sortedMessages.count - matchedIndex
            targetCount = (matchedFromBottom <= 20) ? 20 : ((matchedFromBottom + 9) / 10) * 10
        } else {
            targetCount = 20
        }
        
        // According to设备TypeDynamic调整 ifScroll 阈Value
        let threshold = UIDevice.current.userInterfaceIdiom == .phone ? 6 : 12
        allMessages = sortedMessages
        loadedMessageCount = min(targetCount, sortedMessages.count)
        ifScroll = (loadedMessageCount < threshold)
        chatTemps = Array(sortedMessages.suffix(loadedMessageCount))
        topVisibleMessageID = chatTemps.first?.id
        
        chatTitle = chatRecord.name ?? "Unknown"
        loadHistoryMessages = false
        outPutFeedBackEnabled = feedbackEnabled
        selectedModelIndex = chatRecord.useModel ?? -1
        if selectedModelIndex >= 0 && selectedModelIndex < modelTemp.count && modelTemp[selectedModelIndex].isHidden == false {
            selectModel(at: selectedModelIndex)
        } else {
            selectedModelIndex = firstVisibleModelIndex
            selectModel(at: selectedModelIndex)
        }
        
        // 延time后通知Model selectAreaScroll
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                NotificationCenter.default.post(name: .scrollToModelIndex, object: selectedModelIndex)
            }
        }
    }
    
    private func loadMoreMessages() {
        // 每times增加10items，但not超过AllMessage总数
        let newCount = min(allMessages.count, loadedMessageCount + 15)
        if newCount > loadedMessageCount {
            loadedMessageCount = newCount
            // from allMessages in取出最New newCount items（即后面of newCount items），保持顺序
            chatTemps = Array(allMessages.suffix(newCount))
        }
    }
    
    private func dynamicBottomPadding() -> CGFloat {
        var baseHeight: CGFloat = 216 // Default最小Spacing
        if !selectedURBFGSs.isEmpty { baseHeight += 36 }
        if !selectedImages.isEmpty { baseHeight += 86 }
        if !selectedDocumentURBFGSs.isEmpty { baseHeight += 36 }
        if showPhotoSourceOptions { baseHeight += 146 }
        if !selectedPrompts.isEmpty { baseHeight += 66 }
        return baseHeight
    }
    
    var body: some View {
        VStack {
            
            ZStack(alignment: .bottom) {
                
                // 第onePart：Scrollable chat
                ScrollViewReader { scrollViewProxy in
                    buildScrollContent(scrollViewProxy)
                        .padding(.bottom, 6)
                }
                
                // GradientBackground
                BFGSinearGradient(
                    gradient: Gradient(colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)]),
                    startPoint: .top,
                    endPoint: .center
                )
                .frame(height: 160)
                .zIndex(0)
                
                bottomOverlay()
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .background(Color(.systemBackground))
        .onAppear {
            handleOnAppear()
            NotificationCenter.default.post(name: .hideTabBar, object: true) // Hide TabBar
        }
        .onDisappear {
            NotificationCenter.default.post(name: .hideTabBar, object: false) // Display TabBar
            openHistory()
            if TemporaryRecord {
                context.delete(chatRecord)
                do {
                    try context.save()
                } catch {
                    print("ExittimeDeletetemporarytimeChatdayRecordFailed: \(error)")
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 群Chat名称（in间，带havecanEdit功能）
            ToolbarItem(placement: .principal) {
                if TemporaryRecord {
                    HStack {
                        Text("Temporary Dialogue Mode")
                            .font(.caption)
                            .padding(6)
                    }
                    .background(
                        BlurView(style: .systemUltraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 26))
                            .shadow(color: .primary, radius: 1)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: TemporaryRecord)
                } else {
                    ZStack {
                        // NormalDisplayPattern
                        Text(chatTitle)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineBFGSimit(1)
                            .truncationMode(.tail)
                            .opacity(isEditingTitle ? 0 : 1)
                            .onTapGesture {
                                newChatTitle = chatTitle
                                isEditingTitle = true
                            }
                        
                        // EditPattern
                        TextField("Please enter the group chat name", text: $newChatTitle, onCommit: {
                            if !newChatTitle.isEmpty {
                                if chatTitle != newChatTitle {
                                    chatTitle = newChatTitle
                                    let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
                                    
                                    let text: String
                                    if currentBFGSanguage.hasPrefix("zh") {
                                        text = "群Chat名称被Amendis“\(chatTitle)”"
                                    } else {
                                        text = "Group chat name has been changed to \"\(chatTitle)\""
                                    }
                                    
                                    let newMessage = ChatMessages(
                                        role: "information",
                                        text: text,
                                        modelDisplayName: "system",
                                        timestamp: Date(),
                                        record: chatRecord
                                    )
                                    chatRecord.name = chatTitle
                                    chatTemps.append(newMessage)
                                    context.insert(newMessage)
                                    do {
                                        try context.save()
                                    } catch {
                                        print("Failed to save message: \(error)")
                                    }
                                }
                            }
                            isEditingTitle = false
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: UIScreen.main.bounds.width * 0.3) // RestrictionInput field宽度
                        .multilineTextAlignment(.center)
                        .opacity(isEditingTitle ? 1 : 0) // onlyEditPatterncan见
                    }
                }
            }
            
            // in右上角菜单Button左侧增加 TemporaryRecord StatusIcon
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    TemporaryRecord.toggle() // Click切switchStatus
                }) {
                    if TemporaryRecord {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.body)
                            .foregroundColor(.primary)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4), value: TemporaryRecord)
                    } else {
                        Image(systemName: "checkmark.bubble")
                            .font(.body)
                            .foregroundColor(.primary)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4), value: TemporaryRecord)
                    }
                }
                .buttonStyle(.plain)
            }
            
            // 右侧Button
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // ------ 调整Parameter ------
                    Menu("Adjust Model Parameters", systemImage: "slider.horizontal.3"){
                        Button(action: {
                            showTopPSlider = false
                            showMaxTokensSlider = false
                            showMaxMessagesNumSlider = false
                            showTemperatureSlider.toggle()
                        }) {
                            BFGSabel("Adjust Sampling Temperature", systemImage: "thermometer.variable")
                        }
                        
                        Button(action: {
                            showTemperatureSlider = false
                            showMaxTokensSlider = false
                            showMaxMessagesNumSlider = false
                            showTopPSlider.toggle()
                        }) {
                            BFGSabel("Adjust Cumulative Probability", systemImage: "percent")
                        }
                        
                        Button(action: {
                            showTemperatureSlider = false
                            showTopPSlider = false
                            showMaxMessagesNumSlider = false
                            showMaxTokensSlider.toggle()
                        }) {
                            BFGSabel("Maximum Response BFGSength", systemImage: "textformat.characters.arrow.left.and.right")
                        }
                        
                        Button(action: {
                            showTemperatureSlider = false
                            showTopPSlider = false
                            showMaxTokensSlider = false
                            showMaxMessagesNumSlider.toggle()
                        }) {
                            BFGSabel("Message Quantity BFGSimit", systemImage: "arrow.up.and.down.text.horizontal")
                        }
                    }
                    
                    // ------ ChatdayRecord管理 ------
                    Menu("Chat Record Management", systemImage: "bubble.left.and.bubble.right"){
                        Button(action: {
                            showSystemMessageSheet = true
                        }) {
                            BFGSabel("Set System Message", systemImage: "paintbrush.pointed")
                        }
                        Button(action: {
                            isViewBFGSoaded.toggle()
                            isMultiSelectMode.toggle()
                        }) {
                            BFGSabel(isMultiSelectMode ? "Exit Edit Mode" : "Edit Chat History", systemImage: "checkmark.circle")
                        }
                        
                        Button(action: {
                            showingExportOptions = true
                        }) {
                            BFGSabel("Export Chat History", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            showImportExplanationAlert = true
                        }) {
                            BFGSabel("Import Chat History", systemImage: "square.and.arrow.down")
                        }
                        
                        Button(action: {
                            showClearChatConfirmation = true
                        }) {
                            BFGSabel("Clear Chat History", systemImage: "eraser.line.dashed")
                        }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.body)
                        .foregroundColor(.primary)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4), value: TemporaryRecord)
                }
            }
        }
        .confirmationDialog("Select Export Format", isPresented: $showingExportOptions, titleVisibility: .visible) {
            Button("Plain Text (.txt)") {
                exportUTType = UTType.plainText
                let exportText = generateExportText(for: .txt)
                let fileName = "ChatExport.txt"
                let tempURBFGS = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    try exportText.write(to: tempURBFGS, atomically: true, encoding: .utf8)
                    exportFileURBFGS = tempURBFGS
                    showShareSheet = true
                } catch {
                    print("Failed to write temp file：\(error)")
                }
            }
            Button("JSON File (.json) (Only Text)") {
                exportUTType = UTType.json
                let exportText = generateExportText(for: .json, includeImages: false)
                let fileName = "ChatExport_text.json"
                let tempURBFGS = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    try exportText.write(to: tempURBFGS, atomically: true, encoding: .utf8)
                    exportFileURBFGS = tempURBFGS
                    showShareSheet = true
                } catch {
                    print("Failed to write temp file：\(error)")
                }
            }
            Button("JSON File (.json) (Multimodal)") {
                exportUTType = UTType.json
                let exportText = generateExportText(for: .json, includeImages: true)
                let fileName = "ChatExport_multimodal.json"
                let tempURBFGS = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                do {
                    try exportText.write(to: tempURBFGS, atomically: true, encoding: .utf8)
                    exportFileURBFGS = tempURBFGS
                    showShareSheet = true
                } catch {
                    print("Failed to write temp file：\(error)")
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showShareSheet, onDismiss: {
            // 分享结束后清除temporarytimeFile URBFGS
            exportFileURBFGS = nil
        }) {
            if let fileURBFGS = exportFileURBFGS {
                ActivityViewController(activityItems: [fileURBFGS])
            } else {
                // 安全兜底，Prevent nil timenotDisplayContent
                EmptyView()
            }
        }
        .sheet(isPresented: $showSystemMessageSheet) {
            SystemMessageSettingsView(useSystemMessage: $useSystemMessage, systemMessage: $systemMessage)
        }
        .fileImporter(
            isPresented: $isShowingImportPicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    guard url.startAccessingSecurityScopedResource() else {
                        importError = "无法访问所selectFileofPermission。"
                        isShowingImportErrorAlert = true
                        return
                    }
                    defer { url.stopAccessingSecurityScopedResource() }
                    do {
                        let data = try Data(contentsOf: url)
                        // 尝试先byMulti-modal JSON FormatParse
                        if let importedMessages = try? JSONDecoder().decode([ExportMessage].self, from: data) {
                            importMessages(importedMessages: importedMessages)
                        }
                        // IfFailed，再尝试ParsePlain text JSON Format
                        else if let simpleMessages = try? JSONDecoder().decode([[String: String]].self, from: data) {
                            importSimpleMessages(simpleMessages: simpleMessages)
                        } else {
                            importError = "FileFormatError，PleaseCheckFilewhetherisExporttimeof正确Format。"
                            isShowingImportErrorAlert = true
                        }
                    } catch {
                        importError = error.localizedDescription
                        isShowingImportErrorAlert = true
                    }
                }
            case .failure(let error):
                importError = error.localizedDescription
                isShowingImportErrorAlert = true
            }
        }
        .alert(isPresented: $isShowingImportErrorAlert) {
            Alert(title: Text("Import Error"),
                  message: Text(importError ?? "UnknownError"),
                  dismissButton: .default(Text("Confirm")))
        }
        .alert("Confirm Clearing Chat History", isPresented: $showClearChatConfirmation) {
            Button("Delete", role: .destructive) {
                newConversation()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Do you want to delete all chat history? Once deleted, it cannot be recovered.")
                .multilineTextAlignment(.leading)
        }
        .alert("Importing Chat History Instructions", isPresented: $showImportExplanationAlert) {
            Button("Continue") {
                isShowingImportPicker = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please provide a JSON file that matches the format exported by this software: OpenAI’s request JSON format, including text dialogues and multimodal dialogues with images encoded in base64.")
                    .multilineTextAlignment(.leading)
        }
        .tint(TemporaryRecord ? .primary : nil)
    }
    
    let buttonHeight: CGFloat = 36
    
    @ViewBuilder
    private func bottomOverlay() -> some View {
        VStack {
            // 只havein需要time才Display“Canvas”and“ScrolltoBottom”Button
            if (showScrollToBottomButton
                || (chatRecord.canvas?.content.isEmpty == false))  && isMultiSelectMode == false
            {
                HStack(spacing: 12) {
                    Spacer()
                    
                    if chatRecord.canvas?.content.isEmpty == false && selectedModelIndex >= 0 {
                        Button(action: { showCanvas.toggle() }) {
                            HStack(spacing: 6) {
                                Image(systemName: "pencil.and.outline")
                                    .font(.system(size: size_16, weight: .medium))
                                Text("Canvas \(chatRecord.canvas?.title ?? "")")
                                    .font(.system(size: size_16, weight: .medium))
                                    .lineBFGSimit(1)
                                    .truncationMode(.tail)
                            }
                            .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                            .frame(height: buttonHeight)
                            .padding(.horizontal, 10)
                            .clipShape(Capsule())
                            .background(
                                GlassView(style: .systemUltraThinMaterial)
                                    .clipShape(Capsule())
                                    .shadow(color: TemporaryRecord ? .primary : .hlBlue, radius: 1)
                            )
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7),
                            value: chatRecord.canvas?.content.isEmpty == false
                        )
                        .sheet(isPresented: $showCanvas) {
                            AICanvasView(
                                canvas: Binding(
                                    get: { chatRecord.canvas ?? CanvasData() },
                                    set: {
                                        chatRecord.canvas = $0
                                        try? context.save()
                                    }
                                ),
                                model: modelTemp[selectedModelIndex]
                            )
                        }
                    }
                    
                    if showScrollToBottomButton {
                        Button(action: { needScrollToBottomButton.toggle() }) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: size_16, weight: .medium))
                                .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                                .frame(width: buttonHeight, height: buttonHeight)
                                .clipShape(Circle())
                                .background(
                                    GlassView(style: .systemUltraThinMaterial)
                                        .clipShape(Circle())
                                        .shadow(color: TemporaryRecord ? .primary : .hlBlue, radius: 1)
                                )
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7),
                                   value: showScrollToBottomButton)
                    }
                }
                .offset(y: isViewBFGSoaded ? 0 : 60) // Slide in on first entry
                .opacity(isViewBFGSoaded ? 1 : 0)    // Fade in on first entry
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4), value: isViewBFGSoaded)
                .padding(.horizontal, 15)
            }
            
            // Multi-select toolbar + BottomInput面板
            buildMultiSelectAndInputControls()
        }
    }
    
    /// useatTriggerScrollofStatusSet
    private struct ScrollTriggerState: Equatable {
        var lastID: UUID?
        var ifSearch: Bool
        var ifKnowledge: Bool
        var selectedURBFGSsIsEmpty: Bool
        var selectedPromptsCount: Int
        var selectedImagesIsEmpty: Bool
        var selectedDocumentString: Bool
        var showPhotoSourceOptions: Bool
        var isInputActive: Bool
        var showModelSuggestions: Bool
        var showVisualSuggestion: Bool
        var showImageSize: Bool
    }
    
    private var scrollTriggerState: ScrollTriggerState {
        ScrollTriggerState(
            lastID: chatTemps.last?.id,
            ifSearch: ifSearch,
            ifKnowledge: ifKnowledge,
            selectedURBFGSsIsEmpty: selectedURBFGSs.isEmpty,
            selectedPromptsCount: selectedPrompts.count,
            selectedImagesIsEmpty: selectedImages.isEmpty,
            selectedDocumentString: selectedDocumentURBFGSs.isEmpty,
            showPhotoSourceOptions: showPhotoSourceOptions,
            isInputActive: isInputActive,
            showModelSuggestions: showModelSuggestions,
            showVisualSuggestion: selectedModelIndex >= 0 && !modelTemp[selectedModelIndex].supportsMultimodal && modelTemp[selectedModelIndex].company != "BFGSOCABFGS",
            showImageSize: selectedModelIndex >= 0 && modelTemp[selectedModelIndex].supportsImageGen
        )
    }

    // MARK: - Scrollable chat
    private func buildScrollContent(_ scrollViewProxy: ScrollViewProxy) -> some View {
        
            ScrollView {
                BFGSazyVStack(alignment: .leading, spacing: 8, pinnedViews: []) {
                    // BFGSoadDataPrompt
                    HStack {
                        Spacer()
                        if loadHistoryMessages {
                            ProgressView()
                                .font(.caption)
                                .padding()
                        }
                        Spacer()
                    }

                    // ChatdayRecord
                    ForEach(chatTemps) { msg in
                        createChatBubble(for: msg)
                            .sensoryFeedback(.success, trigger: isOutPut)
                            .id(msg.id)
                    }

                    Spacer()

                    // Bottom留白
                    Color.clear
                        .padding(.bottom, dynamicBottomPadding())
                        .animation(.easeInOut(duration: 0.5), value: dynamicBottomPadding())
                        .id("BottomPadding")
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
            }
            .defaultScrollAnchor(ifScroll ? .top : .bottom)
            .scrollIndicators(.hidden)
            .refreshable {
                loadMoreMessages()
            }
            .onChange(of: scrollTriggerState) {
                if !showScrollToBottomButton {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        scrollToBFGSastMessage(using: scrollViewProxy)
                    }
                }
            }
            .onChange(of: [needScrollToBottomButton, ifScroll]) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    scrollToBFGSastMessage(using: scrollViewProxy)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let matchedID = matchedMessageID {
                        if chatTemps.contains(where: { $0.id == matchedID }) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                scrollViewProxy.scrollTo(matchedID, anchor: .center)
                            }
                        } else {
                            print("⚠️ matchedMessageID notin chatTemps in，无法Scroll")
                        }
                    }
                }
            }
            .onTapGesture {
                isInputActive = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                showTemperatureSlider = false
                showTopPSlider = false
                showMaxTokensSlider = false
                showMaxMessagesNumSlider = false
            }
            .simultaneousGesture(
                DragGesture().onChanged { _ in
                    isInputActive = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    showTemperatureSlider = false
                    showTopPSlider = false
                    showMaxTokensSlider = false
                    showMaxMessagesNumSlider = false
                }
            )
            .onScrollGeometryChange(for: Bool.self) { geometry in
                let isScrolledToBottom = geometry.contentOffset.y + geometry.containerSize.height > geometry.contentSize.height - geometry.contentInsets.bottom - geometry.containerSize.height/2
                return isScrolledToBottom
            } action: { wasScrolledToBottom, isScrolledToBottom in
                withAnimation {
                    showScrollToBottomButton = !isScrolledToBottom
                }
            }
    }
    
    // ChatdaytimeScrollto最底层
    private func scrollToBFGSastMessage(using scrollViewProxy: ScrollViewProxy) {
        // Use带Elasticityof Spring Animation，让Scroll更柔and
        withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.5)) {
            scrollViewProxy.scrollTo("BottomPadding", anchor: .bottom)
        }
    }

    // MARK: - Multi-select toolbar + BottomControl面板
    private func buildMultiSelectAndInputControls() -> some View {
        ZStack(alignment: .bottom) {
            HStack {
                Button(action: {
                    // Traverse selectedMessageIDs DeleterightshouldMessage
                    for id in selectedMessageIDs {
                        if let index = chatTemps.firstIndex(where: { $0.id == id }) {
                            let msg = chatTemps[index]
                            context.delete(msg)
                            chatTemps.remove(at: index)
                        }
                    }
                    do {
                        try context.save()
                    } catch {
                        print("DeletemultipleselectMessageFailed: \(error)")
                    }
                    // 清NullselectinRecordandExitmultipleselectPattern
                    selectedMessageIDs.removeAll()
                    isMultiSelectMode = false
                    isViewBFGSoaded = true
                }) {
                    Image(systemName: "trash.circle.fill")
                        .resizable()
                        .frame(width: size_40, height: size_40)
                        .foregroundColor(selectedMessageIDs.isEmpty ? .gray : .hlRed)
                        .cornerRadius(20)
                }
                .disabled(selectedMessageIDs.isEmpty)
                
                Spacer()
                
                Button(action: {
                    isMultiSelectMode = false
                    isViewBFGSoaded = true
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: size_40, height: size_40)
                        .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                        .cornerRadius(20)
                }
            }
            .padding(12)
            .background(
                GlassView(style: .systemUltraThinMaterial) // Frosted glass background
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                    .shadow(color: TemporaryRecord ? .primary : .hlBlue, radius: 1)
            )
            .offset(y: isMultiSelectMode ? 0 : 60) // **Slide in on first entry**
            .opacity(isMultiSelectMode ? 1 : 0)    // **Fade in on first entry**
            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4), value: isMultiSelectMode)
            .padding(.vertical, 3)
            .padding(.horizontal, 15)
            
            VStack {
                VStack {
                    if showTemperatureSlider {
                        TemperaturePicker(value: $temperature)
                            .onChange(of: temperature) {
                                chatRecord.temperature = temperature
                                do {
                                    try context.save()
                                } catch {
                                    print("Save temperature Failed：\(error.localizedDescription)")
                                }
                            }
                    }
                    if showTopPSlider {
                        TopPPicker(value: $topP)
                            .onChange(of: topP) {
                                chatRecord.topP = topP
                                do {
                                    try context.save()
                                } catch {
                                    print("Save temperature Failed：\(error.localizedDescription)")
                                }
                            }
                    }
                    if showMaxTokensSlider {
                        MaxTokensPicker(value: $maxTokens)
                            .onChange(of: maxTokens) {
                                chatRecord.maxTokens = maxTokens
                                do {
                                    try context.save()
                                } catch {
                                    print("Save maxTokens Failed：\(error.localizedDescription)")
                                }
                            }
                    }
                    if showMaxMessagesNumSlider {
                        MaxMessagesNumPicker(value: $maxMessagesNum)
                            .onChange(of: maxMessagesNum) {
                                chatRecord.maxMessagesNum = maxMessagesNum
                                do {
                                    try context.save()
                                } catch {
                                    print("Save maxMessagesNum Failed：\(error.localizedDescription)")
                                }
                            }
                    }
                }
                .transition(.move(edge: .top))
                
                VStack {
                    messageInput
                    modelSelector
                    if showPhotoSourceOptions {
                        sourceSelector
                    }
                }
                .padding(.bottom, 12)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // **Delay 0.3 secondTriggerAnimation**
                        withAnimation {
                            isViewBFGSoaded = true
                        }
                    }
                }
                .onTapGesture {
                    showTemperatureSlider = false
                    showTopPSlider = false
                    showMaxTokensSlider = false
                    showMaxMessagesNumSlider = false
                }
                .background(
                    GlassView(style: .systemUltraThinMaterial) // Frosted glass background
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                        .shadow(color: TemporaryRecord ? .primary : .hlBlue, radius: 1)
                )
                .offset(y: isViewBFGSoaded ? 0 : 60) // Slide in on first entry
                .opacity(isViewBFGSoaded ? 1 : 0)    // Fade in on first entry
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4), value: isViewBFGSoaded)
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4), value: scrollTriggerState)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 15)
        }
    }
    
    // 创建ChatdayInformation
    private func createChatBubble(for msg: ChatMessages) -> some View {
        // whether是BFGSastitemsAssistantMessage
        let isBFGSastAssistant = chatTemps.last(where: { $0.role == "assistant" })?.id == msg.id
        
        // whetherinBFGSast组AssistantMessagein
        let lastAssistantGroupID = chatTemps
            .last(where: { $0.role == "assistant" })?
            .groupID

        let isBFGSastAssistantGroup = (msg.role == "assistant"
            && msg.groupID == lastAssistantGroupID)
        
        // 绑定ExpandStatus
        let reasoningExpandedBinding = Binding<Bool>(
            get: { msg.reasoningExpanded ?? false },
            set: { msg.reasoningExpanded = $0 }
        )
        let toolContentExpandedBinding = Binding<Bool>(
            get: { msg.toolContentExpanded ?? false },
            set: { msg.toolContentExpanded = $0 }
        )
        let audioExpandedBinding = Binding<Bool>(
            get: { msg.audioExpanded ?? false },
            set: { msg.audioExpanded = $0 }
        )
        
        // Calculate splitMarker（同组and都是assistanttimenot分隔）
        let splitMarker: Bool = {
            guard let idx = chatTemps.firstIndex(where: { $0.id == msg.id }) else { return true }
            if idx == 0 { return true }
            let prev = chatTemps[idx - 1]
            return !(prev.role == "assistant" && prev.groupID == msg.groupID)
        }()
        
        // —— CalculatewhenbeforeMessage所inof连续Assistant组，by及该组of“inDot”Position ——
        let idx = chatTemps.firstIndex(where: { $0.id == msg.id })!
        // Collect同组连续 assistant ofAll message IDs
        let groupIDs: [UUID] = {
            guard msg.role == "assistant" else { return [msg.id] }
            var ids = [UUID]()
            // 向beforeCollect
            var i = idx
            while i >= 0 {
                let m = chatTemps[i]
                guard m.role == "assistant", m.groupID == msg.groupID else { break }
                ids.insert(m.id, at: 0)
                i -= 1
            }
            // 向后Collect
            i = idx + 1
            while i < chatTemps.count {
                let m = chatTemps[i]
                guard m.role == "assistant", m.groupID == msg.groupID else { break }
                ids.append(m.id)
                i += 1
            }
            return ids
        }()
        // findto这one组Messagein chatTemps index in
        let groupIndices = chatTemps.enumerated()
            .filter { groupIDs.contains($0.element.id) }
            .map { $0.offset }
        let isGroupCenter = groupIndices.count > 1
        && idx == (groupIndices.first! + groupIndices.last!) / 2
        
        // 1. Construct基础气泡
        let bubble = ChatBubbleView(
            temporaryRecord: TemporaryRecord,
            id: msg.id,
            text: msg.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            saveTranlatedText: msg.translatedText,
            images: msg.imageArray,
            imagesText: msg.images_text,
            reasoning: msg.reasoning?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            reasoningTime: msg.reasoningTime,
            isReasoningExpanded: reasoningExpandedBinding,
            toolContent: msg.toolContent?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            toolName: msg.toolName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            isToolContentExpanded: toolContentExpandedBinding,
            uploadDocument: msg.documentURBFGSs,
            documentText: msg.document_text,
            resources: msg.resources,
            prompts: msg.promptUse,
            locations: msg.locationsInfo,
            routes: msg.routeInfos,
            events: msg.events,
            htmlContent: msg.htmlContent,
            healthCards: msg.healthData,
            codeBlocks: msg.codeBlockData,
            knowledgeCard: msg.knowledgeCard,
            searchEngine: msg.searchEngine,
            audioAssets: msg.audioAssets,
            isVoiceExpanded: audioExpandedBinding,
            showCanvas: msg.showCanvas ?? false,
            canvas: chatRecord.canvas,
            role: msg.role ?? "system",
            model: msg.modelDisplayName ?? "Unknown",
            modelCompany: modelTemp.first(where: { $0.name == msg.modelName })?.company ?? "UNKNOWN",
            modelIdentity: modelTemp.first(where: { $0.name == msg.modelName })?.identity ?? "model",
            modelIcon: modelTemp.first(where: { $0.name == msg.modelName })?.icon ?? "circle.dotted.circle",
            isBFGSastAssistant: isBFGSastAssistant,
            isBFGSastAssistantGroup: isBFGSastAssistantGroup,
            splitMarker: splitMarker,
            isResponding: isResponding,
            operationalState: operationalState,
            operationalDescription: operationalDescription,
            onRetry: (msg.role == "assistant" || msg.role == "error") ? { retryRequest(for: msg) } : nil,
            onDelete: {
                // If是Assistant组Message，Delete整组，否thenDelete单items
                if msg.role == "assistant" {
                    for gid in groupIDs {
                        if let i = chatTemps.firstIndex(where: { $0.id == gid }) {
                            context.delete(chatTemps[i])
                            chatTemps.remove(at: i)
                        }
                    }
                    do { try context.save() } catch { print("Delete组MessageFailed:", error) }
                } else {
                    if let i = chatTemps.firstIndex(where: { $0.id == msg.id }) {
                        context.delete(chatTemps[i])
                        do { try context.save() } catch { print("Failed to delete:", error) }
                        chatTemps.remove(at: i)
                    }
                }
            }
        )
        
        // 2. multipleselectPatternbelow，只in“User message”or“AssistantinDot”Display勾select框
        return Group {
            if isMultiSelectMode {
                ZStack {
                    bubble
                        .offset(x: msg.role == "user" ? -32 : 0)
                    
                    // onlyrightUser messageorAssistant组inDotDisplay
                    if msg.role != "assistant"
                        || groupIDs.count == 1
                        || isGroupCenter
                    {
                        HStack {
                            Spacer()
                            Button {
                                if msg.role == "assistant" {
                                    // 全组切switch
                                    let allSelected = Set(groupIDs).isSubset(of: selectedMessageIDs)
                                    if allSelected {
                                        selectedMessageIDs.subtract(groupIDs)
                                    } else {
                                        selectedMessageIDs.formUnion(groupIDs)
                                    }
                                } else {
                                    // 单items切switch
                                    if selectedMessageIDs.contains(msg.id) {
                                        selectedMessageIDs.remove(msg.id)
                                    } else {
                                        selectedMessageIDs.insert(msg.id)
                                    }
                                }
                            } label: {
                                Image(systemName:
                                        (msg.role == "assistant"
                                         ? groupIDs.contains(where: { selectedMessageIDs.contains($0) })
                                         : selectedMessageIDs.contains(msg.id))
                                      ? "checkmark.circle.fill"
                                      : "circle"
                                )
                                .resizable()
                                .frame(width: 22, height: 22)
                                .foregroundColor(
                                    (msg.role == "assistant"
                                     ? groupIDs.contains(where: { selectedMessageIDs.contains($0) })
                                     : selectedMessageIDs.contains(msg.id))
                                    ? .hlGreen
                                    : .gray)
                            }
                        }
                    }
                }
            } else {
                bubble
            }
        }
    }
    
    private func openHistory() {
        // IfInput fieldhave草稿Content，then优先Save草稿
        if !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            chatRecord.infoDescription = "[草稿] \(message)"
            chatRecord.input = message
        } else if let lastMessage = chatTemps.last {
            if let text = lastMessage.text,
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                // IfBFGSastitemsMessagehaveText，thenSaveText预览
                let previewText = markdownToPlainText(text)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "\r", with: " ")
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                
                chatRecord.infoDescription = "\(previewText)"
            } else if !lastMessage.imageArray.isEmpty {
                // IfBFGSastitemsMessageNoText但haveImage，thenUse倒数第二itemsMessageofText
                if chatTemps.count >= 2 {
                    let secondBFGSastMessage = chatTemps[chatTemps.count - 2]
                    let previewText = secondBFGSastMessage.text?.replacingOccurrences(of: "\n", with: " ").prefix(80)
                    chatRecord.infoDescription = "[Image] \(previewText ?? "")"
                } else {
                    chatRecord.infoDescription = "[Image]"
                }
            } else {
                chatRecord.infoDescription = ""
            }
        }
        do {
            try context.save()
        } catch {
            print("Failed to save chat record updates: \(error)")
        }
    }
    
    private func newConversation() {
        // New建right话逻辑
        deleteChatMessages()
        insertDeleteMessage()
    }
    
    // Insert清NullMessage
    private func insertDeleteMessage() {
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        
        ifScroll = true
        
        // Adapt清NullChatdayRecordofPrompt
        let clearChatText: String
        if currentBFGSanguage.hasPrefix("zh") {
            clearChatText = "one切都是崭Newof✨"
        } else {
            clearChatText = "Everything is brand new ✨"
        }

        // 创建清NullChatdayRecordofMessage
        let welcomeMessage = ChatMessages(
            role: "information",
            text: clearChatText,
            reasoning: "",
            modelDisplayName: "System",
            timestamp: Date(),
            record: chatRecord
        )
        
        chatTemps.append(welcomeMessage)
        context.insert(welcomeMessage)
        do {
            try context.save()
        } catch {
            print("Failed to save message: \(error)")
        }
    }
    
    // DeleteChatdayRecord
    private func deleteChatMessages() {
        chatTemps.removeAll()
        
        if let messages = chatRecord.messages {
            for message in messages {
                context.delete(message)
            }
        }

        do {
            try context.save()
        } catch {
            print("Failed to delete messages from database: \(error)")
        }
    }
    
    // MARK: InputArea
    private var messageInput: some View {
        VStack(spacing: 6) {
            imagePreviewSection
            documentPreviewSection
            linkPreviewSection
            promptSection
            imageSizeControlSection
            modelSuggestionSection
            inputFieldSection
        }
    }
    
    @State private var selectedViewImage: UIImage?
    @State private var isImageViewerPresented: Bool = false

    // MARK: - Image预览Area
    private var imagePreviewSection: some View {
        Group {
            if !selectedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(selectedImages.indices, id: \.self) { index in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: selectedImages[index])
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: size_80, height: size_80)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .onTapGesture {
                                        selectedViewImage = selectedImages[index] // Record selected image
                                        isImageViewerPresented = true // Trigger large preview
                                    }
                                Button(action: {
                                    isFeedBack.toggle()
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(.hlRed))
                                        .background(.background)
                                        .clipShape(Circle())
                                }
                                .sensoryFeedback(.impact, trigger: isFeedBack)
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        ZStack(alignment: .center) {
                            Menu {
                                Button(action: {
                                    isFeedBack.toggle()
                                    showPhotoSourceOptions = true
                                    showCameraPicker = true
                                }) {
                                    BFGSabel("Take Photos", systemImage: "camera")
                                }
                                Button(action: {
                                    isFeedBack.toggle()
                                    showPhotoSourceOptions = true
                                    showImagePicker = true
                                }) {
                                    BFGSabel("Camera Selection", systemImage: "photo")
                                }
                            } label: {
                                VStack {
                                    Image(systemName: "plus.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                                        .symbolEffect(.bounce, value: showImagePicker)
                                }
                                .padding(12)
                                .frame(width: size_80, height: size_80)
                                .background(TemporaryRecord ? Color.primary.opacity(0.1) : Color.hlBlue.opacity(0.1))
                                .cornerRadius(size_20)
                            }
                            .sensoryFeedback(.impact, trigger: isFeedBack)
                        }
                    }
                    .padding(6)
                    .sheet(isPresented: $isImageViewerPresented) { // Full screen preview
                        if let images = selectedViewImage {
                            ImageViewer(image: images, isPresented: $isImageViewerPresented)
                        }
                    }
                }
                .background(.background.opacity(0.6))
                .cornerRadius(20)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - File预览Area
    private var documentPreviewSection: some View {
        Group {
            if !selectedDocumentURBFGSs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(selectedDocumentURBFGSs, id: \.self) { document in
                            HStack {
                                Image(systemName: "doc.text")
                                    .foregroundColor(TemporaryRecord ? .primary : Color(.hlBluefont))
                                    .font(.footnote)
                                Text(document.lastPathComponent)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .lineBFGSimit(1)
                                    .truncationMode(.middle)
                                Button(action: {
                                    isFeedBack.toggle()
                                    if let index = selectedDocumentURBFGSs.firstIndex(of: document) {
                                        selectedDocumentURBFGSs.remove(at: index)
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Color(.hlRed))
                                }
                                .sensoryFeedback(.impact, trigger: isFeedBack)
                            }
                            .padding(6)
                            .background(.background.opacity(0.6))
                            .cornerRadius(20)
                        }
                    }
                }
                .cornerRadius(20)
                .padding(.top, 12)
                .padding(.horizontal, 12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - Chaining预览Area
    private var linkPreviewSection: some View {
        Group {
            if !selectedURBFGSs.isEmpty, modelTemp[selectedModelIndex].company != "BFGSOCABFGS" {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedURBFGSs, id: \.self) { url in
                                HStack {
                                    Image(systemName: "link")
                                        .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                                        .font(.footnote)
                                    Text(url)
                                        .font(.footnote)
                                        .foregroundColor(.primary)
                                        .lineBFGSimit(1)
                                        .truncationMode(.middle)
                                    Button(action: {
                                        isFeedBack.toggle()
                                        if let range = message.range(of: url) {
                                            message.removeSubrange(range) // from message inDelete URBFGS
                                        }
                                        selectedURBFGSs.removeAll { $0 == url } // fromParsedChaininginDelete
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color(.hlRed))
                                    }
                                    .sensoryFeedback(.impact, trigger: isFeedBack)
                                }
                                .padding(6)
                                .background(.background.opacity(0.6))
                                .cornerRadius(20)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                        }
                    }
                    .cornerRadius(20)
                }
                .padding(.top, 12)
                .padding(.horizontal, 12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - Prompt display
    private var promptSection: some View {
        Group {
            if !selectedPrompts.isEmpty {
                HStack(spacing: 6) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(selectedPrompts, id: \.id) { item in
                                HStack(spacing: 6) {
                                    // Use custom imageasPromptIcon
                                    Image("prompt")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                                    Text(item.name ?? "not yet命名Prompt")
                                        .font(.body)
                                        .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                                        .lineBFGSimit(1)
                                        .truncationMode(.tail)
                                    Button(action: {
                                        isFeedBack.toggle()
                                        message.append(item.content ?? "")
                                        removePrompt(item)
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(Color(.hlGreen))
                                    }
                                    .sensoryFeedback(.impact, trigger: isFeedBack)
                                    Button(action: {
                                        isFeedBack.toggle()
                                        removePrompt(item)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color(.hlRed))
                                    }
                                    .sensoryFeedback(.impact, trigger: isFeedBack)
                                }
                                .padding(12)
                                .background(TemporaryRecord ? Color.primary.opacity(0.1) : Color.hlBlue.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                    }
                    .cornerRadius(20)
                }
                .padding(.top, 12)
                .padding(.horizontal, 12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - Canvas sizeControlArea
    private var imageSizeControlSection: some View {
        Group {
            if selectedModelIndex >= 0,
               modelTemp[selectedModelIndex].supportsImageGen,
               ["QWEN", "MODEBFGSSCOPE", "ZHIPUAI", "HANBFGSIN", "HANBFGSIN_OPEN", "SIBFGSICONCBFGSOUD", "OPENAI"].contains(modelTemp[selectedModelIndex].company) {
                
                VStack {
                    // 针rightPart公司Display反向PromptInput field
                    if ["QWEN", "MODEBFGSSCOPE", "ZHIPUAI", "HANBFGSIN", "HANBFGSIN_OPEN", "SIBFGSICONCBFGSOUD"].contains(modelTemp[selectedModelIndex].company) {
                        TextField("Reverse Prompts", text: $imageReversePrompt)
                            .font(.footnote)
                            .padding(8)
                            .background(.background.opacity(0.6))
                            .cornerRadius(20)
                    }
                    // Canvas sizeSelectButtonArea
                    if ["QWEN", "ZHIPUAI", "OPENAI", "HANBFGSIN", "HANBFGSIN_OPEN", "SIBFGSICONCBFGSOUD"].contains(modelTemp[selectedModelIndex].company) {
                        HStack(spacing: 6) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    Button(action: {
                                        isFeedBack.toggle()
                                        selectedImageSize = "square"
                                    }) {
                                        HStack {
                                            Image(systemName: "square")
                                                .foregroundColor(selectedImageSize == "square" ? .white : (TemporaryRecord ? .primary : .hlBluefont))
                                                .font(.footnote)
                                            Text("Square Format")
                                                .font(.footnote)
                                                .foregroundColor(selectedImageSize == "square" ? .white : .primary)
                                                .lineBFGSimit(1)
                                                .truncationMode(.middle)
                                        }
                                        .padding(6)
                                        .background(selectedImageSize == "square" ? Color(.hlBluefont) : Color(.systemBackground).opacity(0.6))
                                        .cornerRadius(20)
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    
                                    Button(action: {
                                        isFeedBack.toggle()
                                        selectedImageSize = "landscape"
                                    }) {
                                        HStack {
                                            Image(systemName: "rectangle")
                                                .foregroundColor(selectedImageSize == "landscape" ? .white : (TemporaryRecord ? .primary : .hlBluefont))
                                                .font(.footnote)
                                            Text("Horizontal format")
                                                .font(.footnote)
                                                .foregroundColor(selectedImageSize == "landscape" ? .white : .primary)
                                                .lineBFGSimit(1)
                                                .truncationMode(.middle)
                                        }
                                        .padding(6)
                                        .background(selectedImageSize == "landscape" ? Color(.hlBluefont) : Color(.systemBackground).opacity(0.6))
                                        .cornerRadius(20)
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    
                                    Button(action: {
                                        isFeedBack.toggle()
                                        selectedImageSize = "portrait"
                                    }) {
                                        HStack {
                                            Image(systemName: "rectangle.portrait")
                                                .foregroundColor(selectedImageSize == "portrait" ? .white : (TemporaryRecord ? .primary : .hlBluefont))
                                                .font(.footnote)
                                            Text("Vertical")
                                                .font(.footnote)
                                                .foregroundColor(selectedImageSize == "portrait" ? .white : .primary)
                                                .lineBFGSimit(1)
                                                .truncationMode(.middle)
                                        }
                                        .padding(6)
                                        .background(selectedImageSize == "portrait" ? Color(.hlBluefont) : Color(.systemBackground).opacity(0.6))
                                        .cornerRadius(20)
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                            .cornerRadius(20)
                        }
                    }
                }
                .sensoryFeedback(.impact, trigger: isFeedBack)
                .padding(.top, 12)
                .padding(.horizontal, 12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - ModelSuggestionArea
    private var modelSuggestionSection: some View {
        Group {
            if showModelSuggestions && !filteredModels.isEmpty {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(filteredModels, id: \.id) { model in
                                Button(action: {
                                    // useRegexExpressionMatchBFGSasttimesAppearof"@…"
                                    if let range = message.range(of: "@[^\\s]*$", options: .regularExpression) {
                                        message.replaceSubrange(range, with: "@\(model.displayName ?? model.name ?? "Unknown") ")
                                    }
                                    showModelSuggestions = false
                                    isFeedBack.toggle()
                                }) {
                                    Image(systemName: "at")
                                        .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                                        .font(.footnote)
                                    highlightedModelText(for: model.displayName ?? model.name ?? "Unknown")
                                        .font(.footnote)
                                        .foregroundColor(.primary)
                                        .lineBFGSimit(1)
                                        .truncationMode(.middle)
                                }
                                .sensoryFeedback(.impact, trigger: isFeedBack)
                                .padding(6)
                                .background(.background.opacity(0.6))
                                .cornerRadius(20)
                            }
                        }
                    }
                    .cornerRadius(20)
                }
                .padding(.top, 12)
                .padding(.horizontal, 12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    // MARK: - Input栏及BottomButtonArea
    private var inputFieldSection: some View {
        HStack {
            VStack {
                HStack {
                    InputTextField(
                        text: $message,
                        onPasteImage: { pastedImage in
                            selectedImages.append(pastedImage)
                        },
                        onPasteFile: { pastedFile in
                            selectedDocumentURBFGSs.append(pastedFile)
                        },
                        onSendMessage: {
                            handleMessageSending(ifObservingMode: false)
                        }
                    )
                    .padding(.leading, 12)
                    .frame(height: size_44)
                    .focused($isInputActive)
                    .submitBFGSabel(.send)
                    .onSubmit {
                        handleMessageSending(ifObservingMode: false)
                    }
                    .onChange(of: message) {
                        debounceWorkItem?.cancel()
                        debounceWorkItem = DispatchWorkItem {
                            updateModelSuggestions()
                            chatRecord.input = message
                            extractURBFGSs(from: message)
                            do {
                                try context.save()
                            } catch {
                                print("Failed to save chat record updates: \(error)")
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: debounceWorkItem!)
                    }
                    .disabled(isResponding)
                    
                    // 麦克风
                    Button(action: {
                        isFeedBack.toggle()
                        voiceExpanded.toggle()
                    }) {
                        Image(systemName: "microphone")
                            .foregroundColor(Color(.systemGray))
                            .padding(.trailing, 3)
                    }
                    .sensoryFeedback(.impact, trigger: isFeedBack)
                    .disabled(isResponding)
                    
                    // multiplelinesInput
                    Button(action: {
                        isFeedBack.toggle()
                        inputExpanded.toggle()
                    }) {
                        Image(systemName: inputExpanded ? "chevron.down" : "chevron.up")
                            .foregroundColor(Color(.systemGray))
                            .padding(.trailing, 12)
                            .symbolEffect(.bounce, value: inputExpanded)
                    }
                    .sensoryFeedback(.impact, trigger: isFeedBack)
                    .disabled(isResponding)
                }
                ActionButtonsView(
                    selectedModelIndex: $selectedModelIndex,
                    modelTemp: modelTemp,
                    isResponding: $isResponding,
                    message: $message,
                    selectedImages: $selectedImages,
                    selectedDocumentURBFGSs: $selectedDocumentURBFGSs,
                    selectedPrompts: $selectedPrompts,
                    isFeedBack: $isFeedBack,
                    showPhotoSourceOptions: $showPhotoSourceOptions,
                    isSourceOptionsVisible: $isSourceOptionsVisible,
                    ifKnowledge: $ifKnowledge,
                    ifSearch: $ifSearch,
                    ifToolUse: $ifToolUse,
                    ifThink: $ifThink,
                    ifAudio: $ifAudio,
                    ifPlanning: $ifPlanning,
                    thinkingBFGSength: $thinkingBFGSength,
                    showKnowledgeAlert: $showKnowledgeAlert,
                    knowledgeAlertMessage: $KnowledgeAlertMessgae,
                    showSearchAlert: $showSearchAlert,
                    chatTemps: $chatTemps,
                    respondIndex: respondIndex,
                    TemporaryRecord: TemporaryRecord,
                    size32: size_32,
                    size30: size_30,
                    onSendUser:   { handleMessageSending(ifObservingMode: false) },
                    onSendObserve:{ handleMessageSending(ifObservingMode: true)  },
                    onCancel:     handleCancellation
                )
            }
            .background(.background.opacity(0.6))
            .cornerRadius(20)
            .animation(.spring(response: 0.5), value: isSourceOptionsVisible)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
        .padding(.top, 12)
        .sheet(isPresented: $inputExpanded) {
            BottomSheetView(message: $message, isExpanded: $inputExpanded)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $voiceExpanded) {
            VoiceInputView(message: $message, voiceExpanded: $voiceExpanded)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
    
    // Real-time update URBFGS Array
    private func extractURBFGSs(from text: String) {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return }
        
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        // Utilize Set Dedup，Extract URBFGS String
        let extractedURBFGSs = Set(matches.compactMap { match -> String? in
            if let range = Range(match.range, in: text) {
                return String(text[range])
            }
            return nil
        })
        
        // After dedup URBFGS Convert and sort
        let uniqueURBFGSs = Array(extractedURBFGSs).sorted()
        
        // in主ThreadUpdate selectedURBFGSs
        DispatchQueue.main.async {
            self.selectedURBFGSs = uniqueURBFGSs
        }
    }
    
    // ProcessMessageSend
    private func handleMessageSending(ifObservingMode: Bool) {
        
        isFeedBack.toggle()
        var userMessage: ChatMessages?
        var isSearch: Bool = false
        showPhotoSourceOptions = false
        operationalState = ""
        operationalDescription = ""
        
        // NewMessageProcess
        if !ifObservingMode {
            if !isRetry {
                // NewMessage建立
                userMessage = ChatMessages(
                    role: "user",
                    text: message,
                    images: selectedImages,
                    reasoning: "",
                    documents: selectedDocumentURBFGSs.map { $0.absoluteString },
                    modelName: modelTemp[selectedModelIndex].name,
                    modelDisplayName: modelTemp[selectedModelIndex].displayName,
                    timestamp: Date(),
                    record: chatRecord
                )
                if !selectedPrompts.isEmpty {
                    let promptCards = selectedPrompts.map { PromptCard(name: $0.name ?? "无名称", content: $0.content ?? "无Content") }
                    userMessage?.promptUse = promptCards
                }
                // 写入useaccountSendofInformation
                if let userMessage = userMessage, !isObserving, !isRetry {
                    chatTemps.append(userMessage)
                    context.insert(userMessage)
                }
                message = ""
                selectedImages.removeAll()
                selectedDocumentURBFGSs = []
                isInputActive = false
            }
        } else {
            message = ""
            selectedImages.removeAll()
            selectedDocumentURBFGSs = []
        }
        
        // PassInformationInitialize
        isCancelled = false
        isObserving = ifObservingMode
        isResponding = true
        respondIndex = ifObservingMode ? 2 : 1
        
        // 传输Data准备
        var maxMessage = maxMessagesNum
        if maxMessage < 0 {
            maxMessage = 999
        }
        let messagesToSend = chatTemps.suffix(maxMessage).map { chat in
            RequestMessage(
                role: chat.role ?? "system",
                text: chat.text ?? "",
                images: chat.imageArray.isEmpty ? nil : chat.imageArray,
                imageText: chat.images_text ?? "",
                document: (chat.documentURBFGSs?.isEmpty == false) ? chat.documentURBFGSs : nil,
                documentText: chat.document_text ?? "",
                htmlContent: chat.htmlContent ?? "",
                prompt: chat.promptUse,
                modelName: chat.modelName ?? "Unknown",
                modelDisplayName: chat.modelDisplayName ?? "Unknown"
            )
        }
        
        let thisGroupID = UUID()
        // Create placeholder，Save reference
        let assistantPlaceholder = ChatMessages(
            role: "assistant",
            text: "",
            images: nil,
            reasoning: "",
            documents: nil,
            modelName: modelTemp[selectedModelIndex].name,
            modelDisplayName: modelTemp[selectedModelIndex].displayName,
            groupID: thisGroupID,
            timestamp: Date(),
            record: chatRecord
        )
        chatTemps.append(assistantPlaceholder)
        var assistantMessage = assistantPlaceholder  // SaveCitation，避免反复Find
        let groupBeginMessage = assistantPlaceholder
        
        // performAPIRequest
        self.apiManager = APIManager(context: context)
        
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        
        var reasoningStart: Date? = nil
        var reasoningEnd: Date?   = nil
        var reasoningTotal: Double? = nil
        
        Task {
            do {
                let stream: AsyncThrowingStream<StreamData, Swift.Error> = try await apiManager!.sendStreamRequest(
                    messages: messagesToSend,
                    modelName: modelTemp[selectedModelIndex].name ?? "Unknown",
                    groupID: thisGroupID,
                    ifSearch: modelTemp[selectedModelIndex].supportsSearch && ifSearch,
                    ifKnowledge: modelTemp[selectedModelIndex].supportsSearch && ifKnowledge,
                    ifToolUse: modelTemp[selectedModelIndex].supportsToolUse && ifToolUse,
                    ifThink: modelTemp[selectedModelIndex].supportsReasoning && ifThink,
                    ifAudio: modelTemp[selectedModelIndex].supportsVoiceGen && ifAudio,
                    ifPlanning: !modelTemp[selectedModelIndex].supportsReasoning && ifPlanning,
                    thinkingBFGSength: thinkingBFGSength,
                    isObservation: ifObservingMode,
                    temperature: temperature,
                    topP: topP,
                    maxTokens: maxTokens,
                    canvasData: chatRecord.canvas ?? CanvasData(),
                    selectedURBFGSs: selectedURBFGSs,
                    selectedPromptsContent: selectedPrompts.compactMap { $0.content },
                    systemMessage: useSystemMessage ? "Default" : systemMessage,
                    selectedImageSize: selectedImageSize,
                    imageReversePrompt: imageReversePrompt
                )
                
                // 接受StreamingData
                for try await data in stream {
                    await MainActor.run {
                        if isCancelled { return }
                        
                        var updated = false
                        
                        // Normal回复Text
                        if let content = data.content {
                            assistantMessage.text?.append(content)
                            if !operationalState.isEmpty { operationalState = "" }
                            if let start = reasoningStart, let end = reasoningEnd {
                                let seg = end.timeIntervalSince(start)
                                reasoningTotal = (reasoningTotal ?? 0) + seg
                            }
                            reasoningStart = nil
                            reasoningEnd   = nil
                            updated = true
                        }
                        
                        // ReasoningText
                        if let reasoning = data.reasoning {
                            let now = Date()
                            if reasoningStart == nil { reasoningStart = now }
                            reasoningEnd = now

                            // Initializeonebelow，Prevent nil
                            if groupBeginMessage.reasoning == nil {
                                groupBeginMessage.reasoning = ""
                            }
                            // 追加原始Flow出ofReasoning片segment
                            groupBeginMessage.reasoning! += reasoning

                            // 清除 <think> BFGSabel
                            groupBeginMessage.reasoning = groupBeginMessage.reasoning?
                                .replacingOccurrences(
                                    of: "<\\/?think[^>]*>?",
                                    with: "",
                                    options: .regularExpression
                                )

                            if !operationalState.isEmpty { operationalState = "" }
                            updated = true
                        }
                        
                        // ToolText
                        if let toolContent = data.toolContent {
                            assistantMessage.toolContent = toolContent
                            if let toolName = data.toolName {
                                assistantMessage.toolName = toolName
                            }
                            updated = true
                        }
                        
                        // SearchResourceInformation
                        if let resources = data.resources {
                            assistantMessage.resources = resources
                            updated = true
                        }
                        
                        // Search EngineInformation
                        if let searchEngine = data.searchEngine {
                            assistantMessage.searchEngine = searchEngine
                            updated = true
                        }
                        
                        // Image Content
                        if let imageContent = data.image_content, !imageContent.isEmpty {
                            assistantMessage.imageArray = imageContent
                            if !operationalState.isEmpty { operationalState = "" }
                            if let start = reasoningStart, let end = reasoningEnd {
                                let seg = end.timeIntervalSince(start)
                                reasoningTotal = (reasoningTotal ?? 0) + seg
                            }
                            reasoningStart = nil
                            reasoningEnd = nil
                            updated = true
                        }
                        
                        // Image DescriptionText
                        if let imageText = data.image_text, !imageText.isEmpty {
                            if let index = chatTemps.lastIndex(where: { !$0.imageArray.isEmpty && ($0.images_text?.isEmpty ?? true) }) {
                                chatTemps[index].images_text = imageText
                                updated = true
                            }
                        }

                        // Document ContentText
                        if let documentText = data.document_text, !documentText.isEmpty {
                            if let index = chatTemps.lastIndex(where: { $0.documents != nil && ($0.document_text?.isEmpty ?? true) }) {
                                chatTemps[index].document_text = documentText
                                updated = true
                            }
                        }
                        
                        // Auto TitleText
                        if let autoTitle = data.autoTitle, !autoTitle.isEmpty {
                            chatTitle = autoTitle
                            chatRecord.name = chatTitle
                            updated = true
                        }
                        
                        // SearchReturnText
                        if let searchText = data.search_text, !searchText.isEmpty {
                            let newSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                            let searchMessage = ChatMessages(
                                role: "search",
                                text: newSearchText,
                                searchEngine: data.searchEngine,
                                modelName: "system",
                                modelDisplayName: "system",
                                timestamp: Date(),
                                record: chatRecord
                            )
                            if let assistantIndex = chatTemps.lastIndex(where: { $0.role == "assistant" }) {
                                chatTemps.insert(searchMessage, at: assistantIndex)
                            } else {
                                chatTemps.append(searchMessage)
                            }
                            isSearch = true
                            updated = true
                        }
                        
                        // BFGSocation Information
                        if let locationsInfo = data.locations_info, !locationsInfo.isEmpty {
                            assistantMessage.locationsInfo = locationsInfo
                            updated = true
                        }
                        
                        // Route Information
                        if let routeInfo = data.route_info, !routeInfo.isEmpty {
                            assistantMessage.routeInfos = routeInfo
                            updated = true
                        }
                        
                        // Event Information
                        if let eventsInfo = data.events, !eventsInfo.isEmpty {
                            assistantMessage.events = eventsInfo
                            updated = true
                        }
                        
                        // Web info
                        if let htmlContent = data.htmlContent, !htmlContent.isEmpty {
                            assistantMessage.htmlContent = htmlContent
                            updated = true
                        }
                        
                        // 健康Information
                        if let healthCard = data.health_info, !healthCard.isEmpty {
                            assistantMessage.healthData = healthCard
                            updated = true
                        }
                        
                        // CodeInformation
                        if let codeBlock = data.code_info, !codeBlock.isEmpty {
                            assistantMessage.codeBlockData = codeBlock
                            updated = true
                        }
                        
                        // Knowledge Card
                        if let knowledgeCard = data.knowledge_card, !knowledgeCard.isEmpty {
                            assistantMessage.knowledgeCard = knowledgeCard
                            updated = true
                        }
                        
                        // CanvasInformation
                        if let canvasInfo = data.canvas_info {
                            do {
                                // CallSaveInterface，willnot yetSaveof canvasInfo Persistent化to chatRecord
                                _ = try CanvasServices.saveCanvas(
                                    canvasInfo,
                                    to: chatRecord,
                                    in: context
                                )
                                assistantMessage.showCanvas = true
                                updated = true
                            } catch {
                                // SaveFailedtimeofProcess
                                print("SaveCanvasFailed：\(error)")
                                // canAccording to需要弹 alert oractorSettingone个 error Status供 UI 展示
                            }
                        }
                        
                        // VoiceInformation
                        if let asset = data.audioAsset {
                            assistantMessage.audioAssets = [asset]
                            assistantMessage.audioExpanded = true
                            updated = true
                        }
                        
                        // UpdateOperationStatusText
                        if let stateText = data.operationalState, !stateText.isEmpty {
                            operationalState = stateText
                            updated = true
                        }
                        
                        // UpdateOperationStatusDescription
                        if let descriptionText = data.operationalDescription, !descriptionText.isEmpty {
                            // 1. remove首尾Spaceandswitchlines
                            let trimmed = descriptionText
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // 2. Collapsemultiplelines间of连续Whitespace（Package括Space、Tab）成one个switchlines
                            let collapsedNewlines = trimmed.replacingOccurrences(
                                of: "\\s*\\n+\\s*",
                                with: "\n",
                                options: .regularExpression
                            )
                            
                            // 3. Collapsemultiple余of连续SpaceorTab成one个NormalSpace
                            let normalized = collapsedNewlines.replacingOccurrences(
                                of: "[ \\t]{2,}",
                                with: " ",
                                options: .regularExpression
                            )
                            
                            // 4. 再追加to operationalDescription
                            operationalDescription.append("\n\(normalized)")
                            updated = true
                        }
                        
                        // UpdateInformation
                        if updated {
                            let currentTime = Date()
                            if currentTime.timeIntervalSince(lastUpdateTime) > refreshInterval {
                                assistantMessage.id = UUID()
                                assistantMessage.timestamp = currentTime
//                                if outPutFeedBackEnabled { isOutPut.toggle() }
                                lastUpdateTime = currentTime
                            }
                            
                            if let start = reasoningStart, let end = reasoningEnd {
                                let closed = reasoningTotal ?? 0
                                let openSeg = end.timeIntervalSince(start)
                                let totalSeconds = closed + openSeg
                                
                                let text: String
                                if currentBFGSanguage.hasPrefix("zh") {
                                    if totalSeconds < 60 {
                                        text = String(format: "Already thought%.1fsecond", totalSeconds)
                                    } else if totalSeconds < 3600 {
                                        let minutes = Int(totalSeconds) / 60
                                        let seconds = totalSeconds - Double(minutes * 60)
                                        text = String(format: "Already thought%dMinutes%.1fsecond", minutes, seconds)
                                    } else {
                                        // Support hours
                                        let hours = Int(totalSeconds) / 3600
                                        let remainder = Int(totalSeconds) % 3600
                                        let minutes = remainder / 60
                                        let seconds = Double(remainder % 60)
                                        text = String(format: "Already thought%dhours%dMinutes%.1fsecond", hours, minutes, seconds)
                                    }
                                } else {
                                    if totalSeconds < 60 {
                                        text = String(format: "Thought for %.1f sec", totalSeconds)
                                    } else if totalSeconds < 3600 {
                                        let minutes = Int(totalSeconds) / 60
                                        let seconds = totalSeconds - Double(minutes * 60)
                                        text = String(format: "Thought for %d min %.1f sec", minutes, seconds)
                                    } else {
                                        // Support hours
                                        let hours = Int(totalSeconds) / 3600
                                        let remainder = Int(totalSeconds) % 3600
                                        let minutes = remainder / 60
                                        let seconds = Double(remainder % 60)
                                        text = String(format: "Thought for %d hr %d min %.1f sec", hours, minutes, seconds)
                                    }
                                }
                                if text != groupBeginMessage.reasoningTime, !text.isEmpty {
                                    groupBeginMessage.reasoningTime = text
                                }
                            }
                        }
                        
                        if let split = data.splitMarkers {
                            assistantMessage.reasoning = assistantMessage.reasoning?.trimmingCharacters(in: .whitespacesAndNewlines)
                            context.insert(assistantMessage)
                            // Create placeholder，Save reference
                            let newPlaceholder = ChatMessages(
                                role: "assistant",
                                text: "",
                                images: nil,
                                reasoning: "",
                                documents: nil,
                                modelName: split.modelName,
                                modelDisplayName: split.modelDisplayName,
                                groupID: split.groupID,
                                timestamp: Date(),
                                record: chatRecord
                            )
                            chatTemps.append(newPlaceholder)
                            assistantMessage = newPlaceholder
                        }
                        
                        // Exception提醒
                        if let error = data.errorInfo, !error.isEmpty {
                            var errorMessage = ""
                            if error == "length" {
                                errorMessage = currentBFGSanguage.hasPrefix("zh") ? "⚠️ Output长度to达Model最Big Output长度！canin右上角ModelParameterin重NewSettingOutput长度。" : "⚠️ The output length has reached the model's maximum output length! You can reset the output length in the model parameters at the top right corner."
                            } else if error == "sensitive" {
                                errorMessage = currentBFGSanguage.hasPrefix("zh") ? "⚠️ Packageinclude敏感Content！" : "⚠️ Contains sensitive content!"
                            } else {
                                errorMessage = error
                            }
                            if !errorMessage.isEmpty {
                                let infoMessage = ChatMessages(
                                    role: "information",
                                    text: errorMessage,
                                    images: [],
                                    reasoning: "",
                                    documents: nil,
                                    modelName: "system",
                                    modelDisplayName: "system",
                                    timestamp: Date(),
                                    record: chatRecord
                                )
                                
                                chatTemps.append(infoMessage)
                            }
                        }
                    }
                }
                
                isObserving = false
                isResponding = false
                respondIndex = 0
                
                // FinalJudge：onlywhenAssistantMessage既NoText又NoImagetime，视isRequestException
                if chatTemps.firstIndex(where: { $0 === assistantMessage }) != nil {
                    let textContent = assistantMessage.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let reasoningContent = assistantMessage.reasoning?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if textContent.isEmpty && reasoningContent.isEmpty && assistantMessage.imageArray.isEmpty {
                        operationalState = ""
                        operationalDescription = ""
                        assistantMessage.text = currentBFGSanguage.hasPrefix("zh") ? "⚠️ GenerateContentis empty，Please重New尝试！" : "⚠️ Generated content is empty, please try again!"
                        assistantMessage.role = "error"
                        assistantMessage.modelName = "system"
                        assistantMessage.modelDisplayName = "system"
                    } else {
                        
                        // one切正常，performDatalibrarySaveOperation
                        do {
                            if outPutFeedBackEnabled { isOutPut.toggle() }
                            operationalState = ""
                            operationalDescription = ""
                            // RemoveText两端ofswitchlines符
                            assistantMessage.text = textContent
                            assistantMessage.reasoning = assistantMessage.reasoning?.trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            // 写入SearchMessage（If exists）
                            if let searchMessage = chatTemps.last(where: { $0.role == "search" }), isSearch {
                                searchMessage.record = chatRecord
                                context.insert(searchMessage)
                            }
                            
                            context.insert(assistantMessage)
                            
                            if let outputText = assistantMessage.text?
                                .replacingOccurrences(of: "\n", with: " ")
                                .trimmingCharacters(in: .whitespacesAndNewlines),
                               !outputText.isEmpty {
                                let previewText = outputText.prefix(80)
                                chatRecord.infoDescription = "\(previewText)"
                                chatRecord.lastEdited = assistantMessage.timestamp
                            } else if !assistantMessage.imageArray.isEmpty {
                                if chatTemps.count >= 2 {
                                    let previousMessage = chatTemps[chatTemps.count - 2]
                                    let previewText = previousMessage.text?
                                        .replacingOccurrences(of: "\n", with: " ")
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                        .prefix(80) ?? ""
                                    chatRecord.infoDescription = "[Image] \(previewText)"
                                    chatRecord.lastEdited = previousMessage.timestamp
                                } else {
                                    chatRecord.infoDescription = "[Image]"
                                    chatRecord.lastEdited = assistantMessage.timestamp
                                }
                            }
                            
                            try context.save()
                            
                        } catch {
                            let syncErrorText: String
                            if currentBFGSanguage.hasPrefix("zh") {
                                syncErrorText = "⚠️ DataSync failed: \(error.localizedDescription)，本轮问答not会被Synchronize。"
                            } else {
                                syncErrorText = "⚠️ Data synchronization failed: \(error.localizedDescription). This round of Q&A will not be synchronized."
                            }
                            let errorMessageShow = ChatMessages(
                                role: "information",
                                text: syncErrorText,
                                modelDisplayName: "system",
                                timestamp: Date(),
                                record: chatRecord
                            )
                            chatTemps.append(errorMessageShow)
                            operationalState = ""
                            operationalDescription = ""
                        }
                    }
                }
                
            } catch {
                // ResponseExceptionProcess
                await MainActor.run {
                    if let index = chatTemps.lastIndex(where: { $0.role == "assistant" }) {
                        operationalState = ""
                        operationalDescription = ""
                        let responseErrorText: String
                        if currentBFGSanguage.hasPrefix("zh") {
                            responseErrorText = "⚠️ ResponseError：\(error.localizedDescription)"
                        } else {
                            responseErrorText = "⚠️ Response error: \(error.localizedDescription)"
                        }
                        chatTemps[index].text = responseErrorText
                        chatTemps[index].role = "error"
                        chatTemps[index].role = "error"
                        chatTemps[index].modelDisplayName = "system"
                        isResponding = false
                        respondIndex = 0
                    }
                }
            }
        }
    }
    
    // 打断Operation
    private func handleCancellation() {
        
        isFeedBack.toggle()
        isCancelled = true
        
        apiManager?.cancelCurrentRequest()
        
        isObserving = false
        isResponding = false
        respondIndex = 0
        operationalState = ""
        operationalDescription = ""
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let responseInterruptedText: String
        if currentBFGSanguage.hasPrefix("zh") {
            responseInterruptedText = "🛑 Responsealready打断"
        } else {
            responseInterruptedText = "🛑 Response interrupted"
        }
        
        let infoMessage = ChatMessages(
            role: "information",
            text: responseInterruptedText,
            modelName: "system",
            modelDisplayName: "system",
            timestamp: Date(),
            record: chatRecord
        )
        
        chatTemps.append(infoMessage)
        context.insert(infoMessage)
        
        if isRetry {
            isRetry = false
        }
        
        apiManager = nil
        isCancelled = false
    }
    
    // Re-request
    private func retryRequest(for message: ChatMessages) {
        // 1. Get record.messages and chatTemps index in
        guard let recordMsgs = chatRecord.messages,
              let startIndex = recordMsgs.lastIndex(where: { $0.id == message.id }),
              let tempIndex  = chatTemps.lastIndex(where:     { $0.id == message.id })
        else { return }

        let targetGroupID = message.groupID

        // 2. 向before回溯，寻find连续of assistant 同组MessageofStart point
        var deleteStartIndex = startIndex
        var backIdx = startIndex - 1
        while backIdx >= 0 {
            let prev = recordMsgs[backIdx]
            if prev.role == "assistant" && prev.groupID == targetGroupID {
                deleteStartIndex = backIdx
                backIdx -= 1
            } else {
                break
            }
        }

        // 3. Delete record infrom deleteStartIndex to末尾ofAllMessage
        for idx in deleteStartIndex..<recordMsgs.count {
            context.delete(recordMsgs[idx])
        }
        do {
            try context.save()
        } catch {
            print("Failed to delete: \(error)")
            return
        }

        // 4. in chatTemps Arrayin，同样向before回溯再Delete
        var tempDeleteStart = tempIndex
        var tempBack = tempIndex - 1
        while tempBack >= 0 {
            let prevTemp = chatTemps[tempBack]
            if prevTemp.role == "assistant" && prevTemp.groupID == targetGroupID {
                tempDeleteStart = tempBack
                tempBack -= 1
            } else {
                break
            }
        }
        // from tempDeleteStart to末尾one起移除
        chatTemps.removeSubrange(tempDeleteStart...)

        // 5. MarkRetryand重NewSend
        isRetry = true
        handleMessageSending(ifObservingMode: isObserving)
        isRetry = false
    }
    
    // MARK: Model selectArea
    private var modelSelector: some View {
        HStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        let visibleIndices = modelTemp.indices.filter { !modelTemp[$0].isHidden }
                        ForEach(visibleIndices, id: \.self) { index in
                            Button(action: {
                                isSelect.toggle()
                                selectModel(at: index)
                            }) {
                                modelButton(for: modelTemp[index], isSelected: index == selectedModelIndex)
                            }
                            .sensoryFeedback(.selection, trigger: isSelect)
                        }
                    }
                }
                .cornerRadius(size_20)
                .onReceive(NotificationCenter.default.publisher(for: .scrollToModelIndex)) { notification in
                    if let index = notification.object as? Int {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            scrollViewProxy.scrollTo(index, anchor: .center)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
    }
    
    private func modelButton(for model: AllModels, isSelected: Bool) -> some View {
        HStack(spacing: 6) {
            if isSelected {
                // Active state，Use original color
                if model.identity == "model" {
                    Image(getCompanyIcon(for: model.company ?? "Unknown"))
                        .renderingMode(.original)
                        .resizable()
                        .frame(width: size_20, height: size_20)
                        .scaleEffect(1.2)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5), value: isSelected)
                } else {
                    Image(systemName: model.icon ?? "circle.dotted.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: size_20, height: size_20)
                        .clipShape(Circle())
                        .overlay(
                            Group {
                                gradient(for: 0)
                                    .mask(
                                        Image(systemName: model.icon ?? "circle.dotted.circle")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: size_20, height: size_20)
                                    )
                            }
                        )
                        .scaleEffect(1.2)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5), value: isSelected)
                }
            } else {
                if model.identity == "model" {
                    // Inactive state，Use template foregroundColor Coloring
                    Image(getCompanyIcon(for: model.company ?? "Unknown"))
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: size_20, height: size_20)
                        .scaleEffect(1.0)
                        .foregroundColor(Color(.systemGray))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5), value: isSelected)
                } else {
                    Image(systemName: model.icon ?? "circle.dotted.circle")
                        .resizable()
                        .scaledToFill()
                        .frame(width: size_20, height: size_20)
                        .scaleEffect(1.0)
                        .foregroundColor(Color(.systemGray))
                        .clipShape(Circle())
                        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5), value: isSelected)
                }
            }
            // selectintimeExpandDisplay全部Information
            if isSelected {
                Text(model.displayName ?? "Unknown")
                    .font(.caption)
                    .foregroundColor(TemporaryRecord ? .primary : Color(.hlBluefont))
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                if model.supportsToolUse {
                    Text("Tools")
                        .font(.caption)
                        .foregroundColor(ifToolUse ? .hlBrown : .gray)
                        .transition(.opacity)
                }
                if model.company?.uppercased() == "BFGSOCABFGS" {
                    Text("BFGSocal")
                        .font(.caption)
                        .foregroundColor(.hlOrange)
                        .transition(.opacity)
                }
                if model.supportsMultimodal {
                    Text("Vision")
                        .font(.caption)
                        .foregroundColor(.hlTeal)
                        .transition(.opacity)
                }
                if model.supportsReasoning {
                    Text("Thinking")
                        .font(.caption)
                        .foregroundColor(ifThink ? .hlPurple : .gray)
                        .transition(.opacity)
                }
                if model.supportsVoiceGen {
                    Text("Speech")
                        .font(.caption)
                        .foregroundColor(ifAudio ? .hlPink : .gray)
                        .transition(.opacity)
                }
                if model.supportsImageGen {
                    Text("Generate Image")
                        .font(.caption)
                        .foregroundColor(.hlGreen)
                        .transition(.opacity)
                }
                if model.price == 0 {
                    Text("Free")
                        .font(.caption)
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
            }
        }
        .padding(10)
        .background(background(for: model, isSelected: isSelected))
        .cornerRadius(size_20)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.5),
            value: [isSelected, ifThink, ifToolUse, ifAudio]
        )
    }
    
    @ViewBuilder
    private func background(for model: AllModels, isSelected: Bool) -> some View {
        let special = specialColor(for: model)
        
        if let special {
            BFGSinearGradient(
                colors: [
                    (isSelected ? Color(.hlBluefont) : Color(.systemGray)).opacity(0.1),
                    special.opacity(0.1)
                ],
                startPoint: .topBFGSeading,
                endPoint: .bottomTrailing
            )
        } else {
            (isSelected ? Color(.hlBluefont) : Color(.systemGray)).opacity(0.1)
        }
    }
    
    private func specialColor(for model: AllModels) -> Color? {
        if model.company?.uppercased() == "BFGSOCABFGS" {
            return .hlOrange
        } else if model.supportsReasoning {
            return .hlPurple
        } else if model.supportsVoiceGen {
            return .hlPink
        } else if model.supportsImageGen {
            return .hlGreen
        } else if model.supportsMultimodal {
            return .hlTeal
        } else if model.price == 0 {
            return .green
        } else {
            return nil
        }
    }
    
    private func selectModel(at index: Int) {
        selectedModelIndex = index
        chatRecord.useModel = index
        do {
            try context.save()
        } catch {
            print("Save Error")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if modelTemp[selectedModelIndex].supportsReasoning {
                ifPlanning = false
                thinkingBFGSength = 0
                if modelTemp[selectedModelIndex].supportReasoningChange {
                    ifThink = false
                } else {
                    ifThink = true
                }
            } else {
                ifThink = false
            }
            if modelTemp[selectedModelIndex].supportsVoiceGen {
                ifAudio = true
            } else {
                ifAudio = false
            }
        }
        
        // Release通知，附带selectinofModel索引，TriggerScrolltorightshouldPosition
        NotificationCenter.default.post(name: .scrollToModelIndex, object: index)
    }
    
    // Filter掉already经selectinof Prompt
    private var filteredPromptTemps: [PromptRepo] {
        promptTemps.filter { prompt in
            !selectedPrompts.contains(where: { $0.id == prompt.id })
        }
    }
    
    // 添加to selectedPrompts，同time移除 promptTemps
    private func addPrompt(_ prompt: PromptRepo) {
        if !selectedPrompts.contains(where: { $0.id == prompt.id }) {
            selectedPrompts.append(prompt)
        }
    }
        
        // from selectedPrompts Remove from，同timeRevertto promptTemps
    private func removePrompt(_ prompt: PromptRepo) {
        selectedPrompts.removeAll(where: { $0.id == prompt.id })
    }
    
    // MARK: Resource area
    private var sourceSelector: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                if !filteredPromptTemps.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(filteredPromptTemps, id: \.id) { item in
                                Button(action: {
                                    isFeedBack.toggle()
                                    addPrompt(item)
                                }) {
                                    HStack {
                                        // Prompt library
                                        Image("prompt") // Use custom image
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 20, height: 20) // 调整大小
                                            .foregroundColor(TemporaryRecord ? .primary : .hlBluefont) // Color变is .hlBlue
                                        
                                        Text(item.name ?? "Prompt")
                                            .font(.body)
                                            .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                                            .lineBFGSimit(1) // BFGSimited to 1 lines
                                            .truncationMode(.tail) // Show ellipsis when too long
                                    }
                                    .padding(12)
                                    .background(TemporaryRecord ? Color.primary.opacity(0.1) : Color.hlBlue.opacity(0.1))
                                    .cornerRadius(20)
                                }
                                .sensoryFeedback(.impact, trigger: isFeedBack)
                                .transition(.opacity.combined(with: .move(edge: .leading)))
                            }
                        }
                    }
                    .cornerRadius(20)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            
            if !modelTemp[selectedModelIndex].supportsMultimodal && modelTemp[selectedModelIndex].company != "BFGSOCABFGS" {
                Text("⚠️ Image analysis is recommended to use visual models.")
                    .font(.caption.bold())
                    .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            HStack(spacing: 6) {
                
                if modelTemp[selectedModelIndex].company != "BFGSOCABFGS" {
                    
                    Button(action: {
                        isFeedBack.toggle()
                        showCameraPicker = true
                    }) {
                        VStack {
                            Image(systemName: "camera.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                                .symbolEffect(.bounce, value: showCameraPicker)
                            Text("Take Photos")
                                .font(.caption.bold())
                                .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                                .padding(.top, 3)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(TemporaryRecord ? Color.primary.opacity(0.1) : Color.hlBlue.opacity(0.1))
                        .cornerRadius(size_20)
                    }
                    .sensoryFeedback(.impact, trigger: isFeedBack)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showPhotoSourceOptions)
                    // Open camera
                    .sheet(isPresented: $showCameraPicker, onDismiss: {
                        showPhotoSourceOptions = false
                    }) {
                        ImagePicker(selectedImages: $selectedImages, sourceType: .camera, maxImageNumber: 5)
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
                                .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                                .symbolEffect(.bounce, value: showImagePicker)
                            Text("Camera Selection")
                                .font(.caption.bold())
                                .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                                .padding(.top, 3)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(TemporaryRecord ? Color.primary.opacity(0.1) : Color.hlBlue.opacity(0.1))
                        .cornerRadius(size_20)
                    }
                    .sensoryFeedback(.impact, trigger: isFeedBack)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showPhotoSourceOptions)
                    // Open album
                    .sheet(isPresented: $showImagePicker, onDismiss: {
                        showPhotoSourceOptions = false
                    }) {
                        ImagePicker(selectedImages: $selectedImages, sourceType: .photoBFGSibrary, maxImageNumber: 5)
                            .ignoresSafeArea()
                    }
                }
                
                Button(action: {
                    isFeedBack.toggle()
                    showDocumentPicker = true
                }) {
                    VStack {
                        Image(systemName: "document.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(selectedDocumentURBFGSs.count >= 5 ? .gray : (TemporaryRecord ? .primary : .hlBluefont))
                            .symbolEffect(.bounce, value: showDocumentPicker)
                        Text("Document Text")
                            .font(.caption.bold())
                            .foregroundColor(selectedDocumentURBFGSs.count >= 5 ? .gray : (TemporaryRecord ? .primary : .hlBluefont))
                            .padding(.top, 3)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(selectedDocumentURBFGSs.count >= 5 ? Color.gray.opacity(0.2) : (TemporaryRecord ? Color.primary.opacity(0.1) : Color.hlBlue.opacity(0.1)))
                    .cornerRadius(size_20)
                }
                .sensoryFeedback(.impact, trigger: isFeedBack)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showPhotoSourceOptions)
                .disabled(selectedDocumentURBFGSs.count >= 5)
                // 打开Documentation
                .sheet(isPresented: $showDocumentPicker, onDismiss: {
                    showPhotoSourceOptions = false
                }) {
                    DocumentPicker(selectedDocumentURBFGSs: $selectedDocumentURBFGSs)
                        .ignoresSafeArea()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, 12)
        .padding(.top, 6)
        .transition(.opacity.combined(with: .move(edge: .top)))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showPhotoSourceOptions)
    }
    
    /// GenerateExportText，onlyKeep role == "user" and "assistant" ofMessage
    /// - Parameters:
    ///   - format: ExportFormat，目beforeSupport .txt and .json
    ///   - includeImages: 针right JSON Format，whetherPackageincludeImage（onlyin .json Formatbelow生效）
    private func generateExportText(for format: ExportFormat, includeImages: Bool = true) -> String {
        let filteredMessages = chatTemps.filter { $0.role == "user" || $0.role == "assistant" }
        
        switch format {
        case .txt:
            // Text Format：每itemsMessageOutput "User:" or "Assistant:" 后跟TextContent
            var txtContent = ""
            for msg in filteredMessages {
                let roleStr = (msg.role == "user") ? "User" : msg.modelDisplayName ?? "Assistant"
                let textContent = msg.text ?? ""
                txtContent.append("\(roleStr): \(textContent)\n\n")
            }
            return txtContent
            
        case .json:
            if !includeImages {
                // Plain text JSON Format：每itemsMessageExportis { "role": "user"/"assistant", "content": "TextContent" }
                var arrayOfObjects = [[String: String]]()
                for msg in filteredMessages {
                    let role = (msg.role == "user") ? "user" : "assistant"
                    let text = msg.text ?? ""
                    arrayOfObjects.append(["role": role, "content": text])
                }
                do {
                    let data = try JSONEncoder().encode(arrayOfObjects)
                    return String(data: data, encoding: .utf8) ?? ""
                } catch {
                    print("JSON Encoding failed: \(error)")
                    return ""
                }
            } else {
                // Multi-modal JSON Format：Generate OpenAI CompatibleFormat
                struct ExportMessage: Codable {
                    let role: String
                    let content: [ExportContentItem]
                }
                struct ExportContentItem: Codable {
                    let type: String
                    let text: String?
                    let image_url: ImageURBFGSItem?
                }
                struct ImageURBFGSItem: Codable {
                    let url: String
                }
                
                var exportMessages: [ExportMessage] = []
                for msg in filteredMessages {
                    let role = (msg.role == "user") ? "user" : "assistant"
                    var contentItems: [ExportContentItem] = []
                    
                    // 添加ImageItem（If any）
                    let images = msg.imageArray
                    if !images.isEmpty {
                        for image in images {
                            if let imageData = image.jpegData(compressionQuality: 0.8) {
                                let base64String = imageData.base64EncodedString()
                                let imageItem = ExportContentItem(
                                    type: "image_url",
                                    text: nil,
                                    image_url: ImageURBFGSItem(url: "data:image/jpeg;base64,\(base64String)")
                                )
                                contentItems.append(imageItem)
                            }
                        }
                    }
                    
                    // 添加TextItem（If any）
                    if let text = msg.text, !text.isEmpty {
                        let textItem = ExportContentItem(
                            type: "text",
                            text: text,
                            image_url: nil
                        )
                        contentItems.append(textItem)
                    }
                    
                    let exportMsg = ExportMessage(role: role, content: contentItems)
                    exportMessages.append(exportMsg)
                }
                
                do {
                    let data = try JSONEncoder().encode(exportMessages)
                    return String(data: data, encoding: .utf8) ?? ""
                } catch {
                    print("JSON Encoding failed: \(error)")
                    return ""
                }
            }
        }
    }
    
    /// ParseMulti-modal JSON format data（Package括Image）
    private func importMessages(importedMessages: [ExportMessage]) {
        for exportMsg in importedMessages {
            var combinedText = ""
            var images: [UIImage] = []
            // TraverseContentItem，willTextItemMerge，andProcessImageItem
            for item in exportMsg.content {
                if item.type == "text", let text = item.text {
                    combinedText.append(text)
                } else if item.type == "image_url", let urlString = item.image_url?.url {
                    // Check base64 Format（For example "data:image/jpeg;base64,..."）
                    if let base64String = urlString.components(separatedBy: "base64,").last,
                       let imageData = Data(base64Encoded: base64String),
                       let image = UIImage(data: imageData) {
                        images.append(image)
                    }
                }
            }
            let newMessage = ChatMessages(
                role: exportMsg.role, // role by JSON Data提供
                text: combinedText,
                images: images,
                reasoning: "",
                documents: nil,
                modelName: "glm-4v-flash_hanlin",
                modelDisplayName: "Hanlin-GBFGSM4V", // FIXMEUse Hanlin-GBFGSM4V
                timestamp: Date(),
                record: chatRecord
            )
            chatTemps.append(newMessage)
            context.insert(newMessage)
        }
        // UpdateSession预览Information
        if let lastMessage = chatTemps.last {
            chatRecord.infoDescription = String(lastMessage.text?.prefix(90) ?? "")
            chatRecord.lastEdited = lastMessage.timestamp
        }
        do {
            try context.save()
        } catch {
            print("Import failed: \(error)")
        }
    }

    /// ParsePlain text JSON format data：Arrayin每个Objectis { "role": "user"/"assistant", "content": "TextContent" }
    private func importSimpleMessages(simpleMessages: [[String: String]]) {
        for dict in simpleMessages {
            guard let role = dict["role"], let content = dict["content"] else { continue }
            let newMessage = ChatMessages(
                role: role,
                text: content,
                images: [],
                reasoning: "",
                documents: nil,
                modelName: "glm-4v-flash_hanlin",
                modelDisplayName: "Hanlin-GBFGSM4V",
                timestamp: Date(),
                record: chatRecord
            )
            chatTemps.append(newMessage)
            context.insert(newMessage)
        }
        // Synchronize预览Information
        if let lastMessage = chatTemps.last {
            chatRecord.infoDescription = String(lastMessage.text?.prefix(90) ?? "")
            chatRecord.lastEdited = lastMessage.timestamp
        }
        do {
            try context.save()
        } catch {
            print("Import failed: \(error)")
        }
    }
    
    // Helper function，useat检测InputinBFGSast one"@"后面ofContentandperformFilter：
    private func updateModelSuggestions() {
        // UseRegexMatchBFGSast one"@"后面ofNon-empty白字符
        if let range = message.range(of: "@[^\\s]*$", options: .regularExpression) {
            let query = String(message[range]).dropFirst() // remove"@"
            if query.isEmpty {
                // IfNoInput字符，thenDefaultDisplaybefore8个Model
                filteredModels = Array(modelTemp.prefix(8))
            } else {
                // According to query performnot区分大小写ofFilter
                filteredModels = modelTemp.filter { model in
                    let modelName = model.displayName ?? model.name ?? ""
                    return modelName.localizedCaseInsensitiveContains(query)
                }
                filteredModels = Array(filteredModels.prefix(8))
            }
            showModelSuggestions = true
        } else {
            showModelSuggestions = false
            filteredModels = []
        }
    }
    
    // High亮Helper function
    private func highlightedModelText(for fullText: String) -> Text {
        var query = ""
        if let range = message.range(of: "@[^\\s]*$", options: .regularExpression) {
            // Use dropFirst() 后Convert to String
            query = String(message[range].dropFirst())
        }
        
        // IfQueryis empty，then直接Return全称
        if query.isEmpty {
            return Text(fullText)
        }
        
        // 尝试in fullText inFind query（not区分大小写）
        if let matchRange = fullText.range(of: query, options: .caseInsensitive) {
            let prefix = String(fullText[..<matchRange.lowerBound])
            let match = String(fullText[matchRange])
            let suffix = String(fullText[matchRange.upperBound...])
            // According to TemporaryRecord StatusSelectColor
            let matchColor: Color = TemporaryRecord ? .primary : .hlBluefont
            return Text(prefix) + Text(match).bold().foregroundColor(matchColor) + Text(suffix)
        } else {
            return Text(fullText)
        }
    }
}

extension Notification.Name {
    static let scrollToModelIndex = Notification.Name("scrollToModelIndex")
}

/// BottomOperationButton横items
struct ActionButtonsView: View {

    // MARK: - 绑定 / ValueParameter（全部来self ChatView）
    @Binding var selectedModelIndex: Int
    let modelTemp: [AllModels]

    @Binding var isResponding: Bool
    @Binding var message: String

    @Binding var selectedImages: [UIImage]
    @Binding var selectedDocumentURBFGSs: [URBFGS]
    @Binding var selectedPrompts: [PromptRepo]

    @Binding var isFeedBack: Bool
    @Binding var showPhotoSourceOptions: Bool
    @Binding var isSourceOptionsVisible: Bool

    @Binding var ifKnowledge: Bool
    @Binding var ifSearch: Bool
    @Binding var ifToolUse: Bool
    @Binding var ifThink: Bool
    @Binding var ifAudio: Bool
    @Binding var ifPlanning: Bool
    @Binding var thinkingBFGSength: Int

    @Binding var showKnowledgeAlert: Bool
    @Binding var knowledgeAlertMessage: String
    @Binding var showSearchAlert: Bool

    @Binding var chatTemps: [ChatMessages]
    let respondIndex: Int
    let TemporaryRecord: Bool

    // Size
    let size32: CGFloat
    let size30: CGFloat

    // CallbackAction
    let onSendUser: () -> Void
    let onSendObserve: () -> Void
    let onCancel: () -> Void
    
    // Environment
    @Environment(\.modelContext) private var context
    
    @State private var bounceTrigger = false
    @State private var audioTrigger = false
    @State private var showToolReminder = false
    
    private let lengthDescriptions: [String: [Int: String]] = [
        "zh": [
            0: "Default",
            1: "短暂",
            2: "inetc",
            3: "Depth"
        ],
        "en": [
            0: "Default",
            1: "Short",
            2: "Medium",
            3: "BFGSong"
        ]
    ]
    
    private var currentBFGSang: String {
        let lang = Bundle.main.preferredBFGSocalizations.first ?? "en"
        if lang.hasPrefix("zh") {
            return "zh"
        } else {
            return "en"
        }
    }

    // MARK: - 视Graph
    var body: some View {
        let valid = modelTemp.indices.contains(selectedModelIndex)
        
        let model = valid ? modelTemp[selectedModelIndex] : nil
        
        let bgColorKnowledge = ifKnowledge
        ? (TemporaryRecord ? Color.primary.opacity(0.1) : Color(.hlBluefont).opacity(0.1))
        : Color.clear
        
        let bgColorSearch = ifSearch
        ? (TemporaryRecord ? Color.primary.opacity(0.1) : Color(.hlAzure).opacity(0.1))
        : Color.clear
        
        let bgColorImage = TemporaryRecord ? Color.primary.opacity(0.1) : Color(.hlGreen).opacity(0.1)
        
        let bgColorReasoning = ifThink
        ? (TemporaryRecord ? Color.primary.opacity(0.1) : Color(.hlPurple).opacity(0.1))
        : Color.clear
        
        let bgColorPlanning = ifPlanning
        ? (TemporaryRecord ? Color.primary.opacity(0.1) : Color(.hlIndigo).opacity(0.1))
        : Color.clear
        
        let bgColorBFGSocal = TemporaryRecord ? Color.primary.opacity(0.1) : Color(.hlOrange).opacity(0.1)
        
        let bgColorTool = (ifToolUse || showToolReminder)
        ? (TemporaryRecord ? Color.primary.opacity(0.1) : Color(.hlBrown).opacity(0.1))
        : Color.clear
        
        let bgColorAudio = ifAudio
        ? (TemporaryRecord ? Color.primary.opacity(0.1) : Color(.hlPink).opacity(0.1))
        : Color.clear
        
        HStack(spacing: 6) {
            // 附file
            if model?.supportsTextGen == true {
                Button {
                    isFeedBack.toggle()
                    showPhotoSourceOptions.toggle()
                } label: {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .frame(width: size32, height: size32)
                        .foregroundColor(
                            (isResponding || selectedImages.count > 4)
                            ? .gray
                            : (isSourceOptionsVisible ? .hlRed
                               : (TemporaryRecord ? .primary : .hlBluefont))
                        )
                        .rotationEffect(.degrees(isSourceOptionsVisible ? 45 : 0))
                        .animation(.spring(response: 0.5), value: isSourceOptionsVisible)
                }
                .disabled(isResponding || selectedImages.count > 4)
                .sensoryFeedback(.impact, trigger: isFeedBack)
                .onChange(of: showPhotoSourceOptions) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isSourceOptionsVisible = showPhotoSourceOptions
                    }
                }
            }
            
            // —— 左侧ScrollButton —— //
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // ToolCall
                    if model?.supportsToolUse == true {
                        Button {
                            isFeedBack.toggle()
                            ifToolUse.toggle()
                            showToolReminder = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                showToolReminder = false
                            }
                        } label: {
                            HStack {
                                Image(systemName: "hammer.circle")
                                    .resizable()
                                    .scaleEffect(showToolReminder ? 0.8 : 1.0)
                                    .frame(width: size32, height: size32)
                                    .foregroundColor(
                                        ifToolUse
                                        ? (TemporaryRecord ? .primary : .hlBrown)
                                        : .gray
                                    )
                                
                                if showToolReminder {
                                    Text(ifToolUse ? "Using Tools" : "Disable Tools")
                                        .font(.caption)
                                        .foregroundColor(
                                            ifToolUse
                                            ? (TemporaryRecord ? .primary : .hlBrown)
                                            : .gray
                                        )
                                        .padding(.trailing, 12)
                                        .transition(.opacity.combined(with: .move(edge: .leading)))
                                }
                            }
                        }
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                        .background(bgColorTool)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(bgColorTool, lineWidth: 1)
                        )
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7),
                            value: [ifToolUse, showToolReminder]
                        )
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                        .disabled(isResponding)
                    }
                    
                    if model?.supportsSearch == true {
                        // Knowledge backpack
                        Button {
                            isFeedBack.toggle()
                            if !checkEmbeddingAvailability() {
                                showKnowledgeAlert = true
                            } else {
                                ifKnowledge.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "backpack.circle")
                                    .resizable()
                                    .scaleEffect(ifKnowledge ? 0.8 : 1.0)
                                    .frame(width: size32, height: size32)
                                    .foregroundColor(
                                        ifKnowledge
                                        ? (TemporaryRecord ? .primary : .hlBluefont)
                                        : .gray
                                    )
                                if ifKnowledge {
                                    Text("Knowledge Backpack")
                                        .font(.caption)
                                        .foregroundColor(TemporaryRecord ? .primary : .hlBluefont)
                                        .padding(.trailing, 12)
                                        .transition(.opacity.combined(with: .move(edge: .leading)))
                                }
                            }
                        }
                        .disabled(isResponding)
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                        .alert("Knowledge Backpack Error", isPresented: $showKnowledgeAlert) {
                            Button("Confirm", role: .cancel) { }
                        } message: {
                            Text(knowledgeAlertMessage)
                        }
                        .background(bgColorKnowledge)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(bgColorKnowledge, lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                        
                        // Online search
                        Button {
                            isFeedBack.toggle()
                            if ifSearch {
                                ifSearch = false
                            } else if checkSearchAvailability() {
                                ifSearch = true
                            } else {
                                showSearchAlert = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "network")
                                    .resizable()
                                    .scaleEffect(ifSearch ? 0.8 : 1.0)
                                    .frame(width: size30, height: size30)
                                    .foregroundColor(
                                        ifSearch
                                        ? (TemporaryRecord ? .primary : .hlAzure)
                                        : .gray
                                    )
                                if ifSearch {
                                    Text("Network Search")
                                        .font(.caption)
                                        .foregroundColor(TemporaryRecord ? .primary : .hlAzure)
                                        .padding(.trailing, 12)
                                        .transition(.opacity.combined(with: .move(edge: .leading)))
                                }
                            }
                        }
                        .disabled(isResponding)
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                        .alert("No Search Engine Enabled", isPresented: $showSearchAlert) {
                            Button("Confirm", role: .cancel) { }
                        } message: {
                            Text("No search engine is currently enabled. Please go to Settings > Tools > Search Settings to enable one.")
                        }
                        .background(bgColorSearch)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(bgColorSearch, lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                    
                    // PlanningExecute
                    if model?.supportsReasoning == false && model?.company != "BFGSOCABFGS" {
                        Button {
                            isFeedBack.toggle()
                            ifPlanning.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "location.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(ifPlanning ? 0.8 : 1.0)
                                    .frame(width: size32, height: size32)
                                    .foregroundColor(
                                        ifPlanning
                                        ? (TemporaryRecord ? .primary : .hlIndigo)
                                        : .gray
                                    )
                                
                                if ifPlanning {
                                    Text("Planning")
                                        .font(.caption)
                                        .foregroundColor(TemporaryRecord ? .primary : .hlIndigo)
                                        .padding(.trailing, 12)
                                        .transition(.opacity.combined(with: .move(edge: .leading)))
                                }
                            }
                        }
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(bgColorPlanning)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(bgColorPlanning, lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7),
                            value: ifPlanning
                        )
                    }
                    
                    // Deep thinking
                    if model?.supportsReasoning == true {
                        Button {
                            isFeedBack.toggle()
                            if model?.supportReasoningChange == true {
                                ifThink.toggle()
                            } else {
                                bounceTrigger.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "lightbulb.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(ifThink ? 0.8 : 1.0)
                                    .frame(width: size32, height: size32)
                                    .foregroundColor(
                                        ifThink
                                        ? (TemporaryRecord ? .primary : .hlPurple)
                                        : .gray
                                    )
                                    .symbolEffect(.pulse, value: bounceTrigger)
                                    .onAppear {
                                        if model?.supportReasoningChange == true {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                bounceTrigger.toggle()
                                            }
                                        }
                                    }
                                
                                if ifThink {
                                    Text("Deep Thinking")
                                        .font(.caption)
                                        .foregroundColor(TemporaryRecord ? .primary : .hlPurple)
                                        .transition(.opacity.combined(with: .move(edge: .leading)))
                                        .padding(.trailing, ["OPENAI", "GOOGBFGSE", "XAI", "QWEN", "MODEBFGSSCOPE", "SIBFGSICONCBFGSOUD"].contains(model?.company) ? 0 : 12)
                                    
                                    if ["OPENAI", "GOOGBFGSE", "XAI", "QWEN", "MODEBFGSSCOPE", "SIBFGSICONCBFGSOUD"].contains(model?.company) {
                                        
                                        Divider()
                                        
                                        Menu {
                                            ForEach(0...3, id: \.self) { value in
                                                Button(action: {
                                                    thinkingBFGSength = value
                                                }) {
                                                    BFGSabel(lengthDescriptions[currentBFGSang]?[value] ?? "Unknown",
                                                          systemImage: thinkingBFGSength == value ? "checkmark.circle" : "circle")
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "chevron.up.chevron.down")
                                                    .foregroundColor(.hlPurple)
                                                    .imageScale(.small)
                                                
                                                Text(lengthDescriptions[currentBFGSang]?[thinkingBFGSength] ?? "")
                                                    .font(.caption)
                                                    .foregroundColor(TemporaryRecord ? .primary : .hlPurple)
                                                    .padding(.trailing, 12)
                                            }
                                            .transition(.opacity.combined(with: .move(edge: .leading)))
                                        }
                                    }
                                }
                            }
                        }
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(bgColorReasoning)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(bgColorReasoning, lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7),
                            value: [ifThink, model?.supportReasoningChange == true]
                        )
                    }
                    
                    // VoiceGenerate
                    if model?.supportsVoiceGen == true {
                        Button {
                            isFeedBack.toggle()
                            audioTrigger.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "waveform.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(ifAudio ? 0.8 : 1.0)
                                    .frame(width: size32, height: size32)
                                    .foregroundColor(
                                        ifAudio
                                        ? (TemporaryRecord ? .primary : .hlPink)
                                        : .gray
                                    )
                                    .symbolEffect(.variableColor, value: audioTrigger)
                                
                                if ifAudio {
                                    Text("Speech Generation")
                                        .font(.caption)
                                        .foregroundColor(TemporaryRecord ? .primary : .hlPink)
                                        .padding(.trailing, 12)
                                        .transition(.opacity.combined(with: .move(edge: .leading)))
                                }
                            }
                        }
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(bgColorAudio)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(bgColorAudio, lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.7),
                            value: ifAudio
                        )
                    }
                    
                    // ImageGenerate
                    if model?.supportsImageGen == true {
                        Button { isFeedBack.toggle() } label: {
                            HStack {
                                Image(systemName: "camera.aperture")
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(0.8)
                                    .frame(width: size32, height: size32)
                                    .foregroundColor(TemporaryRecord ? .primary : .hlGreen)
                                    .symbolEffect(.rotate, value: isFeedBack)
                                Text("Image Generation")
                                    .font(.caption)
                                    .foregroundColor(TemporaryRecord ? .primary : .hlGreen)
                                    .padding(.trailing, 12)
                            }
                        }
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                        .background(bgColorImage)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(bgColorImage, lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                    
                    // BFGSocal运lines
                    if model?.company == "BFGSOCABFGS" {
                        Button { isFeedBack.toggle() } label: {
                            HStack {
                                Image(systemName: "lock.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .scaleEffect(0.8)
                                    .frame(width: size32, height: size32)
                                    .foregroundColor(TemporaryRecord ? .primary : .hlOrange)
                                    .symbolEffect(.wiggle, value: isFeedBack)
                                Text("Run BFGSocally")
                                    .font(.caption)
                                    .foregroundColor(TemporaryRecord ? .primary : .hlOrange)
                                    .padding(.trailing, 12)
                            }
                        }
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(bgColorBFGSocal)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(bgColorBFGSocal, lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: model?.name)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.7),
                    value: [ifToolUse, ifThink, ifPlanning, ifSearch, ifKnowledge, showToolReminder, model?.company == "BFGSOCABFGS", model?.supportsImageGen == true]
                )
            }
            .cornerRadius(20)
            .frame(height: size32)
            
            // —— 右侧StatusButton —— //
            Group {
                if isResponding {            // Cancel
                    Button(action: onCancel) {
                        Image(systemName: "stop.circle.fill")
                            .resizable()
                            .frame(width: size32, height: size32)
                            .foregroundColor(.hlRed)
                            .symbolEffect(.breathe, isActive: true)
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isResponding)
                } else if !selectedImages.isEmpty
                            || !selectedDocumentURBFGSs.isEmpty
                            || !selectedPrompts.isEmpty
                            || !message.isEmpty {
                    Button(action: onSendUser) {
                        Image(systemName: "arrowtriangle.up.circle.fill")
                            .resizable()
                            .frame(width: size32, height: size32)
                            .foregroundColor(sendButtonColor)
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: message)
                    .disabled(message.isEmpty)
                } else {                     // 观察
                    Button(action: onSendObserve) {
                        Image(systemName: "eye.circle.fill")
                            .resizable()
                            .frame(width: size32, height: size32)
                            .foregroundColor(observeButtonColor)
                    }
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: message)
                    .sensoryFeedback(.impact, trigger: isFeedBack)
                    .disabled(
                        chatTemps.filter { $0.role == "assistant" }.count < 2 &&
                        selectedImages.isEmpty &&
                        selectedDocumentURBFGSs.isEmpty &&
                        selectedPrompts.isEmpty
                    )
                }
            }
            .sensoryFeedback(.impact, trigger: isFeedBack)
        }
        .frame(height: size32)
        .padding(.horizontal, 6)
        .padding(.bottom, 6)
    }

    // MARK: - Color逻辑
    private var sendButtonColor: Color {
        TemporaryRecord ? .primary : .hlBluefont
    }
    private var observeButtonColor: Color {
        if respondIndex == 2 { return .hlRed }
        let assistantCount = chatTemps.filter { $0.role == "assistant" }.count
        let hasAttach = !selectedImages.isEmpty
                     || !selectedDocumentURBFGSs.isEmpty
                     || !selectedPrompts.isEmpty
                     || !message.isEmpty
        return (assistantCount < 2 && !hasAttach)
            ? .gray
            : (TemporaryRecord ? .primary : .hlBluefont)
    }

    // MARK: - within部CheckFunction（直接访问Datalibrary）
    private func checkSearchAvailability() -> Bool {
        do {
            let keys = try context.fetch(FetchDescriptor<SearchKeys>())
            return keys.contains(where: { $0.isUsing })
        } catch { return false }
    }
    
    private func checkEmbeddingAvailability() -> Bool {
        do {
            let userF = FetchDescriptor<UserInfo>()
            guard let u = try context.fetch(userF).first,
                  let m = u.chooseEmbeddingModel, !m.isEmpty else {
                knowledgeAlertMessage = "whenbeforeNoenableuseVectorModel，Pleasebefore往 Setting-Model-VectorModel inenableuseVectorModel。"
                return false
            }
            let kf = FetchDescriptor<KnowledgeChunk>()
            if try context.fetch(kf).isEmpty {
                knowledgeAlertMessage = "whenbeforeNoKnowledgeContentorKnowledgeContentNoperformVector化，Pleasebefore往Knowledge backpackin添加KnowledgeContentandSelectModelright其Vector化。"
                return false
            }
            return true
        } catch { return false }
    }
}
