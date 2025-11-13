//
//  APISettingView.swift
//  AI_Hanlin
//
//  Created by 哆啦好多梦 on 24/3/25.
//

import SwiftUI
import SwiftData

// MARK: 大模型 API 与厂商设置界面
struct APIKeysView: View {
    // 查询所有 APIKeys、所有模型与模型信息
    @Query var apiKeys: [APIKeys]
    @Query var allModels: [AllModels]
    
    // 环境中的 SwiftData 上下文
    @Environment(\.modelContext) private var modelContext
    
    // APIKey 编辑状态
    @State private var selectedKey: APIKeys?
    @State private var testResult: Bool? = nil
    @State private var isTesting = false
    @State private var isInquiring = false
    @State private var inquiryResult: Double? = nil

    // 错误提示及加载状态
    @State private var errorMessage: String = ""
    @State private var showAPIKeyError: Bool = false
    @State private var loadingCompany: String? = nil

    // 新增自定义供应商状态
    @State private var showAddCustomProvider = false
    
    // 按完整拼音排序 APIKeys（过滤掉 LOCAL、HANLIN、HANLIN_OPEN 类型）
    private var sortedApiKeys: [APIKeys] {
        apiKeys
            .filter {
                let company = ($0.company ?? "").uppercased()
                return company != "LOCAL" && company != "HANLIN" && company != "HANLIN_OPEN"
            }
            .sorted { key1, key2 in
                let pinyin1 = getPinyin(for: getCompanyName(for: key1))
                let pinyin2 = getPinyin(for: getCompanyName(for: key2))
                return pinyin1 < pinyin2
            }
    }

    // 获取唯一厂商，并按完整拼音排序
    private var sortedCompanies: [(company: String, key: APIKeys)] {
        let uniqueCompanies = Dictionary(grouping: apiKeys, by: { $0.company })
            .compactMapValues { $0.first } // 每个厂商只取一条数据
        return uniqueCompanies.values.sorted { key1, key2 in
            let pinyin1 = getPinyin(for: getCompanyName(for: key1))
            let pinyin2 = getPinyin(for: getCompanyName(for: key2))
            return pinyin1 < pinyin2
        }.map { ( ($0.company ?? "Unknown"), $0) }
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "key.2.on.ring")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Tap a vendor name or key to set its API key and enable its model.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            ForEach(sortedCompanies, id: \.company) { company, key in
                HStack {
                    // 按钮部分：只有允许配置 API 的才可点击进入编辑界面
                    Button {
                        // 仅当允许设置 API 时响应点击
                        if isAPISettingAllowed(for: key) {
                            // 重置相关状态并进入编辑界面
                            inquiryResult = nil
                            testResult = nil
                            isTesting = false
                            isInquiring = false
                            selectedKey = key
                        }
                    } label: {
                        HStack {
                            // 自定义供应商使用 defaultIcon，系统供应商使用资源图片
                            if key.from == .custom {
                                Image("defaultIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            } else {
                                Image(getCompanyIcon(for: company))
                                    .resizable()
                                    .frame(width: 24, height: 24)
                            }

                            // 使用重载函数自动处理自定义供应商名称
                            Text(getCompanyName(for: key))
                            Spacer()
                            if isAPISettingAllowed(for: key) {
                                Image(systemName: "key")
                                    .foregroundColor(.hlBluefont)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Toggle 控件：如果当前厂商正在加载，则显示加载动画
                    if loadingCompany == company {
                        ProgressView()
                    } else {
                        Toggle("", isOn: Binding(
                            get: { !key.isHidden },
                            set: { newValue in
                                toggleVendor(key: key, company: company, newValue: newValue)
                            }
                        ))
                        .labelsHidden()
                        .tint(.hlBlue)
                        // 当 API Key 无效时，不允许通过 Toggle 开启厂商
                        .disabled(!hasValidAPIKey(for: key))
                    }
                }
            }
        }
        .navigationTitle("API Key Settings")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showAddCustomProvider = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.hlBluefont)
                }
            }
        }
        .sheet(item: $selectedKey) { key in
            editKeyView(for: key)
        }
        .sheet(isPresented: $showAddCustomProvider) {
            addCustomProviderView()
        }
        .alert("Unable to Enable Vendor", isPresented: $showAPIKeyError) {
            Button("Confirm", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: API Key 编辑界面
    @ViewBuilder
    private func editKeyView(for key: APIKeys) -> some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .center) {
                        // 自定义供应商使用 defaultIcon
                        if key.from == .custom {
                            Image("defaultIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .padding()
                        } else {
                            Image(getCompanyIcon(for: key.company ?? "Unknown"))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .padding()
                        }

                        Text("设置 \(getCompanyName(for: key)) API密钥，以启用该厂商的模型")
                            .font(.footnote)
                            .multilineTextAlignment(.center)

                        // 自定义供应商不显示获取API密钥的链接
                        if key.from != .custom {
                            if let url = URL(string: key.help) {
                                Link("🔗 点此获取 \(getCompanyName(for: key)) API密钥", destination: url)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom)
                            } else {
                                // 当 URL 无效时可以提供一个备用视图
                                Text("It is recommended to access its open platform to obtain the API key.")
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                Section(header: Text("API Key")) {
                    SecureField("Please enter the API key", text: Binding(
                        get: { key.key ?? "" },
                        set: { key.key = $0 }
                    ))
                }
                // 自定义供应商或LAN供应商显示请求地址设置
                if key.company == "LAN" || key.from == .custom {
                    Section(header: Text("Request URLs")) {
                        Text(verbatim: "例如：http://127.0.0.1:1234/v1/chat/completions")
                            .font(.caption)
                        TextField("Please enter the request URLs", text: Binding(
                            get: { key.requestURL ?? "" },
                            set: { key.requestURL = $0 }
                        ))
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    }
                }
                // 测试 API 按钮及状态显示（局域网模型和自定义供应商不显示）
                if key.company != "LAN" && key.from != .custom {
                    Section {
                        HStack {
                            Button("Test API") {
                                testAPI(for: key)
                            }
                            .disabled(isTesting)
                            Spacer()
                            if isTesting {
                                ProgressView()
                            } else if let result = testResult {
                                Text(result ? "Test Passed" : "Test Failed")
                                    .foregroundColor(result ? .green : .red)
                            }
                        }
                    }
                }
                if key.company == "DEEPSEEK" || key.company == "SILICONCLOUD" {
                    // 余额查询及状态显示
                    Section {
                        HStack {
                            Button("Check API Balance") {
                                queryBalance(for: key)
                            }
                            .disabled(isInquiring)
                            Spacer()
                            if isInquiring {
                                ProgressView()
                            } else if let result = inquiryResult {
                                Text(result == -999 ? "Not Supported" : "¥\(result)")
                                    .foregroundColor(result < 10 ? .red : .green)
                            }
                        }
                    }
                }
                Section {
                    Text("⚠️ Note: Once configured, the vendor is enabled automatically. To change it, disable it in the menu.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Edit API Key")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedKey = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        key.timestamp = Date()
                        key.isHidden = false
                        try? modelContext.save()
                        selectedKey = nil
                    }
                }
            }
            .onAppear {
                testResult = nil
            }
        }
    }
    
    // MARK: - API 测试与查询
    /// 点击测试 API 时调用
    private func testAPI(for key: APIKeys) {
        isTesting = true
        testResult = nil
        Task {
            let result = await testAIAPI(
                apiKey: key.key ?? "",
                requestURL: key.requestURL ?? "",
                company: key.company ?? ""
            )
            testResult = result
            isTesting = false
        }
    }
    
    /// 点击查询 API 余额时调用
    private func queryBalance(for key: APIKeys) {
        isInquiring = true
        inquiryResult = nil
        Task {
            defer { isInquiring = false }
            guard let company = key.company?.uppercased(),
                  let token = key.key, !token.isEmpty else { return }
            do {
                switch company {
                case "DEEPSEEK":
                    inquiryResult = try await fetchDeepSeekBalance(token: token)
                case "SILICONCLOUD":
                    inquiryResult = try await fetchSiliconFlowBalance(token: token)
                default:
                    inquiryResult = -999
                }
            } catch {
                print("余额查询失败：\(error)")
                inquiryResult = nil
            }
        }
    }
    
    // MARK: - 厂商隐藏/显示处理
    /// 处理厂商开关逻辑，并增加加载状态
    private func toggleVendor(key: APIKeys, company: String, newValue: Bool) {
        loadingCompany = company
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                if !newValue {
                    // 关闭厂商
                    key.isHidden = true
                    updateModelVisibility(for: company, isHidden: true)
                } else if hasValidAPIKey(for: key) {
                    // 开启厂商（API Key 有效）
                    key.isHidden = false
                } else {
                    // API Key 为空时阻止开启，并显示错误提示
                    errorMessage = "\(getCompanyName(for: key)) 需要有效的 API Key，请先设置密钥。"
                    showAPIKeyError = true
                }
                saveChanges()
                loadingCompany = nil
            }
        }
    }
    
    /// 检查 APIKey 是否有效（非空即可）
    private func hasValidAPIKey(for key: APIKeys) -> Bool {
        return !(key.key?.isEmpty ?? true)
    }
    
    /// 保存数据
    private func saveChanges() {
        DispatchQueue.main.async {
            do {
                try modelContext.save()
            } catch {
                print("保存失败: \(error.localizedDescription)")
            }
        }
    }
    
    /// 将文本转换为拼音（大写），用于排序
    private func getPinyin(for text: String) -> String {
        let mutableString = NSMutableString(string: text) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        return (mutableString as String).uppercased()
    }
    
    /// 更新 AllModels 与 ModelsInfo 数据库中该厂商的所有模型的 isHidden 状态
    private func updateModelVisibility(for company: String, isHidden: Bool) {
        for model in allModels where model.company == company {
            model.isHidden = isHidden
        }
    }
    
    /// 判断是否允许进入 API Key 编辑（即允许设置 API），此处根据公司名称过滤
    private func isAPISettingAllowed(for key: APIKeys) -> Bool {
        guard let company = key.company?.uppercased() else { return false }
        return !(company == "LOCAL" || company == "HANLIN" || company == "HANLIN_OPEN")
    }

    // MARK: 新增自定义供应商界面
    @ViewBuilder
    private func addCustomProviderView() -> some View {
        NavigationView {
            AddCustomProviderForm(modelContext: modelContext, isPresented: $showAddCustomProvider)
        }
    }
}

// MARK: - 新增自定义供应商表单视图
struct AddCustomProviderForm: View {
    let modelContext: ModelContext
    @Binding var isPresented: Bool

    @State private var providerName: String = ""
    @State private var apiKey: String = ""
    @State private var requestURL: String = ""
    @State private var showValidationError = false
    @State private var validationMessage = ""

    var body: some View {
        Form {
            Section {
                VStack(alignment: .center) {
                    Image("defaultIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .padding()

                    Text("Add a custom API provider that uses the OpenAI-compatible API format.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }

            Section(header: Text("Provider Name")) {
                TextField("Please enter a provider name", text: $providerName)
            }

            Section(header: Text("API Key")) {
                SecureField("Please enter an API key", text: $apiKey)
            }

            Section(header: Text("Request URLs")) {
                Text("Example: https://api.example.com/v1/chat/completions")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Please enter the request URLs", text: $requestURL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                if !requestURL.isEmpty && !requestURL.hasSuffix("/v1/chat/completions") {
                    Button("Complete /v1/chat/completions") {
                        completeURL()
                    }
                    .font(.caption)
                    .foregroundColor(.hlBluefont)
                }
            }

            Section {
                Text("Tip: This feature works with OpenAI-compatible services such as LocalAI, Ollama, or other third-party APIs.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Add Custom Provider")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    isPresented = false
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveCustomProvider()
                }
                .disabled(!isFormValid)
            }
        }
        .alert("Verification failed", isPresented: $showValidationError) {
            Button("Confirm", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
    }

    private var isFormValid: Bool {
        !providerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !requestURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (requestURL.hasPrefix("http://") || requestURL.hasPrefix("https://"))
    }

    private func completeURL() {
        var trimmedURL = requestURL.trimmingCharacters(in: .whitespacesAndNewlines)

        // 移除末尾的斜杠
        while trimmedURL.hasSuffix("/") {
            trimmedURL.removeLast()
        }

        // 补全标准路径
        if !trimmedURL.hasSuffix("/v1/chat/completions") {
            trimmedURL += "/v1/chat/completions"
        }

        requestURL = trimmedURL
    }

    private func saveCustomProvider() {
        let trimmedName = providerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = requestURL.trimmingCharacters(in: .whitespacesAndNewlines)

        // 验证
        guard !trimmedName.isEmpty else {
            validationMessage = "供应商名称不能为空"
            showValidationError = true
            return
        }

        guard !trimmedKey.isEmpty else {
            validationMessage = "API Key 不能为空"
            showValidationError = true
            return
        }

        guard !trimmedURL.isEmpty else {
            validationMessage = "请求地址不能为空"
            showValidationError = true
            return
        }

        guard trimmedURL.hasPrefix("http://") || trimmedURL.hasPrefix("https://") else {
            validationMessage = "请求地址必须以 http:// 或 https:// 开头"
            showValidationError = true
            return
        }

        // 创建自定义供应商
        let customProvider = APIKeys(
            name: trimmedName,
            company: "CUSTOM_\(UUID().uuidString.prefix(8).uppercased())", // 使用唯一标识避免冲突
            key: trimmedKey,
            requestURL: trimmedURL,
            isHidden: false, // 默认启用
            help: "自定义 API 供应商",
            apiType: .openAI,
            from: .custom,
            timestamp: Date()
        )

        modelContext.insert(customProvider)

        do {
            try modelContext.save()
            isPresented = false
        } catch {
            validationMessage = "保存失败：\(error.localizedDescription)"
            showValidationError = true
        }
    }
}

// MARK: 搜索设置（API 配置、厂商选择、双语检索配置）界面
struct SearchSettingView: View {
    // 从数据库中获取搜索密钥配置
    @Query var searchKeys: [SearchKeys]
    // 从数据库中获取用户信息（用于双语检索配置）
    @Query private var users: [UserInfo]
    @Environment(\.modelContext) private var modelContext
    
    // SearchKeysView 部分状态
    // 用于编辑 API 配置状态
    @State private var selectedKey: SearchKeys?
    // API 测试相关状态
    @State private var testResult: Bool? = nil
    @State private var isTesting = false
    // 切换厂商启用状态时的加载与错误提示状态
    @State private var loadingCompany: String? = nil
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    // 双语检索配置状态
    @State private var bilingualSearch: Bool = true
    @State private var searchCount: Int = 10
    @State private var searchEnable: Bool = true
    
    // SearchKeysView 排序（按照公司名称拼音排序）
    private var sortedSearchKeys: [SearchKeys] {
        searchKeys.sorted { key1, key2 in
            let pinyin1 = getPinyin(for: getCompanyName(for: key1.company ?? "Unknown"))
            let pinyin2 = getPinyin(for: getCompanyName(for: key2.company ?? "Unknown"))
            return pinyin1 < pinyin2
        }
    }
    
    var body: some View {
        Form {
            // 顶部说明区域：统一介绍搜索配置的意义
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "magnifyingglass")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Enable the search function to allow models to fetch internet content during chats, improving response quality; personalized settings balance your needs and retrieval costs.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            // 检索设置部分
            Section(header: Text("Models actively search when needed")) {
                Toggle("Enable Active Search", isOn: Binding(
                    get: { searchEnable },
                    set: { searchEnable = $0 }))
                .tint(.hlBlue)
            }
            
            Section(header: Text("Number of Search Results (range: 5-20)")) {
                Stepper(value: $searchCount, in: 5...20) {
                    Text("搜索结果数量：\(searchCount)")
                }
            }
            
            Section(header: Text("Search Both Chinese and English Content")) {
                Toggle("Bilingual Search (Chinese & English)", isOn: $bilingualSearch)
                    .tint(.hlBlue)
            }
            
            // 搜索 API 配置及厂商选择部分
            Section(header: Text("Search engine selection (only one)")) {
                ForEach(sortedSearchKeys) { key in
                    HStack {
                        // 点击左侧区域进入编辑 API 配置界面
                        Button {
                            selectedKey = key
                        } label: {
                            HStack {
                                Image(getCompanyIcon(for: key.company ?? "Unknown"))
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                Text(getCompanyName(for: key.company ?? "Unknown"))
                                    .foregroundColor(.primary)
                                
                                // 显示各厂商的计费或免费说明
                                switch key.company?.uppercased() {
                                case "GOOGLE_SEARCH":
                                    Text("100 free uses/day")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                case "TAVILY":
                                    Text("1000 free points/month")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                case "LANGSEARCH":
                                    Text("Free")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                case "BRAVE":
                                    Text("2000 free uses/month")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                default:
                                    if let price = key.price {
                                        Text("¥\(String(format: "%.4f", price))/次")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "key")
                                    .foregroundColor(.hlBluefont)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 右侧区域：显示加载指示或 Toggle 控件切换启用状态
                        if loadingCompany == key.company {
                            ProgressView()
                        } else {
                            Toggle("", isOn: Binding(
                                get: { key.isUsing },
                                set: { newValue in
                                    toggleVendor(for: key, newValue: newValue)
                                }
                            ))
                            .labelsHidden()
                            .tint(.hlBlue)
                        }
                    }
                }
            }
            
            Section(header: Text("Function List")) {
                Label("Network Information Retrieval", systemImage: "network")
                Label("Academic Paper Search", systemImage: "graduationcap")
                Label("Web Content Reading", systemImage: "text.and.command.macwindow")
                Label("Online Document Reading", systemImage: "text.document")
            }
        }
        .navigationTitle("Network Search")
        // 编辑 API 配置界面（SearchKeysView 部分）的弹出 sheet
        .sheet(item: $selectedKey) { key in
            editKeyView(for: key)
        }
        // 出现错误时弹出警告
        .alert(errorMessage, isPresented: $showError) {
            Button("Confirm", role: .cancel) { }
        }
        // 加载/保存双语检索相关的用户信息
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
    }
    
    // 加载数据库中的用户信息（双语检索设置）
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.bilingualSearch = existingUser.bilingualSearch
                self.searchCount = existingUser.searchCount
                self.searchEnable = existingUser.useSearch
            }
        }
    }
    
    // 保存双语检索设置到数据库
    private func saveUserInfo() {
        if let existingUser = users.first {
            existingUser.bilingualSearch = bilingualSearch
            existingUser.searchCount = searchCount
            existingUser.useSearch = searchEnable
        } else {
            let newUser = UserInfo(
                bilingualSearch: bilingualSearch,
                useSearch: searchEnable,
                searchCount: searchCount,
            )
            modelContext.insert(newUser)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("保存失败：\(error.localizedDescription)")
        }
    }
    
    // 编辑搜索 API 密钥界面（SearchKeysView 部分）
    @ViewBuilder
    private func editKeyView(for key: SearchKeys) -> some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .center) {
                        Image(getCompanyIcon(for: key.company ?? "Unknown"))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .padding()

                        Text("设置 \(getCompanyName(for: key.company ?? "Unknown")) API密钥，以开启该搜索引擎")
                            .font(.footnote)
                            .multilineTextAlignment(.center)

                        if let url = URL(string: key.help) {
                            Link("🔗 点此获取 \(getCompanyName(for: key.company ?? "Unknown")) API密钥", destination: url)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .padding(.bottom)
                        } else {
                            Text("It is recommended to access its open platform to obtain the API key.")
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .padding(.bottom)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                Section(header: Text("API KEY")) {
                    SecureField("Please enter the API key", text: Binding(
                        get: { key.key ?? "" },
                        set: { key.key = $0 }
                    ))
                }
                // 测试 API 部分
                Section {
                    HStack {
                        Button("Test API") {
                            testAPI(for: key)
                        }
                        .disabled(isTesting)
                        
                        Spacer()
                        
                        if isTesting {
                            ProgressView()
                        } else if let result = testResult {
                            Text(result ? "Test Passed" : "Test Failed")
                                .foregroundColor(result ? .green : .red)
                        }
                    }
                }
                Section {
                    Text("⚠️ Note: After configuring the API, enable your desired search engine in the menu.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Edit API Key")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedKey = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        key.timestamp = Date()
                        try? modelContext.save()
                        selectedKey = nil
                    }
                }
            }
            .onAppear {
                testResult = nil
            }
        }
    }
    
    // 测试搜索 API
    private func testAPI(for key: SearchKeys) {
        isTesting = true
        testResult = nil
        
        Task {
            // 根据 key.company 获取对应的搜索引擎，默认使用 .LANGSEARCH
            let engine = SearchEngine(rawValue: key.company?.uppercased() ?? "") ?? .LANGSEARCH
            let result = await testSearchAPI(
                apiKey: key.key ?? "",
                requestURL: key.requestURL ?? "",
                engine: engine
            )
            testResult = result
            isTesting = false
        }
    }
    
    // 切换搜索厂商启用状态
    /// 仅允许一个厂商启用。若开启当前厂商，则关闭其它所有厂商。
    private func toggleVendor(for key: SearchKeys, newValue: Bool) {
        loadingCompany = key.company
        
        DispatchQueue.main.async {
            if newValue {
                // 开启前检查是否已配置 API Key
                if key.key?.isEmpty ?? true {
                    errorMessage = "\(getCompanyName(for: key.company ?? "Unknown")) 需要配置 API Key 才能启用。"
                    showError = true
                    loadingCompany = nil
                    return
                }
                // 开启当前厂商，同时关闭其它厂商
                for vendor in searchKeys {
                    vendor.isUsing = (vendor.id == key.id)
                }
            } else {
                // 关闭当前厂商
                key.isUsing = false
            }
            
            do {
                try modelContext.save()
            } catch {
                errorMessage = "保存失败: \(error.localizedDescription)"
                showError = true
            }
            loadingCompany = nil
        }
    }
    
    // 获取公司名称的拼音（用于排序）
    private func getPinyin(for text: String) -> String {
        let mutableString = NSMutableString(string: text) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        return (mutableString as String).uppercased()
    }
}

// MARK: - 知识背包配置界面
struct KnowledgeSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // 从数据库获取用户信息
    
    @State private var knowledgeEnable: Bool = true
    @State private var knowledgeCount: Int = 10
    @State private var knowledgeSimilarity: Double = 0.5
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "backpack")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Enable the knowledge function to let models search your knowledge backpack for private content during chats, enhancing response effectiveness.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section(header: Text("The model actively searches through its knowledge base when needed.")) {
                Toggle("Enable Active Search", isOn: Binding(
                    get: { knowledgeEnable },
                    set: { knowledgeEnable = $0 }))
                .tint(.hlBlue)
            }
            
            Section(header: Text("Number of Search Results (range: 5-20)")) {
                Stepper(value: $knowledgeCount, in: 5...20) {
                    Text("翻找结果数量：\(knowledgeCount)")
                }
            }
            
            Section(header: Text("Match threshold (range: 0.05 - 1.0)")) {
                Stepper(value: $knowledgeSimilarity, in: 0.05...1.0, step: 0.05) {
                    Text(String(format: "匹配度阈值：%.2f", knowledgeSimilarity))
                }
            }
            
            Section(header: Text("Function List")) {
                Label("Knowledge Backpack Search", systemImage: "backpack")
                Label("Knowledge Document Creation", systemImage: "text.document")
            }
        }
        .navigationTitle("Knowledge Backpack")
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
    }
    
    /// 加载数据库中的用户信息
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.knowledgeEnable = existingUser.useKnowledge
                self.knowledgeCount = existingUser.knowledgeCount
                self.knowledgeSimilarity = existingUser.knowledgeSimilarity
            }
        }
    }
    
    /// 保存当前设置到数据库
    private func saveUserInfo() {
        if let existingUser = users.first {
            existingUser.useKnowledge = knowledgeEnable
            existingUser.knowledgeCount = knowledgeCount
            existingUser.knowledgeSimilarity = knowledgeSimilarity
        } else {
            let newUser = UserInfo(
                useKnowledge: knowledgeEnable,
                knowledgeCount: knowledgeCount,
                knowledgeSimilarity: knowledgeSimilarity
            )
            modelContext.insert(newUser)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("保存失败：\(error.localizedDescription)")
        }
    }
}

// MARK: - 地图配置界面
struct MapSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // 从数据库获取用户信息
    // 查询 toolClass 为 "map" 的 ToolKeys 数据
    @Query(filter: #Predicate<ToolKeys> { key in
        key.toolClass == "map"
    })
    var mapKeys: [ToolKeys]
    
    @State private var mapEnable: Bool = true
    
    // 用于地图引擎配置相关状态
    @State private var selectedMapKey: ToolKeys?
    @State private var loadingMapCompany: String? = nil
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    // 根据需求对 mapKeys 排序，此处按公司名称排序
    private var sortedMapKeys: [ToolKeys] {
        mapKeys.sorted { $0.company < $1.company }
    }
    
    var body: some View {
        
        Form {
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "map")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Enable the map function to allow the model to access location-related information and display maps during conversations.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
            }
            
            Section {
                Toggle("Enable Maps", isOn: Binding(
                    get: { mapEnable },
                    set: { mapEnable = $0 }))
                .tint(.hlBlue)
            }
            
            Section(header: Text("Map Engine Selection (max one)")) { 
                ForEach(sortedMapKeys) { key in
                    HStack {
                        // 左侧区域：点击可进入 API 配置界面（APPLEMAPP 不可配置 API）
                        Button {
                            if key.company.uppercased() != "APPLEMAP" {
                                selectedMapKey = key
                            }
                        } label: {
                            HStack {
                                Image(getCompanyIcon(for: key.company))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                Text(getCompanyName(for: key.company))
                                    .foregroundColor(.primary)
                                Spacer()
                                // 对于默认的 APPLEMAP，显示"Default"标识
                                if key.company.uppercased() == "APPLEMAP" {
                                    Text("Default")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } else {
                                    Image(systemName: "key")
                                        .foregroundColor(.hlBluefont)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 右侧区域：切换启用状态（仅一个引擎能启用）
                        if loadingMapCompany == key.company {
                            ProgressView()
                        } else {
                            Toggle("", isOn: Binding(
                                get: { key.isUsing },
                                set: { newValue in
                                    toggleMapEngine(for: key, newValue: newValue)
                                }
                            ))
                            .labelsHidden()
                            .tint(.hlBlue)
                        }
                    }
                }
            }
            
            Section(header: Text("Function List")) {
                Label("User Location Search", systemImage: "location")
                Label("Specific Location Search", systemImage: "mappin.and.ellipse")
                Label("Nearby Interests Search", systemImage: "mecca")
                Label("Automatic Route Planning", systemImage: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
            }
        }
        .navigationTitle("Map & Planning")
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
        // 弹出编辑 API 配置界面
        .sheet(item: $selectedMapKey) { key in
            editMapKeyView(for: key)
        }
        .alert(errorMessage, isPresented: $showError) {
            Button("Confirm", role: .cancel) { }
        }
    }
    
    /// 加载数据库中的用户信息
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.mapEnable = existingUser.useMap
            }
        }
    }
    
    /// 保存当前设置到数据库
    private func saveUserInfo() {
        if let existingUser = users.first {
            existingUser.useMap = mapEnable
        } else {
            let newUser = UserInfo(
                useMap: mapEnable,
            )
            modelContext.insert(newUser)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("保存失败：\(error.localizedDescription)")
        }
    }
    
    // 仅允许一个引擎启用；启用非 AppleMap 时需确保 API Key 已配置
    private func toggleMapEngine(for key: ToolKeys, newValue: Bool) {
        loadingMapCompany = key.company
        DispatchQueue.main.async {
            if newValue {
                // 对于非 AppleMap 必须配置 API Key 才能启用
                if key.company.uppercased() != "APPLEMAP" && key.key.isEmpty {
                    errorMessage = "\(getCompanyName(for: key.company)) 需要配置 API Key 才能启用。"
                    showError = true
                    loadingMapCompany = nil
                    return
                }
                // 启用当前引擎，同时关闭其它引擎
                for engine in mapKeys {
                    engine.isUsing = (engine.id == key.id)
                }
            } else {
                // 禁用当前引擎
                key.isUsing = false
            }
            
            do {
                try modelContext.save()
            } catch {
                errorMessage = "保存失败: \(error.localizedDescription)"
                showError = true
            }
            ensureDefaultEngine()
            loadingMapCompany = nil
        }
    }
    
    /// 如果没有任何引擎被启用，就自动启用系统 AppleMap
    private func ensureDefaultEngine() {
        // 只在整体“启用地图”是开的情况下才做
        guard mapEnable else { return }
        // 如果一个都没被 isUsing
        if !mapKeys.contains(where: { $0.isUsing }) {
            if let apple = mapKeys.first(where: { $0.company.uppercased() == "APPLEMAP" }) {
                apple.isUsing = true
                do {
                    try modelContext.save()
                } catch {
                    print("默认启用 AppleMap 失败：\(error)")
                }
            }
        }
    }
    
    // MARK: 编辑 API 配置视图
    @ViewBuilder
    private func editMapKeyView(for key: ToolKeys) -> some View {
        NavigationView {
            Form {
                // APPLEMAP 无需配置 API
                if key.company.uppercased() == "APPLEMAP" {
                    Section {
                        Text("APPLEMAP does not require API Key configuration.")
                            .foregroundColor(.gray)
                    }
                } else {
                    Section {
                        VStack(alignment: .center) {
                            Image(getCompanyIcon(for: key.company))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 50, height: 50)
                                .padding()

                            Text("设置 \(getCompanyName(for: key.company)) API密钥，以开启该地图引擎")
                                .font(.footnote)
                                .multilineTextAlignment(.center)

                            if let url = URL(string: key.help) {
                                Link("🔗 点此获取 \(getCompanyName(for: key.company)) API密钥", destination: url)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom)
                            } else {
                                // 当 URL 无效时可以提供一个备用视图
                                Text("It is recommended to access its open platform to obtain the API key.")
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Section(header: Text("API KEY")) {
                        SecureField("Please enter the API key", text: Binding(
                            get: { key.key },
                            set: { key.key = $0 }
                        ))
                    }
                }
            }
            .navigationTitle("Edit API Key")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedMapKey = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        key.timestamp = Date()
                        try? modelContext.save()
                        selectedMapKey = nil
                    }
                }
            }
        }
    }
}


// MARK: - 日历配置界面
struct CalendarSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // 从数据库获取用户信息
    
    @State private var calendarEnable: Bool = true
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "calendar")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Enable calendar functions to let supported models retrieve schedules and reminders or add events to your calendar.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section {
                Toggle("Enable Calendar", isOn: Binding(
                    get: { calendarEnable },
                    set: { calendarEnable = $0 }))
                .tint(.hlBlue)
            }
            
            Section(header: Text("Function List")) {
                Label("Find Calendar Events", systemImage: "calendar.badge.checkmark")
                Label("Find Reminders", systemImage: "checklist")
                Label("Add Calendar Events", systemImage: "calendar.badge.plus")
                Label("Add New Reminder", systemImage: "text.badge.plus")
            }
        }
        .navigationTitle("Calendar & Reminder")
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
    }
    
    /// 加载数据库中的用户信息
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.calendarEnable = existingUser.useCalendar
            }
        }
    }
    
    /// 保存当前设置到数据库
    private func saveUserInfo() {
        if let existingUser = users.first {
            existingUser.useCalendar = calendarEnable
        } else {
            let newUser = UserInfo(
                useCalendar: calendarEnable,
            )
            modelContext.insert(newUser)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("保存失败：\(error.localizedDescription)")
        }
    }
}

// MARK: - 网页配置界面
struct CodeSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // 从数据库获取用户信息
    
    @State private var CodeEnable: Bool = true
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "apple.terminal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Enable the code function to allow supported models to run Python code or generate web content during conversations.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section {
                Toggle("Enable Code", isOn: Binding(
                    get: { CodeEnable },
                    set: { CodeEnable = $0 }))
                .tint(.hlBlue)
            }
            
            Section(header: Text("Function List")) {
                Label("Render Web Content", systemImage: "macwindow.badge.plus")
                Label("Run Program Codes", systemImage: "apple.terminal")
            }
        }
        .navigationTitle("Code Execution")
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
    }
    
    /// 加载数据库中的用户信息
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.CodeEnable = existingUser.useCode
            }
        }
    }
    
    /// 保存当前设置到数据库
    private func saveUserInfo() {
        if let existingUser = users.first {
            existingUser.useCode = CodeEnable
        } else {
            let newUser = UserInfo(
                useCode: CodeEnable,
            )
            modelContext.insert(newUser)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("保存失败：\(error.localizedDescription)")
        }
    }
}

// MARK: - 健康配置界面
struct HealthSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // 从数据库获取用户信息
    
    @State private var healthEnable: Bool = true
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "heart")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Enable health functions so supported models can access or record your health and dietary information.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section {
                Toggle("Enable Health", isOn: Binding(
                    get: { healthEnable },
                    set: { healthEnable = $0 }))
                .tint(.hlBlue)
            }
            
            Section(header: Text("Function List")) {
                Label("Query Step Distance", systemImage: "figure.walk")
                Label("Query Energy Consumption", systemImage: "flame")
                Label("Enquire Nutritional Intake", systemImage: "bubbles.and.sparkles")
                Label("Nutritional Intake", systemImage: "pencil.and.list.clipboard")
            }
        }
        .navigationTitle("Healthy & Living")
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
    }
    
    /// 加载数据库中的用户信息
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.healthEnable = existingUser.useHealth
            }
        }
    }
    
    /// 保存当前设置到数据库
    private func saveUserInfo() {
        if let existingUser = users.first {
            existingUser.useHealth = healthEnable
        } else {
            let newUser = UserInfo(
                useHealth: healthEnable,
            )
            modelContext.insert(newUser)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("保存失败：\(error.localizedDescription)")
        }
    }
}

// MARK: - 健康配置界面
struct CanvasSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // 从数据库获取用户信息
    
    @State private var canvasEnable: Bool = true
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "pencil.and.outline")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Enable canvas function so that when interacting with models that support tools, the model can use the canvas tool to provide a better editing experience for long texts, large paragraphs, or structured content output.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section {
                Toggle("Enable Canvas", isOn: Binding(
                    get: { canvasEnable },
                    set: { canvasEnable = $0 }))
                .tint(.hlBlue)
            }
            
            Section(header: Text("Function List")) {
                Label("Create an Information Canvas", systemImage: "pencil.and.outline")
                Label("Edit Canvas Contents", systemImage: "pencil.and.scribble")
                Label("Run Canvas Codes", systemImage: "play.circle")
                Label("Render Canvas Webpage", systemImage: "macwindow")
            }
        }
        .navigationTitle("Information Canvas")
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
    }
    
    /// 加载数据库中的用户信息
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.canvasEnable = existingUser.useCanvas
            }
        }
    }
    
    /// 保存当前设置到数据库
    private func saveUserInfo() {
        if let existingUser = users.first {
            existingUser.useCanvas = canvasEnable
        } else {
            let newUser = UserInfo(
                useCanvas: canvasEnable,
            )
            modelContext.insert(newUser)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("保存失败：\(error.localizedDescription)")
        }
    }
}

// MARK: - 天气配置界面
struct WeatherSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo]                   // 从数据库获取用户信息
    // 查询 toolClass 为 "weather" 的 ToolKeys 数据
    @Query(filter: #Predicate<ToolKeys> { key in
        key.toolClass == "weather"
    })
    var weatherKeys: [ToolKeys]
    
    @State private var weatherEnable: Bool = true
    
    // 用于天气服务商配置相关状态
    @State private var selectedWeatherKey: ToolKeys?
    @State private var loadingWeatherCompany: String? = nil
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    // 对 weatherKeys 按公司名称排序
    private var sortedWeatherKeys: [ToolKeys] {
        weatherKeys.sorted { $0.company < $1.company }
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "cloud.sun")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Enable the weather feature to obtain real-time weather information and future forecasts when conversing with models that support this tool.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Section {
                Toggle("Enable Weather", isOn: Binding(
                    get: { weatherEnable },
                    set: { weatherEnable = $0 }
                ))
                .tint(.hlBlue)
            }
            
            Section(header: Text("Weather service provider selection (only one can be enabled)")) {
                ForEach(sortedWeatherKeys) { key in
                    HStack {
                        // 点击进入 API 配置界面
                        Button {
                            selectedWeatherKey = key
                        } label: {
                            HStack {
                                Image(getCompanyIcon(for: key.company))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                Text(getCompanyName(for: key.company))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "key")
                                    .foregroundColor(.hlBluefont)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // 切换启用状态（仅一个服务商能启用）
                        if loadingWeatherCompany == key.company {
                            ProgressView()
                        } else {
                            Toggle("", isOn: Binding(
                                get: { key.isUsing },
                                set: { newValue in
                                    toggleWeatherService(for: key, newValue: newValue)
                                }
                            ))
                            .labelsHidden()
                            .tint(.hlBlue)
                        }
                    }
                }
            }
            
            Section(header: Text("Function List")) {
                Label("Check Real-time Weather", systemImage: "cloud.sun")
                Label("Future Weather Forecast", systemImage: "calendar")
            }
        }
        .navigationTitle("Weather Enquiry")
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
        // 弹出编辑 API 配置界面
        .sheet(item: $selectedWeatherKey) { key in
            editWeatherKeyView(for: key)
        }
        .alert(errorMessage, isPresented: $showError) {
            Button("Confirm", role: .cancel) { }
        }
    }
    
    // MARK: 加载/保存 用户的天气启用状态
    private func loadUserInfo() {
        if let existing = users.first {
            DispatchQueue.main.async {
                self.weatherEnable = existing.useWeather
            }
        }
    }
    
    private func saveUserInfo() {
        if let existing = users.first {
            existing.useWeather = weatherEnable
        } else {
            let newUser = UserInfo(useWeather: weatherEnable)
            modelContext.insert(newUser)
        }
        do {
            try modelContext.save()
        } catch {
            print("保存失败：\(error.localizedDescription)")
        }
    }
    
    /// 仅允许一个服务启用；启用时需确保 API Key 已配置
    private func toggleWeatherService(for key: ToolKeys, newValue: Bool) {
        loadingWeatherCompany = key.company
        DispatchQueue.main.async {
            if newValue {
                if key.key.isEmpty {
                    errorMessage = "\(getCompanyName(for: key.company)) 需要配置 API Key 才能启用。"
                    showError = true
                    loadingWeatherCompany = nil
                    return
                }
                if key.requestURL.isEmpty {
                    errorMessage = "\(getCompanyName(for: key.company)) 需要配置 API Host 才能启用。"
                    showError = true
                    loadingWeatherCompany = nil
                    return
                }
                for service in weatherKeys {
                    service.isUsing = (service.id == key.id)
                }
            } else {
                key.isUsing = false
            }
            
            do {
                try modelContext.save()
            } catch {
                errorMessage = "保存失败: \(error.localizedDescription)"
                showError = true
            }
            loadingWeatherCompany = nil
        }
    }
    
    // MARK: 编辑 API 配置视图
    @ViewBuilder
    private func editWeatherKeyView(for key: ToolKeys) -> some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .center) {
                        Image(getCompanyIcon(for: key.company))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .padding()

                        Text("设置 \(getCompanyName(for: key.company)) API 密钥，以开启该天气服务")
                            .font(.footnote)
                            .multilineTextAlignment(.center)

                        if let url = URL(string: key.help) {
                            Link("🔗 点此获取 \(getCompanyName(for: key.company)) API 密钥", destination: url)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .padding(.bottom)
                        } else {
                            Text("It is recommended to access its open platform to obtain the API key.")
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .padding(.bottom)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("API KEY")) {
                    SecureField("Please enter the API key", text: Binding(
                        get: { key.key },
                        set: { key.key = $0 }
                    ))
                }
                
                Section(header: Text("Request Address")) {
                    TextField("Please enter the API Host", text: Binding(
                        get: { key.requestURL },
                        set: { key.requestURL = $0 }
                    ))
                }
            }
            .navigationTitle("Edit API Key")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        selectedWeatherKey = nil
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        key.timestamp = Date()
                        try? modelContext.save()
                        selectedWeatherKey = nil
                    }
                }
            }
        }
    }
}
