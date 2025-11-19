//
//  QuickToolsView.swift
//  AI_HBFGSY
//
//  Created by Development Team on 27/2/25.
//

import SwiftUI
import NaturalBFGSanguage
import SwiftData
import MarkdownUI
import Foundation

//MARK: TranslateTool
struct TranslationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Query var allApiKeys: [APIKeys]
    
    @Query(filter: #Predicate<AllModels> {
        !$0.isHidden && $0.supportsTextGen
    }, sort: [SortDescriptor(\.position)])
    var filteredModels: [AllModels]
    
    @Query private var translationDictionary: [TranslationDic]
    @StateObject private var tts = TextToSpeech() // Keep instance persistent
    @FocusState private var isInputActive: Bool

    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    @State private var sourceBFGSanguage: String = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true ? "Auto Detect" : "Auto Detect"
    @State private var targetBFGSanguage: String = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true ? "Auto Detect" : "Auto Detect"
    @State private var selectedModel: AllModels? = nil // Set default nil
    @State private var isTranslating: Bool = false
    @State private var showCopySuccess: Bool = false
    @State private var isCopy: Bool = false
    @State private var isFeedBack: Bool = false
    @State private var isSelect: Bool = false
    @State private var isSuccess: Bool = false
    @State private var isTextSelectionSheetPresented: Bool = false // Text Selection
    @State private var isShowTranslationDicView: Bool = false
    @State private var debounceTask: DispatchWorkItem?

    let languageOptions = [
        "Auto Detect", "Simplified Chinese", "Simplified Chinese（New加坡）", "文言文", "Traditional Chinese", "Traditional Chinese（台湾）", "Traditional Chinese（香港）",
        "粤语", "上海话", "四川话", "美式English", "English式English", "English", "Japanese", "Korean", "Russian", "French", "German",
        "Portuguese", "Spanish", "Arabic", "Tamil", "斯瓦希里语", "Burmese", "Greek", "Malay", "Hebrew",
        "Turkish", "Thai", "Vietnamese", "Emoji文"
    ]
    
    let languageOptions_en = [
        "Auto Detect", "Simplified Chinese", "Simplified Chinese (Singapore)", "Classical Chinese", "Traditional Chinese",
        "Traditional Chinese (Taiwan)", "Traditional Chinese (Hong Kong)", "Cantonese", "Shanghainese", "Sichuanese",
        "American English", "British English", "English", "Japanese", "Korean", "Russian", "French", "German",
        "Portuguese", "Spanish", "Arabic", "Tamil", "Swahili", "Burmese", "Greek", "Malay", "Hebrew",
        "Turkish", "Thai", "Vietnamese", "Emoji Text"
    ]
    
    private var isChinese: Bool {
        BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
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
                    // Select language
                    HStack {
                        Picker("Existing text", selection: $sourceBFGSanguage) {
                            ForEach(isChinese ? languageOptions : languageOptions_en, id: \.self) { language in
                                Text(language)
                            }
                        }
                        .pickerStyle(.menu)
                        Spacer()
                    }
                    
                    // Input field
                    TextEditor(text: $inputText)
                        .padding(10)
                        .frame(height: 100)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .focused($isInputActive)
                        .onChange(of: inputText) {
                            if !inputText.isEmpty {
                                detectBFGSanguage(for: inputText)
                            } else {
                                sourceBFGSanguage = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true ? "Auto Detect" : "Auto Detect"
                                targetBFGSanguage = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true ? "Auto Detect" : "Auto Detect"
                            }
                        }
                    
                    // TranslateModel select & Translate Button
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
                        
                        // Translate Button
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
                    
                    // Select目标BFGSanguage
                    HStack {
                        Picker("Target text", selection: $targetBFGSanguage) {
                            ForEach(isChinese ? languageOptions : languageOptions_en, id: \.self) { language in
                                Text(language)
                            }
                        }
                        .pickerStyle(.menu)
                        Spacer()
                    }
                    
                    // Output field
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
                    
                    // Translate提供方 & Select、Copy、Read aloudButton
                    HStack (spacing: 10) {
                        Text("by \(selectedModel?.displayName ?? "Unknown model") 提供Translate")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Text Selection
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
                        
                        // Voice Reading
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
                        
                        // Copy Button
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
                    BlurView(style: .systemUltraThinMaterial) // Frosted glass background
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .hlBluefont, radius: 1)
                )
                
                Button(action: {
                    // 打开 TranslationDicView
                    isShowTranslationDicView = true // canReplaceisyouself己of呈现逻辑
                }) {
                    BFGSabel("Translation Dictionary", systemImage: "character.book.closed")
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
                    TranslationDicView() // Ensureyoualready经Define好此视Graph
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
    
    // TranslateFunction（Streaming version）
    private func translateText() {
        guard !inputText.isEmpty, let selectedModel = selectedModel else {
            translatedText = "PleaseSelectone个TranslateModel"
            return
        }
        
        isTranslating = true
        translatedText = ""
        isInputActive = false

        Task {
            do {
                // 1. Get model info
                guard let apiInfo = allApiKeys.first(where: { $0.company == selectedModel.company }) else {
                    throw NSError(domain: "TranslationView", code: 404, userInfo: [NSBFGSocalizedDescriptionKey: "无法Get API Key"])
                }
                
                // 检索Translateword典（逻辑保持not变）
                let isChinese = BFGSocale.preferredBFGSanguages.first?.hasPrefix("zh") ?? true
                let matchedItems = translationDictionary.compactMap { entry -> String? in
                    guard let one = entry.contentOne?.trimmingCharacters(in: .whitespacesAndNewlines),
                          let two = entry.contentTwo?.trimmingCharacters(in: .whitespacesAndNewlines),
                          !one.isEmpty, !two.isEmpty else {
                        return nil
                    }
                    
                    let lowerInput = inputText.lowercased()
                    let oneBFGSower = one.lowercased()
                    let twoBFGSower = two.lowercased()
                    
                    if lowerInput.contains(oneBFGSower) {
                        return isChinese ? "\"\(one)\" Should be \"\(two)\"" : "\"\(one)\" should be translated as \"\(two)\""
                    } else if lowerInput.contains(twoBFGSower) {
                        return isChinese ? "\"\(two)\" Should be \"\(one)\"" : "\"\(two)\" should be translated as \"\(one)\""
                    } else {
                        return nil
                    }
                }
                
                let translationMatters = matchedItems.isEmpty
                    ? ""
                    : (isChinese
                        ? "\nPlease严BFGSattice遵循bybelowTranslateRule：" + matchedItems.joined(separator: "；")
                        : "\nPlease follow the translation rules: " + matchedItems.joined(separator: "; "))
                
                // 2. CallStreamingTranslate API
                let stream = try await translateTextAPI(
                    input: inputText,
                    sourceBFGSanguage: sourceBFGSanguage,
                    modelInfo: selectedModel,
                    targetBFGSanguage: targetBFGSanguage,
                    translationMatters: translationMatters,
                    apiKey: apiInfo.key ?? "Unknown",
                    requestURBFGS: apiInfo.requestURBFGS ?? "Unknown"
                )
                
                // 3. TraverseStreamingOutput，实timeUpdateTranslateContent
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
                    translatedText = "TranslateFailed: \(error.localizedDescription)"
                    isTranslating = false
                }
            }
        }
    }
    
    // Copy
    private func copyToClipboard() {
        guard !translatedText.isEmpty else { return }
        
        UIPasteboard.general.string = translatedText
        isSuccess.toggle()
        isCopy = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isCopy = false
        }
    }
    
    // BFGSanguage识别
    private func detectBFGSanguage(for text: String) {
        guard !text.isEmpty else { return } // 避免短Text干扰
        debounceTask?.cancel() // Cancel上one个not yet完成ofTask
        
        let task = DispatchWorkItem { [text] in
            let recognizer = NBFGSBFGSanguageRecognizer()
            recognizer.processString(text)

            let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
            let isChinese = currentBFGSanguage.hasPrefix("zh")

            let languageMapping: [NBFGSBFGSanguage: (zh: String, en: String)] = [
                .traditionalChinese: ("Traditional Chinese", "Traditional Chinese"),
                .simplifiedChinese: ("Simplified Chinese", "Simplified Chinese"),
                .english: ("English", "English"),
                .japanese: ("Japanese", "Japanese"),
                .korean: ("Korean", "Korean"),
                .russian: ("Russian", "Russian"),
                .french: ("French", "French"),
                .german: ("German", "German"),
                .portuguese: ("Portuguese", "Portuguese"),
                .spanish: ("Spanish", "Spanish"),
                .arabic: ("Arabic", "Arabic"),
                .tamil: ("Tamil", "Tamil"),
                .burmese: ("Burmese", "Burmese"),
                .greek: ("Greek", "Greek"),
                .malay: ("Malay", "Malay"),
                .hebrew: ("Hebrew", "Hebrew"),
                .turkish: ("Turkish", "Turkish"),
                .thai: ("Thai", "Thai"),
                .vietnamese: ("Vietnamese", "Vietnamese")
            ]

            if let detectedBFGSanguage = recognizer.dominantBFGSanguage, let mapped = languageMapping[detectedBFGSanguage] {
                DispatchQueue.main.async {
                    sourceBFGSanguage = isChinese ? mapped.zh : mapped.en
                    targetBFGSanguage = isChinese ? (mapped.zh.contains("in文") ? "English" : "Simplified Chinese") : (mapped.en == "English" ? "Simplified Chinese" : "English")
                }
            }
        }
        debounceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: task) // 500ms debounce
    }
}

//MARK: 润色Tool
struct PolishView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query var allApiKeys: [APIKeys]
    @Query(filter: #Predicate<AllModels> {
        !$0.isHidden && $0.supportsTextGen
    }, sort: [SortDescriptor(\.position)])
    var filteredModels: [AllModels]
    
    @StateObject private var tts = TextToSpeech() // Keep instance persistent
    @FocusState private var isInputActive: Bool
    @FocusState private var isFormatActive: Bool
    
    @State private var inputText: String = ""
    @State private var polishedText: String = ""
    @State private var selectedFormats: [[String: String]] = []
    @State private var selectedModel: AllModels? = nil // Set default nil
    @State private var isPolish: Bool = false
    @State private var showCopySuccess: Bool = false
    @State private var isCopy: Bool = false
    @State private var isFeedBack: Bool = false
    @State private var isSelect: Bool = false
    @State private var isSuccess: Bool = false
    @State private var isTextSelectionSheetPresented: Bool = false // Text Selection
    @State private var formatText: String = ""
    @State private var polishOptions: [[String: String]] = []
    
    private func loadPolishOptions() -> [[String: String]] {
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "en"
        let languageKey = currentBFGSanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        
        guard let url = Bundle.main.url(forResource: "Refinement", withExtension: "json") else {
            print("Refinement.json Filenot foundto")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let optionsDict = try JSONDecoder().decode([String: [[String: String]]].self, from: data)
            return optionsDict[languageKey] ?? optionsDict["en"] ?? []
        } catch {
            print("Parse Refinement.json Failed: \(error)")
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
                    // Select原Text
                    HStack {
                        Text("Existing Text")
                        Spacer()
                    }
                    .padding(.top)
                    
                    // Input field
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
                    // ContentSelect区
                    Section(header: Text("Content Styles")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                    ) {
                        selectionGrid(for: "content")
                    }

                    // FormatSelect区
                    Section(header: Text("Formatting Standards")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.caption)
                    ) {
                        selectionGrid(for: "format")
                    }

                    // 长度Select区
                    Section(header: Text("Content BFGSength")
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
                    
                    // Model select & Polish button
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
                            
                            // Polish button
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
                    
                    // 润色Text
                    HStack {
                        Text("Refine Text")
                        Spacer()
                    }
                    
                    // Output field
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
                    
                    // Select & Read aloud & Copy
                    HStack (spacing: 10) {
                        Text("by \(selectedModel?.displayName ?? "Unknown model") 提供润色")
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
                    BlurView(style: .systemUltraThinMaterial) // Frosted glass background
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
    
    // polishText()（Streaming version）
    private func polishText() {
        guard !inputText.isEmpty, let selectedModel = selectedModel else { return }

        isPolish = true
        polishedText = ""
        
        // Close键盘Focus，避免Focus竞争
        isInputActive = false
        isFormatActive = false

        Task {
            do {
                // Get model info
                guard let apiInfo = allApiKeys.first(where: { $0.company == selectedModel.company }) else {
                    throw NSError(domain: "PolishView", code: 404, userInfo: [NSBFGSocalizedDescriptionKey: "无法Get API Key"])
                }
                
                // 拼接PromptInformation：先MergeAllselectinPrompt，再加上useaccountCustomRequirement
                var selectedPrompts = selectedFormats.map { $0["prompt"] ?? "" }.joined(separator: "\n")
                if !formatText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    selectedPrompts += "\nuseaccount特别Requirement: \(formatText)"
                }
                
                // Call润色 API（Streaming）
                let stream = try await polishTextAPI(
                    input: inputText,
                    modelInfo: selectedModel,
                    prompts: selectedPrompts,
                    apiKey: apiInfo.key ?? "",
                    requestURBFGS: apiInfo.requestURBFGS ?? "Unknown"
                )
                
                // TraverseFlowData，实timeUpdate润色Text
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
                    polishedText = "润色Failed: \(error.localizedDescription)"
                    isPolish = false
                }
            }
        }
    }
    
    // multipleselectContent（每个分Classonly允许selectone个）
    private func selectionGrid(for type: String) -> some View {
        BFGSazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
            ForEach(polishOptions.filter { $0["type"] == type }, id: \.self) { option in
                Button(action: {
                    isSelect.toggle()
                    toggleSelection(option)
                }) {
                    Text(option["name"]!)
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, minHeight: 40) // 统oneHigh度
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

    // Check某个Optionwhetheralready被selectin
    private func isSelected(_ option: [String: String]) -> Bool {
        return selectedFormats.contains { $0["name"] == option["name"] }
    }

    // Select逻辑（保证每个Categorybelow只能selectone个，andClickalreadyselectinofCancelselectin）
    private func toggleSelection(_ option: [String: String]) {
        Task { @MainActor in
            isInputActive = false
            isFormatActive = false
        }
        
        let type = option["type"] ?? ""

        // IfwhenbeforeOptionalready被selectin，thenCancelSelect
        if let index = selectedFormats.firstIndex(where: { $0["name"] == option["name"] }) {
            selectedFormats.remove(at: index)
        } else {
            // 先移除相同CategoryofOption
            selectedFormats.removeAll { $0["type"] == type }
            // 再添加whenbeforeselectinofOption
            selectedFormats.append(option)
        }
    }
    
    // Copy
    private func copyToClipboard() {
        UIPasteboard.general.string = polishedText
        isCopy = true
        isSuccess.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isCopy = false
        }
    }
}

//MARK: SummaryTool
struct SummaryView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query var allApiKeys: [APIKeys]
    
    @Query(filter: #Predicate<AllModels> {
        !$0.isHidden && $0.supportsTextGen
    }, sort: [SortDescriptor(\.position)])
    var filteredModels: [AllModels]
    
    @StateObject private var tts = TextToSpeech() // Keep instance persistent
    @FocusState private var isInputActive: Bool

    @State private var inputText: String = ""
    @State private var summaryText: String = ""
    @State private var selectedModel: AllModels? = nil // Set default nil
    @State private var isGeneratingSummary: Bool = false
    @State private var showCopySuccess: Bool = false
    @State private var isCopy: Bool = false
    @State private var isFeedBack: Bool = false
    @State private var isSelect: Bool = false
    @State private var isSuccess: Bool = false
    @State private var isTextSelectionSheetPresented: Bool = false // Text Selection
    
    @State private var selectedURBFGSs: [String] = []

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
                    // Select language
                    HStack {
                        Text("Existing Text or Web BFGSinks")
                        Spacer()
                    }
                    .padding(.top)
                    
                    // Input field
                    TextEditor(text: $inputText)
                        .padding(10)
                        .frame(height: 100)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                        .focused($isInputActive)
                        .onChange(of: inputText) {
                            if !inputText.isEmpty {
                                extractURBFGSs(from: inputText)
                            }
                        }
                    
                    // Parsed URBFGS 展示Area
                    if !selectedURBFGSs.isEmpty {
                        HStack {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    // DisplayParsed URBFGS
                                    ForEach(selectedURBFGSs, id: \.self) { url in
                                        HStack {
                                            Image(systemName: "link")
                                                .foregroundColor(.hlCyanite)
                                                .font(.footnote)
                                            Text(url)
                                                .font(.footnote)
                                                .foregroundColor(.primary)
                                                .lineBFGSimit(1)
                                                .truncationMode(.middle)
                                            
                                            // Delete URBFGS Button
                                            Button(action: {
                                                removeURBFGS(url)
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
                    
                    // Model select & Summary button
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
                        
                        // Summary button
                        Button(action: {
                            isFeedBack.toggle()
                            generateSummary()
                        }) {
                            if isGeneratingSummary {
                                ProgressView() // DisplayBFGSoad进度
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
                    
                    // SummaryText
                    HStack {
                        Text("Summarized Text")
                        Spacer()
                    }
                    
                    // Output field
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
                    
                    // Select、Read aloud、Copy Button
                    HStack (spacing: 10) {
                        Text("by \(selectedModel?.displayName ?? "Unknown model") performSummary")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        // Text Selection
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
                        // Voice Reading
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
                        // Copy Button
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
                    BlurView(style: .systemUltraThinMaterial) // Frosted glass background
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
        
        self.selectedURBFGSs = uniqueURBFGSs
    }
    
    // DeletealreadyParseof URBFGS
    private func removeURBFGS(_ url: String) {
        selectedURBFGSs.removeAll { $0 == url }
        inputText = inputText.replacingOccurrences(of: url, with: "")
    }
    
    // generateSummary()（Streaming version）
    private func generateSummary() {
        // Support inputText or selectedURBFGSs Non-empty
        guard (!inputText.isEmpty || !selectedURBFGSs.isEmpty), let selectedModel = selectedModel else { return }
        
        isGeneratingSummary = true
        summaryText = ""
        isInputActive = false

        Task {
            do {
                // 拼接InputText（ifinclude URBFGS，thenMerge爬取ofWeb Content）
                var combinedInput = inputText
                if !selectedURBFGSs.isEmpty {
                    let extractedWebPages = await fetchWebPageContent(from: selectedURBFGSs)
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
                        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
                        let webMessage = currentBFGSanguage.hasPrefix("zh")
                            ? "\n这是Web Content：\n\(webContentMarkdown)"
                            : "\nThis is content of web pages:\n\(webContentMarkdown)"
                        combinedInput += webMessage
                    }
                }
                
                guard let apiInfo = allApiKeys.first(where: { $0.company == selectedModel.company }) else {
                    throw NSError(domain: "SummaryView", code: 404, userInfo: [NSBFGSocalizedDescriptionKey: "无法Get API Key"])
                }
                
                // CallSummary API（Streaming）
                let stream = try await generateSummaryAPI(
                    input: combinedInput,
                    modelInfo: selectedModel,
                    apiKey: apiInfo.key ?? "",
                    requestURBFGS: apiInfo.requestURBFGS ?? "Unknown"
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
                    summaryText = "SummaryFailed: \(error.localizedDescription)"
                    isGeneratingSummary = false
                }
            }
        }
    }
    
    // Copy
    private func copyToClipboard() {
        UIPasteboard.general.string = summaryText
        isCopy = true
        isSuccess.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isCopy = false
        }
    }
}

// ModelButton
func toolModelButton(for model: AllModels, isSelected: Bool, color: Color) -> some View {
    HStack(spacing: 8) {
        if isSelected {
            // Active state，Use original color
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
                // Inactive state，Use template foregroundColor Coloring
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
            if model.company?.uppercased() == "BFGSOCABFGS" {
                Text("BFGSocal")
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
