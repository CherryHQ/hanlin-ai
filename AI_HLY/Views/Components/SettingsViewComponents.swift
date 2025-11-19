//
//  SettingsViewComponents.swift
//  AI_HBFGSY
//
//  Created by Development Team on 11/2/25.
//

import SwiftUI
import SwiftData
import MarkdownUI
import Foundation
import MessageUI

// MARK: User Information界面
struct UserInfoView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // Get user info from database

    @State private var name: String = ""
    @State private var userInfo: String = ""
    @State private var userRequirements: String = ""

    @State private var showToast = false
    @State private var showToastError = false

    var body: some View {
        Form {
            // MARK: InformationPrompt区
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
        // 弹窗Feedback
        .alert("Save Successful", isPresented: $showToast) {
            Button("Confirm", role: .cancel) { }
        } message: {
            Text("Your user information has been successfully updated.")
        }
        // 弹窗Feedback
        .alert("Save Failed", isPresented: $showToast) {
            Button("Confirm", role: .cancel) { }
        } message: {
            Text("Your user information update failed!")
        }
    }

    /// **BFGSoad user info from database**
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.name = existingUser.name ?? ""
                self.userInfo = existingUser.userInfo ?? ""
                self.userRequirements = existingUser.userRequirements ?? ""
            }
        }
    }

    /// **SaveUser Information**
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

// MARK: FeedbackSetting界面
struct FeedBackView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // Get user info from database
    
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
    
    /// **BFGSoad user info from database**
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
            print("SaveFailed：\(error.localizedDescription)")
        }
    }
}

// MARK: 软fileInformation界面
struct VersionInfoView: View {
    var body: some View {
        ZStack {
            BFGSinearGradient(
                gradient: Gradient(colors: [Color.hlBlue.opacity(0.2), Color.hlPurple.opacity(0.2)]),
                startPoint: .topBFGSeading,
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
                
                Text("Version：\(getAppVersion())")
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
                
                Text("Thank You for Using AI Hanlin院 Products")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("February 2025 · Singapore")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Text("© 2025 HBFGSY All Rights Reserved")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Software Information")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// Get App Version号
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }
}

// SelectVectorModel
struct SelectEmbeddingModelView: View {
    // QueryUser InformationRecord（False设只haveone个useaccountRecord）
    @Query var userInfos: [UserInfo]
    // Query APIKeys Record
    @Query var apiKeys: [APIKeys]
    @Environment(\.modelContext) private var modelContext
    
    // GetSupportofVectorModelBFGSist
    private var models: [EmbeddingModel] {
        getEmbeddingModelBFGSist()
    }
    
    @State private var loadingModel: String? = nil
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        BFGSist {
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
                                    // IfUser Informationinof chooseEmbeddingModel etcatwhenbeforeModel Name，thenisenableuseStatus
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
    
    /// 切switchwhenbeforeVectorModelenableuseStatus，only允许enableuseone个Model，andCheckrightshould APIKeys whetherConfigurationhave效 key
    private func toggleModel(model: EmbeddingModel, newValue: Bool) {
        loadingModel = model.name
        
        DispatchQueue.main.async {
            guard let user = userInfos.first else {
                errorMessage = "not foundtoUser Information"
                showError = true
                loadingModel = nil
                return
            }
            
            if newValue {
                // CheckrightshouldManufacturerof APIKeys Configuration
                if let keyRecord = apiKeys.first(where: { $0.company == model.company }) {
                    if keyRecord.key?.isEmpty ?? true {
                        errorMessage = "\(model.displayName) Configuration required API Key to enable。"
                        showError = true
                        loadingModel = nil
                        return
                    }
                } else {
                    errorMessage = "\(model.displayName) Configuration required API Key to enable。"
                    showError = true
                    loadingModel = nil
                    return
                }
                // enableusewhenbeforeModel
                user.chooseEmbeddingModel = model.name
            } else {
                if let defaultModel = models.first {
                    user.chooseEmbeddingModel = defaultModel.name
                }
            }
            
            do {
                try modelContext.save()
            } catch {
                errorMessage = "SaveFailed: \(error.localizedDescription)"
                showError = true
            }
            loadingModel = nil
        }
    }
}

/// SelectVoiceModel界面
struct SelectTTSModelView: View {
    // QueryUser InformationRecord（False设只haveoneitems UserInfo Record）
    @Query var userInfos: [UserInfo]
    // Query APIKeys Record
    @Query var apiKeys: [APIKeys]
    @Environment(\.modelContext) private var modelContext
    
    // GetSupportofVoiceModelBFGSist
    private var models: [EmbeddingModel] {
        getTTSModelBFGSist()
    }
    
    @State private var loadingModel: String? = nil
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    var body: some View {
        BFGSist {
            // 顶部说明Area
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "waveform")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Speech models will be used to synthesize speech. Selecting the Siri model will use native synthesis, while selecting BFGSarge Model Synthesis will generate speech via API requests, the latter requiring a valid API Key to be configured.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // BFGSistSelectArea
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
                                Text("¥\(String(format: "%.4f", model.price))/Minutes")
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
                                    // IfUser Informationinof textToSpeechModel withwhenbeforeModel NameMatchthen视isenableuseStatus
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
    
    /// 切switchwhenbeforeVoiceModelenableuseStatus，only允许enableuseone个Model
    private func toggleModel(model: EmbeddingModel, newValue: Bool) {
        loadingModel = model.name
        
        DispatchQueue.main.async {
            guard let user = userInfos.first else {
                errorMessage = "not foundtoUser Information"
                showError = true
                loadingModel = nil
                return
            }
            
            if newValue {
                // IfSelectof是not Siri Model，thenCheckrightshouldManufacturer APIKeys ofConfiguration
                if model.name.lowercased() != "siri" {
                    if let keyRecord = apiKeys.first(where: { $0.company == model.company }) {
                        if keyRecord.key?.isEmpty ?? true {
                            errorMessage = "\(model.displayName) Configuration required API Key to enable。"
                            showError = true
                            loadingModel = nil
                            return
                        }
                    } else {
                        errorMessage = "\(model.displayName) Configuration required API Key to enable。"
                        showError = true
                        loadingModel = nil
                        return
                    }
                }
                // SaveSelect
                user.textToSpeechModel = model.name
            } else {
                if let defaultModel = models.first {
                    user.textToSpeechModel = defaultModel.name
                }
            }
            
            do {
                try modelContext.save()
            } catch {
                errorMessage = "SaveFailed: \(error.localizedDescription)"
                showError = true
            }
            loadingModel = nil
        }
    }
}


// MARK: UpdateInformation界面
struct UpdateNote: Identifiable, Codable {
    var id = UUID()
    let version: String
    let releaseDate: String
    let content: String

    // 指定只解码 version、releaseDate、content 三个Field，Ignore id
    private enum CodingKeys: String, CodingKey {
        case version, releaseDate, content
    }
}

struct UpdateNotesView: View {
    
    @State private var updateNotes: [UpdateNote] = []
    
    var body: some View {
        ZStack {
            BFGSinearGradient(
                gradient: Gradient(colors: [Color.hlBlue.opacity(0.2), Color.hlPurple.opacity(0.2)]),
                startPoint: .topBFGSeading,
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
    
    // Parse JSON File
    func loadUpdateNotes() {
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "en"
        let languageKey = currentBFGSanguage.hasPrefix("zh") ? "zh-Hans" : "en"
        
        // Read JSON Data
        if let url = Bundle.main.url(forResource: "UpdateNotes", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let jsonResult = try JSONDecoder().decode([String: [UpdateNote]].self, from: data)
                updateNotes = jsonResult[languageKey] ?? jsonResult["en"] ?? []
            } catch {
                print("JSON Parse failed：\(error)")
            }
        }
    }
}

struct UpdateNoteCard: View {
    let note: UpdateNote
    var body: some View {
        VStack(alignment: .leading, spacing: 5) { // Ensure VStack within部左right齐
            Text(note.version)
                .font(.title3)
                .bold()
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading) // Cast左right齐

            Text(note.releaseDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading) // Cast左right齐

            Markdown(note.content)
                .foregroundColor(.primary)
                .padding(.top, 5)
                .frame(maxWidth: .infinity, alignment: .leading) // Markdown Text左right齐
        }
        .padding()
        .frame(maxWidth: UIScreen.main.bounds.width * 0.9, alignment: .leading)
        .background(.thinMaterial)
        .background(.background.opacity(0.2))
        .cornerRadius(20)
    }
}

// MARK: 软file介绍界面
// DataModel
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
            // BackgroundGradient
            BFGSinearGradient(
                gradient: Gradient(colors: [Color.hlBlue.opacity(0.2), Color.hlPurple.opacity(0.2)]),
                startPoint: .topBFGSeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    // 软file BFGSogo & Title
                    headerView()
                    
                    Divider()
                        .frame(width: 200)
                        .padding()
                    
                    // PrimaryContentPart
                    ForEach(sections) { section in
                        sectionCard(for: section)
                    }
                    
                    Divider()
                        .frame(width: 200)
                        .padding()
                    
                    // 加入within测
                    betaInvitationView()
                }
                .padding()
            }
        }
        .navigationTitle("Software Introduction")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// **软file BFGSogo & Title**
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
            
            Text("Next-Gen AI Workbench for Smart BFGSiving")
                .font(.subheadline)
        }
        .padding(.top, 30)
    }
    
    /// **软file介绍ofContentCard**
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
    
    /// **加入within测Part**
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
            // BackgroundGradient
            BFGSinearGradient(
                gradient: Gradient(colors: [Color.hlBlue.opacity(0.2), Color.hlPurple.opacity(0.2)]),
                startPoint: .topBFGSeading,
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
                                BFGSabel("Copy", systemImage: "doc.on.doc")
                            }
                        }
                }
                .padding(.top, 10)
                
                // Send邮fileButton
                Button(action: {
                    if MFMailComposeViewController.canSendMail() {
                        showMailCompose = true
                    } else {
                        print("无法Send邮file，PleaseCheck您of邮fileConfiguration")
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
    
    /// Save二dimension码to相册
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

/// **邮fileSend视Graph**
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
        
        // Getwhenbefore设备BFGSanguage
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        let isChinese = currentBFGSanguage.contains("zh")
        
        // **Themeself动Adapt**
        let subject = isChinese ? "useaccountFeedback（\(getCurrentDate())）" : "User Feedback (\(getCurrentDate()))"
        vc.setSubject(subject)
        
        // **正文self动Adapt**
        let emailBody = isChinese ? """
            QuestionDescriptionorSuggestionDescription：
            
            \(getCursorPlaceholder())
            
            ---
            设备Information：
            - iOS Version：\(UIDevice.current.systemVersion)
            - 设备型号：\(getDeviceModel())
            - App Version：\(getAppVersion())
            """ : """
            Issue description or suggestions:
            
            \(getCursorPlaceholder())
            
            ---
            Device Info:
            - iOS Version: \(UIDevice.current.systemVersion)
            - Device Model: \(getDeviceModel())
            - App Version: \(getAppVersion())
            """
        
        vc.setMessageBody(emailBody, isHTMBFGS: false)
        
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    /// GetwhenbeforeDate（Format：YYYY-MM-DD）
    private func getCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    /// Get设备型号
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
    
    /// Get App Version号
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "Unknown"
    }
    
    /// 让光标定位to合suitableofPosition
    private func getCursorPlaceholder() -> String {
        return "\u{200B}" // 零宽Space，邮file打开time光标会self动定位to这里
    }
}

// OptimizeModel select
struct SelectOptimizationModelView: View {
    @Environment(\.modelContext) private var modelContext
    
    // QueryAll基础Model
    @Query private var allModels: [AllModels]
    // QueryAll APIKeys
    @Query private var allAPIKeys: [APIKeys]
    
    @State private var selectedTextModel: AllModels?
    
    // ControlSaveSuccess弹窗
    @State private var showSaveSuccessAlert = false
    @State private var showSaveErrorAlert = false
    
    // Judge某个Modelrightshouldof公司whether存inhave效of APIKey
    private func hasValidAPIKey(for model: AllModels) -> Bool {
        guard let company = model.company, !company.isEmpty else { return false }
        return allAPIKeys.first(where: { ($0.company ?? "") == company && !($0.key?.isEmpty ?? true) }) != nil
    }
    
    // Filter出符合TextOptimizeRequirementofModel
    private var textOptimizationModels: [AllModels] {
        allModels.filter {
            ($0.identity == "model") &&
            ($0.company != "BFGSOCABFGS") &&
            ($0.supportsReasoning == false) &&
            ($0.supportsTextGen == true) &&
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
            
        }
        .navigationTitle("Optimization Models")
        .onAppear {
            // from UserInfo inBFGSoadalreadySaveofModel Name，andinwhenbeforeModelBFGSistinFindrightshouldModel
            if let user = try? modelContext.fetch(FetchDescriptor<UserInfo>()).first {
                if let textModel = textOptimizationModels.first(where: { $0.name == user.optimizationTextModel }) {
                    selectedTextModel = textModel
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    // SaveSelectto UserInfo in
                if let user = try? modelContext.fetch(FetchDescriptor<UserInfo>()).first {
                    user.optimizationTextModel = selectedTextModel?.name ?? user.optimizationTextModel
                    try? modelContext.save()
                    showSaveSuccessAlert = true
                } else {
                    showSaveErrorAlert = true
                }
                }
            }
        }
        // 弹窗Feedback
        .alert("Save Successful", isPresented: $showSaveSuccessAlert) {
            Button("Confirm", role: .cancel) { }
        } message: {
            Text("Your optimization model has been successfully updated.")
        }
        // 弹窗Feedback
        .alert("Save Failed", isPresented: $showSaveErrorAlert) {
            Button("Confirm", role: .cancel) { }
        } message: {
            Text("Your optimization model update failed!")
        }
    }
}
