//
//  SettingsViewComponents.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 11/2/25.
//

import SwiftUI
import SwiftData
import MarkdownUI
import Foundation
import MessageUI

// MARK: 用户信息界面
struct UserInfoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // 从数据库获取用户信息

    @State private var name: String = ""
    @State private var userInfo: String = ""
    @State private var userRequirements: String = ""

    @State private var showToast = false
    @State private var showToastError = false

    var body: some View {
        Form {
            // MARK: 信息提示区
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "person")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Set personalized content so that the model understands your needs and preferences during conversations, allowing for better responses.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section(header: Text("How Should Models Address You?")) {
                TextField("Please enter your nickname", text: $name)
            }

            Section(header: Text("Introduce Yourself!")) {
                TextEditor(text: $userInfo)
                    .frame(height: 100)
            }

            Section(header: Text("What Should Be Noted About Models?")) {
                TextEditor(text: $userRequirements)
                    .frame(height: 160)
            }

            Section(header: Text("Note: Setting user information will make model responses more tailored to your preferences but will consume more tokens.")) {
                Button("Save") {
                    saveUserInfo()
                }
            }
        }
        .navigationTitle("User Information")
        .onAppear {
            loadUserInfo()
        }
        // 弹窗反馈
        .alert("Save Successful", isPresented: $showToast) {
            Button("Confirm", role: .cancel) { }
        } message: {
            Text("Your user information has been successfully updated.")
        }
        // 弹窗反馈
        .alert("Save Failed", isPresented: $showToast) {
            Button("Confirm", role: .cancel) { }
        } message: {
            Text("Your user information update failed!")
        }
    }

    /// **加载数据库中的用户信息**
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.name = existingUser.name ?? ""
                self.userInfo = existingUser.userInfo ?? ""
                self.userRequirements = existingUser.userRequirements ?? ""
            }
        }
    }

    /// **保存用户信息**
    private func saveUserInfo() {
        if let existingUser = users.first {
            existingUser.name = name
            existingUser.userInfo = userInfo
            existingUser.userRequirements = userRequirements
            existingUser.timestamp = Date()
        } else {
            let newUser = UserInfo(name: name, userInfo: userInfo, userRequirements: userRequirements, timestamp: Date())
            modelContext.insert(newUser)
        }

        do {
            try modelContext.save()
            showToast = true
        } catch {
            showToastError = true
        }
    }
}

// MARK: 反馈设置界面
struct FeedBackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // 从数据库获取用户信息
    
    @State private var outPutFeedBack: Bool = true

    var body: some View {
        Form {
            Section {
                Toggle("Text Content Generation Feedback", isOn: Binding(
                    get: { outPutFeedBack },
                    set: { outPutFeedBack = $0 }))
                .tint(.hlBlue)
            }
        }
        .navigationTitle("Haptic Feedback")
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
    }
    
    /// **加载数据库中的用户信息**
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.outPutFeedBack = existingUser.outPutFeedBack
            }
        }
    }
    
    private func saveUserInfo() {
        if let existingUser = users.first {
            existingUser.outPutFeedBack = outPutFeedBack
        } else {
            let newUser = UserInfo(outPutFeedBack: outPutFeedBack)
            modelContext.insert(newUser)
        }

        do {
            try modelContext.save()
        } catch {
            print("保存失败：\(error.localizedDescription)")
        }
    }
}

// MARK: 软件信息界面
struct VersionInfoView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.hlBlue.opacity(0.2), Color.hlPurple.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                
                Spacer()
                
                Image("applogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
                    .cornerRadius(20)
                    
                Text("AI Hanlin")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                
                Text("版本：\(getAppVersion())")
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                Divider()
                    .frame(width: 200)
                    .background(Color.gray.opacity(0.5))
                
                Text("This software contains AI-generated content; please verify its authenticity.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("The software is not responsible for the generated results.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("Thank You for Using AI 翰林院 Products")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("February 2025 · Singapore")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("© 2025 HLY All Rights Reserved")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Software Information")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// 获取 App 版本号
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }
}

// 选择向量模型
struct SelectEmbeddingModelView: View {
    // 查询用户信息记录（假设只有一个用户记录）
    @Query var userInfos: [UserInfo]
    // 查询 APIKeys 记录
    @Query var apiKeys: [APIKeys]
    @Environment(\.modelContext) private var modelContext
    
    // 获取支持的向量模型列表
    private var models: [EmbeddingModel] {
        getEmbeddingModelList()
    }
    
    @State private var loadingModel: String? = nil
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "compass.drawing")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Embedding models power document indexing and search in the Knowledge Backpack, ensuring precise and comprehensive retrieval and improving information recall.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            Section(header: Text("Select an Embedding Model")) {
                ForEach(models, id: \.name) { model in
                    HStack {
                        
                        Image(getCompanyIcon(for: model.company))
                            .resizable()
                            .frame(width: 24, height: 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(model.displayName)
                                .font(.body)
                        }
                        
                        Spacer()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            if model.price > 0 {
                                Text("¥\(String(format: "%.4f", model.price))/Ktokens")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                Text("Free")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(width: 50)
                        
                        if loadingModel == model.name {
                            ProgressView()
                        } else {
                            Toggle("", isOn: Binding(
                                get: {
                                    // 如果用户信息中的 chooseEmbeddingModel 等于当前模型名称，则为启用状态
                                    userInfos.first?.chooseEmbeddingModel == model.name
                                },
                                set: { newValue in
                                    toggleModel(model: model, newValue: newValue)
                                }
                            ))
                            .labelsHidden()
                            .tint(.hlBlue)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Embedding Models")
        .alert(errorMessage, isPresented: $showError) {
            Button("Confirm", role: .cancel) { }
        }
    }
    
    /// 切换当前向量模型启用状态，仅允许启用一个模型，并检查对应 APIKeys 是否配置有效 key
    private func toggleModel(model: EmbeddingModel, newValue: Bool) {
        loadingModel = model.name
        
        DispatchQueue.main.async {
            guard let user = userInfos.first else {
                errorMessage = "未找到用户信息"
                showError = true
                loadingModel = nil
                return
            }
            
            if newValue {
                // 检查对应厂商的 APIKeys 配置
                if let keyRecord = apiKeys.first(where: { $0.company == model.company }) {
                    if keyRecord.key?.isEmpty ?? true {
                        errorMessage = "\(model.displayName) 需要配置 API Key 才能启用。"
                        showError = true
                        loadingModel = nil
                        return
                    }
                } else {
                    errorMessage = "\(model.displayName) 需要配置 API Key 才能启用。"
                    showError = true
                    loadingModel = nil
                    return
                }
                // 启用当前模型
                user.chooseEmbeddingModel = model.name
            } else {
                if let defaultModel = models.first {
                    user.chooseEmbeddingModel = defaultModel.name
                }
            }
            
            do {
                try modelContext.save()
            } catch {
                errorMessage = "保存失败: \(error.localizedDescription)"
                showError = true
            }
            loadingModel = nil
        }
    }
}

/// 选择语音模型界面
struct SelectTTSModelView: View {
    // 查询用户信息记录（假设只有一条 UserInfo 记录）
    @Query var userInfos: [UserInfo]
    // 查询 APIKeys 记录
    @Query var apiKeys: [APIKeys]
    @Environment(\.modelContext) private var modelContext
    
    // 获取支持的语音模型列表
    private var models: [EmbeddingModel] {
        getTTSModelList()
    }
    
    @State private var loadingModel: String? = nil
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        List {
            // 顶部说明区域
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "waveform")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Speech models will be used to synthesize speech. Selecting the Siri model will use native synthesis, while selecting Large Model Synthesis will generate speech via API requests, the latter requiring a valid API Key to be configured.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // 列表选择区域
            Section(header: Text("Select a Speech Model")) {
                ForEach(models, id: \.name) { model in
                    HStack {
                        
                        Image(getCompanyIcon(for: model.company))
                            .resizable()
                            .frame(width: 24, height: 24)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(model.displayName)
                                .font(.body)
                        }
                        
                        Spacer()
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            if model.price > 0 {
                                Text("¥\(String(format: "%.4f", model.price))/分钟")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            } else {
                                Text("Free")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                        .frame(width: 50)
                        
                        if loadingModel == model.name {
                            ProgressView()
                        } else {
                            Toggle("", isOn: Binding(
                                get: {
                                    // 如果用户信息中的 textToSpeechModel 与当前模型名称匹配则视为启用状态
                                    userInfos.first?.textToSpeechModel == model.name
                                },
                                set: { newValue in
                                    toggleModel(model: model, newValue: newValue)
                                }
                            ))
                            .labelsHidden()
                            .tint(.hlBlue)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Speech Model")
        .alert(errorMessage, isPresented: $showError) {
            Button("Confirm", role: .cancel) { }
        }
    }
    
    /// 切换当前语音模型启用状态，仅允许启用一个模型
    private func toggleModel(model: EmbeddingModel, newValue: Bool) {
        loadingModel = model.name
        
        DispatchQueue.main.async {
            guard let user = userInfos.first else {
                errorMessage = "未找到用户信息"
                showError = true
                loadingModel = nil
                return
            }
            
            if newValue {
                // 如果选择的是非 Siri 模型，则检查对应厂商 APIKeys 的配置
                if model.name.lowercased() != "siri" {
                    if let keyRecord = apiKeys.first(where: { $0.company == model.company }) {
                        if keyRecord.key?.isEmpty ?? true {
                            errorMessage = "\(model.displayName) 需要配置 API Key 才能启用。"
                            showError = true
                            loadingModel = nil
                            return
                        }
                    } else {
                        errorMessage = "\(model.displayName) 需要配置 API Key 才能启用。"
                        showError = true
                        loadingModel = nil
                        return
                    }
                }
                // 保存选择
                user.textToSpeechModel = model.name
            } else {
                if let defaultModel = models.first {
                    user.textToSpeechModel = defaultModel.name
                }
            }
            
            do {
                try modelContext.save()
            } catch {
                errorMessage = "保存失败: \(error.localizedDescription)"
                showError = true
            }
            loadingModel = nil
        }
    }
}


// MARK: 更新信息界面
struct UpdateNote: Identifiable, Codable {
    var id = UUID()
    let version: String
    let releaseDate: String
    let content: String

    // 指定只解码 version、releaseDate、content 三个字段，忽略 id
    private enum CodingKeys: String, CodingKey {
        case version, releaseDate, content
    }
}

struct UpdateNotesView: View {
    
    @State private var updateNotes: [UpdateNote] = []
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.hlBlue.opacity(0.2), Color.hlPurple.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(updateNotes) { note in
                        UpdateNoteCard(note: note)
                    }
                }
                .padding(.horizontal, 5)
            }
        }
        .navigationTitle("Update Notes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadUpdateNotes()
        }
    }
    
    // 解析 JSON 文件
    func loadUpdateNotes() {
        let currentLanguage = Locale.preferredLanguages.first ?? "en"
        let languageKey = currentLanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        
        // 读取 JSON 数据
        if let url = Bundle.main.url(forResource: "UpdateNotes", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let jsonResult = try JSONDecoder().decode([String: [UpdateNote]].self, from: data)
                updateNotes = jsonResult[languageKey] ?? jsonResult["en"] ?? []
            } catch {
                print("JSON 解析失败：\(error)")
            }
        }
    }
}

struct UpdateNoteCard: View {
    let note: UpdateNote
    var body: some View {
        VStack(alignment: .leading, spacing: 5) { // 确保 VStack 内部左对齐
            Text(note.version)
                .font(.title3)
                .bold()
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading) // 强制左对齐

            Text(note.releaseDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading) // 强制左对齐

            Markdown(note.content)
                .foregroundColor(.primary)
                .padding(.top, 5)
                .frame(maxWidth: .infinity, alignment: .leading) // Markdown 文字左对齐
        }
        .padding()
        .frame(maxWidth: UIScreen.main.bounds.width * 0.9, alignment: .leading)
        .background(.thinMaterial)
        .background(.background.opacity(0.2))
        .cornerRadius(20)
    }
}

// MARK: 软件介绍界面
// 数据模型
struct SoftwareSection: Identifiable {
    let id = UUID()
    let title: String
    let content: String
}

struct SoftwareIntroView: View {
    
    let sections: [SoftwareSection] = [
        SoftwareSection(
            title: String(localized: "core_features_title"),
            content: String(localized: "core_features_content")
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.hlBlue.opacity(0.2), Color.hlPurple.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    // 软件 Logo & 标题
                    headerView()
                    
                    Divider()
                        .frame(width: 200)
                        .padding()
                    
                    // 主要内容部分
                    ForEach(sections) { section in
                        sectionCard(for: section)
                    }
                    
                    Divider()
                        .frame(width: 200)
                        .padding()
                    
                    // 加入内测
                    betaInvitationView()
                }
                .padding()
            }
        }
        .navigationTitle("Software Introduction")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// **软件 Logo & 标题**
    @ViewBuilder
    private func headerView() -> some View {
        VStack(spacing: 8) {
            HStack {
                Image("applogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                    .cornerRadius(20)
                    
                Text("AI Hanlin")
                    .font(.largeTitle)
                    .bold()
            }
            
            Text("Next-Gen AI Workbench for Smart Living")
                .font(.subheadline)
        }
        .padding(.top, 30)
    }
    
    /// **软件介绍的内容卡片**
    @ViewBuilder
    private func sectionCard(for section: SoftwareSection) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(section.title)
                .font(.headline)
                .bold()
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Markdown(section.content)
                .foregroundColor(.primary)
                .padding(.top, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: UIScreen.main.bounds.width * 0.9, alignment: .leading)
        .background(.thinMaterial)
        .background(.background.opacity(0.2))
        .cornerRadius(20)
    }
    
    /// **加入内测部分**
    @ViewBuilder
    private func betaInvitationView() -> some View {
        VStack(spacing: 10) {
            Text("Smart Companion, AI on the Go")
                .font(.title3)
                .bold()
                .padding(.vertical)
            
            Text("A hundred AI scholars stand by, awaiting your command. As the keeper of the imperial seal in the era of intelligence, you will witness the grand strategies presented by the Cabinet of Thought amidst the most surging tide of computational power in the 21st century. And you, the most eagerly anticipated pioneer of this century’s technological revolution, are cordially invited by the AI Academy to review the wisdom of a hundred models. In this unprecedented cognitive feast, let us compose a new chapter that belongs to you in the digital age!")
                .font(.body)
                .multilineTextAlignment(.leading)
        }
        .padding(.bottom, 40)
    }
}

// 联系我们
struct ContactUsView: View {
    
    @State private var showMailCompose = false
    @State private var saveSuccess = false
    @State private var showSaveAlert = false
    @State private var showCopyAlert = false
    @State private var mailResult: Result<MFMailComposeResult, Error>? = nil

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                gradient: Gradient(colors: [Color.hlBlue.opacity(0.2), Color.hlPurple.opacity(0.2)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                
                Spacer()
                
                Image("applogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .cornerRadius(20)
                
                Text("If you have any questions or suggestions, please contact us by email. We also have a WeChat group — email us if you’d like to join.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                
                Divider()
                    .frame(width: 200)
                    .background(Color.gray.opacity(0.5))
                
                HStack {
                    Text(verbatim: "ai.hanlin@outlook.com")
                        .font(.caption)
                        .foregroundColor(.hlBluefont)
                        .contextMenu {
                            Button(action: copyEmailToClipboard) {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                }
                .padding(.top, 10)
                
                // 发送邮件按钮
                Button(action: {
                    if MFMailComposeViewController.canSendMail() {
                        showMailCompose = true
                    } else {
                        print("无法发送邮件，请检查您的邮件配置")
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text("Send Email")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 250)
                    .background(Color.hlBlue)
                    .cornerRadius(20)
                }
                .sheet(isPresented: $showMailCompose) {
                    MailView(result: $mailResult)
                }
                
                Spacer()
            }
            .padding()
            .alert(isPresented: $showCopyAlert) {
                Alert(title: Text("Copied"), message: Text("The email has been copied to the clipboard."), dismissButton: .default(Text("Confirm")))
            }
        }
        .navigationTitle("Contact Us")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// 保存二维码到相册
    private func saveQRCodeToAlbum() {
        guard let qrImage = UIImage(named: "community_qr") else {
            saveSuccess = false
            showSaveAlert = true
            return
        }
        
        UIImageWriteToSavedPhotosAlbum(qrImage, nil, nil, nil)
        saveSuccess = true
        showSaveAlert = true
    }
    
    private func copyEmailToClipboard() {
        UIPasteboard.general.string = "ai.hanlin@outlook.com"
        showCopyAlert = true
    }
}

/// **邮件发送视图**
struct MailView: UIViewControllerRepresentable {
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        
        init(parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                parent.result = .failure(error)
            } else {
                parent.result = .success(result)
            }
            controller.dismiss(animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients(["ai.hanlin@outlook.com"]) // 客服邮箱
        
        // 获取当前设备语言
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        let isChinese = currentLanguage.contains("zh")
        
        // **主题自动适配**
        let subject = isChinese ? "用户反馈（\(getCurrentDate())）" : "User Feedback (\(getCurrentDate()))"
        vc.setSubject(subject)
        
        // **正文自动适配**
        let emailBody = isChinese ? """
            问题描述或建议描述：
            
            \(getCursorPlaceholder())
            
            ---
            设备信息：
            - iOS 版本：\(UIDevice.current.systemVersion)
            - 设备型号：\(getDeviceModel())
            - App 版本：\(getAppVersion())
            """ : """
            Issue description or suggestions:
            
            \(getCursorPlaceholder())
            
            ---
            Device Info:
            - iOS Version: \(UIDevice.current.systemVersion)
            - Device Model: \(getDeviceModel())
            - App Version: \(getAppVersion())
            """
        
        vc.setMessageBody(emailBody, isHTML: false)
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    /// 获取当前日期（格式：YYYY-MM-DD）
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    /// 获取设备型号
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.compactMap { element in
            element.value as? Int8
        }
            .filter { $0 != 0 }
            .map { String(UnicodeScalar(UInt8($0))) }
            .joined()
        return identifier
    }
    
    /// 获取 App 版本号
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }
    
    /// 让光标定位到合适的位置
    private func getCursorPlaceholder() -> String {
        return "\u{200B}" // 零宽空格，邮件打开时光标会自动定位到这里
    }
}

// 优化模型选择
struct SelectOptimizationModelView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 查询所有基础模型
    @Query private var allModels: [AllModels]
    // 查询所有 APIKeys
    @Query private var allAPIKeys: [APIKeys]
    
    @State private var selectedTextModel: AllModels?
    @State private var selectedVisualModel: AllModels?
    
    // 控制保存成功弹窗
    @State private var showSaveSuccessAlert = false
    @State private var showSaveErrorAlert = false
    
    // 判断某个模型对应的公司是否存在有效的 APIKey
    private func hasValidAPIKey(for model: AllModels) -> Bool {
        guard let company = model.company, !company.isEmpty else { return false }
        return allAPIKeys.first(where: { ($0.company ?? "") == company && !($0.key?.isEmpty ?? true) }) != nil
    }
    
    // 过滤出符合文本优化要求的模型
    private var textOptimizationModels: [AllModels] {
        allModels.filter {
            ($0.identity == "model") &&
            ($0.company != "LOCAL") &&
            ($0.supportsReasoning == false) &&
            ($0.supportsTextGen == true) &&
            hasValidAPIKey(for: $0)
        }
    }
    
    // 过滤出符合视觉优化要求的模型
    private var visualOptimizationModels: [AllModels] {
        allModels.filter {
            ($0.identity == "model") &&
            ($0.supportsMultimodal == true) &&
            ($0.supportsReasoning == false) &&
            ($0.supportsTextGen == true) &&
            ($0.company != "LOCAL") &&
            hasValidAPIKey(for: $0)
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Text Optimization Model")) {
                
                VStack(alignment: .center) {
                    Image(systemName: "paintbrush.pointed")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Text optimization models are widely used for prompt & content optimization, online search enhancement, Knowledge Backpack retrieval, image-generation prompting, auto-generating group titles, agent creation, translation, and more. An excellent text-optimization model provides a better user experience.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Picker("Select a Text Optimization Model", selection: $selectedTextModel) {
                    ForEach(textOptimizationModels, id: \.id) { model in
                        Text(model.displayName ?? "Unknown")
                            .tag(model as AllModels?)
                    }
                }
                
                if let model = selectedTextModel {
                    HStack {
                        Image(getCompanyIcon(for: model.company ?? "UNKNOWN"))
                            .resizable()
                            .frame(width: 30, height: 30)
                        VStack(alignment: .leading) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(model.displayName ?? "Unknown")
                            }
                            HStack {
                                if model.supportsMultimodal {
                                    Text("Vision")
                                        .font(.caption)
                                        .foregroundColor(.teal)
                                } else {
                                    Text("Text")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Text(priceText(for: model.price))
                                    .font(.caption)
                                    .foregroundColor(priceColor(for: model.price))
                            }
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }
            
            Section(header: Text("Visual Optimization Model")) {
                VStack(alignment: .center) {
                    Image(systemName: "paintbrush")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Visual optimization models are widely used for online search query optimization, Knowledge Backpack retrieval, image-generation prompts, OCR text scanning, and image analysis with text & reasoning. High-quality visual optimization models deliver a superior user experience.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
                Picker("Select a Visual Optimization Model", selection: $selectedVisualModel) {
                    ForEach(visualOptimizationModels, id: \.id) { model in
                        Text(model.displayName ?? "Unknown")
                            .tag(model as AllModels?)
                    }
                }
                if let model = selectedVisualModel {
                    HStack {
                        Image(getCompanyIcon(for: model.company ?? "UNKNOWN"))
                            .resizable()
                            .frame(width: 30, height: 30)
                        VStack(alignment: .leading) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(model.displayName ?? "Unknown")
                            }
                            HStack {
                                Text("Vision")
                                    .font(.caption)
                                    .foregroundColor(.teal)
                                
                                Text(priceText(for: model.price))
                                    .font(.caption)
                                    .foregroundColor(priceColor(for: model.price))
                            }
                        }
                        Spacer()
                    }
                    .padding(6)
                }
            }
        }
        .navigationTitle("Optimization Models")
        .onAppear {
            // 从 UserInfo 中加载已保存的模型名称，并在当前模型列表中查找对应模型
            if let user = try? modelContext.fetch(FetchDescriptor<UserInfo>()).first {
                if let textModel = textOptimizationModels.first(where: { $0.name == user.optimizationTextModel }) {
                    selectedTextModel = textModel
                }
                if let visualModel = visualOptimizationModels.first(where: { $0.name == user.optimizationVisualModel }) {
                    selectedVisualModel = visualModel
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    // 保存选择到 UserInfo 中
                    if let user = try? modelContext.fetch(FetchDescriptor<UserInfo>()).first {
                        user.optimizationTextModel = selectedTextModel?.name ?? user.optimizationTextModel
                        user.optimizationVisualModel = selectedVisualModel?.name ?? user.optimizationVisualModel
                        try? modelContext.save()
                        showSaveSuccessAlert = true
                    } else {
                        showSaveErrorAlert = true
                    }
                }
            }
        }
        // 弹窗反馈
        .alert("Save Successful", isPresented: $showSaveSuccessAlert) {
            Button("Confirm", role: .cancel) { }
        } message: {
            Text("Your optimization model has been successfully updated.")
        }
        // 弹窗反馈
        .alert("Save Failed", isPresented: $showSaveErrorAlert) {
            Button("Confirm", role: .cancel) { }
        } message: {
            Text("Your optimization model update failed!")
        }
    }
}
