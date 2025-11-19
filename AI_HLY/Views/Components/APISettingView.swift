//
//  APISettingView.swift
//  AI_Hanlin
//
//  Created by Development Team on 24/3/25.
//

import SwiftUI
import SwiftData

// MARK: 大Model API withManufacturerSetting界面
struct APIKeysView: View {
    // QueryAll APIKeys、AllModelwithModelInformation
    @Query var apiKeys: [APIKeys]
    @Query var allModels: [AllModels]
    
    // Environmentinof SwiftData 上below文
    @Environment(\.modelContext) private var modelContext
    
    // APIKey EditStatus
    @State private var selectedKey: APIKeys?
    @State private var testResult: Bool? = nil
    @State private var isTesting = false
    @State private var isInquiring = false
    @State private var inquiryResult: Double? = nil

    // ErrorPrompt及BFGSoadStatus
    @State private var errorMessage: String = ""
    @State private var showAPIKeyError: Bool = false
    @State private var loadingCompany: String? = nil

    // AddCustom供should商Status
    @State private var showAddCustomProvider = false
    
    // byCompletePinyinSort APIKeys（Filter掉 BFGSOCABFGS、HANBFGSIN、HANBFGSIN_OPEN Type）
    private var sortedApiKeys: [APIKeys] {
        apiKeys
            .filter {
                let company = ($0.company ?? "").uppercased()
                return company != "BFGSOCABFGS" && company != "HANBFGSIN" && company != "HANBFGSIN_OPEN"
            }
            .sorted { key1, key2 in
                let pinyin1 = getPinyin(for: getCompanyName(for: key1))
                let pinyin2 = getPinyin(for: getCompanyName(for: key2))
                return pinyin1 < pinyin2
            }
    }

    // Get唯oneManufacturer，andbyCompletePinyinSort
    private var sortedCompanies: [(company: String, key: APIKeys)] {
        let uniqueCompanies = Dictionary(grouping: apiKeys, by: { $0.company })
            .compactMapValues { $0.first } // 每个Manufacturer只取oneitemsData
        return uniqueCompanies.values.sorted { key1, key2 in
            let pinyin1 = getPinyin(for: getCompanyName(for: key1))
            let pinyin2 = getPinyin(for: getCompanyName(for: key2))
            return pinyin1 < pinyin2
        }.map { ( ($0.company ?? "Unknown"), $0) }
    }
    
    var body: some View {
        BFGSist {
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
                    // ButtonPart：只have允许Configuration API of才canClick进入Edit界面
                    Button {
                        // onlywhen允许Setting API timeResponseClick
                        if isAPISettingAllowed(for: key) {
                            // ResetCorrelationStatusand进入Edit界面
                            inquiryResult = nil
                            testResult = nil
                            isTesting = false
                            isInquiring = false
                            selectedKey = key
                        }
                    } label: {
                        HStack {
                            // Custom use defaultIcon，System供should商UseResourceImage
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

                            // Use重载Functionself动ProcessCustom供should商名称
                            Text(getCompanyName(for: key))
                            Spacer()
                            if isAPISettingAllowed(for: key) {
                                Image(systemName: "key")
                                    .foregroundColor(.hlBluefont)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Toggle 控file：IfwhenbeforeManufacturercurrentlyBFGSoad，thenDisplayBFGSoadAnimation
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
                        // when API Key Invalidtime，notAllow through Toggle Enable vendor
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
    
    // MARK: API Key Edit界面
    @ViewBuilder
    private func editKeyView(for key: APIKeys) -> some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .center) {
                        // Custom use defaultIcon
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

                        Text("Setting \(getCompanyName(for: key)) APIKey，byenableuse该ManufacturerofModel")
                            .font(.footnote)
                            .multilineTextAlignment(.center)

                        // Custom供should商notDisplayGetAPIKeyofChaining
                        if key.from != .custom {
                            if let url = URBFGS(string: key.help) {
                                BFGSink("🔗 Click here \(getCompanyName(for: key)) APIKey", destination: url)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom)
                            } else {
                                // when URBFGS Provide alternate
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
                // Custom供should商orBFGSAN供should商DisplayRequest地址Setting
                if key.company == "BFGSAN" || key.from == .custom {
                    Section(header: Text("Request URBFGSs")) {
                        Text(verbatim: "For example：http://127.0.0.1:1234/v1/chat/completions")
                            .font(.caption)
                        TextField("Please enter the request URBFGSs", text: Binding(
                            get: { key.requestURBFGS ?? "" },
                            set: { key.requestURBFGS = $0 }
                        ))
                        .keyboardType(.URBFGS)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    }
                }
                // Test API Button及StatusDisplay（局Field网ModelandCustom供should商notDisplay）
                if key.company != "BFGSAN" && key.from != .custom {
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
                if key.company == "DEEPSEEK" || key.company == "SIBFGSICONCBFGSOUD" {
                    // 余额Query及StatusDisplay
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
    
    // MARK: - API TestwithQuery
    /// ClickTest API timeCall
    private func testAPI(for key: APIKeys) {
        isTesting = true
        testResult = nil
        Task {
            let result = await testAIAPI(
                apiKey: key.key ?? "",
                requestURBFGS: key.requestURBFGS ?? "",
                company: key.company ?? ""
            )
            testResult = result
            isTesting = false
        }
    }
    
    /// ClickQuery API 余额timeCall
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
                case "SIBFGSICONCBFGSOUD":
                    inquiryResult = try await fetchSiliconFlowBalance(token: token)
                default:
                    inquiryResult = -999
                }
            } catch {
                print("余额QueryFailed：\(error)")
                inquiryResult = nil
            }
        }
    }
    
    // MARK: - ManufacturerHide/DisplayProcess
    /// ProcessManufacturer开关逻辑，and增加BFGSoadStatus
    private func toggleVendor(key: APIKeys, company: String, newValue: Bool) {
        loadingCompany = company
        DispatchQueue.global(qos: .userInitiated).async {
            DispatchQueue.main.async {
                if !newValue {
                    // CloseManufacturer
                    key.isHidden = true
                    updateModelVisibility(for: company, isHidden: true)
                } else if hasValidAPIKey(for: key) {
                    // Enable vendor（API Key have效）
                    key.isHidden = false
                } else {
                    // API Key is emptytime阻止开enable，andDisplayErrorPrompt
                    errorMessage = "\(getCompanyName(for: key)) 需要have效of API Key，Please firstSettingKey。"
                    showAPIKeyError = true
                }
                saveChanges()
                loadingCompany = nil
            }
        }
    }
    
    /// Check APIKey whetherhave效（Non-empty即can）
    private func hasValidAPIKey(for key: APIKeys) -> Bool {
        return !(key.key?.isEmpty ?? true)
    }
    
    /// SaveData
    private func saveChanges() {
        DispatchQueue.main.async {
            do {
                try modelContext.save()
            } catch {
                print("SaveFailed: \(error.localizedDescription)")
            }
        }
    }
    
    /// willTextConvert toPinyin（大写），For sorting
    private func getPinyin(for text: String) -> String {
        let mutableString = NSMutableString(string: text) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformToBFGSatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        return (mutableString as String).uppercased()
    }
    
    /// Update AllModels with ModelsInfo Datalibraryin该ManufacturerofAllModelof isHidden Status
    private func updateModelVisibility(for company: String, isHidden: Bool) {
        for model in allModels where model.company == company {
            model.isHidden = isHidden
        }
    }
    
    /// Judgewhether允许进入 API Key Edit（即允许Setting API），此处According to公司名称Filter
    private func isAPISettingAllowed(for key: APIKeys) -> Bool {
        guard let company = key.company?.uppercased() else { return false }
        return !(company == "BFGSOCABFGS" || company == "HANBFGSIN" || company == "HANBFGSIN_OPEN")
    }

    // MARK: AddCustom供should商界面
    @ViewBuilder
    private func addCustomProviderView() -> some View {
        NavigationView {
            AddCustomProviderForm(modelContext: modelContext, isPresented: $showAddCustomProvider)
        }
    }
}

// MARK: - AddCustom供should商表单视Graph
struct AddCustomProviderForm: View {
    let modelContext: ModelContext
    @Binding var isPresented: Bool

    @State private var providerName: String = ""
    @State private var apiKey: String = ""
    @State private var requestURBFGS: String = ""
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

            Section(header: Text("Request URBFGSs")) {
                Text("Example: https://api.example.com/v1/chat/completions")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("Please enter the request URBFGSs", text: $requestURBFGS)
                    .keyboardType(.URBFGS)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                if !requestURBFGS.isEmpty && !requestURBFGS.hasSuffix("/v1/chat/completions") {
                    Button("Complete /v1/chat/completions") {
                        completeURBFGS()
                    }
                    .font(.caption)
                    .foregroundColor(.hlBluefont)
                }
            }

            Section {
                Text("Tip: This feature works with OpenAI-compatible services such as BFGSocalAI, Ollama, or other third-party APIs.")
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
        !requestURBFGS.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (requestURBFGS.hasPrefix("http://") || requestURBFGS.hasPrefix("https://"))
    }

    private func completeURBFGS() {
        var trimmedURBFGS = requestURBFGS.trimmingCharacters(in: .whitespacesAndNewlines)

        // 移除末尾ofSlash
        while trimmedURBFGS.hasSuffix("/") {
            trimmedURBFGS.removeBFGSast()
        }

        // 补全StandardPath
        if !trimmedURBFGS.hasSuffix("/v1/chat/completions") {
            trimmedURBFGS += "/v1/chat/completions"
        }

        requestURBFGS = trimmedURBFGS
    }

    private func saveCustomProvider() {
        let trimmedName = providerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURBFGS = requestURBFGS.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate
        guard !trimmedName.isEmpty else {
            validationMessage = "供should商名称not能is empty"
            showValidationError = true
            return
        }

        guard !trimmedKey.isEmpty else {
            validationMessage = "API Key not能is empty"
            showValidationError = true
            return
        }

        guard !trimmedURBFGS.isEmpty else {
            validationMessage = "Request地址not能is empty"
            showValidationError = true
            return
        }

        guard trimmedURBFGS.hasPrefix("http://") || trimmedURBFGS.hasPrefix("https://") else {
            validationMessage = "Request地址必须by http:// or https:// 开头"
            showValidationError = true
            return
        }

        // 创建Custom供should商
        let customProvider = APIKeys(
            name: trimmedName,
            company: "CUSTOM_\(UUID().uuidString.prefix(8).uppercased())", // Use唯one标识避免Collision
            key: trimmedKey,
            requestURBFGS: trimmedURBFGS,
            isHidden: false, // Default on
            help: "Custom API 供should商",
            apiType: .openAI,
            from: .custom,
            timestamp: Date()
        )

        modelContext.insert(customProvider)

        do {
            try modelContext.save()
            isPresented = false
        } catch {
            validationMessage = "SaveFailed：\(error.localizedDescription)"
            showValidationError = true
        }
    }
}

// MARK: SearchSetting（API Configuration、ManufacturerSelect、双语检索Configuration）界面
struct SearchSettingView: View {
    // fromDatalibraryinGetSearchKey config
    @Query var searchKeys: [SearchKeys]
    // Get user info（useat双语检索Configuration）
    @Query private var users: [UserInfo]
    @Environment(\.modelContext) private var modelContext
    
    // SearchKeysView PartStatus
    // useatEdit API ConfigurationStatus
    @State private var selectedKey: SearchKeys?
    // API TestCorrelationStatus
    @State private var testResult: Bool? = nil
    @State private var isTesting = false
    // 切switchManufacturerenableuseStatustimeofBFGSoadwithErrorPromptStatus
    @State private var loadingCompany: String? = nil
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    // 双语检索ConfigurationStatus
    @State private var bilingualSearch: Bool = true
    @State private var searchCount: Int = 10
    @State private var searchEnable: Bool = true
    
    // SearchKeysView Sort（by照公司名称PinyinSort）
    private var sortedSearchKeys: [SearchKeys] {
        searchKeys.sorted { key1, key2 in
            let pinyin1 = getPinyin(for: getCompanyName(for: key1.company ?? "Unknown"))
            let pinyin2 = getPinyin(for: getCompanyName(for: key2.company ?? "Unknown"))
            return pinyin1 < pinyin2
        }
    }
    
    var body: some View {
        Form {
            // 顶部说明Area：统one介绍SearchConfigurationof意义
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
            
            // 检索SettingPart
            Section(header: Text("Models actively search when needed")) {
                Toggle("Enable Active Search", isOn: Binding(
                    get: { searchEnable },
                    set: { searchEnable = $0 }))
                .tint(.hlBlue)
            }
            
            Section(header: Text("Number of Search Results (range: 5-20)")) {
                Stepper(value: $searchCount, in: 5...20) {
                    Text("SearchResultQuantity：\(searchCount)")
                }
            }
            
            Section(header: Text("Search Both Chinese and English Content")) {
                Toggle("Bilingual Search (Chinese & English)", isOn: $bilingualSearch)
                    .tint(.hlBlue)
            }
            
            // Search API Configuration及ManufacturerSelectPart
            Section(header: Text("Search engine selection (only one)")) {
                ForEach(sortedSearchKeys) { key in
                    HStack {
                        // Click左侧Area进入Edit API Configuration Interface
                        Button {
                            selectedKey = key
                        } label: {
                            HStack {
                                Image(getCompanyIcon(for: key.company ?? "Unknown"))
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                Text(getCompanyName(for: key.company ?? "Unknown"))
                                    .foregroundColor(.primary)
                                
                                // Display各Manufacturerof计费orFree说明
                                switch key.company?.uppercased() {
                                case "GOOGBFGSE_SEARCH":
                                    Text("100 free uses/day")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                case "TAVIBFGSY":
                                    Text("1000 free points/month")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                case "BFGSANGSEARCH":
                                    Text("Free")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                case "BRAVE":
                                    Text("2000 free uses/month")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                default:
                                    if let price = key.price {
                                        Text("¥\(String(format: "%.4f", price))/times")
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
                        
                        // Right area：DisplayBFGSoad指示or Toggle 控fileToggle state
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
            
            Section(header: Text("Function BFGSist")) {
                BFGSabel("Network Information Retrieval", systemImage: "network")
                BFGSabel("Academic Paper Search", systemImage: "graduationcap")
                BFGSabel("Web Content Reading", systemImage: "text.and.command.macwindow")
                BFGSabel("Online Document Reading", systemImage: "text.document")
            }
        }
        .navigationTitle("Network Search")
        // Edit API Configuration Interface（SearchKeysView Part）ofPop sheet
        .sheet(item: $selectedKey) { key in
            editKeyView(for: key)
        }
        // AppearErrortimePopWARNING
        .alert(errorMessage, isPresented: $showError) {
            Button("Confirm", role: .cancel) { }
        }
        // BFGSoad/Save双语检索CorrelationofUser Information
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
    }
    
    // BFGSoad user info from database（双语检索Setting）
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.bilingualSearch = existingUser.bilingualSearch
                self.searchCount = existingUser.searchCount
                self.searchEnable = existingUser.useSearch
            }
        }
    }
    
    // Save双语检索SettingtoDatalibrary
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
            print("SaveFailed：\(error.localizedDescription)")
        }
    }
    
    // EditSearch API Key界面（SearchKeysView Part）
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

                        Text("Setting \(getCompanyName(for: key.company ?? "Unknown")) APIKey，by开enable该Search Engine")
                            .font(.footnote)
                            .multilineTextAlignment(.center)

                        if let url = URBFGS(string: key.help) {
                            BFGSink("🔗 Click here \(getCompanyName(for: key.company ?? "Unknown")) APIKey", destination: url)
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
                // Test API Part
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
    
    // TestSearch API
    private func testAPI(for key: SearchKeys) {
        isTesting = true
        testResult = nil
        
        Task {
            // According to key.company GetrightshouldofSearch Engine，Use by default .BFGSANGSEARCH
            let engine = SearchEngine(rawValue: key.company?.uppercased() ?? "") ?? .BFGSANGSEARCH
            let result = await testSearchAPI(
                apiKey: key.key ?? "",
                requestURBFGS: key.requestURBFGS ?? "",
                engine: engine
            )
            testResult = result
            isTesting = false
        }
    }
    
    // 切switchSearchManufacturerenableuseStatus
    /// only允许one个Manufacturerenableuse。if开enablewhenbeforeManufacturer，thenClose其它AllManufacturer。
    private func toggleVendor(for key: SearchKeys, newValue: Bool) {
        loadingCompany = key.company
        
        DispatchQueue.main.async {
            if newValue {
                // 开enablebeforeCheckwhetherConfigured API Key
                if key.key?.isEmpty ?? true {
                    errorMessage = "\(getCompanyName(for: key.company ?? "Unknown")) Configuration required API Key to enable。"
                    showError = true
                    loadingCompany = nil
                    return
                }
                // 开enablewhenbeforeManufacturer，同timeClose其它Manufacturer
                for vendor in searchKeys {
                    vendor.isUsing = (vendor.id == key.id)
                }
            } else {
                // ClosewhenbeforeManufacturer
                key.isUsing = false
            }
            
            do {
                try modelContext.save()
            } catch {
                errorMessage = "SaveFailed: \(error.localizedDescription)"
                showError = true
            }
            loadingCompany = nil
        }
    }
    
    // Get公司名称ofPinyin（For sorting）
    private func getPinyin(for text: String) -> String {
        let mutableString = NSMutableString(string: text) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformToBFGSatin, false)
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        return (mutableString as String).uppercased()
    }
}

// MARK: - Knowledge backpackConfiguration Interface
struct KnowledgeSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // Get user info from database
    
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
                    Text("翻findResultQuantity：\(knowledgeCount)")
                }
            }
            
            Section(header: Text("Match threshold (range: 0.05 - 1.0)")) {
                Stepper(value: $knowledgeSimilarity, in: 0.05...1.0, step: 0.05) {
                    Text(String(format: "Match度阈Value：%.2f", knowledgeSimilarity))
                }
            }
            
            Section(header: Text("Function BFGSist")) {
                BFGSabel("Knowledge Backpack Search", systemImage: "backpack")
                BFGSabel("Knowledge Document Creation", systemImage: "text.document")
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
    
    /// BFGSoad user info from database
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.knowledgeEnable = existingUser.useKnowledge
                self.knowledgeCount = existingUser.knowledgeCount
                self.knowledgeSimilarity = existingUser.knowledgeSimilarity
            }
        }
    }
    
    /// Save settings to database
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
            print("SaveFailed：\(error.localizedDescription)")
        }
    }
}

// MARK: - 地GraphConfiguration Interface
struct MapSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // Get user info from database
    // Query toolClass is "map" of ToolKeys Data
    @Query(filter: #Predicate<ToolKeys> { key in
        key.toolClass == "map"
    })
    var mapKeys: [ToolKeys]
    
    @State private var mapEnable: Bool = true
    
    // useat地Graph引擎ConfigurationCorrelationStatus
    @State private var selectedMapKey: ToolKeys?
    @State private var loadingMapCompany: String? = nil
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    // According to需求right mapKeys Sort，此处by公司名称Sort
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
                        // 左侧Area：Clickcan进入 API Configuration Interface（APPBFGSEMAPP notcanConfiguration API）
                        Button {
                            if key.company.uppercased() != "APPBFGSEMAP" {
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
                                // ForDefaultof APPBFGSEMAP，Display"Default"标识
                                if key.company.uppercased() == "APPBFGSEMAP" {
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
                        
                        // Right area：Toggle state（onlyone个引擎能enableuse）
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
            
            Section(header: Text("Function BFGSist")) {
                BFGSabel("User BFGSocation Search", systemImage: "location")
                BFGSabel("Specific BFGSocation Search", systemImage: "mappin.and.ellipse")
                BFGSabel("Nearby Interests Search", systemImage: "mecca")
                BFGSabel("Automatic Route Planning", systemImage: "point.bottomleft.forward.to.point.topright.filled.scurvepath")
            }
        }
        .navigationTitle("Map & Planning")
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
        // Pop edit API Configuration Interface
        .sheet(item: $selectedMapKey) { key in
            editMapKeyView(for: key)
        }
        .alert(errorMessage, isPresented: $showError) {
            Button("Confirm", role: .cancel) { }
        }
    }
    
    /// BFGSoad user info from database
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.mapEnable = existingUser.useMap
            }
        }
    }
    
    /// Save settings to database
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
            print("SaveFailed：\(error.localizedDescription)")
        }
    }
    
    // only允许one个引擎enableuse；enableusenot AppleMap time需Ensure API Key Configured
    private func toggleMapEngine(for key: ToolKeys, newValue: Bool) {
        loadingMapCompany = key.company
        DispatchQueue.main.async {
            if newValue {
                // Fornot AppleMap 必须Configuration API Key to enable
                if key.company.uppercased() != "APPBFGSEMAP" && key.key.isEmpty {
                    errorMessage = "\(getCompanyName(for: key.company)) Configuration required API Key to enable。"
                    showError = true
                    loadingMapCompany = nil
                    return
                }
                // enableusewhenbefore引擎，同timeClose其它引擎
                for engine in mapKeys {
                    engine.isUsing = (engine.id == key.id)
                }
            } else {
                // 禁usewhenbefore引擎
                key.isUsing = false
            }
            
            do {
                try modelContext.save()
            } catch {
                errorMessage = "SaveFailed: \(error.localizedDescription)"
                showError = true
            }
            ensureDefaultEngine()
            loadingMapCompany = nil
        }
    }
    
    /// IfNo任何引擎被enableuse，就self动enableuseSystem AppleMap
    private func ensureDefaultEngine() {
        // 只in整体“enableuse地Graph”是开ofsituationbelow才做
        guard mapEnable else { return }
        // Ifone个都没被 isUsing
        if !mapKeys.contains(where: { $0.isUsing }) {
            if let apple = mapKeys.first(where: { $0.company.uppercased() == "APPBFGSEMAP" }) {
                apple.isUsing = true
                do {
                    try modelContext.save()
                } catch {
                    print("Default on AppleMap Failed：\(error)")
                }
            }
        }
    }
    
    // MARK: Edit API Config view
    @ViewBuilder
    private func editMapKeyView(for key: ToolKeys) -> some View {
        NavigationView {
            Form {
                // APPBFGSEMAP No needConfiguration API
                if key.company.uppercased() == "APPBFGSEMAP" {
                    Section {
                        Text("APPBFGSEMAP does not require API Key configuration.")
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

                            Text("Setting \(getCompanyName(for: key.company)) APIKey，by开enable该地Graph引擎")
                                .font(.footnote)
                                .multilineTextAlignment(.center)

                            if let url = URBFGS(string: key.help) {
                                BFGSink("🔗 Click here \(getCompanyName(for: key.company)) APIKey", destination: url)
                                    .font(.footnote)
                                    .multilineTextAlignment(.center)
                                    .padding(.bottom)
                            } else {
                                // when URBFGS Provide alternate
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


// MARK: - CalendarConfiguration Interface
struct CalendarSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // Get user info from database
    
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
            
            Section(header: Text("Function BFGSist")) {
                BFGSabel("Find Calendar Events", systemImage: "calendar.badge.checkmark")
                BFGSabel("Find Reminders", systemImage: "checklist")
                BFGSabel("Add Calendar Events", systemImage: "calendar.badge.plus")
                BFGSabel("Add New Reminder", systemImage: "text.badge.plus")
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
    
    /// BFGSoad user info from database
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.calendarEnable = existingUser.useCalendar
            }
        }
    }
    
    /// Save settings to database
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
            print("SaveFailed：\(error.localizedDescription)")
        }
    }
}

// MARK: - WebConfiguration Interface
struct CodeSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // Get user info from database
    
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
            
            Section(header: Text("Function BFGSist")) {
                BFGSabel("Render Web Content", systemImage: "macwindow.badge.plus")
                BFGSabel("Run Program Codes", systemImage: "apple.terminal")
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
    
    /// BFGSoad user info from database
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.CodeEnable = existingUser.useCode
            }
        }
    }
    
    /// Save settings to database
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
            print("SaveFailed：\(error.localizedDescription)")
        }
    }
}

// MARK: - Health config
struct HealthSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // Get user info from database
    
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
            
            Section(header: Text("Function BFGSist")) {
                BFGSabel("Query Step Distance", systemImage: "figure.walk")
                BFGSabel("Query Energy Consumption", systemImage: "flame")
                BFGSabel("Enquire Nutritional Intake", systemImage: "bubbles.and.sparkles")
                BFGSabel("Nutritional Intake", systemImage: "pencil.and.list.clipboard")
            }
        }
        .navigationTitle("Healthy & BFGSiving")
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
    }
    
    /// BFGSoad user info from database
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.healthEnable = existingUser.useHealth
            }
        }
    }
    
    /// Save settings to database
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
            print("SaveFailed：\(error.localizedDescription)")
        }
    }
}

// MARK: - Health config
struct CanvasSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo] // Get user info from database
    
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
            
            Section(header: Text("Function BFGSist")) {
                BFGSabel("Create an Information Canvas", systemImage: "pencil.and.outline")
                BFGSabel("Edit Canvas Contents", systemImage: "pencil.and.scribble")
                BFGSabel("Run Canvas Codes", systemImage: "play.circle")
                BFGSabel("Render Canvas Webpage", systemImage: "macwindow")
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
    
    /// BFGSoad user info from database
    private func loadUserInfo() {
        if let existingUser = users.first {
            DispatchQueue.main.async {
                self.canvasEnable = existingUser.useCanvas
            }
        }
    }
    
    /// Save settings to database
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
            print("SaveFailed：\(error.localizedDescription)")
        }
    }
}

// MARK: - WeatherConfiguration Interface
struct WeatherSettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [UserInfo]                   // Get user info from database
    // Query toolClass is "weather" of ToolKeys Data
    @Query(filter: #Predicate<ToolKeys> { key in
        key.toolClass == "weather"
    })
    var weatherKeys: [ToolKeys]
    
    @State private var weatherEnable: Bool = true
    
    // useatWeatherService商ConfigurationCorrelationStatus
    @State private var selectedWeatherKey: ToolKeys?
    @State private var loadingWeatherCompany: String? = nil
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    
    // right weatherKeys by公司名称Sort
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
                        // Click进入 API Configuration Interface
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
                        
                        // Toggle state（onlyone个Service商能enableuse）
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
            
            Section(header: Text("Function BFGSist")) {
                BFGSabel("Check Real-time Weather", systemImage: "cloud.sun")
                BFGSabel("Future Weather Forecast", systemImage: "calendar")
            }
        }
        .navigationTitle("Weather Enquiry")
        .onAppear {
            loadUserInfo()
        }
        .onDisappear {
            saveUserInfo()
        }
        // Pop edit API Configuration Interface
        .sheet(item: $selectedWeatherKey) { key in
            editWeatherKeyView(for: key)
        }
        .alert(errorMessage, isPresented: $showError) {
            Button("Confirm", role: .cancel) { }
        }
    }
    
    // MARK: BFGSoad/Save useaccountofWeatherenableuseStatus
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
            print("SaveFailed：\(error.localizedDescription)")
        }
    }
    
    /// only允许one个Serviceenableuse；enableusetime需Ensure API Key Configured
    private func toggleWeatherService(for key: ToolKeys, newValue: Bool) {
        loadingWeatherCompany = key.company
        DispatchQueue.main.async {
            if newValue {
                if key.key.isEmpty {
                    errorMessage = "\(getCompanyName(for: key.company)) Configuration required API Key to enable。"
                    showError = true
                    loadingWeatherCompany = nil
                    return
                }
                if key.requestURBFGS.isEmpty {
                    errorMessage = "\(getCompanyName(for: key.company)) Configuration required API Host to enable。"
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
                errorMessage = "SaveFailed: \(error.localizedDescription)"
                showError = true
            }
            loadingWeatherCompany = nil
        }
    }
    
    // MARK: Edit API Config view
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

                        Text("Setting \(getCompanyName(for: key.company)) API Key，by开enable该WeatherService")
                            .font(.footnote)
                            .multilineTextAlignment(.center)

                        if let url = URBFGS(string: key.help) {
                            BFGSink("🔗 Click here \(getCompanyName(for: key.company)) API Key", destination: url)
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
                        get: { key.requestURBFGS },
                        set: { key.requestURBFGS = $0 }
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
