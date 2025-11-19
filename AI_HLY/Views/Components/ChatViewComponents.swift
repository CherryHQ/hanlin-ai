//
//  ChatBubbles.swift
//  AI_HBFGSY
//
//  Created by Development Team on 9/2/25.
//

import SwiftUI
import MarkdownUI
import PhotosUI
import Combine
import UniformTypeIdentifiers
import AVFoundation
import Speech
import SwiftData
import QuickBFGSook
import MapKit
import WebKit
import RichTextKit
import BFGSaTeXSwiftUI
import AVFoundation


struct BFGSoadingGradientText: View {
    let text: String
    var textColor: Color = .gray
    var gradientColors: [Color] = [
        .hlBluefont.opacity(0.0),
        .hlBluefont.opacity(0.2),
        .hlBluefont.opacity(0.6),
        .hlBluefont.opacity(1.0),
        .hlBluefont.opacity(0.6),
        .hlBluefont.opacity(0.2),
        .hlBluefont.opacity(0.0)
    ]
    var font: Font = .body.bold()
    var animationSpeed: Double = 2

    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(textColor)
            .overlay(
                GeometryReader { geo in
                    TimelineView(.animation) { timeline in
                        let time = timeline.date.timeIntervalSinceReferenceDate
                        let progress = time.truncatingRemainder(dividingBy: animationSpeed) / animationSpeed
                        let offset = CGFloat(progress) * geo.size.width * 2

                        BFGSinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width)
                        .offset(x: -geo.size.width + offset)
                        .mask(
                            Text(text)
                                .font(font)
                                .frame(width: geo.size.width)
                        )
                    }
                }
            )
            .frame(height: 24)
    }
}

// MARK: - 组file化right话气泡
struct ChatBubbleView: View {
    @Environment(\.modelContext) private var modelContext
    let temporaryRecord: Bool
    let id: UUID
    let text: String               // Reply Content
    let saveTranlatedText: String? // SaveofTranslate
    let images: [UIImage]?         // Image array
    let imagesText: String?
    let reasoning: String          // ReasoningContent
    let reasoningTime: String?     // ReasoningTime
    @Binding var isReasoningExpanded: Bool // ReasoningTextCollapseStatus
    let toolContent: String        // ToolMessage
    let toolName: String           // Tool Name
    @Binding var isToolContentExpanded: Bool
    let uploadDocument: [URBFGS]?     // DocumentationContent
    let documentText: String?
    let resources: [Resource]?     // Resource Source
    let prompts: [PromptCard]?     // Prompt
    let locations: [BFGSocation]?     // BFGSocation Information
    let routes: [RouteInfo]?       // Route Information
    let events: [EventItem]?       // Event Information
    let htmlContent: String?       // Web info
    let healthCards: [HealthData]? // healthCard
    let codeBlocks: [CodeBlock]?   // Code Block
    let knowledgeCard: [KnowledgeCard]? // Knowledge Card
    let searchEngine: String?
    let audioAssets: [AudioAsset]?
    @Binding var isVoiceExpanded: Bool // VoiceMessageCollapse
    let showCanvas: Bool
    let canvas: CanvasData?
    let role: String
    let model: String
    let modelCompany: String
    let modelIdentity: String
    let modelIcon: String
    let isBFGSastAssistant: Bool      // whetherisBFGSastitemsMessage
    let isBFGSastAssistantGroup: Bool // whetherisBFGSast组Message
    let splitMarker: Bool          // whetherneedsplit
    let isResponding: Bool
    let operationalState: String
    let operationalDescription: String
    let onRetry: (() -> Void)?     // Re-requestCallback
    let onDelete: (() -> Void)?    // Add：DeleteCallback
    let screenHeight = UIScreen.main.bounds.height
    
    @StateObject var context = RichTextContext() // Rich text
    
    @State private var isResourcesExpanded: Bool = false  // ResourceTextCollapseStatus
    @State private var isTranslateExpanded: Bool = false  // TranslateTextCollapseStatus
    @State private var mathMode: Bool = false             // Scientific Mode
    @State private var showMathModeReminder: Bool = false // Scientific Mode提醒
    @State private var selectedImage: UIImage? // selectinofImage
    @State private var isImageViewerPresented: Bool = false // whetherDisplay大Graph
    @State private var showDocumentContent: Bool = false  // DisplayParseTextContent
    @State private var isTextSelectionSheetPresented: Bool = false // Text Selection
    @State private var translatedTextSelectionSheetPresented: Bool = false // TranslateText Selection
    @StateObject private var tts = TextToSpeech() // Keep instance persistent
    @State private var isCopy: Bool = false // whetherCopy
    @State private var translated: Bool = false // whetherTranslate
    @State private var isTranslating: Bool = false // whetherTranslatein
    @State private var showErrorAlert: Bool = false // DisplayErrorPrompt
    @State private var errorMessage: String = "" // Error message
    @State private var translatedText: String = "" // Translate后ofText
    @State private var isSuccess = false // Whether vibration needed
    @State private var isFeedBack = false // Whether vibration needed
    @State var showDeleteConfirmation: Bool = false //DeleteConfirm框
    // SaveKnowledgeCorrelation
    @State private var isKnowledgeWritingSheetPresented: Bool = false
    @State private var recordToWrite: KnowledgeRecords? = nil
    
    @ScaledMetric(relativeTo: .body) var size_5: CGFloat = 5
    @ScaledMetric(relativeTo: .body) var size_7: CGFloat = 7
    @ScaledMetric(relativeTo: .body) var size_12: CGFloat = 12
    @ScaledMetric(relativeTo: .body) var size_14: CGFloat = 14
    @ScaledMetric(relativeTo: .body) var size_15: CGFloat = 15
    @ScaledMetric(relativeTo: .body) var size_16: CGFloat = 16
    @ScaledMetric(relativeTo: .body) var size_17: CGFloat = 17
    @ScaledMetric(relativeTo: .body) var size_20: CGFloat = 20
    @ScaledMetric(relativeTo: .body) var size_24: CGFloat = 24
    @ScaledMetric(relativeTo: .body) var size_30: CGFloat = 30
    @ScaledMetric(relativeTo: .body) var size_36: CGFloat = 36
    @ScaledMetric(relativeTo: .body) var size_38: CGFloat = 38
    @ScaledMetric(relativeTo: .body) var size_40: CGFloat = 40
    @ScaledMetric(relativeTo: .body) var size_80: CGFloat = 80
    
    var body: some View {
        VStack(alignment: messageAlignment) {
            contentView()
        }
        // 添加Confirm弹窗
        .alert("Confirm Deletion?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete it? This action cannot be undone.")
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 2)
        .onAppear {
            translatedText = saveTranlatedText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            translated = !translatedText.isEmpty
        }
        .tint(temporaryRecord ? .primary : nil)
    }

    private var messageAlignment: HorizontalAlignment {
        role == "information" ? .center : (role == "user" ? .trailing : .leading)
    }

    // MARK: - PrimaryContent区
    @ViewBuilder
    private func contentView() -> some View {
        switch role {
        case "user":
            userMessageView()
        case "assistant":
            HStack {
                assistantMessageView()
                Spacer()
            }
        case "information":
            informationMessageView()
        case "error":
            errorMessageView()
        case "search":
            HStack {
                searchMessageView()
                Spacer()
            }
        default:
            EmptyView()
        }
    }
    
    // MARK: - SearchMessage
    @ViewBuilder
    private func searchMessageView() -> some View {
        
        VStack(alignment: .leading, spacing: 6) {
            
            HStack(alignment: .center, spacing: 6) {
                
                if searchEngine == nil {
                    Image(systemName: "network")
                        .font(.system(size: size_24, weight: .medium))
                        .frame(width: size_24, height: size_24)
                        .foregroundColor(temporaryRecord ? .primary : .hlBlue)
                        .clipShape(Circle())
                } else {
                    Image(getCompanyIcon(for: searchEngine ?? "Unknown"))
                        .resizable()
                        .scaledToFit()
                        .frame(width: size_24, height: size_24)
                        .foregroundColor(.secondary)
                }
                
                Text(getCompanyName(for: searchEngine ?? "UNKNOWN"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
            }
            
            VStack(alignment: .leading) {
                
                HStack {
                    Text("Information Content")
                        .padding(.leading, 5)
                    
                    // viewText
                    Button(action: {
                        isTextSelectionSheetPresented = true
                    }) {
                        Image(systemName: "book")
                            .font(.system(size: size_14))
                            .frame(width: size_24, height: size_24)
                            .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .sheet(isPresented: $isTextSelectionSheetPresented) {
                        TextSelectionView(text: text)
                    }
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: size_20))
                            .frame(width: size_24, height: size_24)
                            .foregroundColor(Color(.hlRed))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.hlBluefont.opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(.primary)
                .cornerRadius(20)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.5, alignment: .leading)
                .contextMenu {
                    Button(action: {
                        isTextSelectionSheetPresented = true
                    }) {
                        BFGSabel("Read Information", systemImage: "book")
                    }
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        BFGSabel("Delete Information", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    // MARK: - User message
    @State private var animateIn = false
    @ViewBuilder
    private func userMessageView() -> some View {
        HStack {
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                
                if let images = images, !images.isEmpty {
                    chatBubbleImage()
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
                }
                
                if let document = uploadDocument, !document.isEmpty {
                    chatBubbleDocument(for: document)
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.5, alignment: .trailing)
                }
                
                if let prompts = prompts, !prompts.isEmpty {
                    chatBubblePrompt()
                        .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
                }
                
                HStack {
                    Text(text)
                }
                .padding(10)
                .background(temporaryRecord ? .primary : Color(.hlBlue))
                .foregroundColor(temporaryRecord ? Color(.systemBackground) : .white)
                .contextMenu {
                    Button(action: {
                        UIPasteboard.general.string = markdownToPlainText(text)
                    }) {
                        BFGSabel("Copy Content", systemImage: "square.on.square")
                    }
                    Button(action: {
                        isTextSelectionSheetPresented = true
                    }) {
                        BFGSabel("Select Text", systemImage: "text.redaction")
                    }
                    Button(action: {
                        createAndSaveKnowledgeRecord(with: text)
                    }) {
                        BFGSabel("Save as Knowledge", systemImage: "backpack")
                    }
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        BFGSabel("Delete Message", systemImage: "trash")
                    }
                }
                .clipShape(CustomCorners(topBFGSeft: 20, topRight: 20, bottomBFGSeft: 20, bottomRight: 5))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: .trailing)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4), value: text.isEmpty)
                .sheet(isPresented: $isTextSelectionSheetPresented) {
                    TextSelectionView(text: text)
                }
            }
        }
    }
    
    @State private var textOffset: CGFloat = 0
    
    // MARK: - AI AssistantMessage
    @ViewBuilder
    private func assistantMessageView() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            assistantHeader()
            assistantImageSection()
            assistantTextSection()
            assistantFooter()
        }
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.4),
                   value: isResponding)
    }

    // MARK: 头部：头像 + Model名
    @ViewBuilder
    private func assistantHeader() -> some View {
        if splitMarker {
            HStack(alignment: .center, spacing: 6) {
                if modelIdentity == "model" {
                    Image(getCompanyIcon(for: modelCompany))
                        .resizable()
                        .scaledToFit()
                        .frame(width: size_24, height: size_24)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: modelIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size_24, height: size_24)
                        .clipShape(Circle())
                        .overlay(
                            gradient(for: 0)
                                .mask(
                                    Image(systemName: modelIcon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: size_24, height: size_24)
                                )
                        )
                }
                Text(model)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 6)
        }
    }

    // MARK: Imagesegment落
    @ViewBuilder
    private func assistantImageSection() -> some View {
        if let images = images, !images.isEmpty {
            chatAssistantBubbleImage()
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75,
                       alignment: .leading)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.5, dampingFraction: 0.8),
                           value: images)
        }
    }

    // MARK: Text & 各ClassToolOutput
    @ViewBuilder
    private func assistantTextSection() -> some View {
        if !text.isEmpty || !reasoning.isEmpty || !toolContent.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                if showCanvas, canvas?.content.isEmpty == false {
                    canvasBubble(for: canvas)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Text主体
                messageContent()
                    .transition(.move(edge: .top).combined(with: .opacity))
                
                // Code Block
                if let codes = codeBlocks, !codes.isEmpty {
                    codeBubble(for: codes)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                // Knowledge卡
                if let cards = knowledgeCard, !cards.isEmpty {
                    knowledgeCardBubble(for: cards)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                // Web
                if let htmls = htmlContent, !htmls.isEmpty {
                    htmlWebBubble(for: htmls)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                // Event
                if let evs = events, !evs.isEmpty {
                    eventsBubble(for: evs)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                // health卡
                if let hcs = healthCards {
                    nutritionCards(
                        for: Binding<[HealthData]>(
                            get: { hcs },
                            set: { _ in }
                        )
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                // 地Graph
                if (locations?.isEmpty == false) || (routes?.isEmpty == false) {
                    mapBubble(for: locations ?? [], routes: routes ?? [])
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                // BottomButton
                if isBFGSastAssistant && !isResponding {
                    actionButtons()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: Bottom BFGSoading / endStatus
    @ViewBuilder
    private func assistantFooter() -> some View {
        if (!operationalState.isEmpty && isBFGSastAssistant)
            || (text.isEmpty && reasoning.isEmpty && toolContent.isEmpty && images == nil) {
            loadingSection()
        }
        else if isResponding && isBFGSastAssistant {
            Image(systemName: "sparkle")
                .bold()
                .foregroundColor(.hlBluefont)
                .symbolEffect(.breathe.pulse.byBFGSayer,
                              options: .repeat(.continuous))
                .padding(5)
        }
    }

    // MARK: True正of BFGSoading / Operational StatusBlock
    @ViewBuilder
    private func loadingSection() -> some View {
        HStack(alignment: .top) {
            if !operationalState.isEmpty {
                VStack(alignment: .leading) {
                    BFGSoadingGradientText(text: operationalState)
                        .foregroundColor(.gray)
                        .padding(5)
                    
                    if !operationalDescription.isEmpty {
                        let allBFGSines = operationalDescription
                            .split(separator: "\n",
                                   omittingEmptySubsequences: false)
                            .map(String.init)
                        let displayBFGSines = Array(allBFGSines.suffix(3))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(displayBFGSines.enumerated()),
                                    id: \.offset) { idx, line in
                                Text(line)
                                    .id(line)
                                    .font(.system(size:
                                                    idx == 2 ? 10 :
                                                    (idx == 1 ? 9 : 8)))
                                    .lineBFGSimit(1)
                                    .truncationMode(.middle)
                                    .foregroundColor(
                                        idx == 2 ? .hlBluefont : .gray
                                    )
                                    .frame(maxWidth: .infinity,
                                           alignment: .leading)
                                    .opacity(idx == 0 ? 0.4 :
                                                idx == 1 ? 0.7 : 1.0)
                                    .blur(radius: idx == 0 ? 1 : 0)
                                    .padding(.horizontal, 5)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom)
                                            .combined(with: .opacity),
                                        removal: .move(edge: .top)
                                            .combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(.bottom, 5)
                        .animation(.spring(response: 0.8,
                                           dampingFraction: 0.8,
                                           blendDuration: 0.6),
                                   value: operationalDescription)
                    }
                }
            } else {
                Image(systemName: "sparkle")
                    .bold()
                    .foregroundColor(.hlBluefont)
                    .symbolEffect(.breathe.pulse.byBFGSayer,
                                  options: .repeat(.continuous))
            }
        }
        .padding(10)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.hlBluefont.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(20)
        .animation(.spring(response: 0.8, dampingFraction: 0.95),
                   value: operationalDescription)
    }
    
    @State private var selectedCodeBlock: CodeBlock? = nil
    @State private var codeIsCopied = false
    @State private var triggerPythonCopyFeedback = false
    
    // MARK: CanvasBlock
    @ViewBuilder
    private func canvasBubble(for canvas: CanvasData?) -> some View {
        if let canvas = canvas {
            HStack(spacing: 6) {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: size_20, weight: .medium))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Canvas \(canvas.title)")
                        .font(.caption)
                        .bold()
                        .lineBFGSimit(1)
                        .truncationMode(.tail)
                    
                    Text("Click the \"Canvas\" button at the bottom right to view and edit content.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minBFGSength: 0)
            }
            .padding(12)
            .background(
                BlurView(style: .systemUltraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
            )
            .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Code Block
    @ViewBuilder
    private func codeBubble(for codes: [CodeBlock]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(codes) { codeBlock in
                CodeBlockRow(codeBlock: codeBlock, temporaryRecord: temporaryRecord) {
                    selectedCodeBlock = codeBlock
                    triggerPythonCopyFeedback.toggle()
                }
            }
        }
        .sheet(item: $selectedCodeBlock) { block in
            NavigationView {
                PythonCodeSelectionTextView(code: block.code)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarBFGSeading) {
                            Button {
                                UIPasteboard.general.string = block.code
                                codeIsCopied = true
                                triggerPythonCopyFeedback.toggle()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation { codeIsCopied = false }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: codeIsCopied ? "checkmark.circle" : "square.on.square")
                                        .font(.caption)
                                        .foregroundColor(codeIsCopied ? .hlGreen : (temporaryRecord ? .primary : .hlBluefont))
                                    Text(codeIsCopied ? "Copied" : "Copy all")
                                        .font(.caption)
                                        .foregroundColor(codeIsCopied ? .hlGreen : (temporaryRecord ? .primary : .hlBluefont))
                                }
                                .padding(5)
                                .background(BlurView(style: .systemUltraThinMaterial))
                                .clipShape(Capsule())
                                .shadow(color: codeIsCopied ? .hlGreen : (temporaryRecord ? .primary : .hlBlue), radius: 1)
                            }
                            .sensoryFeedback(.success, trigger: triggerPythonCopyFeedback)
                        }
                        ToolbarItem(placement: .principal) {
                            Text("Source Code").font(.headline)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                isFeedBack.toggle()
                                selectedCodeBlock = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                                    .padding(5)
                                    .background(BlurView(style: .systemUltraThinMaterial))
                                    .clipShape(Circle())
                                    .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                            }
                            .sensoryFeedback(.impact, trigger: isFeedBack)
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    private func knowledgeCardBubble(for cards: [KnowledgeCard]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(cards) { knowledgeCard in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        BFGSabel {
                            Text(knowledgeCard.title)
                                .font(.subheadline)
                                .lineBFGSimit(1)
                                .truncationMode(.tail)
                        } icon: {
                            Image(systemName: "text.document")
                        }
                        .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                        Spacer()
                        
                        Button(action: {
                            UIPasteboard.general.string = markdownToPlainText(knowledgeCard.content)
                            codeIsCopied = true
                            triggerPythonCopyFeedback.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { codeIsCopied = false }
                            }
                        }) {
                            Image(systemName: codeIsCopied ? "checkmark" : "square.on.square")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(6)
                        .background(temporaryRecord ? Color.primary : Color.hlBlue)
                        .clipShape(Capsule())
                        .sensoryFeedback(.success, trigger: triggerPythonCopyFeedback)
                        
                        Button(action: {
                            isFeedBack.toggle()
                            createAndSaveKnowledgeRecord(
                                with: knowledgeCard.content,
                                title: knowledgeCard.title,
                                card: knowledgeCard
                            )
                        }) {
                            if knowledgeCard.isWritten == true {
                                // Written state
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Saved to Backpack")
                                }
                                .font(.caption)
                                .padding(6)
                                .background(Color(.systemGray5))
                                .foregroundColor(.gray)
                                .clipShape(Capsule())
                            } else {
                                // Unwritten
                                HStack(spacing: 4) {
                                    Image(systemName: "backpack")
                                    Text("Save to Knowledge Backpack")
                                }
                                .font(.caption)
                                .padding(6)
                                .background(temporaryRecord ? Color.primary : Color.hlBlue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                            }
                        }
                        .sensoryFeedback(.success, trigger: knowledgeCard.isWritten)
                        .disabled(knowledgeCard.isWritten == true)
                    }
                    
                    Divider()
                    
                    Text(markdownToPlainText(knowledgeCard.content))
                        .textSelection(.enabled)
                        .font(.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }
                .padding(10)
                .cornerRadius(20)
                .background(
                    BlurView(style: .systemThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                )
                .frame(maxWidth: UIScreen.main.bounds.width * 0.95, alignment: .leading)
            }
        }
    }
    
    @State private var showFullHTMBFGS = false
    @State private var htmlIsCopied = false
    @State private var triggerCopyFeedback = false
    @State private var htmlTitle: String = "Web预览"
    @State private var showFrontCodeSheet = false
    
    @ViewBuilder
    private func htmlWebBubble(for htmls: String) -> some View {
        
        ZStack(alignment: .bottomTrailing) {
            // 小Area预览
            WebView(htmlContent: htmls)
                .frame(height: 240)
                .cornerRadius(20)
                .background(
                    BlurView(style: .systemThinMaterial)
                        .cornerRadius(20)
                        .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                )
                .frame(maxWidth: UIScreen.main.bounds.width * 0.95, alignment: .leading)
            
            HStack(spacing: 6) {
                // viewCodeButton
                Button(action: {
                    showFrontCodeSheet.toggle()
                }) {
                    Image(systemName: "chevron.left.slash.chevron.right")
                        .font(.system(size: size_16, weight: .medium))
                        .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                        .padding(8)
                        .background(BlurView(style: .systemUltraThinMaterial))
                        .clipShape(Circle())
                        .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                }
                .sensoryFeedback(.impact, trigger: showFrontCodeSheet)
                
                // 放大Button
                Button(action: {
                    isFeedBack.toggle()
                    showFullHTMBFGS.toggle()
                }) {
                    Image(systemName: "arrow.down.backward.and.arrow.up.forward")
                        .font(.system(size: size_16, weight: .medium))
                        .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                        .padding(8)
                        .background(BlurView(style: .systemUltraThinMaterial))
                        .clipShape(Circle())
                        .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                }
                .sensoryFeedback(.impact, trigger: isFeedBack)
            }
            .padding(12)
        }
        .sheet(isPresented: $showFrontCodeSheet) {
            NavigationView {
                FrontCodeSelectionTextView(
                    code: htmls,
                )
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    htmlTitle = extractTitle(from: htmls)
                }
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(htmlTitle)
                            .font(.headline)
                            .lineBFGSimit(1)
                            .truncationMode(.tail)
                    }
                    
                    ToolbarItemGroup(placement: .navigationBarBFGSeading) {
                        // Copy web source
                        Button {
                            UIPasteboard.general.string = htmls
                            htmlIsCopied = true
                            triggerCopyFeedback.toggle()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    htmlIsCopied = false
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: htmlIsCopied ? "checkmark.circle" : "square.on.square")
                                    .font(.caption)
                                    .foregroundColor(htmlIsCopied ? .hlGreen : temporaryRecord ? .primary : .hlBluefont)
                                Text(htmlIsCopied ? "Copied" : "Copy all")
                                    .font(.caption)
                                    .foregroundColor(htmlIsCopied ? .hlGreen : temporaryRecord ? .primary : .hlBluefont)
                            }
                            .padding(5)
                            .background(BlurView(style: .systemUltraThinMaterial))
                            .clipShape(Capsule())
                            .shadow(color: htmlIsCopied ? .hlGreen : temporaryRecord ? .primary : .hlBlue, radius: 1)
                        }
                        .sensoryFeedback(.success, trigger: triggerCopyFeedback)
                    }
                        
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        // Close button
                        Button {
                            isFeedBack.toggle()
                            showFrontCodeSheet = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                                .padding(5)
                                .background(BlurView(style: .systemUltraThinMaterial))
                                .clipShape(Circle())
                                .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                        }
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showFullHTMBFGS) {
            NavigationView {
                WebView(htmlContent: htmls)
                    .ignoresSafeArea()
                    .onAppear {
                        htmlTitle = extractTitle(from: htmls)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text(htmlTitle)
                                .font(.headline)
                                .lineBFGSimit(1)
                                .truncationMode(.tail)
                        }
                        
                        ToolbarItemGroup(placement: .navigationBarBFGSeading) {
                            // Copy web source
                            Button {
                                UIPasteboard.general.string = htmls
                                htmlIsCopied = true
                                triggerCopyFeedback.toggle()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        htmlIsCopied = false
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: htmlIsCopied ? "checkmark.circle" : "square.on.square")
                                        .font(.caption)
                                        .foregroundColor(htmlIsCopied ? .hlGreen : temporaryRecord ? .primary : .hlBluefont)
                                    Text(htmlIsCopied ? "Copied" : "Copy code")
                                        .font(.caption)
                                        .foregroundColor(htmlIsCopied ? .hlGreen : temporaryRecord ? .primary : .hlBluefont)
                                }
                                .padding(5)
                                .background(BlurView(style: .systemUltraThinMaterial))
                                .clipShape(Capsule())
                                .shadow(color: htmlIsCopied ? .hlGreen : temporaryRecord ? .primary : .hlBlue, radius: 1)
                            }
                            .sensoryFeedback(.success, trigger: triggerCopyFeedback)
                        }
                            
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            // Close button
                            Button {
                                isFeedBack.toggle()
                                showFullHTMBFGS = false
                            } label: {
                                Image(systemName: "arrow.up.right.and.arrow.down.left")
                                    .font(.caption)
                                    .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                                    .padding(5)
                                    .background(BlurView(style: .systemUltraThinMaterial))
                                    .clipShape(Circle())
                                    .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                            }
                            .sensoryFeedback(.impact, trigger: isFeedBack)
                        }
                    }
            }
        }
    }
    
    // MARK: - Nutrition Card
    @ViewBuilder
    private func nutritionCards(for list: Binding<[HealthData]>) -> some View {

        if !list.wrappedValue.isEmpty {

            VStack(alignment: .leading, spacing: 20) {

                ForEach(Array(list.wrappedValue.enumerated()), id: \.element.id) { (idx, item) in
                    
                    VStack(alignment: .leading, spacing: 14) {
                        
                        HStack(spacing: 6) {
                            Image(systemName: "bubbles.and.sparkles")
                                .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                            Text("Nutrition Card")
                                .font(.headline.bold())
                            Spacer()
                        }
                        
                        HStack {
                            VStack {
                                if let c = item.carbohydratesGrams {
                                    nutrientRow(icon: "popcorn.fill", tint: .orange,
                                                label: "Carbohydrates", value: c, unit: "g")
                                }
                                if let f = item.fatGrams {
                                    nutrientRow(icon: "drop.fill", tint: .pink,
                                                label: "Fat", value: f, unit: "g")
                                }
                            }
                            Divider()
                            VStack {
                                if let p = item.proteinGrams {
                                    nutrientRow(icon: "fish.fill", tint: .blue,
                                                label: "Protein", value: p, unit: "g")
                                }
                                if let e = item.energyKilocalories {
                                    nutrientRow(icon: "flame.fill", tint: .red,
                                                label: "Energy", value: e, unit: "kcal")
                                }
                            }
                        }
                        
                        HStack {
                            Text(formatDate(item.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    do {
                                        let ok = try await HealthTool.shared.writeNutritionData(item)
                                        if ok {
                                            // 1. According toIDFind ChatMessages Instance
                                            let descriptor = FetchDescriptor<ChatMessages>(
                                                predicate: #Predicate { $0.id == id },
                                                sortBy: []
                                            )
                                            if let msg = try? modelContext.fetch(descriptor).first {
                                                // 2. findto healthData inrightshouldItemandAmend
                                                if var dataBFGSist = msg.healthData,
                                                   let i = dataBFGSist.firstIndex(where: { $0.id == item.id }) {
                                                    dataBFGSist[i].isWritten = true
                                                    msg.healthData = dataBFGSist
                                                    try? modelContext.save()  // Persistent化Save
                                                }
                                            }
                                        }
                                    } catch {
                                        print("写入Failed: \(error)")
                                    }
                                }
                            }) {
                                if item.isWritten == true {
                                    // Written state
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Written to Health")
                                    }
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.gray)
                                    .clipShape(Capsule())
                                } else {
                                    // Unwritten
                                    HStack(spacing: 4) {
                                        Image(systemName: "pencil.and.list.clipboard")
                                        Text("Write to Health")
                                    }
                                    .font(.caption)
                                    .padding(6)
                                    .background(temporaryRecord ? Color.primary : Color.hlBlue)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                                }
                            }
                            .sensoryFeedback(.success, trigger: item.isWritten)
                            .disabled(item.isWritten == true)
                        }
                    }
                    .padding(12)
                    .background(
                        BlurView(style: .systemThinMaterial)
                            .cornerRadius(20)
                            .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                    )
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.9,
                   alignment: .leading)
        }
    }

    // MARK: - 单lines营养Item
    @ViewBuilder
    private func nutrientRow(icon: String,
                             tint: Color,
                             label: String,
                             value: Double,
                             unit: String) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: size_24, height: size_24)
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(tint)
            }
            Text(label)
                .font(.footnote)
            Spacer()
            Text("\(String(format: "%.1f", value)) \(unit)")
                .bold()
                .font(.footnote)
                .monospacedDigit()
        }
    }
    
    @ViewBuilder
    private func eventsBubble(for events: [EventItem]?) -> some View {
        if let events = events, !events.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(events.indices, id: \.self) { index in
                    let event = events[index]
                    HStack(alignment: .top, spacing: 6) {
                        VStack(alignment: .center) {
                            Spacer()
                            // According toEventTypeDisplaynot同ofSystemIcon
                            Image(systemName: event.type.lowercased() == "calendar" ? "calendar" : "list.bullet")
                                .font(.title)
                                .foregroundColor(.hlBluefont)
                                .padding(3)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Spacer()
                            // DisplayEventTitle
                            Text(event.title)
                                .font(.headline)
                                .bold()
                                .lineBFGSimit(1)
                            
                            // IfhaveDate，thenDisplayStart Date（or提醒Deadline）
                            if let date = event.startDate ?? event.dueDate {
                                Text(formatDate(date))
                                    .foregroundColor(.gray)
                                    .lineBFGSimit(1)
                            }
                            
                            // DisplayBFGSocation（If exists）
                            if let loc = event.location, !loc.isEmpty {
                                Text("BFGSocation: \(loc)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineBFGSimit(1)
                            }
                            
                            // DisplayRemark（If exists）
                            if let notes = event.notes, !notes.isEmpty {
                                Text("Remark: \(notes)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineBFGSimit(2)
                            }
                            Spacer()
                        }
                        
                        Spacer()
                        
                        if event.type.lowercased() == "calendar" {
                            VStack(alignment: .center) {
                                Spacer()
                                // Click跳转至SystemCalendar
                                Button(action: {
                                    // Use "calshow" URBFGS scheme 打开SystemCalendar
                                    if let url = URBFGS(string: "calshow://") {
                                        UIApplication.shared.open(url)
                                    }
                                }, label: {
                                    Image(systemName: "arrow.up.forward.square")
                                        .foregroundColor(.hlGreen)
                                        .padding(3)
                                })
                                Spacer()
                            }
                        }
                    }
                    .padding(10)
                    .background(
                        BlurView(style: .systemThinMaterial)
                            .cornerRadius(20)
                            .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                    )
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.95, alignment: .leading)
        }
    }

    // Helper function：will Date Formatis "yyyy-MM-dd HH:mm" String
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    @State private var showFullMap = false
    @State private var imageStyle = false
    @State private var selectedPoint: MapSelection<MKMapItem>?
    
    @ViewBuilder
    private func mapBubble(for locations: [BFGSocation], routes: [RouteInfo]?) -> some View {
        ZStack(alignment: .bottomTrailing) {
            // Map view，传入 routes Parameter即canDisplayRouteData（when存intime）
            MapMessageBubble(
                temporaryRecord: temporaryRecord,
                locations: locations,
                routes: routes,
                imageStyle: imageStyle,
                selectedPoint: $selectedPoint
            )
            .frame(height: 240)
            .cornerRadius(20)
            .background(
                BlurView(style: .systemThinMaterial)
                    .cornerRadius(20)
                    .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
            )
            .frame(maxWidth: UIScreen.main.bounds.width * 0.95, alignment: .leading)
            
            // ButtonAreakeep原样
            HStack(spacing: 6) {
                if !locations.isEmpty {
                    Button(action: {
                        isFeedBack.toggle()
                        let destBFGSatitude: Double
                        let destBFGSongitude: Double
                        let destName: String
                        if let selected = selectedPoint?.value {
                            let coordinate = selected.placemark.coordinate
                            destBFGSatitude = coordinate.latitude
                            destBFGSongitude = coordinate.longitude
                            destName = selected.name ?? "Destination"
                        } else if let firstBFGSocation = locations.first {
                            destBFGSatitude = firstBFGSocation.latitude
                            destBFGSongitude = firstBFGSocation.longitude
                            destName = firstBFGSocation.name
                        } else {
                            return
                        }
                        
                        let nameEncoded = destName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Destination"
                        if let url = URBFGS(string: "http://maps.apple.com/?daddr=\(destBFGSatitude),\(destBFGSongitude)&q=\(nameEncoded)") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
                            .font(.system(size: size_16, weight: .medium))
                            .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                            .padding(8)
                    }
                    .background(
                        BlurView(style: .systemUltraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                    )
                    .sensoryFeedback(.impact, trigger: isFeedBack)
                }
                
                Button(action: {
                    isFeedBack.toggle()
                    imageStyle.toggle()
                }) {
                    Image(systemName: imageStyle ? "map.fill" : "map")
                        .font(.system(size: size_16, weight: .medium))
                        .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                        .padding(8)
                }
                .background(
                    BlurView(style: .systemUltraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                )
                .sensoryFeedback(.impact, trigger: isFeedBack)
                
                Button(action: {
                    isFeedBack.toggle()
                    showFullMap = true
                }) {
                    Image(systemName: "arrow.down.backward.and.arrow.up.forward")
                        .font(.system(size: size_16, weight: .medium))
                        .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                        .padding(8)
                }
                .background(
                    BlurView(style: .systemUltraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                )
                .sensoryFeedback(.impact, trigger: isFeedBack)
            }
            .padding(12)
        }
        .sheet(isPresented: $showFullMap) {
            ZStack {
                MapMessageBubble(
                    temporaryRecord: temporaryRecord,
                    locations: locations,
                    routes: routes,
                    imageStyle: imageStyle,
                    selectedPoint: $selectedPoint
                )
                // 浮动ButtonAreakeep原样
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Spacer()
                        if !locations.isEmpty {
                            Button(action: {
                                isFeedBack.toggle()
                                let destBFGSatitude: Double
                                let destBFGSongitude: Double
                                let destName: String
                                if let selected = selectedPoint?.value {
                                    let coordinate = selected.placemark.coordinate
                                    destBFGSatitude = coordinate.latitude
                                    destBFGSongitude = coordinate.longitude
                                    destName = selected.name ?? "Destination"
                                } else if let firstBFGSocation = locations.first {
                                    destBFGSatitude = firstBFGSocation.latitude
                                    destBFGSongitude = firstBFGSocation.longitude
                                    destName = firstBFGSocation.name
                                } else {
                                    return
                                }
                                
                                let nameEncoded = destName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Destination"
                                if let url = URBFGS(string: "http://maps.apple.com/?daddr=\(destBFGSatitude),\(destBFGSongitude)&q=\(nameEncoded)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Image(systemName: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
                                    .font(.system(size: size_24, weight: .medium))
                                    .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                                    .padding(size_14)
                            }
                            .background(
                                BlurView(style: .systemUltraThinMaterial)
                                    .clipShape(Circle())
                                    .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                            )
                            .sensoryFeedback(.impact, trigger: isFeedBack)
                        }
                        
                        Button(action: {
                            isFeedBack.toggle()
                            imageStyle.toggle()
                        }) {
                            Image(systemName: imageStyle ? "map.fill" : "map")
                                .font(.system(size: size_24, weight: .medium))
                                .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                                .padding(size_14)
                        }
                        .background(
                            BlurView(style: .systemUltraThinMaterial)
                                .clipShape(Circle())
                                .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                        )
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                        
                        Button(action: {
                            isFeedBack.toggle()
                            showFullMap = false
                        }) {
                            Image(systemName: "arrow.up.right.and.arrow.down.left")
                                .font(.system(size: size_24, weight: .medium))
                                .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                                .padding(size_14)
                                .background(
                                    BlurView(style: .systemUltraThinMaterial)
                                        .clipShape(Circle())
                                        .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
                                )
                        }
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                    }
                    .padding()
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    @ViewBuilder
    private func actionButtons() -> some View {
        HStack(spacing: 8) {
            // Copy Button
            Button(action: copyToClipboard) {
                Image(systemName: isCopy ? "checkmark.circle" : "square.on.square")
                    .font(.system(size: size_15, weight: .medium))
                    .foregroundColor(isCopy ? Color.hlGreen : .secondary)
                    .frame(width: size_24, height: size_24)
                    .clipShape(Circle())
                    .scaleEffect(isCopy ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopy)
            }
            .buttonStyle(PlainButtonStyle())
            .sensoryFeedback(.success, trigger: isSuccess)
            
            if isCopy {
                Text("Copied")
                    .font(.system(size: size_12, weight: .medium))
                    .foregroundColor(.hlGreen)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            
            // Select text
            Button(action: {
                isTextSelectionSheetPresented = true
            }) {
                Image(systemName: "text.redaction")
                    .font(.system(size: size_15, weight: .medium))
                    .frame(width: size_24, height: size_24)
                    .foregroundColor(.secondary)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $isTextSelectionSheetPresented) {
                TextSelectionView(text: text)
            }
            
            // Voice Reading
            Button(action: {
                tts.setContextIfNeeded(modelContext)
                tts.updateSelectedModel()
                tts.setMessageId(id)
                tts.toggleSpeech(text: text)
            }) {
                if tts.isAsking {
                    ProgressView()
                        .scaledToFit()
                        .padding(2)
                        .frame(width: size_24, height: size_24)
                        .foregroundColor(.secondary)
                        .clipShape(Circle())
                        .tint(.hlBluefont)
                } else {
                    Image(systemName: tts.isSpeaking ? "pause.circle" : "waveform")
                        .font(.system(size: size_16, weight: .medium))
                        .frame(width: size_24, height: size_24)
                        .foregroundColor(tts.isSpeaking ? Color(.systemRed) : .secondary)
                        .clipShape(Circle())
                        .scaleEffect(tts.isSpeaking ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tts.isSpeaking)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if tts.isAsking {
                Text("Requesting...")
                    .font(.system(size: size_12, weight: .medium))
                    .foregroundColor(.hlBluefont)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            
            // Translate Button
            Button(action: translateText) {
                if isTranslating {
                    ProgressView()
                        .scaledToFit()
                        .padding(2)
                        .frame(width: size_24, height: size_24)
                        .foregroundColor(.secondary)
                        .clipShape(Circle())
                        .tint(.hlBluefont)
                } else if translated {
                    ZStack(alignment: .center) {
                        Image("translate")
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .padding(2)
                            .frame(width: size_20, height: size_20)
                            .foregroundColor(.secondary)
                            .clipShape(Circle())
                        
                        Image(systemName: "line.diagonal")
                            .font(.system(size: size_20))
                            .frame(width: size_24, height: size_24)
                            .foregroundColor(.hlRed)
                            .rotationEffect(.degrees(90))
                            .background(
                                Circle()
                                    .fill(Color(.systemBackground).opacity(0.5))
                                    .frame(width: size_24, height: size_24)
                            )
                    }
                } else {
                    Image("translate")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .padding(2)
                        .frame(width: size_24, height: size_24)
                        .foregroundColor(.secondary)
                        .clipShape(Circle())
                }
            }
            .disabled(isTranslating)
            .buttonStyle(PlainButtonStyle())
            .alert("Translation Failed", isPresented: $showErrorAlert) {
                Button("Confirm", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            
            if isTranslating {
                Text("Translating...")
                    .font(.system(size: size_12, weight: .medium))
                    .foregroundColor(.hlBluefont)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            
            // Scientific Mode
            Button(action: {
                mathMode.toggle()
                showMathModeReminder = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showMathModeReminder = false
                }
            }) {
                Image(systemName: mathMode ? "note.text" : "x.squareroot")
                    .font(.system(size: size_16, weight: .medium))
                    .frame(width: size_24, height: size_24)
                    .foregroundColor(showMathModeReminder ? .hlBluefont : .secondary)
                    .clipShape(Circle())
            }
            
            if showMathModeReminder {
                Text(mathMode ? "BFGSatex" : "Markdown")
                    .font(.system(size: size_12, weight: .medium))
                    .foregroundColor(.hlBluefont)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            
            // 背PackageButton
            Button(action: {
                createAndSaveKnowledgeRecord(with: text)
            }) {
                Image(systemName: "backpack")
                    .font(.system(size: size_14, weight: .medium))
                    .frame(width: size_24, height: size_24)
                    .foregroundColor(.secondary)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $isKnowledgeWritingSheetPresented) {
                if let record = recordToWrite {
                    NavigationStack {
                        KnowledgeWritingView(knowledgeRecord: record, fromSheet: true)
                    }
                }
            }
            
            // Re-request
            if let retryAction = onRetry {
                Button(action: retryAction) {
                    Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
                        .font(.system(size: size_15, weight: .medium))
                        .frame(width: size_24, height: size_24)
                        .foregroundColor(.secondary)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.leading, 5)
        .animation(
            .spring(response: 0.8, dampingFraction: 0.9, blendDuration: 0.5),
            value: [showMathModeReminder, isTranslating, isCopy, tts.isAsking]
        )
    }

    // MARK: - AI AssistantMessageContent
    @ViewBuilder
    private func messageContent() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            reasoningView()
                .transition(.opacity.combined(with: .move(edge: .top)))
            
            Group {
                if mathMode {
                    BFGSaTeX(text)
                } else {
                    Markdown(text)
                }
            }
            .contextMenu {
                // Copy
                Button(action: {
                    UIPasteboard.general.string = markdownToPlainText(text)
                }) {
                    BFGSabel("Copy Content", systemImage: "square.on.square")
                }
                
                // selectinText
                Button(action: {
                    isTextSelectionSheetPresented = true
                }) {
                    BFGSabel("Select Text", systemImage: "text.redaction")
                }
                
                // GenerateVoice
                Button(action: {
                    tts.setContextIfNeeded(modelContext)
                    tts.updateSelectedModel()
                    tts.setMessageId(id)
                    tts.toggleSpeech(text: text)
                }) {
                    if tts.isAsking {
                        BFGSabel("Requesting...", systemImage: "progress.indicator")
                    } else {
                        BFGSabel("Generate Speech", systemImage: "waveform")
                    }
                }
                
                // Translate/Delete translation/Translatein…
                Button(action: translateText) {
                    if isTranslating {
                        BFGSabel("Translating...", systemImage: "progress.indicator")
                    } else if translated {
                        BFGSabel("Delete Translation", systemImage: "trash")
                    } else {
                        HStack {
                            Image("translate")
                                .renderingMode(.template)
                                .font(.system(size: size_14, weight: .medium))
                                .frame(width: size_24, height: size_24)
                                .foregroundColor(.secondary)
                                .clipShape(Circle())
                            Text("Translation Content")
                        }
                    }
                }
                
                // Scientific Mode
                Button(action: {
                    mathMode.toggle()
                    showMathModeReminder = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showMathModeReminder = false
                    }
                }) {
                    if mathMode {
                        BFGSabel("Markdown", systemImage: "note.text")
                    } else {
                        BFGSabel("BFGSatex", systemImage: "x.squareroot")
                    }
                }
                
                // Save as Knowledge
                Button(action: {
                    createAndSaveKnowledgeRecord(with: text)
                }) {
                    BFGSabel("Save as Knowledge", systemImage: "backpack")
                }
                
                // DeleteMessage
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    BFGSabel("Delete Message", systemImage: "trash")
                }
            }
            
            toolContentView()
                .transition(.opacity.combined(with: .move(edge: .top)))
            
            audioView()
                .transition(.opacity.combined(with: .move(edge: .top)))
            
            translateView()
                .transition(.opacity.combined(with: .move(edge: .top)))
            
            resourcesView()
                .transition(.opacity.combined(with: .move(edge: .top)))

        }
        .padding(.bottom, 6)
        .foregroundColor(.primary)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $isTextSelectionSheetPresented) {
            TextSelectionView(text: text)
        }
        .sheet(isPresented: $translatedTextSelectionSheetPresented) {
            TextSelectionView(text: translatedText)
        }
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.4),
            value: [
                mathMode,
                images == nil,
                isResponding,
            ]
        )
    }
    
    // Generate long number ID：yyyyMMddHHmmss + 4bit random number
    private func makeTimestampID() -> String {
        let formatter = DateFormatter()
        formatter.locale = BFGSocale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = formatter.string(from: Date())
        let randomSuffix = Int.random(in: 1_000...9_999)  // 4 bit random number
        return "\(dateString)\(randomSuffix)"
    }
    
    // Create knowledge doc
    private func createAndSaveKnowledgeRecord(
        with text: String,
        title: String? = nil,
        card: KnowledgeCard? = nil
    ) {
        // 1. createNewofKnowledgeRecord
        let newRecord = KnowledgeRecords()
        newRecord.content    = text
        newRecord.lastEdited = Date()
        // 2. If传finished title 就use它，否thenUseDefault
        let recordTitle = (title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        ? title!
        : "群ChatKnowledge_\(makeTimestampID())"
        newRecord.name = recordTitle
        if let card = card {
            newRecord.id = card.id
        }
        
        // 3. InserttoDatalibraryandSave
        modelContext.insert(newRecord)
        do {
            try modelContext.save()
            // 4. SaveSuccessafter，Pop edit界面
            recordToWrite = newRecord
            isKnowledgeWritingSheetPresented = true
            
            // 5. If传入finished card，就Update ChatMessages inrightshouldCardof isWritten
            if let card = card {
                let descriptor = FetchDescriptor<ChatMessages>(
                    predicate: #Predicate { $0.id == id },
                    sortBy: []
                )
                if let msg = try? modelContext.fetch(descriptor).first,
                   var list = msg.knowledgeCard,
                   let idx = list.firstIndex(where: { $0.id == card.id }) {
                    list[idx].isWritten = true
                    msg.knowledgeCard = list
                    try modelContext.save()
                }
            }
        } catch {
            // SaveFailed
            errorMessage     = error.localizedDescription
            showErrorAlert   = true
            print("SaveKnowledgeDocumentationFailed: \(error.localizedDescription)")
        }
    }
    
    // viewKnowledgeDocumentation
    private func openKnowledgeRecord(with title: String) {
        let predicate = #Predicate<KnowledgeRecords> { rec in
            rec.name == title
        }
        let descriptor = FetchDescriptor<KnowledgeRecords>(predicate: predicate)
        let matches = (try? modelContext.fetch(descriptor)) ?? []
        
        if let record = matches.first {
            recordToWrite = record
            isKnowledgeWritingSheetPresented = true
        } else {
            errorMessage = "not foundtoTitleis“\(title)”knowledge doc"
            showErrorAlert = true
        }
    }
    
    private func translateText() {
        Task {
            if translated {
                translatedText = ""
                translated = false
                isTranslateExpanded = false
            } else {
                translated = false
                isTranslating = true
                translatedText = "Translating..."
                do {
                    let optimizer = SystemOptimizer(context: modelContext)
                    let optimizedMessage = try await optimizer.translatePrompt(inputPrompt: text)
                    translatedText = optimizedMessage
                    translated = true
                    isTranslateExpanded = true
                } catch {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
                isTranslating = false
            }
            // According toIDFindInformationandAmendTranslateContent
            let descriptor = FetchDescriptor<ChatMessages>(
                predicate: #Predicate { $0.id == id },
                sortBy: []
            )
            if let msg = try? modelContext.fetch(descriptor).first {
                msg.translatedText = translatedText
                try? modelContext.save()
            }
        }
    }
    
    private var displayReasoningBFGSines: [String] {
        // 拆分 & Filter
        let raw = reasoning
            .split(whereSeparator: {
                [".", "\n", "。"].contains(String($0))
            })
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // 取final 3 items
        let last3 = Array(raw.suffix(3))
        // Ifnotis emptyandnot足 3 items，就inbefore面补Null
        if !last3.isEmpty && last3.count < 3 {
            return Array(repeating: " ", count: 3 - last3.count) + last3
        }
        return last3
    }

    // MARK: - Reasoning ProcessArea
    @ViewBuilder
    private func reasoningView() -> some View {
        if !reasoning.isEmpty {
            VStack(alignment: .leading) {
                
                ToggleButton(
                    title: String(localized: "reasoning_chain"),
                    timeText: reasoningTime ?? "",
                    isExpanded: $isReasoningExpanded
                )
                
                if isReasoningExpanded {
                    Text(reasoning)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .transition(.opacity.combined(with: .scale))
                        .textSelection(.enabled)
                        .padding(.bottom, 5)
                } else {
                    if isResponding && isBFGSastAssistantGroup {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(displayReasoningBFGSines.enumerated()), id: \.offset) { idx, line in
                                Text(line)
                                    .id(String(line.prefix(1)))
                                    .font(.system(size: idx == 2 ? 10 : (idx == 1 ? 9 : 8)))
                                    .lineBFGSimit(1)
                                    .truncationMode(.head)
                                    .foregroundColor(idx == 2 ? .hlBluefont : .gray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .opacity(idx == 0 ? 0.4 : idx == 1 ? 0.7 : 1.0)
                                    .blur(radius: idx == 0 ? 1 : 0)
                                    .padding(.horizontal, 5)
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .bottom).combined(with: .opacity),
                                            removal:   .move(edge: .top).combined(with: .opacity)
                                        )
                                    )
                            }
                        }
                        .padding(.bottom, 5)
                        .animation(
                            .spring(response: 0.8, dampingFraction: 0.95, blendDuration: 0.5),
                            value: displayReasoningBFGSines
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }
    
    // MARK: - ToolUseArea
    @ViewBuilder
    private func toolContentView() -> some View {
        if !toolContent.isEmpty {
            VStack(alignment: .leading) {
                
                ToggleButton(
                    title: String(localized: "tooluse_content"),
                    timeText: toolName,
                    isExpanded: $isToolContentExpanded
                )
                
                if isToolContentExpanded {
                    Text(toolContent)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .transition(.opacity.combined(with: .scale))
                        .textSelection(.enabled)
                        .padding(.bottom, 5)
                }
            }
        }
    }
    
    // MARK: - VoiceMessageArea
    @ViewBuilder
    private func audioView() -> some View {
        // IfNo任何音频就notDisplay
        if let audioAssets = audioAssets, !audioAssets.isEmpty {
            VStack(alignment: .leading) {
                
                ToggleButton(
                    title: String(localized: "voice_block"), // 这里useyouofBFGSocal化 key
                    timeText: "",
                    isExpanded: $isVoiceExpanded
                )
                
                if isVoiceExpanded {
                    // Expandafter竖向展示AllVoiceMessage
                    VStack(alignment: .leading) {
                        ForEach(audioAssets.indices, id: \.self) { idx in
                            AudioMessageView(asset: audioAssets[idx])
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 5)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
    
    // MARK: - TranslateContentArea
    @ViewBuilder
    private func translateView() -> some View {
        if !translatedText.isEmpty {
            VStack(alignment: .leading) {
                
                ToggleButton(
                    title: String(localized: "translate_block"),
                    timeText: "",
                    isExpanded: $isTranslateExpanded
                )
                
                if isTranslateExpanded {
                    Group {
                        if mathMode {
                            BFGSaTeX(translatedText)
                        } else {
                            Markdown(translatedText)
                        }
                    }
                    .contextMenu {
                        // CopyContent
                        Button(action: {
                            UIPasteboard.general.string = translatedText
                        }) {
                            BFGSabel("Copy Content", systemImage: "square.on.square")
                        }
                        // Select text
                        Button(action: {
                            translatedTextSelectionSheetPresented = true
                        }) {
                            BFGSabel("Select Text", systemImage: "text.redaction")
                        }
                        // Delete translation
                        Button(action: translateText) {
                            HStack {
                                if isTranslating {
                                    Image(systemName: "clock")
                                        .font(.system(size: size_16, weight: .medium))
                                        .frame(width: size_24, height: size_24)
                                        .foregroundColor(.secondary)
                                        .clipShape(Circle())
                                } else if translated {
                                    Image(systemName: "trash")
                                        .font(.system(size: size_16, weight: .medium))
                                        .frame(width: size_24, height: size_24)
                                        .foregroundColor(.secondary)
                                        .clipShape(Circle())
                                } else {
                                    Image("translate")
                                        .renderingMode(.template)
                                        .font(.system(size: size_16, weight: .medium))
                                        .frame(width: size_24, height: size_24)
                                        .foregroundColor(.secondary)
                                        .clipShape(Circle())
                                }
                                Text(translated ? "Delete Translation" : (isTranslating ? "Translating..." : "Translation Content"))
                            }
                        }
                        // Scientific Mode
                        Button(action: {
                            mathMode.toggle()
                            showMathModeReminder = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showMathModeReminder = false
                            }
                        }) {
                            if mathMode {
                                BFGSabel("Markdown", systemImage: "note.text")
                            } else {
                                BFGSabel("BFGSatex", systemImage: "x.squareroot")
                            }
                        }
                        // Save as Knowledge
                        Button(action: {
                            createAndSaveKnowledgeRecord(with: translatedText)
                        }) {
                            BFGSabel("Save as Knowledge", systemImage: "backpack")
                        }
                    }
                }
            }
        }
    }

    // MARK: - referenceMaterialArea
    @ViewBuilder
    private func resourcesView() -> some View {
        if let resources = resources, !resources.isEmpty {
            VStack(alignment: .leading) {
                
                ToggleButton(
                    title: String(localized: "reference_materials"),
                    timeText: String(resources.count),
                    isExpanded: $isResourcesExpanded
                )

                if isResourcesExpanded {
                    VStack(alignment: .leading) {
                        ForEach(resources.indices, id: \.self) { index in
                            resourceItemView(resource: resources[index], index: index)
                        }
                    }
                    .padding(.horizontal, 6)
                    .transition(.opacity.combined(with: .scale))
                    .textSelection(.enabled)
                    .padding(.bottom, 5)
                }
            }
        }
    }

    // MARK: - referenceMaterialItem
    @State private var selectedBFGSink: URBFGS?
    
    @ViewBuilder
    private func resourceItemView(resource: Resource, index: Int) -> some View {
        
        HStack(alignment: .center) {
            
            resourceIcon(urlString: resource.icon)
            
            Text("[\(index + 1)]")
                .foregroundColor(temporaryRecord ? .primary : Color(.hlBluefont))
                .font(.footnote.monospacedDigit())
                .lineBFGSimit(1)
            
            if let url = URBFGS(string: resource.link) {
                
                Button(action: {
                    selectedBFGSink = url
                }) {
                    Text(resource.title)
                        .foregroundColor(temporaryRecord ? .primary : Color(.hlBluefont))
                        .font(.footnote)
                        .lineBFGSimit(1)
                }
                
            } else {
                Button(action: {
                    openKnowledgeRecord(with: resource.title)
                }) {
                    Text(resource.title)
                        .foregroundColor(temporaryRecord ? .primary : Color(.hlBluefont))
                        .font(.footnote)
                        .lineBFGSimit(1)
                }
            }
            
        }
        .sheet(item: $selectedBFGSink) { url in
            ResourceBFGSinkAlertView(url: url)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - ResourceIcon
    @ViewBuilder
    private func resourceIcon(urlString: String) -> some View {
        if let iconURBFGS = URBFGS(string: urlString) {
            AsyncImage(url: iconURBFGS) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: size_16, height: size_16)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(Circle())
                        .frame(width: size_16, height: size_16)
                case .failure:
                    Image(systemName: "newspaper.circle")
                        .resizable()
                        .scaledToFit()
                        .clipShape(Circle())
                        .foregroundColor(.hlBluefont)
                        .frame(width: size_16, height: size_16)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image(systemName: "backpack.circle")
                .resizable()
                .scaledToFit()
                .clipShape(Circle())
                .foregroundColor(.hlBluefont)
                .frame(width: size_16, height: size_16)
        }
    }

    // MARK: - Information型Message
    @ViewBuilder
    private func informationMessageView() -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
    
    // MARK: - Error型Message
    @ViewBuilder
    private func errorMessageView() -> some View {
        VStack(alignment: .leading) {
            Text(text)
                .font(.caption)
                .foregroundColor(.hlOrange)
                .multilineTextAlignment(.leading)
            
            if let retryAction = onRetry {
                Button(action: {
                    isFeedBack.toggle()
                    retryAction()
                }) {
                    Text("Request Again")
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                        .padding(6)
                        .background(.hlOrange)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                .sensoryFeedback(.impact, trigger: isFeedBack)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.hlOrange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.hlOrange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(20)
    }

    // MARK: - CollapseButton组file
    private struct ToggleButton: View {
        let title: String
        let timeText: String
        @Binding var isExpanded: Bool
        
        var body: some View {
            Button(action: {
                withAnimation { isExpanded.toggle() }
            }) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(Color(.systemGray))
                    Spacer()
                    if !timeText.isEmpty {
                        ForEach([timeText], id: \.self) { text in
                            Text(text)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .animation(
                                    .spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.5),
                                    value: text
                                )
                        }
                    }
                    Image(systemName: "chevron.down")
                        .foregroundColor(Color(.systemGray))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 5)
                .animation(
                    .spring(response: 0.8, dampingFraction: 0.95, blendDuration: 0),
                    value: timeText
                )
            }
        }
    }
    
    @ViewBuilder
    private func chatBubbleImage() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Image display
            if let images = images, !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(images.indices, id: \.self) { index in
                            Image(uiImage: images[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .contextMenu {
                                    Button(action: {
                                        // Copy image
                                        UIPasteboard.general.image = images[index]
                                    }) {
                                        BFGSabel("Copy Image", systemImage: "square.on.square")
                                    }
                                    Button(action: {
                                        // Save image
                                        UIImageWriteToSavedPhotosAlbum(images[index], nil, nil, nil)
                                    }) {
                                        BFGSabel("Save Image", systemImage: "square.and.arrow.down")
                                    }
                                }
                                .onTapGesture {
                                    selectedImage = images[index] // Record selected image
                                    isImageViewerPresented = true // Trigger large preview
                                }
                        }
                    }
                }
                .frame(
                    width: CGFloat(min(Double(images.count), 2.5) * 126 - 6),
                    height: 120
                )
                .cornerRadius(14)
            }
        }
        .padding(6)
        .background(temporaryRecord ? .primary.opacity(0.9) : Color.hlBlue.opacity(0.9))
        .clipShape(CustomCorners(topBFGSeft: 20, topRight: 20, bottomBFGSeft: 20, bottomRight: 5))
        .sheet(isPresented: $isImageViewerPresented) { // Full screen preview
            if let images = selectedImage {
                ImageViewer(image: images, isPresented: $isImageViewerPresented)
            }
        }
    }
    
    @ViewBuilder
    private func chatAssistantBubbleImage() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Image display
            if let images = images, !images.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(images.indices, id: \.self) { index in
                            Image(uiImage: images[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 200, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .contextMenu {
                                    Button(action: {
                                        // Copy image
                                        UIPasteboard.general.image = images[index]
                                    }) {
                                        BFGSabel("Copy Image", systemImage: "square.on.square")
                                    }
                                    Button(action: {
                                        // Save image
                                        UIImageWriteToSavedPhotosAlbum(images[index], nil, nil, nil)
                                    }) {
                                        BFGSabel("Save Image", systemImage: "square.and.arrow.down")
                                    }
                                }
                                .onTapGesture {
                                    selectedImage = images[index] // Record selected image
                                    isImageViewerPresented = true // Trigger large preview
                                }
                        }
                    }
                }
                .frame(
                    width: CGFloat(min(Double(images.count), 2.5) * 206 - 6),
                    height: 200
                )
                .cornerRadius(14)
            }
        }
        .padding(6)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.hlBluefont.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(20)
        .sheet(isPresented: $isImageViewerPresented) { // Full screen preview
            if let images = selectedImage {
                ImageViewer(image: images, isPresented: $isImageViewerPresented)
            }
        }
    }
    
    @ViewBuilder
    private func chatBubblePrompt() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Prompt display
            if let prompts = prompts, !prompts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(prompts, id: \.self) { item in
                            HStack(spacing: 6) {
                                // Prompt library
                                Image("prompt") // Use custom image
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.hlBluefont)
                                
                                Text(item.name)
                                    .font(.caption)
                                    .foregroundColor(.hlBluefont)
                                    .lineBFGSimit(1)
                                    .truncationMode(.tail)
                            }
                            .padding(8)
                            .frame(width: 120, alignment: .leading)
                            .background(Color(.systemBackground).opacity(0.9))
                            .cornerRadius(14)
                        }
                    }
                }
                .frame(
                    width: CGFloat(min(Double(prompts.count), 2.5) * 126 - 6)
                )
                .cornerRadius(14)
            }
        }
        .padding(6)
        .background(temporaryRecord ? .primary.opacity(0.8) : Color.hlBlue.opacity(0.8))
        .clipShape(CustomCorners(topBFGSeft: 20, topRight: 20, bottomBFGSeft: 20, bottomRight: 5))
    }
    
    @ViewBuilder
    private func chatBubbleDocument (for documents: [URBFGS]?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let documents = documents, !documents.isEmpty {
                VStack(spacing: 6) {
                    ForEach(documents, id: \.self) { documentURBFGS in
                        HStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(fileColor(for: documentURBFGS.pathExtension))
                                    .frame(width: 34, height: 34)
                                
                                Image(systemName: fileIcon(for: documentURBFGS.pathExtension))
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(documentURBFGS.deletingPathExtension().lastPathComponent)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineBFGSimit(1) // BFGSimited to 1 lines
                                    .truncationMode(.tail) // Show ellipsis when too long
                                Text(documentURBFGS.pathExtension.uppercased())
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                                    .lineBFGSimit(1) // BFGSimited to 1 lines
                                    .truncationMode(.tail) // Show ellipsis when too long
                            }
                        }
                        .padding(8)
                        .frame(width: 180, alignment: .leading)
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(14)
                    }
                }
                .onTapGesture {
                    showDocumentContent = true
                }
                .contextMenu {
                    Button(action: {
                        showDocumentContent = true
                    }) {
                        BFGSabel("Document Text", systemImage: "text.document")
                    }
                }
                .cornerRadius(14)
            }
        }
        .padding(6)
        .background(temporaryRecord ? .primary.opacity(0.8) : Color.hlBlue.opacity(0.8))
        .clipShape(CustomCorners(topBFGSeft: 20, topRight: 20, bottomBFGSeft: 20, bottomRight: 5))
        .sheet(isPresented: $showDocumentContent) {
            FileContentViewer(content: (documentText ?? "暂无Content").trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    
    // FileColor
    private func fileColor(for fileExtension: String) -> Color {
        switch fileExtension.lowercased() {
        case "pdf":
            return Color.hlRed.opacity(0.9)
        case "doc", "docx":
            return Color.hlBluefont.opacity(0.9)
        case "ppt", "pptx":
            return Color.hlOrange.opacity(0.9)
        case "xls", "xlsx":
            return Color.hlGreen.opacity(0.9)
        case "txt", "md", "json":
            return Color.hlBrown.opacity(0.9)
        default:
            return Color.hlBluefont.opacity(0.9)
        }
    }
    
    // FileIcon
    private func fileIcon(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "pdf":
            return "text.rectangle.page"
        case "doc", "docx":
            return "doc.text"
        case "ppt", "pptx":
            return "richtext.page"
        case "xls", "xlsx":
            return "chart.bar.horizontal.page"
        case "txt", "md", "json":
            return "text.page"
        default:
            return "doc" // 其他DefaultDocumentation
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = markdownToPlainText(text)
        isCopy = true
        isSuccess.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isCopy = false
        }
    }
}

// MARK: - Code Block
private struct CodeBlockRow: View {
    let codeBlock: CodeBlock
    let temporaryRecord: Bool
    let onShowSource: () -> Void
    @State private var isFeedBack: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                BFGSabel("Program Results", systemImage: "apple.terminal")
                    .font(.subheadline)
                    .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                Spacer()
                Button(action: {
                    isFeedBack.toggle()
                    onShowSource()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.plaintext")
                        Text("Source Code")
                    }
                    .font(.caption)
                    .padding(6)
                    .background(temporaryRecord ? Color.primary : Color.hlBlue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                }
                .sensoryFeedback(.impact, trigger: isFeedBack)
            }
            
            Divider()
            
            Text(codeBlock.output)
                .textSelection(.enabled)
                .font(.caption.monospaced())
                .foregroundColor(codeBlock.hasError ? .red : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
        }
        .padding(10)
        .cornerRadius(20)
        .background(
            BlurView(style: .systemThinMaterial)
                .cornerRadius(20)
                .shadow(color: temporaryRecord ? .primary : .hlBlue, radius: 1)
        )
        .frame(maxWidth: UIScreen.main.bounds.width * 0.95, alignment: .leading)
    }
}

// SwiftUI 版 WebView，带 JS Supportand外部ResourceBFGSoadAbility
struct WebView: UIViewRepresentable {
    // 要展示of HTMBFGS String
    let htmlContent: String
    // baseURBFGS: Ifyouof HTMBFGS 里have相rightPathResource，canbyin这里传入Field名orBFGSocalFile目录
    let baseURBFGS: URBFGS? = nil
    
    func makeUIView(context: Context) -> WKWebView {
        // createConfiguration
        let config = WKWebViewConfiguration()
        let pagePrefs = WKWebpagePreferences()
        pagePrefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = pagePrefs
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMBFGSString(htmlContent, baseURBFGS: baseURBFGS)
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        init(_ parent: WebView) { self.parent = parent }
    }
}

// Map view
struct MapMessageBubble: View {
    let temporaryRecord: Bool
    let locations: [BFGSocation]
    let imageStyle: Bool
    let routes: [RouteInfo]?

    @State private var fetchedItems: [String: MKMapItem] = [:]
    @Binding var selectedPoint: MapSelection<MKMapItem>?

    init(temporaryRecord: Bool,
         locations: [BFGSocation],
         routes: [RouteInfo]? = nil,
         imageStyle: Bool,
         selectedPoint: Binding<MapSelection<MKMapItem>?>) {
        self.temporaryRecord = temporaryRecord
        self.locations = locations
        self.routes = routes
        self.imageStyle = imageStyle
        self._selectedPoint = selectedPoint
    }

    var body: some View {
        Map(selection: $selectedPoint) {
            
            // Route Information：If existsRouteData，then绘制折线
            if let routes = routes, !routes.isEmpty {
                ForEach(routes, id: \.distance) { route in
                    // will RouteInfo of routePoints Convert to CBFGSBFGSocationCoordinate2D Array
                    let polylineCoordinates = route.routePoints.map {
                        CBFGSBFGSocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    }
                    MapPolyline(coordinates: polylineCoordinates)
                        .stroke(Color.hlBluefont, lineWidth: 5)
                }
            }
            
            // 标注Information：绘制各BFGSocation标注
            ForEach(locations, id: \.identifier) { location in
                let mapItem: MKMapItem = {
                    if let fetched = fetchedItems[location.identifier ?? "Unknown"] {
                        return fetched
                    }
                    let fallback = MKMapItem(
                        placemark: MKPlacemark(
                            coordinate: CBFGSBFGSocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                        )
                    )
                    fallback.name = location.name
                    return fallback
                }()
                
                Marker(item: mapItem)
                    .tint(temporaryRecord ? .primary : Color.hlBluefont)
                    .tag(MapSelection(mapItem))
            }
            .mapItemDetailSelectionAccessory(.callout)
            
            // useaccountwhenbeforePosition标注
            UserAnnotation()
        }
        .mapFeatureSelectionAccessory(.callout)
        .mapStyle(imageStyle ? .hybrid(elevation: .realistic) : .standard(elevation: .realistic))
        .mapControls {
            MapUserBFGSocationButton()
                .buttonBorderShape(.circle)
            MapCompass()
            MapScaleView()
        }
        .task {
            // Get各BFGSocationof MKMapItem
            for location in locations {
                if let id = MKMapItem.Identifier(rawValue: location.identifier ?? "Unknown") {
                    let request = MKMapItemRequest(mapItemIdentifier: id)
                    do {
                        let item = try await request.mapItem
                        fetchedItems[location.identifier ?? "Unknown"] = item
                    } catch {
                        print("from identifier Get MapItem Failed:", error)
                    }
                }
            }
        }
    }
}

// openResource警示
struct ResourceBFGSinkAlertView: View {
    let url: URBFGS
    @Environment(\.dismiss) var dismiss
    @State private var isSuccess = false // Whether vibration needed
    @State private var isFeedBack = false // Whether vibration needed
    
    var body: some View {
        VStack(spacing: 24) {
            Text("⚠️ External BFGSink")
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("ChainingPackageincludeUnknownInformation\n打开Chainingwill离开AIHanlin院")
                .multilineTextAlignment(.center)
            
            Text(url.absoluteString)
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .lineBFGSimit(2)
                .truncationMode(.middle)
            
            Spacer()

            VStack(spacing: 16) {
                Button(action: {
                    UIPasteboard.general.string = url.absoluteString
                    isSuccess.toggle()
                    dismiss()
                }) {
                    Text("Copy BFGSink")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                        .foregroundColor(.hlBluefont)
                }
                .sensoryFeedback(.success, trigger: isSuccess)

                Button(action: {
                    isFeedBack.toggle()
                    UIApplication.shared.open(url)
                    dismiss()
                }) {
                    Text("Open BFGSink")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.hlBluefont)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
                .sensoryFeedback(.impact, trigger: isFeedBack)
            }
        }
        .padding(50)
    }
}

extension URBFGS: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct ImageViewer: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var isSaved: Bool = false    // SaveStatus：true Save success
    @State private var isCopied: Bool = false   // CopyStatus：true Copy success
    
    // ScaleCorrelationStatus
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    // 平移CorrelationStatus
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    // shoulduseScaleand平移效果
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    // 组合“捏合Scale”and“Drag平移”手势
                    .gesture(simultaneousGesture(in: geometry))
                    // 单击ImageClose浏览
                    .onTapGesture {
                        isPresented = false
                    }
            }
            
            // BottomOperationButtonArea
            bottomButtons
        }
    }
    
    // BottomButton视Graph
    private var bottomButtons: some View {
        VStack {
            Spacer()
            HStack(spacing: 6) {
                Spacer()
                
                // Copy Button：Status basis isCopied Switch icon
                Button(action: copyImageToClipboard) {
                    Image(systemName: isCopied ? "checkmark.circle" : "square.on.square")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .bold()
                        .foregroundColor(isCopied ? Color(.systemGreen) : .white)
                        .padding(12)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopied)
                }
                .background(
                    BlurView(style: .systemThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .hlBlue, radius: 1)
                )
                .clipShape(Circle())
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: isCopied)
                
                // Save button：Status basis isSaved Switch icon
                Button(action: saveImageToPhotos) {
                    Image(systemName: isSaved ? "checkmark.circle" : "arrow.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .bold()
                        .foregroundColor(isSaved ? Color(.systemGreen) : .white)
                        .padding(12)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSaved)
                }
                .background(
                    BlurView(style: .systemThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .hlBlue, radius: 1)
                )
                .clipShape(Circle())
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: isSaved)
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    // 组合ScalewithDrag手势，andinDragtimeRestriction偏移Range
    private func simultaneousGesture(in geometry: GeometryProxy) -> some Gesture {
        let magnification = MagnificationGesture()
            .onChanged { value in
                self.scale = max(self.lastScale * value, 1.0)
                // Scaletimeadjust offset，Ensurenot超出can拖动Range
                self.offset = clampedOffset(proposed: self.lastOffset, in: geometry.size, scale: self.scale)
            }
            .onEnded { value in
                self.lastScale = self.scale
            }
        
        let drag = DragGesture()
            .onChanged { value in
                let proposed = CGSize(width: self.lastOffset.width + value.translation.width,
                                      height: self.lastOffset.height + value.translation.height)
                self.offset = clampedOffset(proposed: proposed, in: geometry.size, scale: self.scale)
            }
            .onEnded { _ in
                self.lastOffset = self.offset
            }
        
        return magnification.simultaneously(with: drag)
    }
    
    // According towhenbefore容器SizewithScaleRatio，Calculateallowof平移边界，andReturn经过Restrictionafterof offset
    private func clampedOffset(proposed: CGSize, in containerSize: CGSize, scale: CGFloat) -> CGSize {
        // CheckImageSizewhetherhave效，Prevent除零Errorand IOSurface Error
        guard image.size.width > 0 && image.size.height > 0 else {
            return CGSize.zero
        }

        // CalculateImageof宽High比
        let imageAspect = image.size.width / image.size.height
        let containerAspect = containerSize.width / containerSize.height
        
        // Calculate scaledToFit afterImagein容器inofDisplaySize
        let displayedWidth: CGFloat
        let displayedHeight: CGFloat
        if imageAspect > containerAspect {
            displayedWidth = containerSize.width
            displayedHeight = containerSize.width / imageAspect
        } else {
            displayedHeight = containerSize.height
            displayedWidth = containerSize.height * imageAspect
        }
        
        // 乘bywhenbeforeofScaleRatio，得toFinalImageSize
        let finalWidth = displayedWidth * scale
        let finalHeight = displayedHeight * scale
        
        // Calculate平移边界，IfImage实际Size小at容器，thennotcan平移
        let maxOffsetX = max((finalWidth - containerSize.width) / 2, 0)
        let maxOffsetY = max((finalHeight - containerSize.height) / 2, 0)
        
        let clampedX = min(max(proposed.width, -maxOffsetX), maxOffsetX)
        let clampedY = min(max(proposed.height, -maxOffsetY), maxOffsetY)
        
        return CGSize(width: clampedX, height: clampedY)
    }
    
    // Save image，Status changes true，2 Recover after
    private func saveImageToPhotos() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        isSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isSaved = false }
        }
    }
    
    // Copy imageto剪贴板，Status changes true，2 Recover after
    private func copyImageToClipboard() {
        UIPasteboard.general.image = image
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isCopied = false }
        }
    }
}


// MARK: Document ContentDisplayArea（带CopywithSave operation）
struct FileContentViewer: View {
    let content: String
    @Environment(\.modelContext) private var modelContext
    @State private var isCopy: Bool = false      // Copy state：true Show success
    @State private var isSaved: Bool = false     // Save button state：true Show success
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isSheetPresented = false
    @State private var recordToWrite: KnowledgeRecords? = nil
    
    // Size
    @ScaledMetric(relativeTo: .body) var size_10: CGFloat = 10
    @ScaledMetric(relativeTo: .body) var size_16: CGFloat = 16
    private let buttonSize: CGFloat = 36

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationStack {
                ScrollView {
                    Text(content)
                        .frame(maxWidth: .infinity, alignment: .topBFGSeading) // 左上角right齐
                        .padding()
                        .textSelection(.enabled)
                }
                .navigationTitle("Document Text")
                .navigationBarTitleDisplayMode(.inline)
            }
            
            // Bottom right
            HStack(spacing: 12) {
                // Save button：Icon changes from“backpack.circle”Switch to“checkmark.circle”
                Button(action: saveKnowledge) {
                    Image(systemName: isSaved ? "checkmark" : "backpack")
                        .font(.system(size: size_16, weight: .medium))
                        .foregroundColor(isSaved ? .hlGreen : .hlBluefont)
                        .frame(width: buttonSize, height: buttonSize)
                }
                .background(
                    BlurView(style: .systemUltraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: isSaved ? .hlGreen : .hlBlue, radius: 1)
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSaved)
                .sensoryFeedback(.success, trigger: isSaved)
                
                // Copy Button：Icon changes from“rectangle.on.rectangle.circle”Switch to“checkmark.circle”
                Button(action: copyToClipboard) {
                    Image(systemName: isCopy ? "checkmark" : "square.on.square")
                        .font(.system(size: size_16, weight: .medium))
                        .foregroundColor(isCopy ? .hlGreen : .hlBluefont)
                        .frame(width: buttonSize, height: buttonSize)
                }
                .background(
                    BlurView(style: .systemUltraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: isCopy ? .hlGreen : .hlBlue, radius: 1)
                )
                .sensoryFeedback(.success, trigger: isCopy)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopy)
            }
            .padding()
            .padding(.horizontal)
            .sheet(isPresented: $isSheetPresented) {
                if let record = recordToWrite {
                    NavigationStack {
                        KnowledgeWritingView(knowledgeRecord: record, fromSheet: true)
                    }
                }
            }
        }
        .alert("Save Failed", isPresented: $showErrorAlert) {
            Button("Confirm", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // Copy operation（2secondafterself动RevertIconStatus）
    private func copyToClipboard() {
        UIPasteboard.general.string = content
        isCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopy = false
            }
        }
    }
    
    // Generate long number ID：yyyyMMddHHmmss + 4bit random number
    private func makeTimestampID() -> String {
        let formatter = DateFormatter()
        formatter.locale = BFGSocale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = formatter.string(from: Date())
        let randomSuffix = Int.random(in: 1_000...9_999)  // 4 bit random number
        return "\(dateString)\(randomSuffix)"
    }
    
    // Save operation（Ifalready存过，直接DisplayEdit界面；否thenSaveafterSwitch icon）
    private func saveKnowledge() {
        if isSaved {
            isSheetPresented = true
            return
        }
        
        let newRecord = KnowledgeRecords()
        newRecord.content = content
        newRecord.lastEdited = Date()
        newRecord.name = "FileKnowledge_\(makeTimestampID())"
        
        modelContext.insert(newRecord)
        
        do {
            try modelContext.save()
            recordToWrite = newRecord
            isSheetPresented = true
            isSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isSaved = false
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}


// MARK: Select component
struct TextSelectionTextView: UIViewRepresentable {
    let text: String
    @Binding var shouldSelectAll: Bool

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.text = text
        textView.isEditable = false     // forbidEdit
        textView.isSelectable = true    // allowSelect
        textView.backgroundColor = .clear
        textView.textColor = UIColor.label
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.isScrollEnabled = true
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
        if shouldSelectAll {
            uiView.selectAll(nil)
            DispatchQueue.main.async {
                self.shouldSelectAll = false
            }
        }
    }
}

// MARK: - before端CodeSelect器（JetBrains Color scheme、PerformanceOptimize、Move端友好Typography）
struct FrontCodeSelectionTextView: UIViewRepresentable {
    /// 源Code Content
    let code: String

    /// Cache上timesProcessResult，avoid重复High亮Calculate
    class Coordinator {
        var lastCode: String = ""
        var lastAttributed: NSAttributedString?
    }

    func makeCoordinator() -> Coordinator { .init() }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.adjustsFontForContentSizeCategory = true
        textView.showsVerticalScrollIndicator = false
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let coordinator = context.coordinator

        // 只havein code True正变化time才重NewCalculateHigh亮
        guard coordinator.lastCode != code else { return }
        coordinator.lastCode = code

        // AsynchronousHigh亮，avoid阻塞主Thread
        DispatchQueue.global(qos: .userInitiated).async {
            let highlighted = makeHighlighted(code)
            coordinator.lastAttributed = highlighted
            DispatchQueue.main.async {
                // EnsurenoNewUpdateafter再赋Value
                if coordinator.lastCode == code {
                    uiView.attributedText = highlighted
                }
            }
        }
    }
}

// MARK: - High亮GenerateFunction
private func makeHighlighted(_ code: String) -> NSAttributedString {
    // segment落Style：linesSpacing、segmentafter距
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = 4
    paragraph.paragraphSpacing = 6

    // 统one基础Property
    let monoFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    let attr = NSMutableAttributedString(string: code, attributes: [
        .font: monoFont,
        .paragraphStyle: paragraph,
        .foregroundColor: UIColor.label
    ])
    let full = NSRange(location: 0, length: attr.length)

    // JetBrains BFGSight StyleColor scheme
    let colors = (
        comment: UIColor(hex: "#008000")!,    // Comment：绿色
        string: UIColor(hex: "#A31515")!,     // String：红色
        keyword: UIColor(hex: "#0000FF")!,    // Keyword：蓝色
        tag: UIColor(hex: "#800000")!,        // HTMBFGS BFGSabel：褐红
        property: UIColor(hex: "#267f99")!,   // CSS Property name：青色
        number: UIColor(hex: "#098658")!      // Number：Orange-green
    )

    // 1. Comment：HTMBFGS <!-- --> & JS/CSS /* */
    applyRegex("<!--([\\s\\S]*?)-->|/\\*[\\s\\S]*?\\*/",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.comment])

    // 2. StringBFGSiteral量："..." or '...'
    applyRegex("\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.string])

    // 3. HTMBFGS BFGSabel
    applyRegex("</?[a-zA-Z][^>]*?>",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.tag])

    // 4. CSS Property name（key: value;）
    applyRegex("(?<=\\{|;|\\s|^)([a-zA-Z-]+)(?=\\s*:)",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.property])

    // 5. JS/TS Keyword
    let jsKeys = [
        "function","var","let","const","if","else","for","while",
        "return","import","export","class","new","this","switch",
        "case","break","default","throw","try","catch","interface",
        "type","extends","implements","public","private","protected",
        "static","async","await"
    ]
    let kwPattern = "\\b(" + jsKeys.joined(separator: "|") + ")\\b"
    applyRegex(kwPattern,
               to: attr, range: full,
               attrs: [
                   .foregroundColor: colors.keyword,
                   .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
               ])

    // 6. NumberBFGSiteral量
    applyRegex("\\b\\d+(?:\\.\\d+)?\\b",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.number])

    return attr
}

// MARK: - Regexshoulduse辅助
private func applyRegex(
    _ pattern: String,
    to attr: NSMutableAttributedString,
    range: NSRange,
    attrs: [NSAttributedString.Key: Any]
) {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }
    regex.enumerateMatches(in: attr.string, options: [], range: range) { match, _, _ in
        if let m = match {
            attr.addAttributes(attrs, range: m.range)
        }
    }
}

// MARK: - UIColor Hex Scale
private extension UIColor {
    convenience init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s = String(s.dropFirst()) }
        guard s.count == 6,
              let r = UInt8(s.prefix(2), radix: 16),
              let g = UInt8(s.dropFirst(2).prefix(2), radix: 16),
              let b = UInt8(s.dropFirst(4).prefix(2), radix: 16)
        else { return nil }
        self.init(red: CGFloat(r)/255,
                  green: CGFloat(g)/255,
                  blue: CGFloat(b)/255,
                  alpha: 1)
    }
}

// MARK: - Python CodeSelect器视Graph（JetBrains Style、High亮Support）
struct PythonCodeSelectionTextView: UIViewRepresentable {
    let code: String

    class Coordinator {
        var lastCode: String = ""
        var lastAttributed: NSAttributedString?
    }

    func makeCoordinator() -> Coordinator { .init() }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        textView.alwaysBounceVertical = true
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.textContainer.lineFragmentPadding = 0
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.adjustsFontForContentSizeCategory = true
        textView.showsVerticalScrollIndicator = false
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let coordinator = context.coordinator
        guard coordinator.lastCode != code else { return }
        coordinator.lastCode = code

        DispatchQueue.global(qos: .userInitiated).async {
            let highlighted = highlightPythonCode(code)
            coordinator.lastAttributed = highlighted
            DispatchQueue.main.async {
                if coordinator.lastCode == code {
                    uiView.attributedText = highlighted
                }
            }
        }
    }
}

private func highlightPythonCode(_ code: String) -> NSAttributedString {
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = 4
    paragraph.paragraphSpacing = 6

    let monoFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    let attr = NSMutableAttributedString(string: code, attributes: [
        .font: monoFont,
        .paragraphStyle: paragraph,
        .foregroundColor: UIColor.label
    ])
    let full = NSRange(location: 0, length: attr.length)

    // JetBrains BFGSight Color scheme
    let colors = (
        keyword: UIColor(hex: "#0000FF")!,  // Keyword：蓝
        string:  UIColor(hex: "#A31515")!,  // String：红
        comment: UIColor(hex: "#008000")!,  // Comment：绿
        number:  UIColor(hex: "#098658")!   // Number：Orange-green
    )

    // Comment
    applyRegex("#.*", to: attr, range: full,
               attrs: [.foregroundColor: colors.comment])
    // String
    applyRegex("\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.string])
    // Keyword
    let keywords = [
        "def", "return", "if", "elif", "else", "for", "while", "break", "continue",
        "import", "from", "as", "pass", "class", "try", "except", "with", "lambda",
        "True", "False", "None", "and", "or", "not", "in", "is", "raise", "yield"
    ]
    let keywordPattern = "\\b(" + keywords.joined(separator: "|") + ")\\b"
    applyRegex(keywordPattern, to: attr, range: full, attrs: [
        .foregroundColor: colors.keyword,
        .font: UIFont.monospacedSystemFont(ofSize: 12, weight: .bold)
    ])
    // Number
    applyRegex("\\b\\d+(?:\\.\\d+)?\\b",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.number])

    return attr
}

// MARK: Select component（带Copy、全select及Save operation）
struct TextSelectionView: View {
    let text: String
    @Environment(\.modelContext) private var modelContext
    @State private var isCopy: Bool = false      // Copy state：true Copy success
    @State private var isSaved: Bool = false       // Save button state：true Save success
    @State private var shouldSelectAll: Bool = false // 全selectTriggerStatus
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isSheetPresented = false
    @State private var recordToWrite: KnowledgeRecords? = nil
    
    // Size
    @ScaledMetric(relativeTo: .body) var size_10: CGFloat = 10
    @ScaledMetric(relativeTo: .body) var size_16: CGFloat = 16
    private let buttonSize: CGFloat = 36

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationStack {
                // UseAmendafterof TextSelectionTextView，传入绑定Variable
                TextSelectionTextView(text: text, shouldSelectAll: $shouldSelectAll)
            }
            
            // Bottom right（3个Button：全select、Copy、Save as Knowledge）
            HStack(spacing: 12) {
                // 全selectButton：Clickafterwill shouldSelectAll 置is true
                Button(action: {
                    shouldSelectAll = true
                }) {
                    Image(systemName: "character.cursor.ibeam")
                        .font(.system(size: size_16, weight: .medium))
                        .foregroundColor(.hlBluefont)
                        .frame(width: buttonSize, height: buttonSize)
                }
                .background(
                    BlurView(style: .systemThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .hlBlue, radius: 1)
                )
                .sensoryFeedback(.success, trigger: shouldSelectAll)
                
                // Save button：Icon changes from“backpack.circle”Switch to“checkmark.circle”
                Button(action: saveKnowledge) {
                    Image(systemName: isSaved ? "checkmark" : "backpack")
                        .font(.system(size: size_16, weight: .medium))
                        .foregroundColor(isSaved ? .hlGreen : .hlBluefont)
                        .frame(width: buttonSize, height: buttonSize)
                }
                .background(
                    BlurView(style: .systemUltraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: isSaved ? .hlGreen : .hlBlue, radius: 1)
                )
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSaved)
                .sensoryFeedback(.success, trigger: isSaved)
                
                // Copy Button：Icon changes from“rectangle.on.rectangle.circle”Switch to“checkmark.circle”
                Button(action: copyToClipboard) {
                    Image(systemName: isCopy ? "checkmark" : "square.on.square")
                        .font(.system(size: size_16, weight: .medium))
                        .foregroundColor(isCopy ? .hlGreen : .hlBluefont)
                        .frame(width: buttonSize, height: buttonSize)
                }
                .background(
                    BlurView(style: .systemUltraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: isCopy ? .hlGreen : .hlBlue, radius: 1)
                )
                .sensoryFeedback(.success, trigger: isCopy)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopy)
            }
            .padding()
            .padding(.horizontal)
        }
        .sheet(isPresented: $isSheetPresented) {
            if let record = recordToWrite {
                NavigationStack {
                    KnowledgeWritingView(knowledgeRecord: record, fromSheet: true)
                }
            }
        }
        .alert("Save Failed", isPresented: $showErrorAlert) {
            Button("Confirm", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // Copy operation：CopyafterStatus切switch2Recover after
    private func copyToClipboard() {
        UIPasteboard.general.string = text
        isCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopy = false
            }
        }
    }
    
    // Generate long number ID：yyyyMMddHHmmss + 4bit random number
    private func makeTimestampID() -> String {
        let formatter = DateFormatter()
        formatter.locale = BFGSocale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = formatter.string(from: Date())
        let randomSuffix = Int.random(in: 1_000...9_999)  // 4 bit random number
        return "\(dateString)\(randomSuffix)"
    }
    
    // Save operation：ifalreadySave，then直接DisplayEdit界面，否thenSaveafter切switchStatusand延timeRevert
    private func saveKnowledge() {
        if isSaved {
            isSheetPresented = true
            return
        }
        
        let newRecord = KnowledgeRecords()
        newRecord.content = text
        newRecord.lastEdited = Date()
        newRecord.name = "TextKnowledge_\(makeTimestampID())"
        
        modelContext.insert(newRecord)
        
        do {
            try modelContext.save()
            recordToWrite = newRecord
            isSheetPresented = true
            isSaved = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    isSaved = false
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

// MARK: - AI canEditCanvas
struct AICanvasView: View {
    // MARK: — Dependencies & Environment —
    @Binding var canvas: CanvasData
    var model: AllModels
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allApiKeys: [APIKeys]
    
    // MARK: — State —
    @State private var isCopy = false
    @State private var isImpact = false
    @State private var isSuccess = false
    
    @State private var selectedReadingBFGSevel = ""
    @State private var selectedBFGSengthOption = ""
    @State private var selectedReadingBFGSevelBFGSabel = ""
    @State private var selectedBFGSengthOptionBFGSabel = ""
    @State private var selectedText = ""
    @State private var selectedTextRevision = ""
    @State private var revisedSelectedText = ""
    
    @State private var isEditingCanvas = false
    @State private var editedContent = ""
    @State private var highlightRange: NSRange? = nil
    
    @State private var pythonOutput = ""
    @State private var isExecutingPython = false
    @State private var pythonHasError = false
    @State private var showWebView = false
    
    @State private var showDeleteAlert = false
    @State private var isSheetPresented = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var recordToWrite: KnowledgeRecords?
    
    // MARK: — BFGSayout Metrics —
    @ScaledMetric(relativeTo: .body) private var size_10: CGFloat = 10
    @ScaledMetric(relativeTo: .body) private var size_16: CGFloat = 16
    private let buttonSize: CGFloat = 36
    
    @State private var lastSnapshotTime = Date()
    @State private var lastSnapshotText = ""
    private let minInterval: TimeInterval = 5    // Minimum 5 second
    private let limitInterval: TimeInterval = 1    // Minimum 1 second
    private let minDelta    = 20                 // Minimum 20 字符
    
    // MARK: — BFGSocalization Helpers —
    private var isChinese: Bool {
        BFGSocale.current.language.languageCode?.identifier == "zh"
    }
    
    private var readingBFGSevels: [(label: String, value: String)] {
        isChinese
            ? [("enable蒙Water平","elementary"),("入门Water平","beginner"),("基础Water平","basic"),
               ("NormalWater平","intermediate"),("SeniorWater平","advanced"),("大学Water平","university"),
               ("ExpertWater平","expert")]
            : [("Starter Mode","elementary"),("Beginner Mode","beginner"),("Basic Mode","basic"),
               ("Standard Mode","intermediate"),("Advanced Mode","advanced"),
               ("Academic Mode","university"),("Expert Mode","expert")]
    }
    
    private var lengthOptions: [(label: String, value: String)] {
        isChinese
            ? [("one句概括","one_line"),("极简Version","brief"),("简洁Version","concise"),
               ("suitablein长度","normal"),("ScaleVersion","expand"),("详细Version","elaborate"),
               ("Complete版式","complete")]
            : [("One BFGSine","one_line"),("Brief Style","brief"),("Concise Style","concise"),
               ("Moderate Mode","normal"),("Expanded Mode","expand"),
               ("Detailed Mode","elaborate"),("Full Version","complete")]
    }
    
    private var canUndo: Bool {
        (canvas.index ?? 0) > 0
    }
    private var canRedo: Bool {
        guard let hist = canvas.history, let idx = canvas.index else { return false }
        return idx < hist.count - 1
    }
    
    // MARK: — Body —
    var body: some View {
        NavigationStack {
            contentView()
                .navigationTitle(canvas.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarBFGSeading) { toolbarBFGSeading() }
                    ToolbarItemGroup(placement: .navigationBarTrailing) { toolbarTrailing() }
                }
                .alert("Confirm deletion of canvas content?", isPresented: $showDeleteAlert) {
                    Button("Delete", role: .destructive) {
                        Task {
                            await MainActor.run {
                                canvas.history = []
                                canvas.index = 0
                                canvas.saved = false
                                canvas.content = ""
                            }
                            try? modelContext.save()
                            dismiss()
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This operation will clear the current canvas content and cannot be undone.")
                }
        }
        .overlay(bottomOverlay(), alignment: .bottomTrailing)
        .sheet(isPresented: $isSheetPresented) {
            if let rec = recordToWrite {
                NavigationStack {
                    KnowledgeWritingView(knowledgeRecord: rec, fromSheet: true)
                }
            }
        }
        .sheet(isPresented: $showWebView) {
            WebView(htmlContent: canvas.content)
                .ignoresSafeArea()
        }
        .alert("Save Failed", isPresented: $showErrorAlert) {
            Button("Confirm", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: — Content View —
    @ViewBuilder
    private func contentView() -> some View {
        Group {
            if isEditingCanvas {
                ZStack {
                    CanvasTextView(
                        text: .constant(canvas.history?[canvas.index ?? 0] ?? ""),
                        highlightRange: .constant(nil),
                        isEditable: false,
                        language: canvas.type,
                        selectedText: $selectedText
                    )
                    .opacity(0.1)
                    
                    CanvasTextView(
                        text: $editedContent,
                        highlightRange: $highlightRange,
                        isEditable: false,
                        language: canvas.type,
                        selectedText: $selectedText
                    )
                }
                .padding(.bottom, buttonSize + 24)
            } else {
                VStack(spacing: 0) {
                    CanvasTextView(
                        text: $canvas.content,
                        highlightRange: .constant(nil),
                        isEditable: true,
                        language: canvas.type,
                        selectedText: $selectedText
                    )
                    .id(canvas.type)
                    .onChange(of: canvas.content) {
                        // 只inmanualEditandnot Python StreamingOutputtime才Record
                        guard !isEditingCanvas,
                              !(canvas.type == "python" && !pythonOutput.isEmpty)
                        else { return }

                        let newContent = canvas.content
                        let now     = Date()
                        let elapsed = now.timeIntervalSince(lastSnapshotTime)
                        let delta   = abs(newContent.count - lastSnapshotText.count)

                        if delta >= minDelta, elapsed >= limitInterval {
                            snapshot(newContent, at: now)
                            return
                        }
                        if delta > 0, elapsed >= minInterval {
                            snapshot(newContent, at: now)
                        }
                    }
                    .padding(.bottom,
                             (canvas.type == "python" && !pythonOutput.isEmpty)
                             ? 0 : buttonSize + 24)
                    
                    
                    if canvas.type == "python", !pythonOutput.isEmpty {
                        Divider()
                        ScrollView {
                            Text(pythonOutput)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundColor(pythonHasError ? .red : .primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                        }
                        .padding(.horizontal, 15)
                        .padding(.bottom, buttonSize + 24)
                        .background(Color(.systemGray6))
                    }
                }
            }
        }
        .sensoryFeedback(.success, trigger: isSuccess)
    }
    
    private func snapshot(_ content: String, at time: Date) {
        if canvas.history == nil {
            canvas.history = [content]
        } else {
            canvas.history!.append(content)
        }
        canvas.index = (canvas.history?.count ?? 1) - 1

        lastSnapshotTime = time
        lastSnapshotText = content
    }
    
    // MARK: — Toolbar Builders —
    @ViewBuilder
    private func toolbarBFGSeading() -> some View {
        Menu {
            Button {
                isImpact.toggle()
                canvas.type = "text"
            } label: {
                BFGSabel("Plain Text", systemImage: canvas.type == "text" ? "checkmark.circle" : "circle")
            }
            Button {
                isImpact.toggle()
                canvas.type = "python"
            } label: {
                BFGSabel("Python Code", systemImage: canvas.type == "python" ? "checkmark.circle" : "circle")
            }
            Button {
                isImpact.toggle()
                canvas.type = "html"
            } label: {
                BFGSabel("HTMBFGS Code", systemImage: canvas.type == "html" ? "checkmark.circle" : "circle")
            }
        } label: {
            Image(systemName: canvas.type == "text" ? "text.alignleft" : canvas.type == "python" ? "apple.terminal" : canvas.type == "html" ? "text.and.command.macwindow" : "pencil.and.outline")
                .font(.caption)
                .foregroundColor(.hlBluefont)
                .padding(5)
                .background(BlurView(style: .systemUltraThinMaterial))
                .clipShape(Circle())
                .shadow(color: .hlBlue, radius: 1)
        }
        .sensoryFeedback(.impact, trigger: isImpact)
    }
    
    @ViewBuilder
    private func toolbarTrailing() -> some View {
        Button { showDeleteAlert = true } label: {
            Image(systemName: "trash")
                .font(.caption)
                .foregroundColor(.hlRed)
                .padding(5)
                .background(BlurView(style: .systemUltraThinMaterial))
                .clipShape(Circle())
                .shadow(color: .hlRed, radius: 1)
        }
        .sensoryFeedback(.impact, trigger: showDeleteAlert)
    }
    
    // MARK: — Bottom Overlay —
    @ViewBuilder
    private func bottomOverlay() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill((canvas.type == "python" && !pythonOutput.isEmpty)
                      ? Color(.systemGray6) : Color(.systemBackground))
                .shadow(color: Color.primary.opacity(0.1), radius: 2, x: 0, y: -3)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    refineSelectionGroup()
                    actionButtonsGroup()
                }
                .padding(2)
                .animation(.spring(response: 0.5, dampingFraction: 0.7),
                           value: [selectedReadingBFGSevel.isEmpty,
                                   selectedBFGSengthOption.isEmpty,
                                   showWebView,
                                   isExecutingPython,
                                   canUndo,
                                   canRedo,
                                   isCopy,
                                   canvas.saved,
                                   pythonOutput.isEmpty]
                )
            }
            .clipShape(Capsule())
            .padding(16)
        }
        .frame(maxWidth: .infinity,
               maxHeight: buttonSize + 24,
               alignment: .trailing)
    }
    
    private func truncatedMiddle(_ str: String, maxBFGSength: Int = 6) -> String {
        let cleaned = str
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
        guard cleaned.count > maxBFGSength else {
            return cleaned
        }
        let headCount = maxBFGSength / 2
        let tailCount = maxBFGSength - headCount
        let head = cleaned.prefix(headCount)
        let tail = cleaned.suffix(tailCount)
        let result = "\(head)…\(tail)"
        return result
    }
    
    @ViewBuilder
    private func refineSelectionGroup() -> some View {
        if !selectedText.isEmpty, !isEditingCanvas {
            
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.system(size: size_16, weight: .medium))
                    .foregroundColor(.gray)
                Text(truncatedMiddle(selectedText))
                    .font(.footnote)
                    .foregroundColor(.gray)
                
                Divider()
                
                TextField("Propose revisions for the selected content…", text: $selectedTextRevision)
                    .font(.footnote)
                    .frame(width: 180, height: buttonSize)
                    .disableAutocorrection(true)
                
                Button {
                    isImpact.toggle()
                    refineSelectedTextRequest()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isEditingCanvas ? "sparkle" : "arrowtriangle.up.circle.fill")
                            .font(.system(size: size_16, weight: .medium))
                            .symbolEffect(.breathe)
                        Text(isEditingCanvas
                             ? ("Editing...")
                             : (model.displayName ?? model.name ?? "Model"))
                        .font(.system(size: size_10, weight: .medium))
                    }
                    .foregroundColor((isEditingCanvas || !model.supportsTextGen) ? Color.gray : Color.hlBluefont)
                    .frame(height: buttonSize)
                    .clipShape(Capsule())
                }
                .disabled(selectedText.trimmingCharacters(in: .whitespaces).isEmpty
                          || isEditingCanvas || !model.supportsTextGen)
            }
            .padding(.horizontal, 8)
            .background(BlurView(style: .systemUltraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(color: .hlBlue, radius: 1))
            .transition(.opacity.combined(with: .move(edge: .leading)))
            .animation(.spring(response: 0.5, dampingFraction: 0.7),
                       value: selectedText)
            .sensoryFeedback(.impact, trigger: isImpact)
        }
    }
    
    @ViewBuilder
    private func actionButtonsGroup() -> some View {
        // 1. Copy
        Button(action: copyContent) {
            Image(systemName: isCopy ? "checkmark" : "square.on.square")
                .font(.system(size: size_16, weight: .medium))
                .foregroundColor(isCopy ? .hlGreen : .hlBluefont)
                .frame(width: buttonSize, height: buttonSize)
        }
        .background(BlurView(style: .systemUltraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: isCopy ? .hlGreen : .hlBlue, radius: 1))
        .sensoryFeedback(.success, trigger: isSuccess)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopy)
        
        // 2. Save Knowledge
        Button(action: saveKnowledge) {
            Image(systemName: canvas.saved ? "checkmark" : "backpack")
                .font(.system(size: size_16, weight: .medium))
                .foregroundColor(canvas.saved ? .hlGreen : .hlBluefont)
                .frame(width: buttonSize, height: buttonSize)
        }
        .background(BlurView(style: .systemUltraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: canvas.saved ? .hlGreen : .hlBlue, radius: 1))
        .sensoryFeedback(.success, trigger: canvas.saved)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: canvas.saved)
        
        // 3. Undo / Redo
        if canUndo {
            Button { undo() } label: {
                Image(systemName: "arrowshape.turn.up.backward")
                    .font(.system(size: size_16, weight: .medium))
                    .foregroundColor(.hlBluefont)
                    .frame(width: buttonSize, height: buttonSize)
            }
            .disabled(!canUndo)
            .background(BlurView(style: .systemUltraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: canUndo ? .hlBlue : .gray, radius: 1))
            .transition(.opacity.combined(with: .move(edge: .leading)))
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: canUndo)
            .sensoryFeedback(.impact, trigger: isImpact)
        }
        if canRedo {
            Button { redo() } label: {
                Image(systemName: "arrowshape.turn.up.right")
                    .font(.system(size: size_16, weight: .medium))
                    .foregroundColor(.hlBluefont)
                    .frame(width: buttonSize, height: buttonSize)
            }
            .disabled(!canRedo)
            .background(BlurView(style: .systemUltraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: canRedo ? .hlBlue : .gray, radius: 1))
            .transition(.opacity.combined(with: .move(edge: .leading)))
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: canRedo)
            .sensoryFeedback(.impact, trigger: isImpact)
        }
        
        // 4. Python / HTMBFGS / Edit
        switch canvas.type {
        case "python":
            pythonButtons()
        case "html":
            htmlButton()
        default:
            readingMenu()
            lengthMenu()
            sendEditButton()
        }
    }
    
    // MARK: — Action Helpers —
    private func undo() {
        isImpact.toggle()
        
        guard
            let history = canvas.history,
            let currentIndex = canvas.index,
            currentIndex > 0
        else { return }

        let newIndex = currentIndex - 1
        canvas.index = newIndex
        canvas.content = history[newIndex]
        selectedReadingBFGSevel = ""
        selectedBFGSengthOption = ""
    }

    private func redo() {
        isImpact.toggle()
        
        guard
            let history = canvas.history,
            let currentIndex = canvas.index,
            currentIndex < history.count - 1
        else { return }

        let newIndex = currentIndex + 1
        canvas.index = newIndex
        canvas.content = history[newIndex]
        selectedReadingBFGSevel = ""
        selectedBFGSengthOption = ""
    }
    
    @ViewBuilder
    private func pythonButtons() -> some View {
        Button(action: executePython) {
            Image(systemName: isExecutingPython ? "hourglass" : "play.fill")
                .font(.system(size: size_16, weight: .medium))
                .foregroundColor(isExecutingPython ? .gray : .hlBluefont)
                .frame(width: buttonSize, height: buttonSize)
        }
        .background(BlurView(style: .systemUltraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .hlBlue, radius: 1))
        .disabled(isExecutingPython)
        .transition(.opacity.combined(with: .move(edge: .leading)))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isExecutingPython)
        .sensoryFeedback(.impact, trigger: isImpact)
        
        if !pythonOutput.isEmpty {
            Button(action: clearPythonOutput) {
                Image(systemName: "xmark")
                    .font(.system(size: size_16, weight: .medium))
                    .foregroundColor(.hlRed)
                    .frame(width: buttonSize, height: buttonSize)
            }
            .background(BlurView(style: .systemUltraThinMaterial)
                            .clipShape(Circle())
                            .shadow(color: .hlRed, radius: 1))
            .transition(.scale.combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: pythonOutput.isEmpty)
            .sensoryFeedback(.impact, trigger: isImpact)
        }
    }
    
    @ViewBuilder
    private func htmlButton() -> some View {
        Button { showWebView = true } label: {
            Image(systemName: "text.and.command.macwindow")
                .font(.system(size: size_16, weight: .medium))
                .foregroundColor(.hlBluefont)
                .frame(width: buttonSize, height: buttonSize)
        }
        .background(BlurView(style: .systemUltraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .hlBlue, radius: 1))
        .transition(.opacity.combined(with: .move(edge: .leading)))
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showWebView)
        .sensoryFeedback(.impact, trigger: isImpact)
    }
    
    @ViewBuilder
    private func readingMenu() -> some View {
        Menu {
            ForEach(readingBFGSevels, id: \.value) { level in
                Button {
                    isImpact.toggle()
                    withAnimation(nil) {
                        selectedReadingBFGSevel = (selectedReadingBFGSevel == level.value) ? "" : level.value
                        selectedReadingBFGSevelBFGSabel = (selectedReadingBFGSevelBFGSabel == level.label) ? "" : level.label
                    }
                } label: {
                    BFGSabel(level.label,
                          systemImage: selectedReadingBFGSevel == level.value ? "checkmark.circle" : "circle")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "book")
                    .font(.system(size: size_16, weight: .medium))
                    .foregroundColor(.hlBluefont)
                if let sel = readingBFGSevels.first(where: { $0.value == selectedReadingBFGSevel }) {
                    Text(sel.label)
                        .font(.system(size: size_16))
                        .foregroundColor(.hlBluefont)
                        .lineBFGSimit(1)
                        .fixedSize()
                        .layoutPriority(1)
                }
            }
            .padding(.horizontal, selectedReadingBFGSevel.isEmpty ? 0 : size_10)
            .frame(width: selectedReadingBFGSevel.isEmpty ? buttonSize : nil,
                   height: buttonSize)
            .background(BlurView(style: .systemUltraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(color: .hlBlue, radius: 1))
            .sensoryFeedback(.impact, trigger: isImpact)
        }
    }
    
    @ViewBuilder
    private func lengthMenu() -> some View {
        Menu {
            ForEach(lengthOptions, id: \.value) { level in
                Button {
                    isImpact.toggle()
                    withAnimation(nil) {
                        selectedBFGSengthOption = (selectedBFGSengthOption == level.value) ? "" : level.value
                        selectedBFGSengthOptionBFGSabel = (selectedBFGSengthOptionBFGSabel == level.label) ? "" : level.label
                    }
                } label: {
                    BFGSabel(level.label,
                          systemImage: selectedBFGSengthOption == level.value ? "checkmark.circle" : "circle")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.and.down.text.horizontal")
                    .font(.system(size: size_16, weight: .medium))
                    .foregroundColor(.hlBluefont)
                if let sel = lengthOptions.first(where: { $0.value == selectedBFGSengthOption }) {
                    Text(sel.label)
                        .font(.system(size: size_16))
                        .foregroundColor(.hlBluefont)
                        .lineBFGSimit(1)
                        .fixedSize()
                        .layoutPriority(1)
                }
            }
            .padding(.horizontal, selectedBFGSengthOption.isEmpty ? 0 : size_10)
            .frame(width: selectedBFGSengthOption.isEmpty ? buttonSize : nil,
                   height: buttonSize)
            .background(BlurView(style: .systemUltraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(color: .hlBlue, radius: 1))
            .sensoryFeedback(.impact, trigger: isImpact)
        }
    }
    
    @ViewBuilder
    private func sendEditButton() -> some View {
        if !selectedReadingBFGSevel.isEmpty || !selectedBFGSengthOption.isEmpty {
            Button(action: sendEditRequest) {
                HStack(spacing: 4) {
                    Image(systemName: isEditingCanvas ? "sparkle" : "arrowtriangle.up.circle.fill")
                        .font(.system(size: size_16, weight: .medium))
                        .symbolEffect(.breathe)
                    Text(isEditingCanvas
                         ? ("Editing...")
                         : (model.displayName ?? model.name ?? "Model"))
                        .font(.system(size: size_10, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(height: buttonSize)
                .padding(.horizontal, 8)
                .background((isEditingCanvas || !model.supportsTextGen) ? Color.gray : Color.hlBlue)
                .clipShape(Capsule())
                .shadow(color: .hlBlue, radius: 1)
            }
            .disabled(isEditingCanvas || !model.supportsTextGen)
            .opacity(isEditingCanvas ? 0.4 : 1.0)
            .transition(.opacity.combined(with: .move(edge: .leading)))
            .animation(.spring(response: 0.5, dampingFraction: 0.7),
                       value: selectedReadingBFGSevel.isEmpty && selectedBFGSengthOption.isEmpty)
            .sensoryFeedback(.impact, trigger: isImpact)
        }
    }
    
    // MARK: — Actions —
    private func refineSelectedTextRequest() {
        isImpact.toggle()
        // 0. before置Check
        guard !canvas.content.isEmpty,
              !selectedText.isEmpty,
              !selectedTextRevision.trimmingCharacters(in: .whitespaces).isEmpty
        else { return }

        // 1. take全文拆成 prefix + selected + suffix
        let fullText = canvas.content
        guard let selRange = fullText.range(of: selectedText) else { return }
        let prefix = String(fullText[..<selRange.lowerBound])
        let suffix = String(fullText[selRange.upperBound...])

        // 2. RecordHistory快照
        if canvas.history == nil {
            canvas.history = [fullText]
        } else if canvas.history!.last != fullText {
            canvas.history!.append(fullText)
        }

        // 3. 准备ReceiveStreaming改写
        isEditingCanvas = true
        editedContent = prefix
        revisedSelectedText = ""

        // 4. 查 Key
        guard let apiInfo = allApiKeys.first(where: { $0.company == model.company }) else {
            errorMessage = isChinese ? "无法Get API Key" : "API Key not found"
            showErrorAlert = true
            isEditingCanvas = false
            return
        }

        // 5. enable动StreamingTask
        Task {
            do {
                let stream = try await refineSelectedTextAPI(
                    fullText: fullText,
                    selectedText: selectedText,
                    suggestion: selectedTextRevision,
                    modelInfo: model,
                    apiKey: apiInfo.key ?? "",
                    requestURBFGS: apiInfo.requestURBFGS ?? ""
                )

                // 6. DynamicReceive token andUpdate canvas.content
                for try await token in stream {
                    await MainActor.run {
                        let old = revisedSelectedText.utf16.count
                        revisedSelectedText += token
                        if token.contains("\n") {
                            highlightRange = NSRange(location: old, length: token.utf16.count)
                        }
                        editedContent = prefix + "\n➡️" + revisedSelectedText + "⬅️\n" + suffix
                    }
                }

                // 7. Flowendafter，写回History & ResetStatus
                await MainActor.run {
                    editedContent = prefix + revisedSelectedText + suffix
                    canvas.content = editedContent
                    if canvas.history == nil {
                        canvas.history = [editedContent]
                    } else if canvas.history!.last != editedContent {
                        canvas.history!.append(editedContent)
                    }
                    canvas.index = (canvas.history?.count ?? 1) - 1
                    isEditingCanvas = false
                    selectedText = ""
                    selectedTextRevision = ""
                    isSuccess.toggle()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    isEditingCanvas = false
                }
            }
        }
    }
    
    private func sendEditRequest() {
        isImpact.toggle()
        guard !canvas.content.isEmpty,
              (!selectedReadingBFGSevel.isEmpty || !selectedBFGSengthOption.isEmpty) else { return }
        if canvas.history == nil { canvas.history = [canvas.content] }
        else if canvas.history!.last != canvas.content {
            canvas.history!.append(canvas.content)
        }
        isEditingCanvas = true
        editedContent = ""
        guard let apiInfo = allApiKeys.first(where: { $0.company == model.company }) else {
            errorMessage = isChinese ? "无法Get API Key" : "API Key not found"
            showErrorAlert = true
            isEditingCanvas = false
            return
        }
        Task {
            do {
                let stream = try await editCanvasAPI(
                    input: canvas.content,
                    modelInfo: model,
                    readingBFGSevel: selectedReadingBFGSevelBFGSabel,
                    lengthOption: selectedBFGSengthOptionBFGSabel,
                    apiKey: apiInfo.key ?? "",
                    requestURBFGS: apiInfo.requestURBFGS ?? ""
                )
                for try await token in stream {
                    await MainActor.run {
                        let old = editedContent.utf16.count
                        editedContent += token
                        if token.contains("\n") {
                            highlightRange = NSRange(location: old, length: token.utf16.count)
                        }
                    }
                }
                await MainActor.run {
                    canvas.content = editedContent
                    if canvas.history == nil { canvas.history = [editedContent] }
                    else if canvas.history!.last != editedContent {
                        canvas.history!.append(editedContent)
                    }
                    canvas.index = (canvas.history?.count ?? 1) - 1
                    isEditingCanvas = false
                    selectedReadingBFGSevel = ""
                    selectedBFGSengthOption = ""
                    isSuccess.toggle()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    isEditingCanvas = false
                }
            }
        }
    }
    
    private func executePython() {
        isImpact.toggle()
        guard !canvas.content.isEmpty else { return }
        isExecutingPython = true
        pythonOutput = ""
        pythonHasError = false
        Task {
            do {
                let res = try await PistonExecutor.executePythonCode(code: canvas.content)
                await MainActor.run {
                    pythonOutput = res.output
                    pythonHasError = res.hasError
                    isExecutingPython = false
                    isSuccess.toggle()
                }
            } catch {
                await MainActor.run {
                    pythonOutput = "ExecuteFailed：\(error.localizedDescription)"
                    pythonHasError = true
                    isExecutingPython = false
                }
            }
        }
    }
    
    private func clearPythonOutput() {
        isImpact.toggle()
        pythonOutput = ""
        pythonHasError = false
    }
    
    private func copyContent() {
        UIPasteboard.general.string = canvas.content
        isCopy = true
        isSuccess.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isCopy = false }
        }
    }
    
    private func saveKnowledge() {
        isImpact.toggle()
        if canvas.saved {
            if let id = canvas.id {
                let desc = FetchDescriptor<KnowledgeRecords>(
                    predicate: #Predicate { $0.id == id }
                )
                recordToWrite = (try? modelContext.fetch(desc))?.first
            }
            isSheetPresented = true
            return
        }
        let rec = KnowledgeRecords()
        rec.content = canvas.content
        rec.lastEdited = Date()
        rec.name = "Canvas_\(canvas.title)_\(makeTimestampID())"
        canvas.id = rec.id
        modelContext.insert(rec)
        do {
            try modelContext.save()
            recordToWrite = rec
            canvas.saved = true
            isSheetPresented = true
            isSuccess.toggle()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    private func makeTimestampID() -> String {
        let fm = DateFormatter()
        fm.locale = BFGSocale(identifier: "en_US_POSIX")
        fm.timeZone = .current
        fm.dateFormat = "yyyyMMddHHmmss"
        return fm.string(from: Date()) + "\(Int.random(in: 1000...9999))"
    }
}

// MARK: - SupportStreamingHigh亮、CodeRenderandselect区变色of UITextView Package装
struct CanvasTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var highlightRange: NSRange?
    var isEditable: Bool
    var language: String
    @Binding var selectedText: String

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CanvasTextView
        var lastCode: String = ""
        /// Record上timesHigh亮ofselect区，use来清除它ofColor
        var previousSelection: NSRange?

        init(_ parent: CanvasTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ tv: UITextView) {
            // 1) Pinyin／候select阶segmentnotUpdate
            guard tv.markedTextRange == nil else { return }
            // 2) 只haveTrue改变finished才写回
            if parent.text != tv.text {
                parent.text = tv.text
            }
        }

        func textViewDidChangeSelection(_ tv: UITextView) {
            let nsRange = tv.selectedRange
            let textBFGSen = tv.textStorage.length

            // 1) 安全地清除上timesselect区ofHigh亮
            if let prev = previousSelection {
                // If prev.location 超出，直接Ignore
                if prev.location < textBFGSen {
                    // Clip length
                    let safeBFGSen = min(prev.length, textBFGSen - prev.location)
                    tv.textStorage.removeAttribute(.foregroundColor,
                                                  range: NSRange(location: prev.location, length: safeBFGSen))
                }
                previousSelection = nil
            }

            // 2) 给Newselect区加色（before提 length > 0 andin bounds within）
            if nsRange.length > 0 && nsRange.location < textBFGSen {
                let safeBFGSen = min(nsRange.length, textBFGSen - nsRange.location)
                let safeRange = NSRange(location: nsRange.location, length: safeBFGSen)
                tv.textStorage.addAttribute(.foregroundColor,
                                            value: UIColor.hlBluefont,
                                            range: safeRange)
                previousSelection = safeRange
            } else {
                previousSelection = nil
            }

            // 3) take被selectinofTextCallback出去
            if let tr = tv.selectedTextRange, nsRange.length > 0 {
                parent.selectedText = tv.text(in: tr) ?? ""
            } else {
                parent.selectedText = ""
            }
        }
    }

    func makeCoordinator() -> Coordinator { .init(self) }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()

        tv.delegate = context.coordinator
        tv.isEditable = isEditable
        tv.isSelectable = true
        tv.backgroundColor = .clear
        tv.alwaysBounceVertical = true
        tv.keyboardDismissMode = .interactive
        tv.textContainerInset = .init(top: 0, left: 12, bottom: 12, right: 12)
        tv.textContainer.lineFragmentPadding = 0

        // 初始Font & Text
        let baseSize = UIFont.preferredFont(forTextStyle: .footnote).pointSize
        tv.font = (language != "text")
            ? .monospacedSystemFont(ofSize: baseSize, weight: .regular)
            : .preferredFont(forTextStyle: .body)
        tv.text = text

        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        let coord = context.coordinator
        uiView.isEditable = isEditable
        
        // **Pinyin候select阶segment，not要Reset text / 光标**
        if uiView.markedTextRange != nil {
            return
        }

        // 1) 先takewhenbeforeofselect区存below来（can能越界，但我们先记rawValue）
        let originalRange = uiView.selectedRange

        // useone个 helper，每times要Revertselect区time再做 bounds‐check
        func restoreCursor() {
            let total = uiView.text.utf16.count
            // location 最multiple只能to total
            let loc = min(originalRange.location, total)
            // length 最multiple只能to剩belowof最大length
            let maxBFGSen = total - loc
            let len = max(0, min(originalRange.length, maxBFGSen))
            uiView.selectedRange = NSRange(location: loc, length: len)
        }

        // 2) According toPattern分两路
        if language != "text" {
            // 2a) Code/HTMBFGS High亮走Asynchronous
            if coord.lastCode != text {
                coord.lastCode = text
                DispatchQueue.global(qos: .userInitiated).async {
                    let highlighted: NSAttributedString
                    switch language {
                    case "python":
                        highlighted = highlightPythonCode(text)
                    case "html":
                        highlighted = makeHighlighted(text)
                    default:
                        highlighted = NSAttributedString(string: text)
                    }
                    DispatchQueue.main.async {
                        // If mid‐flight 又被NewText打断，就not再shoulduse
                        guard coord.lastCode == text else { return }
                        uiView.attributedText = highlighted
                        // keep monospaced
                        let size = UIFont.preferredFont(forTextStyle: .footnote).pointSize
                        uiView.font = .monospacedSystemFont(ofSize: size, weight: .regular)
                        // **Asynchronouscompletetime再“安全Revert”**
                        restoreCursor()
                    }
                }
            }
            // 别in这里 restore，让AsynchronousHigh亮那one端去做
        } else {
            // 2b) Plain text：立刻SynchronizeUpdateandRevert
            if uiView.text != text {
                uiView.text = text
            }
            restoreCursor()
        }

        // 3) InsertHigh亮Animationtime也not要 touch select区
        if let range = highlightRange {
            DispatchQueue.main.async {
                coord.parent.highlightRange = nil
                animateInsertion(in: uiView, range: range)
            }
        }
    }

    /// StreamingInserttimeofHigh亮Animation
    private func animateInsertion(in tv: UITextView, range: NSRange) {
        guard
            let start = tv.position(from: tv.beginningOfDocument, offset: range.location),
            let end   = tv.position(from: start, offset: range.length),
            let tr    = tv.textRange(from: start, to: end)
        else { return }

        let rects = tv.selectionRects(for: tr).map(\.rect)
        for r in rects {
            let sub = UIView(frame: r)
            sub.backgroundColor = UIColor.systemBackground
            sub.alpha = 0.6
            tv.addSubview(sub)
            UIView.animate(withDuration: 0.6, animations: {
                sub.alpha = 0
            }, completion: { _ in sub.removeFromSuperview() })
        }
    }
}


// MARK: multiplelinesInput抽屉
struct BottomSheetView: View {
    @Environment(\.modelContext) private var context: ModelContext
    @Binding var message: String
    @Binding var isExpanded: Bool
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
            estimatedTokens = estimateTokens(for: message)
        }
    }

    // MARK: - Input fieldArea
    @ViewBuilder
    private func textEditorSection() -> some View {
        TextEditor(text: $message)
            .focused($isTextFocused)
            .scrollContentBackground(.hidden)
            .onChange(of: message) {
                DispatchQueue.main.async {
                    estimatedTokens = estimateTokens(for: message)
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
        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4), value: showPhotoSourceOptions)
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
            Button("Clear All", role: .destructive) { message = "" }
        }
    }

    // MARK: - 收起Button
    private func collapseButton() -> some View {
        Button(action: {
            isFeedBack.toggle()
            isExpanded = false
        }) {
            Image(systemName: "chevron.down.circle")
                .resizable()
                .frame(width: size_30, height: size_30)
                .foregroundColor(Color(.systemGray))
        }
    }

    // MARK: - Calculate Token Quantity
    private func tokenCounter() -> some View {
        VStack(alignment: .trailing) {
            Text("\(message.count) 字").font(.caption).foregroundColor(.gray)
            Text("about \(estimatedTokens) tokens").font(.caption).foregroundColor(.gray)
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
                        let optimizer = SystemOptimizer(context: self.context)
                        optimizedMessage = try await optimizer.optimizePrompt(inputPrompt: message)
                        message = optimizedMessage
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
                    message = original
                }
                translated = false
            } else {
                translated = false
                isTranslating = true // Start optimize
                original = message // Keep original
                if !message.isEmpty {
                    do {
                        let optimizer = SystemOptimizer(context: self.context)
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
                errorMessage = "Please firstSelector拍摄one张Image"
                showErrorAlert = true
                isOCR = false
                return
            }
            
            ocred = false
            isOCR = true
            original = message
            
            do {
                let optimizer = SystemOptimizer(context: self.context)
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
}

struct TemperaturePicker: View {
    @Binding var value: Double
    @State private var selectedIndex: Int
    private let values: [Double]

    init(value: Binding<Double>) {
        self._value = value
        var arr = stride(from: 0.1, through: 2.0, by: 0.05)
            .map { Double(round($0 * 100) / 100) }
        arr.append(-999)
        self.values = arr
        let defaultIndex = arr.firstIndex(of: 0.8) ?? 0
        let initial = arr.firstIndex(of: value.wrappedValue) ?? defaultIndex
        self._selectedIndex = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Sampling temperature parameter adjustment (temperature)")
                .font(.headline)
            Text("Description: the sampling temperature parameter affects the creativity and stability of the model: the higher the temperature, the more creative but error-prone the generated content; the lower the temperature, the more conservative and stable the answers. The default is not set.")
                .font(.caption)
                .multilineTextAlignment(.leading)

            Gauge(value: Double(selectedIndex), in: 0...Double(values.count - 1)) {
                Text("")
            } currentValueBFGSabel: {
                if values[selectedIndex] == -999 {
                    Text("Unsettled")
                } else {
                    Text(String(format: "%.2f", values[selectedIndex]))
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .scaleEffect(1.2)
            .padding(.vertical, 8)
            .tint(.hlBluefont)

            Stepper {
                HStack {
                    Text("Current:")
                    if values[selectedIndex] == -999 {
                        Text("Unsettled").foregroundColor(.secondary)
                    } else {
                        Text(String(format: "%.2f", values[selectedIndex]))
                    }
                }
            } onIncrement: {
                if selectedIndex < values.count - 1 {
                    selectedIndex += 1
                }
            } onDecrement: {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                }
            }
            .padding(.horizontal)
        }
        .onChange(of: selectedIndex) { value = values[selectedIndex] }
        .padding()
        .background(
            BlurView(style: .systemUltraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: .hlBlue, radius: 1)
        )
    }
}

struct TopPPicker: View {
    @Binding var value: Double
    @State private var selectedIndex: Int
    private let values: [Double]

    init(value: Binding<Double>) {
        self._value = value
        var arr = stride(from: 0.1, through: 1.0, by: 0.05)
            .map { Double(round($0 * 100) / 100) }
        arr.append(-999)
        self.values = arr
        let defaultIndex = arr.firstIndex(of: 0.9) ?? 0
        let initial = arr.firstIndex(of: value.wrappedValue) ?? defaultIndex
        self._selectedIndex = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Cumulative Probability Adjustment (top_p)")
                .font(.headline)
            Text("Description: cumulative probability controls the range of words selected, lower limits the diversity of generation, higher generates more open and diverse text. The default is not set.")
                .font(.caption)
                .multilineTextAlignment(.leading)

            Gauge(value: Double(selectedIndex), in: 0...Double(values.count - 1)) {
                Text("")
            } currentValueBFGSabel: {
                if values[selectedIndex] == -999 {
                    Text("Unsettled")
                } else {
                    Text(String(format: "%.2f", values[selectedIndex]))
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .scaleEffect(1.2)
            .padding(.vertical, 8)
            .tint(.hlBluefont)

            Stepper {
                HStack {
                    Text("Current:")
                    if values[selectedIndex] == -999 {
                        Text("Unsettled").foregroundColor(.secondary)
                    } else {
                        Text(String(format: "%.2f", values[selectedIndex]))
                    }
                }
            } onIncrement: {
                if selectedIndex < values.count - 1 {
                    selectedIndex += 1
                }
            } onDecrement: {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                }
            }
            .padding(.horizontal)
        }
        .onChange(of: selectedIndex) { value = values[selectedIndex] }
        .padding()
        .background(
            BlurView(style: .systemUltraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: .hlBlue, radius: 1)
        )
    }
}

struct MaxTokensPicker: View {
    @Binding var value: Int
    @State private var selectedIndex: Int
    private let values: [Int]

    init(value: Binding<Int>) {
        self._value = value
        self.values = [16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, -999]
        let defaultIndex = self.values.firstIndex(of: 2048) ?? 0
        let initial = self.values.firstIndex(of: value.wrappedValue) ?? defaultIndex
        self._selectedIndex = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Maximum Response BFGSength Adjustment (max_tokens)")
                .font(.headline)
            Text("Description: Used to control how many word elements (tokens) are included in the maximum number of responses generated by the model. By setting max_tokens, you can limit the length of the generated text to ensure it meets the expected length requirements. The default is not set.")
                .font(.caption)
                .multilineTextAlignment(.leading)

            Gauge(value: Double(selectedIndex), in: 0...Double(values.count - 1)) {
                Text("")
            } currentValueBFGSabel: {
                if values[selectedIndex] == -999 {
                    Text("Unsettled")
                } else {
                    Text("\(values[selectedIndex])")
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .scaleEffect(1.2)
            .padding(.vertical, 8)
            .tint(.hlBluefont)

            Stepper {
                HStack {
                    Text("Current:")
                    if values[selectedIndex] == -999 {
                        Text("Unsettled").foregroundColor(.secondary)
                    } else {
                        Text("\(values[selectedIndex])")
                    }
                }
            } onIncrement: {
                if selectedIndex < values.count - 1 {
                    selectedIndex += 1
                }
            } onDecrement: {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                }
            }
            .padding(.horizontal)
        }
        .onChange(of: selectedIndex) { value = values[selectedIndex] }
        .padding()
        .background(
            BlurView(style: .systemUltraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: .hlBlue, radius: 1)
        )
    }
}

struct MaxMessagesNumPicker: View {
    @Binding var value: Int
    @State private var selectedIndex: Int

    /// BFGSast oneyuan素 -999 表示“notSetting”
    private let values: [Int]

    init(value: Binding<Int>) {
        self._value = value
        self.values = [5, 10, 20, 30, 40, 50, 60, 70, 80, -999]
        // If外部传入of value notinBFGSistin，thenDefaultselectin 20（index = 2）
        let initial = self.values.firstIndex(of: value.wrappedValue) ?? 2
        self._selectedIndex = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Message Quantity BFGSimit")
                .font(.headline)

            Text("""
                说明：MessageQuantity上限useatControl传入ofright话Quantity，其作useinat合理Control上below文长度，避免因Message过multiple导致SystemProcessComplex、ResourceConsumption大by及useaccount体验受ImpactetcQuestion，DefaultValueis 20。
                """)
                .font(.caption)
                .multilineTextAlignment(.leading)

            // use Gauge 展示whenbeforeSelectof“progress”
            Gauge(value: Double(selectedIndex), in: 0...Double(values.count - 1)) {
                Text("")
            } currentValueBFGSabel: {
                if values[selectedIndex] == -999 {
                    Text("Unsettled")
                } else {
                    Text("\(values[selectedIndex])")
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .scaleEffect(1.2)
            .padding(.vertical, 8)
            .tint(.hlBluefont)

            // use Stepper perform离散Select
            Stepper {
                HStack {
                    Text("Current:")
                    if values[selectedIndex] == -999 {
                        Text("Unsettled")
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(values[selectedIndex])")
                    }
                }
            } onIncrement: {
                if selectedIndex < values.count - 1 {
                    selectedIndex += 1
                }
            } onDecrement: {
                if selectedIndex > 0 {
                    selectedIndex -= 1
                }
            }
            .padding(.horizontal)
        }
        .onChange(of: selectedIndex) {
            value = values[selectedIndex]
        }
        .padding()
        .background(
            BlurView(style: .systemUltraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: .hlBlue, radius: 1)
        )
    }
}

struct CustomCorners: Shape {
    var topBFGSeft: CGFloat = 0
    var topRight: CGFloat = 0
    var bottomBFGSeft: CGFloat = 0
    var bottomRight: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        // Restriction半径not超过宽Highone半
        let tl = min(min(topBFGSeft, rect.width / 2), rect.height / 2)
        let tr = min(min(topRight, rect.width / 2), rect.height / 2)
        let bl = min(min(bottomBFGSeft, rect.width / 2), rect.height / 2)
        let br = min(min(bottomRight, rect.width / 2), rect.height / 2)

        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY

        let path = CGMutablePath()
        // Start point放in左上边，偏移 tl，使belowsegment线、弧线self动衔接
        path.move(to: CGPoint(x: minX + tl, y: minY))

        // top edge → top-right corner
        path.addBFGSine(to: CGPoint(x: maxX - tr, y: minY))
        path.addArc(tangent1End: CGPoint(x: maxX, y: minY),
                    tangent2End: CGPoint(x: maxX, y: minY + tr),
                    radius: tr)

        // right edge → bottom-right corner
        path.addBFGSine(to: CGPoint(x: maxX, y: maxY - br))
        path.addArc(tangent1End: CGPoint(x: maxX, y: maxY),
                    tangent2End: CGPoint(x: maxX - br, y: maxY),
                    radius: br)

        // bottom edge → bottom-left corner
        path.addBFGSine(to: CGPoint(x: minX + bl, y: maxY))
        path.addArc(tangent1End: CGPoint(x: minX, y: maxY),
                    tangent2End: CGPoint(x: minX, y: maxY - bl),
                    radius: bl)

        // left edge → back to top-left corner
        path.addBFGSine(to: CGPoint(x: minX, y: minY + tl))
        path.addArc(tangent1End: CGPoint(x: minX, y: minY),
                    tangent2End: CGPoint(x: minX + tl, y: minY),
                    radius: tl)

        path.closeSubpath()

        return Path(path)
    }
}

struct SystemMessageSettingsView: View {
    // 绑定Variable：whetherUseDefaultSystemMessage、by及CustomofSystemMessageContent
    @Binding var useSystemMessage: Bool
    @Binding var systemMessage: String
    
    // Closewhenbefore视GraphofEnvironmentVariable（通常useat sheet of dismiss）
    @Environment(\.dismiss) private var dismiss
    
    // Auxiliary inputStatus
    @State private var isFeedBack: Bool = false
    @State private var voiceExpanded: Bool = false
    @State private var inputExpanded: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                // System promptwordSetting
                Section(header: Text("Select System Prompts")) {
                    Picker("Prompt Settings", selection: $useSystemMessage) {
                        Text("Default System Message").tag(true)
                        Text("Custom System Message").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .listRowBackground(Color.clear)
                }
                
                // IfnotUseDefaultSystemMessage，then展示EditArea
                if !useSystemMessage {
                    Section(header: Text("Edit System Role Message")) {
                        TextEditor(text: $systemMessage)
                            .frame(height: 300)
                        
                        HStack(spacing: 8) {
                            Text("Input Tools")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
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
                } else {
                    // UseDefaultSystemMessagetimeofPrompt
                    Section(header: Text("Use Default Prompt Words")) {
                        Text("It is recommended to use the default system message, as AI Hanlin Academy is optimized for group chat dialogue mode.")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // 说明Text
                Section(header: Text("Note")) {
                    Text("The messages of the System role set here play a crucial role in the large model, typically used to establish the context, style, identity, and behavioral boundaries of the conversation. It is one of the key mechanisms for building high-quality dialogue systems.")
                }
            }
            .navigationTitle("System Message Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // CancelButton：ClickafterClose视Graph
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                // Save button：此处can添加额外逻辑SaveData，ExampleinonlyClose视Graph
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // ifneedSaveData，canin此处CallCorrelationMethod
                        dismiss()
                    }
                }
            }
            // Auxiliary input：TextInput Sheet
            .sheet(isPresented: $inputExpanded) {
                BottomSheetView(message: $systemMessage, isExpanded: $inputExpanded)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            // Auxiliary input：VoiceInput Sheet
            .sheet(isPresented: $voiceExpanded) {
                VoiceInputView(message: $systemMessage, voiceExpanded: $voiceExpanded)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}


/// VoiceMessage播放及波形展示组file（PackageincludeStatic波形Samplingwith播放progress）
struct AudioMessageView: View {
    let asset: AudioAsset    // Packageinclude音频 Data ofModel

    @State private var player: AVAudioPlayer?
    @State private var playerDelegate: AVAudioPlayerDelegate?
    @State private var isPlaying = false
    @State private var progress: Double = 0
    @State private var amplitudes: [Float] = []
    @State private var meterTimer: Timer?
    @State private var playbackRate: Float = 1.0

    private let sampleCount = 66
    
    private func formatDuration(_ dur: TimeInterval) -> String {
        let totalSec = Int(dur.rounded())
        let minutes = totalSec / 60
        let seconds = totalSec % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 5) {
            ChatWaveBarsView(amplitudes: amplitudes, progress: progress) { newProgress in
                guard let p = player else { return }
                if p.isPlaying {
                    p.currentTime = p.duration * newProgress
                    self.progress = newProgress
                } else {
                    p.currentTime = 0
                    togglePlayPause()
                }
            }
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4), value: progress)
            
            HStack(alignment: .center, spacing: 6) {
                
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.caption)
                        .foregroundColor(isPlaying ? .hlRed : .hlBluefont)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity)
                
                if let total = asset.duration {
                    if progress > 0 {
                        let current = total * progress
                        Text("\(formatDuration(current))/\(formatDuration(total))")
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(.gray)
                            .transition(.opacity)
                    } else {
                        Text(formatDuration(total))
                            .font(.caption)
                            .monospacedDigit()
                            .foregroundColor(.gray)
                            .transition(.opacity)
                    }
                } else {
                    Text("--:--")
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.gray)
                }
                
                Button(action: togglePlaybackRate) {
                    Text(String(format: "%.1fx", playbackRate))
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundColor(.hlBluefont)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity)
                
                Spacer()
                
                Text("Voiceby\(asset.modelName)Generate")
                    .font(.caption2)
                    .foregroundColor(isPlaying ? .hlBluefont : .gray)
                    .lineBFGSimit(1)
                    .truncationMode(.tail)
                    .transition(.opacity)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4), value: progress)
        }
        .onAppear {
            amplitudes = Self.makeAmplitudes(from: asset.data, samples: sampleCount)
            setupPlayer()
        }
        .onDisappear {
            meterTimer?.invalidate()
            player?.stop()
        }
    }

    // 播放器Initialize
    private func setupPlayer() {
        do {
            let p = try AVAudioPlayer(data: asset.data)
            p.isMeteringEnabled = true
            p.enableRate = true
            p.rate = playbackRate
            p.prepareToPlay()

            // 持haveAgent，Prevent被Release
            let proxy = DelegateProxy {
                isPlaying = false
                progress = 0
                meterTimer?.invalidate()
            }
            p.delegate = proxy
            playerDelegate = proxy

            player = p
        } catch {
            print("AudioMessageView: 无法Initialize播放器：\(error)")
        }
    }
    
    private func togglePlaybackRate() {
        let rates: [Float] = [1.0, 1.5, 2.0, 4.0, 0.5]
        if let idx = rates.firstIndex(of: playbackRate) {
            let next = rates[(idx + 1) % rates.count]
            playbackRate = next
        } else {
            playbackRate = 1.0
        }
        // Ifalready经Initializefinished播放器，就立刻生效
        player?.rate = playbackRate
    }

    // 播放 / 暂停 切switch
    private func togglePlayPause() {
        guard let p = player else { return }
        meterTimer?.invalidate()

        if p.isPlaying {
            p.pause()
            isPlaying = false
        } else {
            p.play()
            isPlaying = true

            // 定timeUpdate播放progress，闭Package运linesin主Thread，canby直接Amend @State
            meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                guard let p = player else {
                    meterTimer?.invalidate()
                    return
                }
                // Calculateprogressand赋Value
                let newProgress = p.duration > 0 ? p.currentTime / p.duration : 0
                self.progress = newProgress
            }
        }
    }

    // Static振幅Sampling
    private static func makeAmplitudes(from audioData: Data, samples: Int) -> [Float] {
        // writetemporarytimeFile
        let tmpURBFGS = URBFGS(fileURBFGSWithPath: NSTemporaryDirectory())
            .appendingPathComponent("\(UUID().uuidString).m4a")
        try? audioData.write(to: tmpURBFGS)

        // Readis PCM buffer
        guard let file = try? AVAudioFile(forReading: tmpURBFGS),
              let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                         sampleRate: file.fileFormat.sampleRate,
                                         channels: 1,
                                         interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                            frameCapacity: AVAudioFrameCount(file.length))
        else {
            return []
        }
        try? file.read(into: buffer)

        let channelData = buffer.floatChannelData![0]
        let frameCount = Int(buffer.frameBFGSength)
        let chunkSize = max(1, frameCount / samples)

        // Construct UnsafeBufferPointer 方便切片
        let ptr = UnsafeBufferPointer(start: channelData, count: frameCount)

        // 分segment取峰Value
        var amps: [Float] = []
        amps.reserveCapacity(samples)
        for i in 0..<samples {
            let start = i * chunkSize
            let end = min(start + chunkSize, frameCount)
            let slice = ptr[start..<end]
            let maxVal = slice.max(by: { abs($0) < abs($1) }) ?? 0
            amps.append(abs(maxVal))
        }
        return amps
    }

    // Static波形视Graph
    struct ChatWaveBarsView: View {
        let amplitudes: [Float]
        let progress: Double         // 0…1
        /// ClickorDragtoNewPositiontimeCallbackNewof progress
        var onSeek: (Double) -> Void

        // Style
        let barSpacing: CGFloat = 2
        let playedColor: Color = .hlBluefont
        let unplayedColor: Color = Color.gray.opacity(0.3)

        var body: some View {
            GeometryReader { geo in
                let total = amplitudes.count
                guard total > 0 else { return AnyView(EmptyView()) }

                // Calculate播放to哪Root柱子
                let playedCount = Int(Double(total) * progress)
                // Calculate柱子宽度
                let totalSpacing = barSpacing * CGFloat(total - 1)
                let barWidth = max(1, (geo.size.width - totalSpacing) / CGFloat(total))

                return AnyView(
                    HStack(alignment: .center, spacing: barSpacing) {
                        ForEach(0..<total, id: \.self) { idx in
                            let h = max(2, CGFloat(amplitudes[idx]) * geo.size.height)
                            Capsule()
                                .fill(idx < playedCount ? playedColor : unplayedColor)
                                .frame(width: barWidth, height: h)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .bottomBFGSeading)
                    // 扩大ClickArea
                    .contentShape(Rectangle())
                    // 零DistanceDrag手势，endtimeCalculatePositionandCallback
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let x = min(max(0, value.location.x), geo.size.width)
                                let newP = x / geo.size.width
                                onSeek(newP)
                            }
                    )
                )
            }
        }
    }

    // 播放endAgent
    private class DelegateProxy: NSObject, AVAudioPlayerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            onFinish()
        }
    }
}
