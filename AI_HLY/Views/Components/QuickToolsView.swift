//
//  QuickToolsView.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 27/2/25.
//

import SwiftUI
import NaturalLanguage
import SwiftData
import MarkdownUI
import Foundation

//MARK: 翻译工具
struct TranslationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query var allApiKeys: [APIKeys]
    
    @Query(filter: #Predicate<AllModels> {
        !$0.isHidden && $0.supportsTextGen
    }, sort: [SortDescriptor(\.position)])
    var filteredModels: [AllModels]
    
    @Query private var translationDictionary: [TranslationDic]
    @StateObject private var tts = TextToSpeech() // 持续保留实例
    @FocusState private var isInputActive: Bool

    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    @State private var sourceLanguage: String = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true ? "自动检测" : "Auto Detect"
    @State private var targetLanguage: String = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true ? "自动检测" : "Auto Detect"
    @State private var selectedModel: AllModels? = nil // 默认值设为 nil
    @State private var isTranslating: Bool = false
    @State private var showCopySuccess: Bool = false
    @State private var isCopy: Bool = false
    @State private var isFeedBack: Bool = false
    @State private var isSelect: Bool = false
    @State private var isSuccess: Bool = false
    @State private var isTextSelectionSheetPresented: Bool = false // 文本选择
    @State private var isShowTranslationDicView: Bool = false
    @State private var debounceTask: DispatchWorkItem?

    let languageOptions = [
        "自动检测", "简体中文", "简体中文（新加坡）", "文言文", "繁体中文", "繁体中文（台湾）", "繁体中文（香港）",
        "粤语", "上海话", "四川话", "美式英语", "英式英语", "英语", "日语", "韩语", "俄语", "法语", "德语",
        "葡萄牙语", "西班牙语", "阿拉伯语", "泰米尔语", "斯瓦希里语", "缅甸语", "希腊语", "马来语", "希伯来语",
        "土耳其语", "泰语", "越南语", "Emoji文"
    ]
    
    let languageOptions_en = [
        "Auto Detect", "Simplified Chinese", "Simplified Chinese (Singapore)", "Classical Chinese", "Traditional Chinese",
        "Traditional Chinese (Taiwan)", "Traditional Chinese (Hong Kong)", "Cantonese", "Shanghainese", "Sichuanese",
        "American English", "British English", "English", "Japanese", "Korean", "Russian", "French", "German",
        "Portuguese", "Spanish", "Arabic", "Tamil", "Swahili", "Burmese", "Greek", "Malay", "Hebrew",
        "Turkish", "Thai", "Vietnamese", "Emoji Text"
    ]
    
    private var isChinese: Bool {
        Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                
                HStack {
                    Image("translate")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.hlBluefont)
                    Text("Translation")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.hlBluefont)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.vertical)
                
                VStack(spacing: 10) {
                    // 选择原文本语言
                    HStack {
                        Picker("Existing text", selection: $sourceLanguage) {
                            ForEach(isChinese ? languageOptions : languageOptions_en, id: \.self) { language in
                                Text(language)
                            }
                        }
                        .pickerStyle(.menu)
                        Spacer()
                    }
                    
                    // 输入框
                    TextEditor(text: $inputText)
                        .padding(10)
                        .frame(height: 100)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .focused($isInputActive)
                        .onChange(of: inputText) {
                            if !inputText.isEmpty {
                                detectLanguage(for: inputText)
                            } else {
                                sourceLanguage = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true ? "自动检测" : "Auto Detect"
                                targetLanguage = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true ? "自动检测" : "Auto Detect"
                            }
                        }
                    
                    // 翻译模型选择 & 翻译按钮
                    HStack {
                        ScrollViewReader { scrollViewProxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    let visibleModels = filteredModels
                                    ForEach(visibleModels, id: \.id) { model in
                                        Button(action: {
                                            isSelect.toggle()
                                            selectedModel = model
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0.3)) {
                                                scrollViewProxy.scrollTo(model.id, anchor: .center)
                                            }
                                        }) {
                                            toolModelButton(for: model, isSelected: selectedModel?.id == model.id, color: .hlBluefont)
                                        }
                                        .padding(.trailing, model.id == visibleModels.last?.id ? nil : 0)
                                        .sensoryFeedback(.selection, trigger: isSelect)
                                    }
                                }
                            }
                            .cornerRadius(20)
                        }
                        
                        // 翻译按钮
                        Button(action: {
                            isFeedBack.toggle()
                            translateText()
                        }) {
                            if isTranslating {
                                ProgressView()
                                    .frame(width: 32, height: 32)
                                    .padding(8)
                            } else {
                                Image(systemName: "arrowtriangle.down.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(Color(.hlBluefont))
                                    .padding(8)
                            }
                        }
                        .background(Color(.hlBluefont).opacity(0.1))
                        .clipShape(Circle())
                        .buttonStyle(.plain)
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                    }
                    
                    // 选择目标语言
                    HStack {
                        Picker("Target text", selection: $targetLanguage) {
                            ForEach(isChinese ? languageOptions : languageOptions_en, id: \.self) { language in
                                Text(language)
                            }
                        }
                        .pickerStyle(.menu)
                        Spacer()
                    }
                    
                    // 输出框
                    ScrollView {
                        Markdown(translatedText.isEmpty ? "" : translatedText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .frame(minHeight: 100)
                    .cornerRadius(20)
                    
                    // 翻译提供方 & 选择、复制、朗读按钮
                    HStack (spacing: 10) {
                        Text("由 \(selectedModel?.displayName ?? "未知模型") 提供翻译")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // 文本选择
                        Button(action: {
                            isTextSelectionSheetPresented = true
                        }) {
                            Image(systemName: "text.redaction")
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 24, height: 24)
                                .foregroundColor(.secondary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(translatedText.isEmpty)
                        .sheet(isPresented: $isTextSelectionSheetPresented) {
                            TextSelectionView(text: translatedText)
                        }
                        
                        // 语音朗读
                        Button(action: {
                            tts.setContextIfNeeded(modelContext)
                            tts.updateSelectedModel()
                            tts.toggleSpeech(text: translatedText)
                        }) {
                            if tts.isAsking {
                                ProgressView()
                                    .scaledToFit()
                                    .padding(2)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.secondary)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: tts.isSpeaking ? "pause.circle" : "waveform")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(tts.isSpeaking ? Color(.systemRed) : .secondary)
                                    .clipShape(Circle())
                                    .scaleEffect(tts.isSpeaking ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tts.isSpeaking)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(translatedText.isEmpty)
                        
                        // 复制按钮
                        Button(action: copyToClipboard) {
                            Image(systemName: isCopy ? "checkmark.circle" : "square.on.square")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isCopy ? Color(.systemGreen) : .secondary)
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                .scaleEffect(isCopy ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopy)
                        }
                        .buttonStyle(.plain)
                        .disabled(translatedText.isEmpty)
                        .sensoryFeedback(.success, trigger: isSuccess)
                    }
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)
                    .padding(.top)
                }
                .padding()
                .background(
                    BlurView(style: .systemUltraThinMaterial) // 毛玻璃背景
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .hlBluefont, radius: 1)
                )
                
                Button(action: {
                    // 打开 TranslationDicView
                    isShowTranslationDicView = true // 可替换为你自己的呈现逻辑
                }) {
                    Label("Translation Dictionary", systemImage: "character.book.closed")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(.hlBluefont)
                        .background(
                            BlurView(style: .systemUltraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .hlBlue, radius: 1)
                        )
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $isShowTranslationDicView) {
                    TranslationDicView() // 确保你已经定义好此视图
                }
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Reminder: Instant features do not save your data. Please back up important information in time!")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding()
                }
            }
            .padding()
        }
        .onAppear {
            updateSelectedModel()
        }
        .onChange(of: filteredModels) {
            updateSelectedModel()
        }
    }
    
    private func updateSelectedModel() {
        if selectedModel == nil, let firstModel = filteredModels.first {
            selectedModel = firstModel
        }
    }
    
    // 翻译函数（流式输出版）
    private func translateText() {
        guard !inputText.isEmpty, let selectedModel = selectedModel else {
            translatedText = "请选择一个翻译模型"
            return
        }
        
        isTranslating = true
        translatedText = ""
        isInputActive = false

        Task {
            do {
                // 1. 获取模型信息
                guard let apiInfo = allApiKeys.first(where: { $0.company == selectedModel.company }) else {
                    throw NSError(domain: "TranslationView", code: 404, userInfo: [NSLocalizedDescriptionKey: "无法获取 API Key"])
                }
                
                // 检索翻译词典（逻辑保持不变）
                let isChinese = Locale.preferredLanguages.first?.hasPrefix("zh") ?? true
                let matchedItems = translationDictionary.compactMap { entry -> String? in
                    guard let one = entry.contentOne?.trimmingCharacters(in: .whitespacesAndNewlines),
                          let two = entry.contentTwo?.trimmingCharacters(in: .whitespacesAndNewlines),
                          !one.isEmpty, !two.isEmpty else {
                        return nil
                    }
                    
                    let lowerInput = inputText.lowercased()
                    let oneLower = one.lowercased()
                    let twoLower = two.lowercased()
                    
                    if lowerInput.contains(oneLower) {
                        return isChinese ? "\"\(one)\" 应翻译为 \"\(two)\"" : "\"\(one)\" should be translated as \"\(two)\""
                    } else if lowerInput.contains(twoLower) {
                        return isChinese ? "\"\(two)\" 应翻译为 \"\(one)\"" : "\"\(two)\" should be translated as \"\(one)\""
                    } else {
                        return nil
                    }
                }
                
                let translationMatters = matchedItems.isEmpty
                    ? ""
                    : (isChinese
                        ? "\n请严格遵循以下翻译规则：" + matchedItems.joined(separator: "；")
                        : "\nPlease follow the translation rules: " + matchedItems.joined(separator: "; "))
                
                // 2. 调用流式翻译 API
                let stream = try await translateTextAPI(
                    input: inputText,
                    sourceLanguage: sourceLanguage,
                    modelInfo: selectedModel,
                    targetLanguage: targetLanguage,
                    translationMatters: translationMatters,
                    apiKey: apiInfo.key ?? "Unknown",
                    requestURL: apiInfo.requestURL ?? "Unknown"
                )
                
                // 3. 遍历流式输出，实时更新翻译内容
                for try await token in stream {
                    await MainActor.run {
                        translatedText.append(token)
                    }
                }
                
                await MainActor.run {
                    isTranslating = false
                }
            } catch {
                await MainActor.run {
                    translatedText = "翻译失败: \(error.localizedDescription)"
                    isTranslating = false
                }
            }
        }
    }
    
    // 复制
    private func copyToClipboard() {
        guard !translatedText.isEmpty else { return }
        
        UIPasteboard.general.string = translatedText
        isSuccess.toggle()
        isCopy = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isCopy = false
        }
    }
    
    // 语言识别
    private func detectLanguage(for text: String) {
        guard !text.isEmpty else { return } // 避免短文本干扰
        debounceTask?.cancel() // 取消上一个未完成的任务
        
        let task = DispatchWorkItem { [text] in
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(text)

            let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
            let isChinese = currentLanguage.hasPrefix("zh")

            let languageMapping: [NLLanguage: (zh: String, en: String)] = [
                .traditionalChinese: ("繁体中文", "Traditional Chinese"),
                .simplifiedChinese: ("简体中文", "Simplified Chinese"),
                .english: ("英语", "English"),
                .japanese: ("日语", "Japanese"),
                .korean: ("韩语", "Korean"),
                .russian: ("俄语", "Russian"),
                .french: ("法语", "French"),
                .german: ("德语", "German"),
                .portuguese: ("葡萄牙语", "Portuguese"),
                .spanish: ("西班牙语", "Spanish"),
                .arabic: ("阿拉伯语", "Arabic"),
                .tamil: ("泰米尔语", "Tamil"),
                .burmese: ("缅甸语", "Burmese"),
                .greek: ("希腊语", "Greek"),
                .malay: ("马来语", "Malay"),
                .hebrew: ("希伯来语", "Hebrew"),
                .turkish: ("土耳其语", "Turkish"),
                .thai: ("泰语", "Thai"),
                .vietnamese: ("越南语", "Vietnamese")
            ]

            if let detectedLanguage = recognizer.dominantLanguage, let mapped = languageMapping[detectedLanguage] {
                DispatchQueue.main.async {
                    sourceLanguage = isChinese ? mapped.zh : mapped.en
                    targetLanguage = isChinese ? (mapped.zh.contains("中文") ? "英语" : "简体中文") : (mapped.en == "English" ? "Simplified Chinese" : "English")
                }
            }
        }
        debounceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task) // 500ms debounce
    }
}

//MARK: 润色工具
struct PolishView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query var allApiKeys: [APIKeys]
    @Query(filter: #Predicate<AllModels> {
        !$0.isHidden && $0.supportsTextGen
    }, sort: [SortDescriptor(\.position)])
    var filteredModels: [AllModels]
    
    @StateObject private var tts = TextToSpeech() // 持续保留实例
    @FocusState private var isInputActive: Bool
    @FocusState private var isFormatActive: Bool
    
    @State private var inputText: String = ""
    @State private var polishedText: String = ""
    @State private var selectedFormats: [[String: String]] = []
    @State private var selectedModel: AllModels? = nil // 默认值设为 nil
    @State private var isPolish: Bool = false
    @State private var showCopySuccess: Bool = false
    @State private var isCopy: Bool = false
    @State private var isFeedBack: Bool = false
    @State private var isSelect: Bool = false
    @State private var isSuccess: Bool = false
    @State private var isTextSelectionSheetPresented: Bool = false // 文本选择
    @State private var formatText: String = ""
    @State private var polishOptions: [[String: String]] = []
    
    private func loadPolishOptions() -> [[String: String]] {
        let currentLanguage = Locale.preferredLanguages.first ?? "en"
        let languageKey = currentLanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        
        guard let url = Bundle.main.url(forResource: "Refinement", withExtension: "json") else {
            print("Refinement.json 文件未找到")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let optionsDict = try JSONDecoder().decode([String: [[String: String]]].self, from: data)
            return optionsDict[languageKey] ?? optionsDict["en"] ?? []
        } catch {
            print("解析 Refinement.json 失败: \(error)")
            return []
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                
                HStack {
                    Image(systemName: "wand.and.sparkles.inverse")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.hlGreen)
                    Text("Refinement")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.hlGreen)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.vertical)
                
                VStack(spacing: 10) {
                    // 选择原文本
                    HStack {
                        Text("Existing Text")
                        Spacer()
                    }
                    .padding(.top)
                    
                    // 输入框
                    TextEditor(text: $inputText)
                        .padding(10)
                        .frame(height: 100)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .focused($isInputActive)
                    
                    HStack {
                        Text("Refinement Requirements")
                            .padding(.top, 5)
                        Spacer()
                    }
                    // 内容选择区
                    Section(header: Text("Content Styles")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                    ) {
                        selectionGrid(for: "content")
                    }

                    // 格式选择区
                    Section(header: Text("Formatting Standards")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                    ) {
                        selectionGrid(for: "format")
                    }

                    // 长度选择区
                    Section(header: Text("Content Length")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                    ) {
                        selectionGrid(for: "length")
                    }
                    
                    Section(header: Text("Special Requests")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                    ) {
                        TextField("Request Description…", text: $formatText)
                            .focused($isFormatActive)
                            .disabled(isPolish)
                            .padding()
                            .frame(height: 40)
                            .background(Color(.systemGray).opacity(0.1))
                            .cornerRadius(20)
                    }
                    
                    // 模型选择 & 润色按钮
                    Section(header: Text("Model Selection")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                    ) {
                        HStack {
                            ScrollViewReader { scrollViewProxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        let visibleModels = filteredModels
                                        ForEach(visibleModels, id: \.id) { model in
                                            Button(action: {
                                                isSelect.toggle()
                                                selectedModel = model
                                                withAnimation(.spring(response: 0.5, dampingFraction: 0.75, blendDuration: 0.3)) {
                                                    scrollViewProxy.scrollTo(model.id, anchor: .center)
                                                }
                                            }) {
                                                toolModelButton(for: model, isSelected: selectedModel?.id == model.id, color: .hlGreen)
                                            }
                                            .padding(.trailing, model.id == visibleModels.last?.id ? nil : 0)
                                            .sensoryFeedback(.selection, trigger: isSelect)
                                        }
                                    }
                                }
                                .cornerRadius(20)
                            }
                            
                            // 润色按钮
                            Button(action: {
                                isFeedBack.toggle()
                                polishText()
                            }) {
                                if isPolish {
                                    ProgressView()
                                        .frame(width: 32, height: 32)
                                        .padding(8)
                                } else {
                                    Image(systemName: "arrowtriangle.down.circle.fill")
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .foregroundColor(Color(.hlGreen))
                                        .padding(8)
                                }
                            }
                            .background(Color(.hlGreen).opacity(0.1))
                            .clipShape(Circle())
                            .buttonStyle(.plain)
                            .sensoryFeedback(.impact, trigger: isFeedBack)
                        }
                    }
                    
                    // 润色文本
                    HStack {
                        Text("Refine Text")
                        Spacer()
                    }
                    
                    // 输出框
                    ScrollView {
                        Markdown(polishedText.isEmpty ? "" : polishedText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .frame(minHeight: 100)
                    .cornerRadius(20)
                    
                    // 选择 & 朗读 & 复制
                    HStack (spacing: 10) {
                        Text("由 \(selectedModel?.displayName ?? "未知模型") 提供润色")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Button(action: {
                            isTextSelectionSheetPresented = true
                        }) {
                            Image(systemName: "text.redaction")
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 24, height: 24)
                                .foregroundColor(.secondary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(polishedText.isEmpty)
                        .sheet(isPresented: $isTextSelectionSheetPresented) {
                            TextSelectionView(text: polishedText)
                        }
                        Button(action: {
                            tts.setContextIfNeeded(modelContext)
                            tts.updateSelectedModel()
                            tts.toggleSpeech(text: polishedText)
                        }) {
                            if tts.isAsking {
                                ProgressView()
                                    .scaledToFit()
                                    .padding(2)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.secondary)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: tts.isSpeaking ? "pause.circle" : "waveform")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(tts.isSpeaking ? Color(.systemRed) : .secondary)
                                    .clipShape(Circle())
                                    .scaleEffect(tts.isSpeaking ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tts.isSpeaking)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(polishedText.isEmpty)
                        
                        Button(action: copyToClipboard) {
                            Image(systemName: isCopy ? "checkmark.circle" : "square.on.square")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isCopy ? Color(.systemGreen) : .secondary)
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                .scaleEffect(isCopy ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopy)
                        }
                        .buttonStyle(.plain)
                        .disabled(polishedText.isEmpty)
                        .sensoryFeedback(.success, trigger: isSuccess)
                    }
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)
                    .padding(.top)
                }
                .padding()
                .background(
                    BlurView(style: .systemUltraThinMaterial) // 毛玻璃背景
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .hlGreen, radius: 1)
                )
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Reminder: Instant features do not save your data. Please back up important information in time!")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding()
                }
            }
            .padding()
            .tint(.hlGreen)
        }
        .onAppear {
            polishOptions = loadPolishOptions()
            if selectedModel == nil, let firstModel = filteredModels.first {
                selectedModel = firstModel
            }
        }
    }
    
    // polishText()（流式输出版）
    private func polishText() {
        guard !inputText.isEmpty, let selectedModel = selectedModel else { return }

        isPolish = true
        polishedText = ""
        
        // 关闭键盘焦点，避免焦点竞争
        isInputActive = false
        isFormatActive = false

        Task {
            do {
                // 获取模型信息
                guard let apiInfo = allApiKeys.first(where: { $0.company == selectedModel.company }) else {
                    throw NSError(domain: "PolishView", code: 404, userInfo: [NSLocalizedDescriptionKey: "无法获取 API Key"])
                }
                
                // 拼接提示信息：先合并所有选中提示，再加上用户自定义要求
                var selectedPrompts = selectedFormats.map { $0["prompt"] ?? "" }.joined(separator: "\n")
                if !formatText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    selectedPrompts += "\n用户特别要求: \(formatText)"
                }
                
                // 调用润色 API（流式）
                let stream = try await polishTextAPI(
                    input: inputText,
                    modelInfo: selectedModel,
                    prompts: selectedPrompts,
                    apiKey: apiInfo.key ?? "",
                    requestURL: apiInfo.requestURL ?? "Unknown"
                )
                
                // 遍历流数据，实时更新润色文本
                for try await token in stream {
                    await MainActor.run {
                        polishedText.append(token)
                    }
                }
                
                await MainActor.run {
                    isPolish = false
                }
            } catch {
                await MainActor.run {
                    polishedText = "润色失败: \(error.localizedDescription)"
                    isPolish = false
                }
            }
        }
    }
    
    // 多选内容（每个分类仅允许选一个）
    private func selectionGrid(for type: String) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(polishOptions.filter { $0["type"] == type }, id: \.self) { option in
                Button(action: {
                    isSelect.toggle()
                    toggleSelection(option)
                }) {
                    Text(option["name"]!)
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, minHeight: 40) // 统一高度
                        .background(isSelected(option) ? Color(.hlGreen).opacity(0.1) : Color(.systemGray).opacity(0.1))
                        .foregroundColor(isSelected(option) ? Color.hlGreen : .gray)
                        .cornerRadius(20)
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.selection, trigger: isSelect)
            }
        }
    }

    // 检查某个选项是否已被选中
    private func isSelected(_ option: [String: String]) -> Bool {
        return selectedFormats.contains { $0["name"] == option["name"] }
    }

    // 选择逻辑（保证每个类别下只能选一个，且点击已选中的取消选中）
    private func toggleSelection(_ option: [String: String]) {
        Task { @MainActor in
            isInputActive = false
            isFormatActive = false
        }
        
        let type = option["type"] ?? ""

        // 如果当前选项已被选中，则取消选择
        if let index = selectedFormats.firstIndex(where: { $0["name"] == option["name"] }) {
            selectedFormats.remove(at: index)
        } else {
            // 先移除相同类别的选项
            selectedFormats.removeAll { $0["type"] == type }
            // 再添加当前选中的选项
            selectedFormats.append(option)
        }
    }
    
    // 复制
    private func copyToClipboard() {
        UIPasteboard.general.string = polishedText
        isCopy = true
        isSuccess.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isCopy = false
        }
    }
}

//MARK: 摘要工具
struct SummaryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query var allApiKeys: [APIKeys]
    
    @Query(filter: #Predicate<AllModels> {
        !$0.isHidden && $0.supportsTextGen
    }, sort: [SortDescriptor(\.position)])
    var filteredModels: [AllModels]
    
    @StateObject private var tts = TextToSpeech() // 持续保留实例
    @FocusState private var isInputActive: Bool

    @State private var inputText: String = ""
    @State private var summaryText: String = ""
    @State private var selectedModel: AllModels? = nil // 默认值设为 nil
    @State private var isGeneratingSummary: Bool = false
    @State private var showCopySuccess: Bool = false
    @State private var isCopy: Bool = false
    @State private var isFeedBack: Bool = false
    @State private var isSelect: Bool = false
    @State private var isSuccess: Bool = false
    @State private var isTextSelectionSheetPresented: Bool = false // 文本选择
    
    @State private var selectedURLs: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                HStack {
                    Image(systemName: "highlighter")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.hlCyanite)
                    Text("Summary")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.hlCyanite)
                    Spacer()
                }
                .padding(.horizontal, 6)
                .padding(.vertical)
                
                VStack(spacing: 10) {
                    // 选择原文本语言
                    HStack {
                        Text("Existing Text or Web Links")
                        Spacer()
                    }
                    .padding(.top)
                    
                    // 输入框
                    TextEditor(text: $inputText)
                        .padding(10)
                        .frame(height: 100)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .focused($isInputActive)
                        .onChange(of: inputText) {
                            if !inputText.isEmpty {
                                extractURLs(from: inputText)
                            }
                        }
                    
                    // 解析出的 URL 展示区域
                    if !selectedURLs.isEmpty {
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    // 显示解析出的 URL
                                    ForEach(selectedURLs, id: \.self) { url in
                                        HStack {
                                            Image(systemName: "link")
                                                .foregroundColor(.hlCyanite)
                                                .font(.footnote)
                                            Text(url)
                                                .font(.footnote)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                            
                                            // 删除 URL 按钮
                                            Button(action: {
                                                removeURL(url)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.hlRed)
                                            }
                                        }
                                        .padding(6)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(20)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                    }
                                }
                            }
                            .cornerRadius(20)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    // 模型选择 & 摘要按钮
                    HStack {
                        ScrollViewReader { scrollViewProxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    let visibleModels = filteredModels
                                    ForEach(visibleModels, id: \.id) { model in
                                        Button(action: {
                                            isSelect.toggle()
                                            selectedModel = model
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3)) {
                                                scrollViewProxy.scrollTo(model.id, anchor: .center)
                                            }
                                        }) {
                                            toolModelButton(for: model, isSelected: selectedModel?.id == model.id, color: .hlCyanite)
                                        }
                                        .padding(.trailing, model.id == visibleModels.last?.id ? nil : 0)
                                        .sensoryFeedback(.selection, trigger: isSelect)
                                    }
                                }
                            }
                            .cornerRadius(20)
                        }
                        
                        // 摘要按钮
                        Button(action: {
                            isFeedBack.toggle()
                            generateSummary()
                        }) {
                            if isGeneratingSummary {
                                ProgressView() // 显示加载进度
                                    .frame(width: 32, height: 32)
                                    .padding(8)
                            } else {
                                Image(systemName: "arrowtriangle.down.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(Color(.hlCyanite))
                                    .padding(8)
                            }
                        }
                        .background(Color(.hlCyanite).opacity(0.1))
                        .clipShape(Circle())
                        .buttonStyle(.plain)
                        .sensoryFeedback(.impact, trigger: isFeedBack)
                    }
                    
                    // 摘要文本
                    HStack {
                        Text("Summarized Text")
                        Spacer()
                    }
                    
                    // 输出框
                    ScrollView {
                        Markdown(summaryText.isEmpty ? "" : summaryText)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .frame(minHeight: 100)
                    .cornerRadius(20)
                    
                    // 选择、朗读、复制按钮
                    HStack (spacing: 10) {
                        Text("由 \(selectedModel?.displayName ?? "未知模型") 进行摘要")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        // 文本选择
                        Button(action: {
                            isTextSelectionSheetPresented = true
                        }) {
                            Image(systemName: "text.redaction")
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 24, height: 24)
                                .foregroundColor(.secondary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(summaryText.isEmpty)
                        .sheet(isPresented: $isTextSelectionSheetPresented) {
                            TextSelectionView(text: summaryText)
                        }
                        // 语音朗读
                        Button(action: {
                            tts.setContextIfNeeded(modelContext)
                            tts.updateSelectedModel()
                            tts.toggleSpeech(text: summaryText)
                        }) {
                            if tts.isAsking {
                                ProgressView()
                                    .scaledToFit()
                                    .padding(2)
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.secondary)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: tts.isSpeaking ? "pause.circle" : "waveform")
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(tts.isSpeaking ? Color(.systemRed) : .secondary)
                                    .clipShape(Circle())
                                    .scaleEffect(tts.isSpeaking ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: tts.isSpeaking)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(summaryText.isEmpty)
                        // 复制按钮
                        Button(action: copyToClipboard) {
                            Image(systemName: isCopy ? "checkmark.circle" : "square.on.square")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(isCopy ? Color(.systemGreen) : .secondary)
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                .scaleEffect(isCopy ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCopy)
                        }
                        .buttonStyle(.plain)
                        .disabled(summaryText.isEmpty)
                        .sensoryFeedback(.success, trigger: isSuccess)
                    }
                    .contentShape(Rectangle())
                    .allowsHitTesting(true)
                    .padding(.top)
                }
                .padding()
                .background(
                    BlurView(style: .systemUltraThinMaterial) // 毛玻璃背景
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .hlCyanite, radius: 1)
                )
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Reminder: Instant features do not save your data. Please back up important information in time!")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding()
                }
            }
            .padding()
            .tint(.hlCyanite)
        }
        .onAppear {
            if selectedModel == nil, let firstModel = filteredModels.first {
                selectedModel = firstModel
            }
        }
    }
    
    // 实时检测并更新 URL 数组
    private func extractURLs(from text: String) {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return }
        
        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        // 利用 Set 去重，提取 URL 字符串
        let extractedURLs = Set(matches.compactMap { match -> String? in
            if let range = Range(match.range, in: text) {
                return String(text[range])
            }
            return nil
        })
        
        // 将去重后的 URL 转换为数组并排序
        let uniqueURLs = Array(extractedURLs).sorted()
        
        self.selectedURLs = uniqueURLs
    }
    
    // 删除已解析的 URL
    private func removeURL(_ url: String) {
        selectedURLs.removeAll { $0 == url }
        inputText = inputText.replacingOccurrences(of: url, with: "")
    }
    
    // generateSummary()（流式输出版）
    private func generateSummary() {
        // 支持 inputText 或 selectedURLs 非空
        guard (!inputText.isEmpty || !selectedURLs.isEmpty), let selectedModel = selectedModel else { return }
        
        isGeneratingSummary = true
        summaryText = ""
        isInputActive = false

        Task {
            do {
                // 拼接输入文本（若含 URL，则合并爬取的网页内容）
                var combinedInput = inputText
                if !selectedURLs.isEmpty {
                    let extractedWebPages = await fetchWebPageContent(from: selectedURLs)
                    if !extractedWebPages.isEmpty {
                        var webContentMarkdown = ""
                        for (_, title, content, icon) in extractedWebPages {
                            webContentMarkdown.append(
                                """
                                - ![\(title)](\(icon))
                                  \(content)...\n
                                """
                            )
                        }
                        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
                        let webMessage = currentLanguage.hasPrefix("zh")
                            ? "\n这是网页内容：\n\(webContentMarkdown)"
                            : "\nThis is content of web pages:\n\(webContentMarkdown)"
                        combinedInput += webMessage
                    }
                }
                
                guard let apiInfo = allApiKeys.first(where: { $0.company == selectedModel.company }) else {
                    throw NSError(domain: "SummaryView", code: 404, userInfo: [NSLocalizedDescriptionKey: "无法获取 API Key"])
                }
                
                // 调用摘要 API（流式）
                let stream = try await generateSummaryAPI(
                    input: combinedInput,
                    modelInfo: selectedModel,
                    apiKey: apiInfo.key ?? "",
                    requestURL: apiInfo.requestURL ?? "Unknown"
                )
                
                for try await token in stream {
                    await MainActor.run {
                        summaryText.append(token)
                    }
                }
                
                await MainActor.run {
                    isGeneratingSummary = false
                }
            } catch {
                await MainActor.run {
                    summaryText = "摘要失败: \(error.localizedDescription)"
                    isGeneratingSummary = false
                }
            }
        }
    }
    
    // 复制
    private func copyToClipboard() {
        UIPasteboard.general.string = summaryText
        isCopy = true
        isSuccess.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isCopy = false
        }
    }
}

// 模型按钮
func toolModelButton(for model: AllModels, isSelected: Bool, color: Color) -> some View {
    HStack(spacing: 8) {
        if isSelected {
            // 激活状态，使用原图颜色
            if model.identity == "model" {
                Image(getCompanyIcon(for: model.company ?? "Unknown"))
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .scaleEffect(1.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSelected)
            } else {
                Image(systemName: model.icon ?? "circle.dotted.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .clipShape(Circle())
                    .overlay(
                        Group {
                            gradient(for: 0)
                            .mask(
                                Image(systemName: model.icon ?? "circle.dotted.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            )
                        }
                    )
                    .scaleEffect(1.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSelected)
            }
        } else {
            if model.identity == "model" {
                // 非激活状态，使用模板模式配合 foregroundColor 上色
                Image(getCompanyIcon(for: model.company ?? "Unknown"))
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .scaleEffect(1.0)
                    .foregroundColor(Color(.systemGray))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSelected)
            } else {
                Image(systemName: model.icon ?? "circle.dotted.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .scaleEffect(1.0)
                    .foregroundColor(Color(.systemGray))
                    .clipShape(Circle())
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isSelected)
            }
        }

        if isSelected {
            Text(model.displayName ?? "Unknown")
                .font(.caption)
                .foregroundColor(color)
                .transition(.opacity.combined(with: .move(edge: .leading)))
            if model.supportsReasoning {
                Text("Thinking")
                    .font(.caption)
                    .foregroundColor(Color(.systemPurple))
                    .transition(.opacity)
            }
            if model.supportsImageGen {
                Text("Generate Image")
                    .font(.caption)
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
            if model.supportsVoiceGen {
                Text("Voice")
                    .font(.caption)
                    .foregroundColor(.pink)
                    .transition(.opacity)
            }
            if model.price == 0 {
                Text("Free")
                    .font(.caption)
                    .foregroundColor(Color(.systemGreen))
                    .transition(.opacity)
            }
            if model.company?.uppercased() == "LOCAL" {
                Text("Local")
                    .font(.caption)
                    .foregroundColor(Color(.systemOrange))
                    .transition(.opacity)
            }
        }
    }
    .padding(10)
    .background(background(for: model, isSelected: isSelected))
    .cornerRadius(20)
    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isSelected)
}

@ViewBuilder
private func background(for model: AllModels, isSelected: Bool) -> some View {
    let special = specialColor(for: model)
    
    if let special {
        LinearGradient(
            colors: [
                (isSelected ? Color(.hlBluefont) : Color(.systemGray)).opacity(0.1),
                special.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    } else {
        (isSelected ? Color(.hlBluefont) : Color(.systemGray)).opacity(0.1)
    }
}

private func specialColor(for model: AllModels) -> Color? {
    if model.company?.uppercased() == "LOCAL" {
        return .hlOrange
    } else if model.supportsReasoning {
        return .hlPurple
    } else if model.supportsMultimodal {
        return .teal
    } else if model.supportsImageGen {
        return Color.hlGreen
    } else if model.supportsVoiceGen {
        return .pink
    } else if model.price == 0 {
        return .green
    } else {
        return nil
    }
}
