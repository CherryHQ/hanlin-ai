//
//  ChatBubbles.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 9/2/25.
//

import SwiftUI
import MarkdownUI
import PhotosUI
import Combine
import UniformTypeIdentifiers
import AVFoundation
import Speech
import SwiftData
import QuickLook
import MapKit
import WebKit
import RichTextKit
import LaTeXSwiftUI
import AVFoundation


struct LoadingGradientText: View {
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

                        LinearGradient(
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

// MARK: - 组件化对话气泡
struct ChatBubbleView: View {
    @Environment(\.modelContext) private var modelContext
    let temporaryRecord: Bool
    let id: UUID
    let text: String               // 回复内容
    let saveTranlatedText: String? // 保存的翻译
    let images: [UIImage]?         // 图片数组
    let imagesText: String?
    let reasoning: String          // 推理内容
    let reasoningTime: String?     // 推理时间
    @Binding var isReasoningExpanded: Bool // 推理文本折叠状态
    let toolContent: String        // 工具消息
    let toolName: String           // 工具名称
    @Binding var isToolContentExpanded: Bool
    let uploadDocument: [URL]?     // 文档内容
    let documentText: String?
    let resources: [Resource]?     // 资料来源
    let prompts: [PromptCard]?     // 提示词
    let locations: [Location]?     // 位置信息
    let routes: [RouteInfo]?       // 路线信息
    let events: [EventItem]?       // 事件信息
    let htmlContent: String?       // 网页信息
    let healthCards: [HealthData]? // 健康卡片
    let codeBlocks: [CodeBlock]?   // 代码块
    let knowledgeCard: [KnowledgeCard]? // 知识卡片
    let searchEngine: String?
    let audioAssets: [AudioAsset]?
    @Binding var isVoiceExpanded: Bool // 语音消息折叠
    let showCanvas: Bool
    let canvas: CanvasData?
    let role: String
    let model: String
    let modelCompany: String
    let modelIdentity: String
    let modelIcon: String
    let isLastAssistant: Bool      // 是否是最后一条消息
    let isLastAssistantGroup: Bool // 是否是最后一组消息
    let splitMarker: Bool          // 是否需要分割
    let isResponding: Bool
    let operationalState: String
    let operationalDescription: String
    let onRetry: (() -> Void)?     // 重新请求回调
    let onDelete: (() -> Void)?    // 新增：删除回调
    let screenHeight = UIScreen.main.bounds.height
    
    @StateObject var context = RichTextContext() // 富文本
    
    @State private var isResourcesExpanded: Bool = false  // 资源文本折叠状态
    @State private var isTranslateExpanded: Bool = false  // 翻译文本折叠状态
    @State private var mathMode: Bool = false             // 科学模式
    @State private var showMathModeReminder: Bool = false // 科学模式提醒
    @State private var selectedImage: UIImage? // 选中的图片
    @State private var isImageViewerPresented: Bool = false // 是否显示大图
    @State private var showDocumentContent: Bool = false  // 显示解析文本内容
    @State private var isTextSelectionSheetPresented: Bool = false // 文本选择
    @State private var translatedTextSelectionSheetPresented: Bool = false // 翻译文本选择
    @StateObject private var tts = TextToSpeech() // 持续保留实例
    @State private var isCopy: Bool = false // 是否复制
    @State private var translated: Bool = false // 是否翻译
    @State private var isTranslating: Bool = false // 是否翻译中
    @State private var showErrorAlert: Bool = false // 显示错误提示
    @State private var errorMessage: String = "" // 错误信息
    @State private var translatedText: String = "" // 翻译后的文本
    @State private var isSuccess = false // 是否需要震动
    @State private var isFeedBack = false // 是否需要震动
    @State var showDeleteConfirmation: Bool = false //删除确认框
    // 保存知识相关
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
        // 添加确认弹窗
        .alert("确认删除？", isPresented: $showDeleteConfirmation) {
            Button("删除", role: .destructive) {
                onDelete?()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("确定要删除吗？删除后不可恢复！")
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

    // MARK: - 主要内容区
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
    
    // MARK: - 搜索消息
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
                    Text("资料内容")
                        .padding(.leading, 5)
                    
                    // 查看文本
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
                        Label("查看资料", systemImage: "book")
                    }
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("删除资料", systemImage: "trash")
                    }
                }
            }
        }
    }
    
    // MARK: - 用户消息
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
                        Label("复制内容", systemImage: "square.on.square")
                    }
                    Button(action: {
                        isTextSelectionSheetPresented = true
                    }) {
                        Label("选择文本", systemImage: "text.redaction")
                    }
                    Button(action: {
                        createAndSaveKnowledgeRecord(with: text)
                    }) {
                        Label("存为知识", systemImage: "backpack")
                    }
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("删除消息", systemImage: "trash")
                    }
                }
                .clipShape(CustomCorners(topLeft: 20, topRight: 20, bottomLeft: 20, bottomRight: 5))
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
    
    // MARK: - AI 助手消息
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

    // MARK: 头部：头像 + 模型名
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

    // MARK: 图片段落
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

    // MARK: 文本 & 各类工具输出
    @ViewBuilder
    private func assistantTextSection() -> some View {
        if !text.isEmpty || !reasoning.isEmpty || !toolContent.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                if showCanvas, canvas?.content.isEmpty == false {
                    canvasBubble(for: canvas)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 文字主体
                messageContent()
                    .transition(.move(edge: .top).combined(with: .opacity))
                
                // 代码块
                if let codes = codeBlocks, !codes.isEmpty {
                    codeBubble(for: codes)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                // 知识卡
                if let cards = knowledgeCard, !cards.isEmpty {
                    knowledgeCardBubble(for: cards)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                // 网页
                if let htmls = htmlContent, !htmls.isEmpty {
                    htmlWebBubble(for: htmls)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                // 事件
                if let evs = events, !evs.isEmpty {
                    eventsBubble(for: evs)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                // 健康卡
                if let hcs = healthCards {
                    nutritionCards(
                        for: Binding<[HealthData]>(
                            get: { hcs },
                            set: { _ in }
                        )
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                // 地图
                if (locations?.isEmpty == false) || (routes?.isEmpty == false) {
                    mapBubble(for: locations ?? [], routes: routes ?? [])
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                // 底部按钮
                if isLastAssistant && !isResponding {
                    actionButtons()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: 底部 Loading / 结束状态
    @ViewBuilder
    private func assistantFooter() -> some View {
        if (!operationalState.isEmpty && isLastAssistant)
            || (text.isEmpty && reasoning.isEmpty && toolContent.isEmpty && images == nil) {
            loadingSection()
        }
        else if isResponding && isLastAssistant {
            Image(systemName: "sparkle")
                .bold()
                .foregroundColor(.hlBluefont)
                .symbolEffect(.breathe.pulse.byLayer,
                              options: .repeat(.continuous))
                .padding(5)
        }
    }

    // MARK: 真正的 Loading / Operational 状态块
    @ViewBuilder
    private func loadingSection() -> some View {
        HStack(alignment: .top) {
            if !operationalState.isEmpty {
                VStack(alignment: .leading) {
                    LoadingGradientText(text: operationalState)
                        .foregroundColor(.gray)
                        .padding(5)
                    
                    if !operationalDescription.isEmpty {
                        let allLines = operationalDescription
                            .split(separator: "\n",
                                   omittingEmptySubsequences: false)
                            .map(String.init)
                        let displayLines = Array(allLines.suffix(3))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(displayLines.enumerated()),
                                    id: \.offset) { idx, line in
                                Text(line)
                                    .id(line)
                                    .font(.system(size:
                                                    idx == 2 ? 10 :
                                                    (idx == 1 ? 9 : 8)))
                                    .lineLimit(1)
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
                    .symbolEffect(.breathe.pulse.byLayer,
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
    
    // MARK: 画布块
    @ViewBuilder
    private func canvasBubble(for canvas: CanvasData?) -> some View {
        if let canvas = canvas {
            HStack(spacing: 6) {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: size_20, weight: .medium))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("画布 \(canvas.title)")
                        .font(.caption)
                        .bold()
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Text("点击右下角“画布”按钮以查看和编辑内容")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 0)
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

    // MARK: 代码块
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
                        ToolbarItemGroup(placement: .navigationBarLeading) {
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
                                    Text(codeIsCopied ? "已复制" : "全部复制")
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
                            Text("程序源码").font(.headline)
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
                        Label {
                            Text(knowledgeCard.title)
                                .font(.subheadline)
                                .lineLimit(1)
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
                                // 已写入状态
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("已经存入背包")
                                }
                                .font(.caption)
                                .padding(6)
                                .background(Color(.systemGray5))
                                .foregroundColor(.gray)
                                .clipShape(Capsule())
                            } else {
                                // 未写入状态
                                HStack(spacing: 4) {
                                    Image(systemName: "backpack")
                                    Text("存入知识背包")
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
    
    @State private var showFullHTML = false
    @State private var htmlIsCopied = false
    @State private var triggerCopyFeedback = false
    @State private var htmlTitle: String = "网页预览"
    @State private var showFrontCodeSheet = false
    
    @ViewBuilder
    private func htmlWebBubble(for htmls: String) -> some View {
        
        ZStack(alignment: .bottomTrailing) {
            // 小区域预览
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
                // 查看代码按钮
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
                
                // 放大按钮
                Button(action: {
                    isFeedBack.toggle()
                    showFullHTML.toggle()
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
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        // 复制网页源码按钮
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
                                Text(htmlIsCopied ? "已复制" : "全部复制")
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
                        // 关闭按钮
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
        .fullScreenCover(isPresented: $showFullHTML) {
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
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        
                        ToolbarItemGroup(placement: .navigationBarLeading) {
                            // 复制网页源码按钮
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
                                    Text(htmlIsCopied ? "已复制" : "复制代码")
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
                            // 关闭按钮
                            Button {
                                isFeedBack.toggle()
                                showFullHTML = false
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
    
    // MARK: - 营养卡片
    @ViewBuilder
    private func nutritionCards(for list: Binding<[HealthData]>) -> some View {

        if !list.wrappedValue.isEmpty {

            VStack(alignment: .leading, spacing: 20) {

                ForEach(Array(list.wrappedValue.enumerated()), id: \.element.id) { (idx, item) in
                    
                    VStack(alignment: .leading, spacing: 14) {
                        
                        HStack(spacing: 6) {
                            Image(systemName: "bubbles.and.sparkles")
                                .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                            Text("营养卡片")
                                .font(.headline.bold())
                            Spacer()
                        }
                        
                        HStack {
                            VStack {
                                if let c = item.carbohydratesGrams {
                                    nutrientRow(icon: "popcorn.fill", tint: .orange,
                                                label: "碳水", value: c, unit: "g")
                                }
                                if let f = item.fatGrams {
                                    nutrientRow(icon: "drop.fill", tint: .pink,
                                                label: "脂肪", value: f, unit: "g")
                                }
                            }
                            Divider()
                            VStack {
                                if let p = item.proteinGrams {
                                    nutrientRow(icon: "fish.fill", tint: .blue,
                                                label: "蛋白质", value: p, unit: "g")
                                }
                                if let e = item.energyKilocalories {
                                    nutrientRow(icon: "flame.fill", tint: .red,
                                                label: "能量", value: e, unit: "kcal")
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
                                            // 1. 根据ID查找 ChatMessages 实例
                                            let descriptor = FetchDescriptor<ChatMessages>(
                                                predicate: #Predicate { $0.id == id },
                                                sortBy: []
                                            )
                                            if let msg = try? modelContext.fetch(descriptor).first {
                                                // 2. 找到 healthData 中对应项并修改
                                                if var dataList = msg.healthData,
                                                   let i = dataList.firstIndex(where: { $0.id == item.id }) {
                                                    dataList[i].isWritten = true
                                                    msg.healthData = dataList
                                                    try? modelContext.save()  // 持久化保存
                                                }
                                            }
                                        }
                                    } catch {
                                        print("写入失败: \(error)")
                                    }
                                }
                            }) {
                                if item.isWritten == true {
                                    // 已写入状态
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("已经写入健康")
                                    }
                                    .font(.caption)
                                    .padding(6)
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.gray)
                                    .clipShape(Capsule())
                                } else {
                                    // 未写入状态
                                    HStack(spacing: 4) {
                                        Image(systemName: "pencil.and.list.clipboard")
                                        Text("写入健康应用")
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

    // MARK: - 单行营养项
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
                            // 根据事件类型显示不同的系统图标
                            Image(systemName: event.type.lowercased() == "calendar" ? "calendar" : "list.bullet")
                                .font(.title)
                                .foregroundColor(.hlBluefont)
                                .padding(3)
                            Spacer()
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Spacer()
                            // 显示事件标题
                            Text(event.title)
                                .font(.headline)
                                .bold()
                                .lineLimit(1)
                            
                            // 如果有日期，则显示开始日期（或提醒截止日期）
                            if let date = event.startDate ?? event.dueDate {
                                Text(formatDate(date))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            // 显示地点（如果存在）
                            if let loc = event.location, !loc.isEmpty {
                                Text("地点: \(loc)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            // 显示备注（如果存在）
                            if let notes = event.notes, !notes.isEmpty {
                                Text("备注: \(notes)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        
                        Spacer()
                        
                        if event.type.lowercased() == "calendar" {
                            VStack(alignment: .center) {
                                Spacer()
                                // 点击跳转至系统日历
                                Button(action: {
                                    // 使用 "calshow" URL scheme 打开系统日历
                                    if let url = URL(string: "calshow://") {
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

    // 辅助函数：将 Date 格式化为 "yyyy-MM-dd HH:mm" 字符串
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    @State private var showFullMap = false
    @State private var imageStyle = false
    @State private var selectedPoint: MapSelection<MKMapItem>?
    
    @ViewBuilder
    private func mapBubble(for locations: [Location], routes: [RouteInfo]?) -> some View {
        ZStack(alignment: .bottomTrailing) {
            // 地图视图，传入 routes 参数即可显示路线数据（当存在时）
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
            
            // 按钮区域保持原样
            HStack(spacing: 6) {
                if !locations.isEmpty {
                    Button(action: {
                        isFeedBack.toggle()
                        let destLatitude: Double
                        let destLongitude: Double
                        let destName: String
                        if let selected = selectedPoint?.value {
                            let coordinate = selected.placemark.coordinate
                            destLatitude = coordinate.latitude
                            destLongitude = coordinate.longitude
                            destName = selected.name ?? "目的地"
                        } else if let firstLocation = locations.first {
                            destLatitude = firstLocation.latitude
                            destLongitude = firstLocation.longitude
                            destName = firstLocation.name
                        } else {
                            return
                        }
                        
                        let nameEncoded = destName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "目的地"
                        if let url = URL(string: "http://maps.apple.com/?daddr=\(destLatitude),\(destLongitude)&q=\(nameEncoded)") {
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
                // 浮动按钮区域保持原样
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Spacer()
                        if !locations.isEmpty {
                            Button(action: {
                                isFeedBack.toggle()
                                let destLatitude: Double
                                let destLongitude: Double
                                let destName: String
                                if let selected = selectedPoint?.value {
                                    let coordinate = selected.placemark.coordinate
                                    destLatitude = coordinate.latitude
                                    destLongitude = coordinate.longitude
                                    destName = selected.name ?? "目的地"
                                } else if let firstLocation = locations.first {
                                    destLatitude = firstLocation.latitude
                                    destLongitude = firstLocation.longitude
                                    destName = firstLocation.name
                                } else {
                                    return
                                }
                                
                                let nameEncoded = destName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "目的地"
                                if let url = URL(string: "http://maps.apple.com/?daddr=\(destLatitude),\(destLongitude)&q=\(nameEncoded)") {
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
            // 复制按钮
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
                Text("已复制")
                    .font(.system(size: size_12, weight: .medium))
                    .foregroundColor(.hlGreen)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            
            // 选择文本
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
            
            // 语音朗读
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
                Text("正在请求")
                    .font(.system(size: size_12, weight: .medium))
                    .foregroundColor(.hlBluefont)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            
            // 翻译按钮
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
            .alert("翻译操作失败", isPresented: $showErrorAlert) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            
            if isTranslating {
                Text("正在翻译")
                    .font(.system(size: size_12, weight: .medium))
                    .foregroundColor(.hlBluefont)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            
            // 科学模式
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
                Text(mathMode ? "科学模式" : "文本模式")
                    .font(.system(size: size_12, weight: .medium))
                    .foregroundColor(.hlBluefont)
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
            
            // 背包按钮
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
            
            // 重新请求
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

    // MARK: - AI 助手消息内容
    @ViewBuilder
    private func messageContent() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            reasoningView()
                .transition(.opacity.combined(with: .move(edge: .top)))
            
            Group {
                if mathMode {
                    LaTeX(text)
                } else {
                    Markdown(text)
                }
            }
            .contextMenu {
                // 复制
                Button(action: {
                    UIPasteboard.general.string = markdownToPlainText(text)
                }) {
                    Label("复制内容", systemImage: "square.on.square")
                }
                
                // 选中文本
                Button(action: {
                    isTextSelectionSheetPresented = true
                }) {
                    Label("选择文本", systemImage: "text.redaction")
                }
                
                // 生成语音
                Button(action: {
                    tts.setContextIfNeeded(modelContext)
                    tts.updateSelectedModel()
                    tts.setMessageId(id)
                    tts.toggleSpeech(text: text)
                }) {
                    if tts.isAsking {
                        Label("正在请求", systemImage: "progress.indicator")
                    } else {
                        Label("生成语音", systemImage: "waveform")
                    }
                }
                
                // 翻译/删除译文/翻译中…
                Button(action: translateText) {
                    if isTranslating {
                        Label("正在翻译", systemImage: "progress.indicator")
                    } else if translated {
                        Label("删除译文", systemImage: "trash")
                    } else {
                        HStack {
                            Image("translate")
                                .renderingMode(.template)
                                .font(.system(size: size_14, weight: .medium))
                                .frame(width: size_24, height: size_24)
                                .foregroundColor(.secondary)
                                .clipShape(Circle())
                            Text("翻译内容")
                        }
                    }
                }
                
                // 科学模式
                Button(action: {
                    mathMode.toggle()
                    showMathModeReminder = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showMathModeReminder = false
                    }
                }) {
                    if mathMode {
                        Label("文本模式", systemImage: "note.text")
                    } else {
                        Label("科学模式", systemImage: "x.squareroot")
                    }
                }
                
                // 存为知识
                Button(action: {
                    createAndSaveKnowledgeRecord(with: text)
                }) {
                    Label("存为知识", systemImage: "backpack")
                }
                
                // 删除消息
                Button(action: {
                    showDeleteConfirmation = true
                }) {
                    Label("删除消息", systemImage: "trash")
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
    
    // 生成长数字 ID：yyyyMMddHHmmss + 4位随机数
    private func makeTimestampID() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = formatter.string(from: Date())
        let randomSuffix = Int.random(in: 1_000...9_999)  // 4 位随机数
        return "\(dateString)\(randomSuffix)"
    }
    
    // 创建知识文档
    private func createAndSaveKnowledgeRecord(
        with text: String,
        title: String? = nil,
        card: KnowledgeCard? = nil
    ) {
        // 1. 创建新的知识记录
        let newRecord = KnowledgeRecords()
        newRecord.content    = text
        newRecord.lastEdited = Date()
        // 2. 如果传了 title 就用它，否则使用默认
        let recordTitle = (title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        ? title!
        : "群聊知识_\(makeTimestampID())"
        newRecord.name = recordTitle
        if let card = card {
            newRecord.id = card.id
        }
        
        // 3. 插入到数据库并保存
        modelContext.insert(newRecord)
        do {
            try modelContext.save()
            // 4. 保存成功后，弹出编辑界面
            recordToWrite = newRecord
            isKnowledgeWritingSheetPresented = true
            
            // 5. 如果传入了 card，就更新 ChatMessages 中对应卡片的 isWritten
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
            // 保存失败
            errorMessage     = error.localizedDescription
            showErrorAlert   = true
            print("保存知识文档失败: \(error.localizedDescription)")
        }
    }
    
    // 查看知识文档
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
            errorMessage = "未找到标题为“\(title)”的知识文档"
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
                translatedText = "翻译中..."
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
            // 根据ID查找信息并修改翻译内容
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
    
    private var displayReasoningLines: [String] {
        // 拆分 & 过滤
        let raw = reasoning
            .split(whereSeparator: {
                [".", "\n", "。"].contains(String($0))
            })
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // 取最后 3 条
        let last3 = Array(raw.suffix(3))
        // 如果不为空且不足 3 条，就在前面补空
        if !last3.isEmpty && last3.count < 3 {
            return Array(repeating: " ", count: 3 - last3.count) + last3
        }
        return last3
    }

    // MARK: - 推理过程区域
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
                    if isResponding && isLastAssistantGroup {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(Array(displayReasoningLines.enumerated()), id: \.offset) { idx, line in
                                Text(line)
                                    .id(String(line.prefix(1)))
                                    .font(.system(size: idx == 2 ? 10 : (idx == 1 ? 9 : 8)))
                                    .lineLimit(1)
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
                            value: displayReasoningLines
                        )
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }
    
    // MARK: - 工具使用区域
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
    
    // MARK: - 语音消息区域
    @ViewBuilder
    private func audioView() -> some View {
        // 如果没有任何音频就不显示
        if let audioAssets = audioAssets, !audioAssets.isEmpty {
            VStack(alignment: .leading) {
                
                ToggleButton(
                    title: String(localized: "voice_block"), // 这里用你的本地化 key
                    timeText: "",
                    isExpanded: $isVoiceExpanded
                )
                
                if isVoiceExpanded {
                    // 展开后竖向展示所有语音消息
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
    
    // MARK: - 翻译内容区域
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
                            LaTeX(translatedText)
                        } else {
                            Markdown(translatedText)
                        }
                    }
                    .contextMenu {
                        // 复制内容
                        Button(action: {
                            UIPasteboard.general.string = translatedText
                        }) {
                            Label("复制内容", systemImage: "square.on.square")
                        }
                        // 选择文本
                        Button(action: {
                            translatedTextSelectionSheetPresented = true
                        }) {
                            Label("选择文本", systemImage: "text.redaction")
                        }
                        // 删除译文
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
                                Text(translated ? "删除译文" : (isTranslating ? "翻译中..." : "翻译内容"))
                            }
                        }
                        // 科学模式
                        Button(action: {
                            mathMode.toggle()
                            showMathModeReminder = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                showMathModeReminder = false
                            }
                        }) {
                            if mathMode {
                                Label("文本模式", systemImage: "note.text")
                            } else {
                                Label("科学模式", systemImage: "x.squareroot")
                            }
                        }
                        // 存为知识
                        Button(action: {
                            createAndSaveKnowledgeRecord(with: translatedText)
                        }) {
                            Label("存为知识", systemImage: "backpack")
                        }
                    }
                }
            }
        }
    }

    // MARK: - 参考资料区域
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

    // MARK: - 参考资料项
    @State private var selectedLink: URL?
    
    @ViewBuilder
    private func resourceItemView(resource: Resource, index: Int) -> some View {
        
        HStack(alignment: .center) {
            
            resourceIcon(urlString: resource.icon)
            
            Text("[\(index + 1)]")
                .foregroundColor(temporaryRecord ? .primary : Color(.hlBluefont))
                .font(.footnote.monospacedDigit())
                .lineLimit(1)
            
            if let url = URL(string: resource.link) {
                
                Button(action: {
                    selectedLink = url
                }) {
                    Text(resource.title)
                        .foregroundColor(temporaryRecord ? .primary : Color(.hlBluefont))
                        .font(.footnote)
                        .lineLimit(1)
                }
                
            } else {
                Button(action: {
                    openKnowledgeRecord(with: resource.title)
                }) {
                    Text(resource.title)
                        .foregroundColor(temporaryRecord ? .primary : Color(.hlBluefont))
                        .font(.footnote)
                        .lineLimit(1)
                }
            }
            
        }
        .sheet(item: $selectedLink) { url in
            ResourceLinkAlertView(url: url)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - 资源图标
    @ViewBuilder
    private func resourceIcon(urlString: String) -> some View {
        if let iconURL = URL(string: urlString) {
            AsyncImage(url: iconURL) { phase in
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

    // MARK: - 信息型消息
    @ViewBuilder
    private func informationMessageView() -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
    
    // MARK: - 错误型消息
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
                    Text("重新请求")
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

    // MARK: - 折叠按钮组件
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
            // 图片显示区域
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
                                        // 复制图片
                                        UIPasteboard.general.image = images[index]
                                    }) {
                                        Label("复制图片", systemImage: "square.on.square")
                                    }
                                    Button(action: {
                                        // 保存图片到相册
                                        UIImageWriteToSavedPhotosAlbum(images[index], nil, nil, nil)
                                    }) {
                                        Label("保存图片", systemImage: "square.and.arrow.down")
                                    }
                                }
                                .onTapGesture {
                                    selectedImage = images[index] // 记录当前选中的图片
                                    isImageViewerPresented = true // 触发大图预览
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
        .clipShape(CustomCorners(topLeft: 20, topRight: 20, bottomLeft: 20, bottomRight: 5))
        .sheet(isPresented: $isImageViewerPresented) { // 全屏预览大图
            if let images = selectedImage {
                ImageViewer(image: images, isPresented: $isImageViewerPresented)
            }
        }
    }
    
    @ViewBuilder
    private func chatAssistantBubbleImage() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 图片显示区域
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
                                        // 复制图片
                                        UIPasteboard.general.image = images[index]
                                    }) {
                                        Label("复制图片", systemImage: "square.on.square")
                                    }
                                    Button(action: {
                                        // 保存图片到相册
                                        UIImageWriteToSavedPhotosAlbum(images[index], nil, nil, nil)
                                    }) {
                                        Label("保存图片", systemImage: "square.and.arrow.down")
                                    }
                                }
                                .onTapGesture {
                                    selectedImage = images[index] // 记录当前选中的图片
                                    isImageViewerPresented = true // 触发大图预览
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
        .sheet(isPresented: $isImageViewerPresented) { // 全屏预览大图
            if let images = selectedImage {
                ImageViewer(image: images, isPresented: $isImageViewerPresented)
            }
        }
    }
    
    @ViewBuilder
    private func chatBubblePrompt() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 提示词显示区域
            if let prompts = prompts, !prompts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(prompts, id: \.self) { item in
                            HStack(spacing: 6) {
                                // 提示词库
                                Image("prompt") // 使用自定义图片
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.hlBluefont)
                                
                                Text(item.name)
                                    .font(.caption)
                                    .foregroundColor(.hlBluefont)
                                    .lineLimit(1)
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
        .clipShape(CustomCorners(topLeft: 20, topRight: 20, bottomLeft: 20, bottomRight: 5))
    }
    
    @ViewBuilder
    private func chatBubbleDocument (for documents: [URL]?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let documents = documents, !documents.isEmpty {
                VStack(spacing: 6) {
                    ForEach(documents, id: \.self) { documentURL in
                        HStack(spacing: 6) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(fileColor(for: documentURL.pathExtension))
                                    .frame(width: 34, height: 34)
                                
                                Image(systemName: fileIcon(for: documentURL.pathExtension))
                                    .renderingMode(.template)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(documentURL.deletingPathExtension().lastPathComponent)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .lineLimit(1) // 限制为 1 行
                                    .truncationMode(.tail) // 文字过长时显示省略号
                                Text(documentURL.pathExtension.uppercased())
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                                    .lineLimit(1) // 限制为 1 行
                                    .truncationMode(.tail) // 文字过长时显示省略号
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
                        Label("文件文本", systemImage: "text.document")
                    }
                }
                .cornerRadius(14)
            }
        }
        .padding(6)
        .background(temporaryRecord ? .primary.opacity(0.8) : Color.hlBlue.opacity(0.8))
        .clipShape(CustomCorners(topLeft: 20, topRight: 20, bottomLeft: 20, bottomRight: 5))
        .sheet(isPresented: $showDocumentContent) {
            FileContentViewer(content: (documentText ?? "暂无内容").trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    
    // 文件颜色
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
    
    // 文件图标
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
            return "doc" // 其他默认文档
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

// MARK: - 代码块
private struct CodeBlockRow: View {
    let codeBlock: CodeBlock
    let temporaryRecord: Bool
    let onShowSource: () -> Void
    @State private var isFeedBack: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("程序运行结果", systemImage: "apple.terminal")
                    .font(.subheadline)
                    .foregroundColor(temporaryRecord ? .primary : .hlBluefont)
                Spacer()
                Button(action: {
                    isFeedBack.toggle()
                    onShowSource()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.plaintext")
                        Text("查看源码")
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

// SwiftUI 版 WebView，带 JS 支持和外部资源加载能力
struct WebView: UIViewRepresentable {
    // 要展示的 HTML 字符串
    let htmlContent: String
    // baseURL: 如果你的 HTML 里有相对路径资源，可以在这里传入域名或本地文件目录
    let baseURL: URL? = nil
    
    func makeUIView(context: Context) -> WKWebView {
        // 创建配置
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
        uiView.loadHTMLString(htmlContent, baseURL: baseURL)
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        init(_ parent: WebView) { self.parent = parent }
    }
}

// 地图视图
struct MapMessageBubble: View {
    let temporaryRecord: Bool
    let locations: [Location]
    let imageStyle: Bool
    let routes: [RouteInfo]?

    @State private var fetchedItems: [String: MKMapItem] = [:]
    @Binding var selectedPoint: MapSelection<MKMapItem>?

    init(temporaryRecord: Bool,
         locations: [Location],
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
            
            // 路线信息：如果存在路线数据，则绘制折线
            if let routes = routes, !routes.isEmpty {
                ForEach(routes, id: \.distance) { route in
                    // 将 RouteInfo 的 routePoints 转换为 CLLocationCoordinate2D 数组
                    let polylineCoordinates = route.routePoints.map {
                        CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
                    }
                    MapPolyline(coordinates: polylineCoordinates)
                        .stroke(Color.hlBluefont, lineWidth: 5)
                }
            }
            
            // 标注信息：绘制各地点标注
            ForEach(locations, id: \.identifier) { location in
                let mapItem: MKMapItem = {
                    if let fetched = fetchedItems[location.identifier ?? "Unknown"] {
                        return fetched
                    }
                    let fallback = MKMapItem(
                        placemark: MKPlacemark(
                            coordinate: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
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
            
            // 用户当前位置标注
            UserAnnotation()
        }
        .mapFeatureSelectionAccessory(.callout)
        .mapStyle(imageStyle ? .hybrid(elevation: .realistic) : .standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
                .buttonBorderShape(.circle)
            MapCompass()
            MapScaleView()
        }
        .task {
            // 获取各地点的 MKMapItem
            for location in locations {
                if let id = MKMapItem.Identifier(rawValue: location.identifier ?? "Unknown") {
                    let request = MKMapItemRequest(mapItemIdentifier: id)
                    do {
                        let item = try await request.mapItem
                        fetchedItems[location.identifier ?? "Unknown"] = item
                    } catch {
                        print("从 identifier 获取 MapItem 失败:", error)
                    }
                }
            }
        }
    }
}

// 打开资源警示
struct ResourceLinkAlertView: View {
    let url: URL
    @Environment(\.dismiss) var dismiss
    @State private var isSuccess = false // 是否需要震动
    @State private var isFeedBack = false // 是否需要震动
    
    var body: some View {
        VStack(spacing: 24) {
            Text("⚠️ 这是一个外部链接")
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)
            
            Text("链接包含未知信息\n打开链接将离开AI翰林院")
                .multilineTextAlignment(.center)
            
            Text(url.absoluteString)
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.horizontal)
                .lineLimit(2)
                .truncationMode(.middle)
            
            Spacer()

            VStack(spacing: 16) {
                Button(action: {
                    UIPasteboard.general.string = url.absoluteString
                    isSuccess.toggle()
                    dismiss()
                }) {
                    Text("复制链接")
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
                    Text("打开链接")
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

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct ImageViewer: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var isSaved: Bool = false    // 保存状态：true 表示保存成功
    @State private var isCopied: Bool = false   // 复制状态：true 表示复制成功
    
    // 缩放相关状态
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    
    // 平移相关状态
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    // 应用缩放和平移效果
                    .scaleEffect(scale)
                    .offset(offset)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    // 组合“捏合缩放”和“拖拽平移”手势
                    .gesture(simultaneousGesture(in: geometry))
                    // 单击图片关闭浏览
                    .onTapGesture {
                        isPresented = false
                    }
            }
            
            // 底部操作按钮区域
            bottomButtons
        }
    }
    
    // 底部按钮视图
    private var bottomButtons: some View {
        VStack {
            Spacer()
            HStack(spacing: 6) {
                Spacer()
                
                // 复制按钮：状态依据 isCopied 切换图标
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
                
                // 保存按钮：状态依据 isSaved 切换图标
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
    
    // 组合缩放与拖拽手势，并在拖拽时限制偏移范围
    private func simultaneousGesture(in geometry: GeometryProxy) -> some Gesture {
        let magnification = MagnificationGesture()
            .onChanged { value in
                self.scale = max(self.lastScale * value, 1.0)
                // 缩放时调整 offset，确保不超出可拖动范围
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
    
    // 根据当前容器尺寸与缩放比例，计算允许的平移边界，并返回经过限制后的 offset
    private func clampedOffset(proposed: CGSize, in containerSize: CGSize, scale: CGFloat) -> CGSize {
        // 检查图片尺寸是否有效，防止除零错误和 IOSurface 错误
        guard image.size.width > 0 && image.size.height > 0 else {
            return CGSize.zero
        }

        // 计算图片的宽高比
        let imageAspect = image.size.width / image.size.height
        let containerAspect = containerSize.width / containerSize.height
        
        // 计算 scaledToFit 后图片在容器中的显示尺寸
        let displayedWidth: CGFloat
        let displayedHeight: CGFloat
        if imageAspect > containerAspect {
            displayedWidth = containerSize.width
            displayedHeight = containerSize.width / imageAspect
        } else {
            displayedHeight = containerSize.height
            displayedWidth = containerSize.height * imageAspect
        }
        
        // 乘以当前的缩放比例，得到最终图片尺寸
        let finalWidth = displayedWidth * scale
        let finalHeight = displayedHeight * scale
        
        // 计算平移边界，如果图片实际尺寸小于容器，则不可平移
        let maxOffsetX = max((finalWidth - containerSize.width) / 2, 0)
        let maxOffsetY = max((finalHeight - containerSize.height) / 2, 0)
        
        let clampedX = min(max(proposed.width, -maxOffsetX), maxOffsetX)
        let clampedY = min(max(proposed.height, -maxOffsetY), maxOffsetY)
        
        return CGSize(width: clampedX, height: clampedY)
    }
    
    // 保存图片到相册，点击后状态变为 true，2 秒后恢复
    private func saveImageToPhotos() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        isSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isSaved = false }
        }
    }
    
    // 复制图片到剪贴板，点击后状态变为 true，2 秒后恢复
    private func copyImageToClipboard() {
        UIPasteboard.general.image = image
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { isCopied = false }
        }
    }
}


// MARK: 文件内容显示区域（带复制与存为知识操作）
struct FileContentViewer: View {
    let content: String
    @Environment(\.modelContext) private var modelContext
    @State private var isCopy: Bool = false      // 复制按钮状态：true 显示成功标志
    @State private var isSaved: Bool = false     // 存为知识按钮状态：true 显示成功标志
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isSheetPresented = false
    @State private var recordToWrite: KnowledgeRecords? = nil
    
    // 尺寸
    @ScaledMetric(relativeTo: .body) var size_10: CGFloat = 10
    @ScaledMetric(relativeTo: .body) var size_16: CGFloat = 16
    private let buttonSize: CGFloat = 36

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationStack {
                ScrollView {
                    Text(content)
                        .frame(maxWidth: .infinity, alignment: .topLeading) // 左上角对齐
                        .padding()
                        .textSelection(.enabled)
                }
                .navigationTitle("文件文本")
                .navigationBarTitleDisplayMode(.inline)
            }
            
            // 右下角按钮区域
            HStack(spacing: 12) {
                // 存为知识按钮：点击后图标从“backpack.circle”切换到“checkmark.circle”
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
                
                // 复制按钮：点击后图标从“rectangle.on.rectangle.circle”切换到“checkmark.circle”
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
        .alert("保存失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // 复制操作（2秒后自动恢复图标状态）
    private func copyToClipboard() {
        UIPasteboard.general.string = content
        isCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopy = false
            }
        }
    }
    
    // 生成长数字 ID：yyyyMMddHHmmss + 4位随机数
    private func makeTimestampID() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = formatter.string(from: Date())
        let randomSuffix = Int.random(in: 1_000...9_999)  // 4 位随机数
        return "\(dateString)\(randomSuffix)"
    }
    
    // 存为知识操作（如果已存过，直接显示编辑界面；否则保存后切换图标）
    private func saveKnowledge() {
        if isSaved {
            isSheetPresented = true
            return
        }
        
        let newRecord = KnowledgeRecords()
        newRecord.content = content
        newRecord.lastEdited = Date()
        newRecord.name = "文件知识_\(makeTimestampID())"
        
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


// MARK: 选择文本组件
struct TextSelectionTextView: UIViewRepresentable {
    let text: String
    @Binding var shouldSelectAll: Bool

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.text = text
        textView.isEditable = false     // 禁止编辑
        textView.isSelectable = true    // 允许选择
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

// MARK: - 前端代码选择器（JetBrains 配色、性能优化、移动端友好排版）
struct FrontCodeSelectionTextView: UIViewRepresentable {
    /// 源代码内容
    let code: String

    /// 缓存上次处理结果，避免重复高亮计算
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

        // 只有在 code 真正变化时才重新计算高亮
        guard coordinator.lastCode != code else { return }
        coordinator.lastCode = code

        // 异步高亮，避免阻塞主线程
        DispatchQueue.global(qos: .userInitiated).async {
            let highlighted = makeHighlighted(code)
            coordinator.lastAttributed = highlighted
            DispatchQueue.main.async {
                // 确保无新更新后再赋值
                if coordinator.lastCode == code {
                    uiView.attributedText = highlighted
                }
            }
        }
    }
}

// MARK: - 高亮生成函数
private func makeHighlighted(_ code: String) -> NSAttributedString {
    // 段落样式：行间距、段后距
    let paragraph = NSMutableParagraphStyle()
    paragraph.lineSpacing = 4
    paragraph.paragraphSpacing = 6

    // 统一基础属性
    let monoFont = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    let attr = NSMutableAttributedString(string: code, attributes: [
        .font: monoFont,
        .paragraphStyle: paragraph,
        .foregroundColor: UIColor.label
    ])
    let full = NSRange(location: 0, length: attr.length)

    // JetBrains Light 风格配色
    let colors = (
        comment: UIColor(hex: "#008000")!,    // 注释：绿色
        string: UIColor(hex: "#A31515")!,     // 字符串：红色
        keyword: UIColor(hex: "#0000FF")!,    // 关键字：蓝色
        tag: UIColor(hex: "#800000")!,        // HTML 标签：褐红
        property: UIColor(hex: "#267f99")!,   // CSS 属性名：青色
        number: UIColor(hex: "#098658")!      // 数字：橙绿色
    )

    // 1. 注释：HTML <!-- --> & JS/CSS /* */
    applyRegex("<!--([\\s\\S]*?)-->|/\\*[\\s\\S]*?\\*/",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.comment])

    // 2. 字符串字面量："..." 或 '...'
    applyRegex("\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.string])

    // 3. HTML 标签
    applyRegex("</?[a-zA-Z][^>]*?>",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.tag])

    // 4. CSS 属性名（key: value;）
    applyRegex("(?<=\\{|;|\\s|^)([a-zA-Z-]+)(?=\\s*:)",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.property])

    // 5. JS/TS 关键字
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

    // 6. 数字字面量
    applyRegex("\\b\\d+(?:\\.\\d+)?\\b",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.number])

    return attr
}

// MARK: - 正则应用辅助
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

// MARK: - UIColor Hex 扩展
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

// MARK: - Python 代码选择器视图（JetBrains 风格、高亮支持）
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

    // JetBrains Light 配色
    let colors = (
        keyword: UIColor(hex: "#0000FF")!,  // 关键字：蓝
        string:  UIColor(hex: "#A31515")!,  // 字符串：红
        comment: UIColor(hex: "#008000")!,  // 注释：绿
        number:  UIColor(hex: "#098658")!   // 数字：橙绿色
    )

    // 注释
    applyRegex("#.*", to: attr, range: full,
               attrs: [.foregroundColor: colors.comment])
    // 字符串
    applyRegex("\"(?:\\\\.|[^\"\\\\])*\"|'(?:\\\\.|[^'\\\\])*'",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.string])
    // 关键字
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
    // 数字
    applyRegex("\\b\\d+(?:\\.\\d+)?\\b",
               to: attr, range: full,
               attrs: [.foregroundColor: colors.number])

    return attr
}

// MARK: 选择文本组件（带复制、全选及存为知识操作）
struct TextSelectionView: View {
    let text: String
    @Environment(\.modelContext) private var modelContext
    @State private var isCopy: Bool = false      // 复制按钮状态：true 表示复制成功
    @State private var isSaved: Bool = false       // 存为知识按钮状态：true 表示保存成功
    @State private var shouldSelectAll: Bool = false // 全选触发状态
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isSheetPresented = false
    @State private var recordToWrite: KnowledgeRecords? = nil
    
    // 尺寸
    @ScaledMetric(relativeTo: .body) var size_10: CGFloat = 10
    @ScaledMetric(relativeTo: .body) var size_16: CGFloat = 16
    private let buttonSize: CGFloat = 36

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationStack {
                // 使用修改后的 TextSelectionTextView，传入绑定变量
                TextSelectionTextView(text: text, shouldSelectAll: $shouldSelectAll)
            }
            
            // 右下角按钮区域（3个按钮：全选、复制、存为知识）
            HStack(spacing: 12) {
                // 全选按钮：点击后将 shouldSelectAll 置为 true
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
                
                // 存为知识按钮：点击后图标从“backpack.circle”切换到“checkmark.circle”
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
                
                // 复制按钮：点击后图标从“rectangle.on.rectangle.circle”切换到“checkmark.circle”
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
        .alert("保存失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // 复制操作：复制后状态切换2秒后恢复
    private func copyToClipboard() {
        UIPasteboard.general.string = text
        isCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isCopy = false
            }
        }
    }
    
    // 生成长数字 ID：yyyyMMddHHmmss + 4位随机数
    private func makeTimestampID() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyyMMddHHmmss"
        let dateString = formatter.string(from: Date())
        let randomSuffix = Int.random(in: 1_000...9_999)  // 4 位随机数
        return "\(dateString)\(randomSuffix)"
    }
    
    // 存为知识操作：若已保存，则直接显示编辑界面，否则保存后切换状态并延时恢复
    private func saveKnowledge() {
        if isSaved {
            isSheetPresented = true
            return
        }
        
        let newRecord = KnowledgeRecords()
        newRecord.content = text
        newRecord.lastEdited = Date()
        newRecord.name = "文本知识_\(makeTimestampID())"
        
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

// MARK: - AI 可编辑画布
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
    
    @State private var selectedReadingLevel = ""
    @State private var selectedLengthOption = ""
    @State private var selectedReadingLevelLabel = ""
    @State private var selectedLengthOptionLabel = ""
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
    
    // MARK: — Layout Metrics —
    @ScaledMetric(relativeTo: .body) private var size_10: CGFloat = 10
    @ScaledMetric(relativeTo: .body) private var size_16: CGFloat = 16
    private let buttonSize: CGFloat = 36
    
    @State private var lastSnapshotTime = Date()
    @State private var lastSnapshotText = ""
    private let minInterval: TimeInterval = 5    // 最少 5 秒
    private let limitInterval: TimeInterval = 1    // 最少 1 秒
    private let minDelta    = 20                 // 最少 20 字符
    
    // MARK: — Localization Helpers —
    private var isChinese: Bool {
        Locale.current.language.languageCode?.identifier == "zh"
    }
    
    private var readingLevels: [(label: String, value: String)] {
        isChinese
            ? [("启蒙水平","elementary"),("入门水平","beginner"),("基础水平","basic"),
               ("普通水平","intermediate"),("高级水平","advanced"),("大学水平","university"),
               ("专家水平","expert")]
            : [("Starter Mode","elementary"),("Beginner Mode","beginner"),("Basic Mode","basic"),
               ("Standard Mode","intermediate"),("Advanced Mode","advanced"),
               ("Academic Mode","university"),("Expert Mode","expert")]
    }
    
    private var lengthOptions: [(label: String, value: String)] {
        isChinese
            ? [("一句概括","one_line"),("极简版本","brief"),("简洁版本","concise"),
               ("适中长度","normal"),("扩展版本","expand"),("详细版本","elaborate"),
               ("完整版式","complete")]
            : [("One Line","one_line"),("Brief Style","brief"),("Concise Style","concise"),
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
                    ToolbarItemGroup(placement: .navigationBarLeading) { toolbarLeading() }
                    ToolbarItemGroup(placement: .navigationBarTrailing) { toolbarTrailing() }
                }
                .alert("确认删除画布内容？", isPresented: $showDeleteAlert) {
                    Button("删除", role: .destructive) {
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
                    Button("取消", role: .cancel) { }
                } message: {
                    Text("此操作会清空当前画布内容，无法撤销。")
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
        .alert("保存失败", isPresented: $showErrorAlert) {
            Button("确定", role: .cancel) {}
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
                        // 只在手动编辑且非 Python 流式输出时才记录
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
    private func toolbarLeading() -> some View {
        Menu {
            Button {
                isImpact.toggle()
                canvas.type = "text"
            } label: {
                Label("纯文本", systemImage: canvas.type == "text" ? "checkmark.circle" : "circle")
            }
            Button {
                isImpact.toggle()
                canvas.type = "python"
            } label: {
                Label("Python代码", systemImage: canvas.type == "python" ? "checkmark.circle" : "circle")
            }
            Button {
                isImpact.toggle()
                canvas.type = "html"
            } label: {
                Label("HTML代码", systemImage: canvas.type == "html" ? "checkmark.circle" : "circle")
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
                           value: [selectedReadingLevel.isEmpty,
                                   selectedLengthOption.isEmpty,
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
    
    private func truncatedMiddle(_ str: String, maxLength: Int = 6) -> String {
        let cleaned = str
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
        guard cleaned.count > maxLength else {
            return cleaned
        }
        let headCount = maxLength / 2
        let tailCount = maxLength - headCount
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
                
                TextField("对选中内容提出修改意见…", text: $selectedTextRevision)
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
                             ? ("编辑中...")
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
        
        // 4. Python / HTML / Edit
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
        selectedReadingLevel = ""
        selectedLengthOption = ""
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
        selectedReadingLevel = ""
        selectedLengthOption = ""
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
            ForEach(readingLevels, id: \.value) { level in
                Button {
                    isImpact.toggle()
                    withAnimation(nil) {
                        selectedReadingLevel = (selectedReadingLevel == level.value) ? "" : level.value
                        selectedReadingLevelLabel = (selectedReadingLevelLabel == level.label) ? "" : level.label
                    }
                } label: {
                    Label(level.label,
                          systemImage: selectedReadingLevel == level.value ? "checkmark.circle" : "circle")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "book")
                    .font(.system(size: size_16, weight: .medium))
                    .foregroundColor(.hlBluefont)
                if let sel = readingLevels.first(where: { $0.value == selectedReadingLevel }) {
                    Text(sel.label)
                        .font(.system(size: size_16))
                        .foregroundColor(.hlBluefont)
                        .lineLimit(1)
                        .fixedSize()
                        .layoutPriority(1)
                }
            }
            .padding(.horizontal, selectedReadingLevel.isEmpty ? 0 : size_10)
            .frame(width: selectedReadingLevel.isEmpty ? buttonSize : nil,
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
                        selectedLengthOption = (selectedLengthOption == level.value) ? "" : level.value
                        selectedLengthOptionLabel = (selectedLengthOptionLabel == level.label) ? "" : level.label
                    }
                } label: {
                    Label(level.label,
                          systemImage: selectedLengthOption == level.value ? "checkmark.circle" : "circle")
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.and.down.text.horizontal")
                    .font(.system(size: size_16, weight: .medium))
                    .foregroundColor(.hlBluefont)
                if let sel = lengthOptions.first(where: { $0.value == selectedLengthOption }) {
                    Text(sel.label)
                        .font(.system(size: size_16))
                        .foregroundColor(.hlBluefont)
                        .lineLimit(1)
                        .fixedSize()
                        .layoutPriority(1)
                }
            }
            .padding(.horizontal, selectedLengthOption.isEmpty ? 0 : size_10)
            .frame(width: selectedLengthOption.isEmpty ? buttonSize : nil,
                   height: buttonSize)
            .background(BlurView(style: .systemUltraThinMaterial)
                            .clipShape(Capsule())
                            .shadow(color: .hlBlue, radius: 1))
            .sensoryFeedback(.impact, trigger: isImpact)
        }
    }
    
    @ViewBuilder
    private func sendEditButton() -> some View {
        if !selectedReadingLevel.isEmpty || !selectedLengthOption.isEmpty {
            Button(action: sendEditRequest) {
                HStack(spacing: 4) {
                    Image(systemName: isEditingCanvas ? "sparkle" : "arrowtriangle.up.circle.fill")
                        .font(.system(size: size_16, weight: .medium))
                        .symbolEffect(.breathe)
                    Text(isEditingCanvas
                         ? ("编辑中...")
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
                       value: selectedReadingLevel.isEmpty && selectedLengthOption.isEmpty)
            .sensoryFeedback(.impact, trigger: isImpact)
        }
    }
    
    // MARK: — Actions —
    private func refineSelectedTextRequest() {
        isImpact.toggle()
        // 0. 前置检查
        guard !canvas.content.isEmpty,
              !selectedText.isEmpty,
              !selectedTextRevision.trimmingCharacters(in: .whitespaces).isEmpty
        else { return }

        // 1. 把全文拆成 prefix + selected + suffix
        let fullText = canvas.content
        guard let selRange = fullText.range(of: selectedText) else { return }
        let prefix = String(fullText[..<selRange.lowerBound])
        let suffix = String(fullText[selRange.upperBound...])

        // 2. 记录历史快照
        if canvas.history == nil {
            canvas.history = [fullText]
        } else if canvas.history!.last != fullText {
            canvas.history!.append(fullText)
        }

        // 3. 准备接收流式改写
        isEditingCanvas = true
        editedContent = prefix
        revisedSelectedText = ""

        // 4. 查 Key
        guard let apiInfo = allApiKeys.first(where: { $0.company == model.company }) else {
            errorMessage = isChinese ? "无法获取 API Key" : "API Key not found"
            showErrorAlert = true
            isEditingCanvas = false
            return
        }

        // 5. 启动流式任务
        Task {
            do {
                let stream = try await refineSelectedTextAPI(
                    fullText: fullText,
                    selectedText: selectedText,
                    suggestion: selectedTextRevision,
                    modelInfo: model,
                    apiKey: apiInfo.key ?? "",
                    requestURL: apiInfo.requestURL ?? ""
                )

                // 6. 动态接收 token 并更新 canvas.content
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

                // 7. 流结束后，写回历史 & 重置状态
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
              (!selectedReadingLevel.isEmpty || !selectedLengthOption.isEmpty) else { return }
        if canvas.history == nil { canvas.history = [canvas.content] }
        else if canvas.history!.last != canvas.content {
            canvas.history!.append(canvas.content)
        }
        isEditingCanvas = true
        editedContent = ""
        guard let apiInfo = allApiKeys.first(where: { $0.company == model.company }) else {
            errorMessage = isChinese ? "无法获取 API Key" : "API Key not found"
            showErrorAlert = true
            isEditingCanvas = false
            return
        }
        Task {
            do {
                let stream = try await editCanvasAPI(
                    input: canvas.content,
                    modelInfo: model,
                    readingLevel: selectedReadingLevelLabel,
                    lengthOption: selectedLengthOptionLabel,
                    apiKey: apiInfo.key ?? "",
                    requestURL: apiInfo.requestURL ?? ""
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
                    selectedReadingLevel = ""
                    selectedLengthOption = ""
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
                    pythonOutput = "执行失败：\(error.localizedDescription)"
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
        rec.name = "画布_\(canvas.title)_\(makeTimestampID())"
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
        fm.locale = Locale(identifier: "en_US_POSIX")
        fm.timeZone = .current
        fm.dateFormat = "yyyyMMddHHmmss"
        return fm.string(from: Date()) + "\(Int.random(in: 1000...9999))"
    }
}

// MARK: - 支持流式高亮、代码渲染和选区变色的 UITextView 包装
struct CanvasTextView: UIViewRepresentable {
    @Binding var text: String
    @Binding var highlightRange: NSRange?
    var isEditable: Bool
    var language: String
    @Binding var selectedText: String

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CanvasTextView
        var lastCode: String = ""
        /// 记录上次高亮的选区，用来清除它的颜色
        var previousSelection: NSRange?

        init(_ parent: CanvasTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ tv: UITextView) {
            // 1) 拼音／候选阶段不更新
            guard tv.markedTextRange == nil else { return }
            // 2) 只有真改变了才写回
            if parent.text != tv.text {
                parent.text = tv.text
            }
        }

        func textViewDidChangeSelection(_ tv: UITextView) {
            let nsRange = tv.selectedRange
            let textLen = tv.textStorage.length

            // 1) 安全地清除上次选区的高亮
            if let prev = previousSelection {
                // 如果 prev.location 超出，直接忽略
                if prev.location < textLen {
                    // 裁剪 length
                    let safeLen = min(prev.length, textLen - prev.location)
                    tv.textStorage.removeAttribute(.foregroundColor,
                                                  range: NSRange(location: prev.location, length: safeLen))
                }
                previousSelection = nil
            }

            // 2) 给新选区加色（前提 length > 0 且在 bounds 内）
            if nsRange.length > 0 && nsRange.location < textLen {
                let safeLen = min(nsRange.length, textLen - nsRange.location)
                let safeRange = NSRange(location: nsRange.location, length: safeLen)
                tv.textStorage.addAttribute(.foregroundColor,
                                            value: UIColor.hlBluefont,
                                            range: safeRange)
                previousSelection = safeRange
            } else {
                previousSelection = nil
            }

            // 3) 把被选中的文本回调出去
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

        // 初始字体 & 文本
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
        
        // **拼音候选阶段，不要重置 text / 光标**
        if uiView.markedTextRange != nil {
            return
        }

        // 1) 先把当前的选区存下来（可能越界，但我们先记原始值）
        let originalRange = uiView.selectedRange

        // 用一个 helper，每次要恢复选区时再做 bounds‐check
        func restoreCursor() {
            let total = uiView.text.utf16.count
            // location 最多只能到 total
            let loc = min(originalRange.location, total)
            // length 最多只能到剩下的最大长度
            let maxLen = total - loc
            let len = max(0, min(originalRange.length, maxLen))
            uiView.selectedRange = NSRange(location: loc, length: len)
        }

        // 2) 根据模式分两路
        if language != "text" {
            // 2a) 代码/HTML 高亮走异步
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
                        // 如果 mid‐flight 又被新文本打断，就不再应用
                        guard coord.lastCode == text else { return }
                        uiView.attributedText = highlighted
                        // 保持 monospaced
                        let size = UIFont.preferredFont(forTextStyle: .footnote).pointSize
                        uiView.font = .monospacedSystemFont(ofSize: size, weight: .regular)
                        // **异步完成时再“安全恢复”**
                        restoreCursor()
                    }
                }
            }
            // 别在这里 restore，让异步高亮那一端去做
        } else {
            // 2b) 纯文本：立刻同步更新并恢复
            if uiView.text != text {
                uiView.text = text
            }
            restoreCursor()
        }

        // 3) 插入高亮动画时也不要 touch 选区
        if let range = highlightRange {
            DispatchQueue.main.async {
                coord.parent.highlightRange = nil
                animateInsertion(in: uiView, range: range)
            }
        }
    }

    /// 流式插入时的高亮动画
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


// MARK: 多行输入抽屉
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
            estimatedTokens = estimateTokens(for: message)
        }
    }

    // MARK: - 输入框区域
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
        .padding(12)
        .background(
            BlurView(style: .systemThinMaterial) // 毛玻璃背景
                .clipShape(RoundedRectangle(cornerRadius: 26))
                .shadow(color: .hlBlue, radius: 1)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.4), value: showPhotoSourceOptions)
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

    // MARK: - 收起按钮
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

    // MARK: - 计算 Token 数量
    private func tokenCounter() -> some View {
        VStack(alignment: .trailing) {
            Text("\(message.count) 字").font(.caption).foregroundColor(.gray)
            Text("约 \(estimatedTokens) tokens").font(.caption).foregroundColor(.gray)
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
                        let optimizer = SystemOptimizer(context: self.context)
                        optimizedMessage = try await optimizer.optimizePrompt(inputPrompt: message)
                        message = optimizedMessage
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
                    message = original
                }
                translated = false
            } else {
                translated = false
                isTranslating = true // 开始优化
                original = message // 保留原句
                if !message.isEmpty {
                    do {
                        let optimizer = SystemOptimizer(context: self.context)
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
                let optimizer = SystemOptimizer(context: self.context)
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
            Text("采样温度参数调节 (temperature)")
                .font(.headline)
            Text("说明：采样温度参数影响模型的创造性和稳定性：温度越高，生成内容更有创意但易出错；温度越低，回答更保守稳定。默认为不设置。")
                .font(.caption)
                .multilineTextAlignment(.leading)

            Gauge(value: Double(selectedIndex), in: 0...Double(values.count - 1)) {
                Text("")
            } currentValueLabel: {
                if values[selectedIndex] == -999 {
                    Text("不设置")
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
                    Text("当前：")
                    if values[selectedIndex] == -999 {
                        Text("不设置").foregroundColor(.secondary)
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
            Text("累积概率参数调节 (top_p)")
                .font(.headline)
            Text("说明：累积概率控制选择的词汇范围，较低时限制了生成的多样性，较高时生成的文本更加开放和多样。默认为不设置。")
                .font(.caption)
                .multilineTextAlignment(.leading)

            Gauge(value: Double(selectedIndex), in: 0...Double(values.count - 1)) {
                Text("")
            } currentValueLabel: {
                if values[selectedIndex] == -999 {
                    Text("不设置")
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
                    Text("当前：")
                    if values[selectedIndex] == -999 {
                        Text("不设置").foregroundColor(.secondary)
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
            Text("最大回复长度调节 (max_tokens)")
                .font(.headline)
            Text("说明：用于控制模型生成的回复中最多包含多少个词元（tokens）。通过设置 max_tokens，可以限制生成文本的长度，确保其符合预期的长度要求。默认为不设置。")
                .font(.caption)
                .multilineTextAlignment(.leading)

            Gauge(value: Double(selectedIndex), in: 0...Double(values.count - 1)) {
                Text("")
            } currentValueLabel: {
                if values[selectedIndex] == -999 {
                    Text("不设置")
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
                    Text("当前：")
                    if values[selectedIndex] == -999 {
                        Text("不设置").foregroundColor(.secondary)
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

    /// 最后一个元素 -999 表示“不设置”
    private let values: [Int]

    init(value: Binding<Int>) {
        self._value = value
        self.values = [5, 10, 20, 30, 40, 50, 60, 70, 80, -999]
        // 如果外部传入的 value 不在列表中，则默认选中 20（index = 2）
        let initial = self.values.firstIndex(of: value.wrappedValue) ?? 2
        self._selectedIndex = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("消息数量上限")
                .font(.headline)

            Text("""
                说明：消息数量上限用于控制传入的对话数量，其作用在于合理控制上下文长度，避免因消息过多导致系统处理复杂、资源消耗大以及用户体验受影响等问题，默认值为 20。
                """)
                .font(.caption)
                .multilineTextAlignment(.leading)

            // 用 Gauge 展示当前选择的“进度”
            Gauge(value: Double(selectedIndex), in: 0...Double(values.count - 1)) {
                Text("")
            } currentValueLabel: {
                if values[selectedIndex] == -999 {
                    Text("不设置")
                } else {
                    Text("\(values[selectedIndex])")
                }
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .scaleEffect(1.2)
            .padding(.vertical, 8)
            .tint(.hlBluefont)

            // 用 Stepper 进行离散选择
            Stepper {
                HStack {
                    Text("当前：")
                    if values[selectedIndex] == -999 {
                        Text("不设置")
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
    var topLeft: CGFloat = 0
    var topRight: CGFloat = 0
    var bottomLeft: CGFloat = 0
    var bottomRight: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        // 限制半径不超过宽高一半
        let tl = min(min(topLeft, rect.width / 2), rect.height / 2)
        let tr = min(min(topRight, rect.width / 2), rect.height / 2)
        let bl = min(min(bottomLeft, rect.width / 2), rect.height / 2)
        let br = min(min(bottomRight, rect.width / 2), rect.height / 2)

        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY

        let path = CGMutablePath()
        // 起点放在左上边，偏移 tl，使下段线、弧线自动衔接
        path.move(to: CGPoint(x: minX + tl, y: minY))

        // top edge → top-right corner
        path.addLine(to: CGPoint(x: maxX - tr, y: minY))
        path.addArc(tangent1End: CGPoint(x: maxX, y: minY),
                    tangent2End: CGPoint(x: maxX, y: minY + tr),
                    radius: tr)

        // right edge → bottom-right corner
        path.addLine(to: CGPoint(x: maxX, y: maxY - br))
        path.addArc(tangent1End: CGPoint(x: maxX, y: maxY),
                    tangent2End: CGPoint(x: maxX - br, y: maxY),
                    radius: br)

        // bottom edge → bottom-left corner
        path.addLine(to: CGPoint(x: minX + bl, y: maxY))
        path.addArc(tangent1End: CGPoint(x: minX, y: maxY),
                    tangent2End: CGPoint(x: minX, y: maxY - bl),
                    radius: bl)

        // left edge → back to top-left corner
        path.addLine(to: CGPoint(x: minX, y: minY + tl))
        path.addArc(tangent1End: CGPoint(x: minX, y: minY),
                    tangent2End: CGPoint(x: minX + tl, y: minY),
                    radius: tl)

        path.closeSubpath()

        return Path(path)
    }
}

struct SystemMessageSettingsView: View {
    // 绑定变量：是否使用默认系统消息、以及自定义的系统消息内容
    @Binding var useSystemMessage: Bool
    @Binding var systemMessage: String
    
    // 关闭当前视图的环境变量（通常用于 sheet 的 dismiss）
    @Environment(\.dismiss) private var dismiss
    
    // 辅助输入状态
    @State private var isFeedBack: Bool = false
    @State private var voiceExpanded: Bool = false
    @State private var inputExpanded: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                // 系统提示词设置
                Section(header: Text("选择系统提示词")) {
                    Picker("提示词设置", selection: $useSystemMessage) {
                        Text("默认系统消息").tag(true)
                        Text("自定义系统消息").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .listRowBackground(Color.clear)
                }
                
                // 如果不使用默认系统消息，则展示编辑区域
                if !useSystemMessage {
                    Section(header: Text("编辑 System 角色消息")) {
                        TextEditor(text: $systemMessage)
                            .frame(height: 300)
                        
                        HStack(spacing: 8) {
                            Text("输入工具")
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
                    // 使用默认系统消息时的提示
                    Section(header: Text("使用默认提示词")) {
                        Text("推荐使用默认系统消息，AI翰林院专为群聊对话模式优化。")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // 说明文字
                Section(header: Text("说明")) {
                    Text("这里设定的 System 角色的消息在大模型中起着至关重要的作用，通常用于设定对话的上下文、风格、身份与行为边界，是构建高质量对话系统的关键机制之一。")
                }
            }
            .navigationTitle("系统消息设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 取消按钮：点击后关闭视图
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                // 保存按钮：此处可添加额外逻辑保存数据，示例中仅关闭视图
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        // 若需要保存数据，可在此处调用相关方法
                        dismiss()
                    }
                }
            }
            // 辅助输入：文本输入 Sheet
            .sheet(isPresented: $inputExpanded) {
                BottomSheetView(message: $systemMessage, isExpanded: $inputExpanded)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            // 辅助输入：语音输入 Sheet
            .sheet(isPresented: $voiceExpanded) {
                VoiceInputView(message: $systemMessage, voiceExpanded: $voiceExpanded)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}


/// 语音消息播放及波形展示组件（包含静态波形采样与播放进度）
struct AudioMessageView: View {
    let asset: AudioAsset    // 包含音频 Data 的模型

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
                
                Text("语音由\(asset.modelName)生成")
                    .font(.caption2)
                    .foregroundColor(isPlaying ? .hlBluefont : .gray)
                    .lineLimit(1)
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

    // 播放器初始化
    private func setupPlayer() {
        do {
            let p = try AVAudioPlayer(data: asset.data)
            p.isMeteringEnabled = true
            p.enableRate = true
            p.rate = playbackRate
            p.prepareToPlay()

            // 持有代理，防止被释放
            let proxy = DelegateProxy {
                isPlaying = false
                progress = 0
                meterTimer?.invalidate()
            }
            p.delegate = proxy
            playerDelegate = proxy

            player = p
        } catch {
            print("AudioMessageView: 无法初始化播放器：\(error)")
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
        // 如果已经初始化了播放器，就立刻生效
        player?.rate = playbackRate
    }

    // 播放 / 暂停 切换
    private func togglePlayPause() {
        guard let p = player else { return }
        meterTimer?.invalidate()

        if p.isPlaying {
            p.pause()
            isPlaying = false
        } else {
            p.play()
            isPlaying = true

            // 定时更新播放进度，闭包运行在主线程，可以直接修改 @State
            meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                guard let p = player else {
                    meterTimer?.invalidate()
                    return
                }
                // 计算进度并赋值
                let newProgress = p.duration > 0 ? p.currentTime / p.duration : 0
                self.progress = newProgress
            }
        }
    }

    // 静态振幅采样
    private static func makeAmplitudes(from audioData: Data, samples: Int) -> [Float] {
        // 写入临时文件
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("\(UUID().uuidString).m4a")
        try? audioData.write(to: tmpURL)

        // 读取为 PCM buffer
        guard let file = try? AVAudioFile(forReading: tmpURL),
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
        let frameCount = Int(buffer.frameLength)
        let chunkSize = max(1, frameCount / samples)

        // 构造 UnsafeBufferPointer 方便切片
        let ptr = UnsafeBufferPointer(start: channelData, count: frameCount)

        // 分段取峰值
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

    // 静态波形视图
    struct ChatWaveBarsView: View {
        let amplitudes: [Float]
        let progress: Double         // 0…1
        /// 点击或拖拽到新位置时回调新的 progress
        var onSeek: (Double) -> Void

        // 样式
        let barSpacing: CGFloat = 2
        let playedColor: Color = .hlBluefont
        let unplayedColor: Color = Color.gray.opacity(0.3)

        var body: some View {
            GeometryReader { geo in
                let total = amplitudes.count
                guard total > 0 else { return AnyView(EmptyView()) }

                // 计算播放到哪根柱子
                let playedCount = Int(Double(total) * progress)
                // 计算柱子宽度
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
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .bottomLeading)
                    // 扩大点击区域
                    .contentShape(Rectangle())
                    // 零距离拖拽手势，结束时计算位置并回调
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

    // 播放结束代理
    private class DelegateProxy: NSObject, AVAudioPlayerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            onFinish()
        }
    }
}
