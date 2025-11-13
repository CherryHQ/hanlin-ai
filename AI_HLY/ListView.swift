import SwiftUI
import SwiftData

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var chatRecords: [ChatRecords]
    @Query private var allModels: [AllModels]
    
    @State private var searchText: String = ""
    @State private var loadHistoryMessages: Bool = false
    @State private var infoDescriptionCache: [UUID: String] = [:]
    @State private var newlyCreatedChat: ChatRecords?
    @State private var showTranslationSheet: Bool = false
    @State private var showPolishSheet: Bool = false
    @State private var showSummarySheet: Bool = false
    
    @State private var showIconSheet = false
    @State private var editingRecord: ChatRecords? = nil
    @State private var editingIcon: String = "bubble.left.circle"
    @State private var editingColor: Color = .hlBlue
    @State private var editingTitle: String = "title"
    
    @State private var navigationPath: [ChatRecords] = []
    @State private var matchedSnippets: [UUID: (AttributedString, UUID)] = [:]
    
    @State private var showSafariGuide: Bool = false
    
    // 添加一个强制刷新状态，当需要更新列表时切换该状态
    @State private var forceRefresh: Bool = false
    
    // 修改计算属性，让置顶的记录始终显示在上方
    private var filteredChatRecords: [ChatRecords] {
        if searchText.isEmpty {
            let pinnedRecords = chatRecords.filter { $0.isPinned }
                .sorted { $0.lastEdited > $1.lastEdited }
            let unpinnedRecords = chatRecords.filter { !$0.isPinned }
                .sorted { $0.lastEdited > $1.lastEdited }
            return pinnedRecords + unpinnedRecords
        } else {
            let lowercasedSearchText = searchText.lowercased()
            let pinyinSearchText = searchText.toPinyin().lowercased()
            let filtered = chatRecords.filter { record in
                let recordName = record.name ?? ""
                let lowercasedRecordName = recordName.lowercased()
                let matchName = lowercasedRecordName.contains(lowercasedSearchText)
                let matchNamePinyin = recordName.toPinyin().lowercased().contains(pinyinSearchText)
                // 检测聊天消息中是否包含搜索词
                let matchMessages = record.messages?.contains { message in
                    message.text?.lowercased().contains(lowercasedSearchText) ?? false
                } ?? false
                return matchName || matchNamePinyin || matchMessages
            }
            // 对筛选后的记录根据是否置顶分组，并排序
            let pinnedRecords = filtered.filter { $0.isPinned }
                .sorted { $0.lastEdited > $1.lastEdited }
            let unpinnedRecords = filtered.filter { !$0.isPinned }
                .sorted { $0.lastEdited > $1.lastEdited }
            return pinnedRecords + unpinnedRecords
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            content
                .navigationTitle("AI Hanlin")
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 75)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            addNewChat()
                        } label: {
                            Image(systemName: "plus.bubble")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        if loadHistoryMessages {
                            HStack {
                                ProgressView().font(.caption)
                                Text("Loading...").font(.caption)
                            }
                        } else {
                            HStack {
                                Button(action: {
                                    showSafariGuide = true
                                }) {
                                    Label {
                                        Text("Software Guide")
                                            .font(.caption)
                                    } icon: {
                                        Image(systemName: "text.rectangle.page")
                                    }
                                }
                            }
                        }
                    }
                }
                .onAppear {
                    handleOnAppear()
                    searchText = ""
                }
                .sheet(isPresented: $showTranslationSheet) {
                    TranslationView()
                }
                .sheet(isPresented: $showPolishSheet) {
                    PolishView()
                }
                .sheet(isPresented: $showSummarySheet) {
                    SummaryView()
                }
                .sheet(isPresented: $showIconSheet) {
                    IconAndColorPicker(
                        selectedIcon: $editingIcon,
                        selectedColor: $editingColor,
                        title: $editingTitle
                    )
                    .onDisappear {
                        // 当编辑面板关闭时，将编辑好的 icon/color 回写到对应 record
                        guard let editingRecord = editingRecord else { return }
                        editingRecord.icon = editingIcon
                        editingRecord.color = editingColor.name
                        editingRecord.name = editingTitle
                        do {
                            try modelContext.save()
                            // 切换 forceRefresh 强制刷新列表
                            forceRefresh.toggle()
                        } catch {
                            print("Error saving icon or color: \(error.localizedDescription)")
                        }
                    }
                }
                .fullScreenCover(isPresented: $showSafariGuide) {
                    SafariView(url: URL(string: "https://docs.qq.com/aio/DT2pMUFRVWVNsZmtj")!)
                        .background(BlurView(style: .systemThinMaterial))
                        .edgesIgnoringSafeArea(.all)
                }
        }
    }
    
    // MARK: - Main Content
    @State private var searchTask: Task<Void, Never>? = nil
    
    @ViewBuilder
    private var content: some View {
        List {
            topButtonsSection
            chatRecordsSection
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search chat and message content")
        .onChange(of: searchText) {
            // 取消上一次搜索任务
            searchTask?.cancel()
            
            // 创建新的搜索任务并延迟 300 毫秒
            searchTask = Task {
                do {
                    try await Task.sleep(nanoseconds: 300_000_000)
                    // 若没有被取消，执行搜索逻辑（这里只更新 matchedSnippets）
                    if !Task.isCancelled {
                        searchRecords()
                    }
                } catch {
                    // 被取消或出现其它错误时可忽略
                }
            }
        }
        .onChange(of: navigationPath) { oldPath, newPath in
            let isHidden = !newPath.isEmpty
            NotificationCenter.default.post(name: .hideTabBar, object: isHidden)
        }
        .refreshable {
            handleOnAppear()
        }
        .navigationDestination(for: ChatRecords.self) { chat in
            ChatViewWrapper(chatRecord: chat)
        }
    }
    
    // MARK: - 子视图：顶部 3 个按钮
    private var topButtonsSection: some View {
        Section {
            HStack(spacing: 10) {
                Button {
                    showTranslationSheet = true
                } label: {
                    HStack {
                        Image("translate")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.hlBluefont)
                        Text("Translation")
                            .foregroundColor(.hlBluefont)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.hlBluefont.opacity(0.2))
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
                
                Button {
                    showPolishSheet = true
                } label: {
                    HStack {
                        Image(systemName: "wand.and.sparkles.inverse")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.hlGreen)
                        Text("Refinement")
                            .foregroundColor(.hlGreen)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.hlGreen.opacity(0.2))
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
                
                Button {
                    showSummarySheet = true
                } label: {
                    HStack {
                        Image(systemName: "highlighter")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundColor(.hlCyanite)
                        Text("Summary")
                            .foregroundColor(.hlCyanite)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color.hlCyanite.opacity(0.2))
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
            .listRowInsets(EdgeInsets())
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder
    private func backgroundView(for record: ChatRecords) -> some View {
        if record.isPinned {
            BlurView(style: .systemUltraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.from(name: record.color ?? "hlBlue"), radius: 1)
                .padding(3)
        } else {
            Color.clear
        }
    }
    
    // MARK: - 子视图：聊天记录列表
    @ViewBuilder
    private func chatRecordRow(for record: ChatRecords) -> some View {
        // 将 matchedSnippets 的取值与 NavigationLink 封装到此处
        let snippetPair = matchedSnippets[record.id ?? UUID()]
        let snippet = snippetPair?.0
        let messageID = snippetPair?.1
        
        NavigationLink(destination: {
            ChatViewWrapper(chatRecord: record, matchedMessageID: messageID)
        }) {
            ChatRowView(
                record: record,
                searchText: searchText,
                matchedSnippet: snippet
            )
            .contextMenu {
                Button {
                    // 编辑图标操作
                    editingRecord = record
                    editingIcon   = record.icon ?? "bubble.left.circle"
                    editingColor  = Color.from(name: record.color ?? ".hlBlue")
                    editingTitle  = record.name ?? ""
                    showIconSheet = true
                } label: {
                    Label("Edit Icon", systemImage: "paintbrush")
                }
                
                Button {
                    togglePin(record)
                } label: {
                    Label(record.isPinned ? "Unpin" : "Pin Message", systemImage: record.isPinned ? "pin.slash" : "pin")
                }
                
                Button(role: .destructive) {
                    deleteChat(record)
                } label: {
                    Label("Delete Message", systemImage: "trash")
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .listRowInsets(EdgeInsets())
        .listRowBackground(backgroundView(for: record))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteChat(record)
            } label: {
                Label("Delete Message", systemImage: "trash")
            }
            .tint(Color(.hlRed))
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                togglePin(record)
            } label: {
                Label(
                    record.isPinned ? "Unpin" : "Pin Message",
                    systemImage: record.isPinned ? "pin.slash" : "pin"
                )
            }
            .tint(Color(.hlBlue))
            
            Button {
                // 进入编辑模式
                editingRecord = record
                editingIcon   = record.icon ?? "bubble.left.circle"
                editingColor  = Color.from(name: record.color ?? ".hlBlue")
                editingTitle  = record.name ?? ""
                showIconSheet = true
            } label: {
                Label("Edit Icon", systemImage: "paintbrush")
            }
            .tint(.hlGreen)
        }
        // 利用 forceRefresh 作为 id 变化触发视图刷新
        .id((record.id?.uuidString ?? "") + String(forceRefresh))
    }
    
    // 使用 filteredChatRecords 计算属性替代原来的缓存数据
    private var chatRecordsSection: some View {
        Section {
            ForEach(filteredChatRecords, id: \.id) { record in
                chatRecordRow(for: record)
            }
        }
    }
    
    // MARK: - 其他逻辑
    private func handleOnAppear() {
        loadHistoryMessages = true
        Task {
            let records: [ChatRecords] = chatRecords
            let sortedRecords = await sortChatRecords(records)
            await MainActor.run {
                loadHistoryMessages = false
                infoDescriptionCache = sortedRecords.reduce(into: [:]) {
                    $0[$1.id ?? UUID()] = $1.infoDescription
                }
            }
        }
    }
    
    private func sortChatRecords(_ records: [ChatRecords]) async -> [ChatRecords] {
        var pinnedRecords: [ChatRecords] = []
        var unpinnedRecords: [ChatRecords] = []
        
        for record in records {
            if record.isPinned {
                pinnedRecords.append(record)
            } else {
                unpinnedRecords.append(record)
            }
        }
        
        pinnedRecords.sort { $0.lastEdited > $1.lastEdited }
        unpinnedRecords.sort { $0.lastEdited > $1.lastEdited }
        
        return pinnedRecords + unpinnedRecords
    }
    
    // MARK: - 搜索逻辑
    private func searchRecords() {
        if searchText.isEmpty {
            matchedSnippets.removeAll()
        } else {
            let lowercasedSearchText = searchText.lowercased()
            var newMatchedSnippets: [UUID: (AttributedString, UUID)] = [:]
            for record in chatRecords {
                if let messages = record.messages {
                    if let snippetResult = findMatchSnippet(
                        messages: messages,
                        searchText: lowercasedSearchText
                    ) {
                        newMatchedSnippets[record.id ?? UUID()] = snippetResult
                    } else {
                        newMatchedSnippets.removeValue(forKey: record.id ?? UUID())
                    }
                }
            }
            matchedSnippets = newMatchedSnippets
        }
    }
    
    /// 找到第一条包含 searchText 的消息，并返回 (带前后文高亮的片段, 消息ID)
    private func findMatchSnippet(messages: [ChatMessages], searchText: String) -> (AttributedString, UUID)? {
        for msg in messages.reversed() {
            guard let msgText = msg.text, !msgText.isEmpty else { continue }
            let lowerMsgText = msgText.lowercased()
            if let range = lowerMsgText.range(of: searchText) {
                let snippetLength = 40
                let startIndex = lowerMsgText.index(range.lowerBound, offsetBy: -snippetLength, limitedBy: lowerMsgText.startIndex) ?? lowerMsgText.startIndex
                let endIndex = lowerMsgText.index(range.upperBound, offsetBy: snippetLength, limitedBy: lowerMsgText.endIndex) ?? lowerMsgText.endIndex
                let snippetString = String(msgText[startIndex..<endIndex])
                
                var attributed = AttributedString(snippetString)
                attributed.font = .caption
                attributed.foregroundColor = Color(.systemGray)
                
                let snippetLower = snippetString.lowercased()
                if let subRange = snippetLower.range(of: searchText) {
                    let nsRange = NSRange(subRange, in: snippetString)
                    if let attrRange = Range(nsRange, in: attributed) {
                        attributed[attrRange].foregroundColor = .hlBlue
                        attributed[attrRange].font = .caption.bold()
                    }
                }
                return (attributed, msg.id)
            }
        }
        return nil
    }
    
    private func togglePin(_ record: ChatRecords) {
        record.isPinned.toggle()
        do {
            try modelContext.save()
            // 置顶后强制刷新列表视图
            forceRefresh.toggle()
        } catch {
            print("Error saving pin state: \(error.localizedDescription)")
        }
    }
    
    private func deleteChat(_ record: ChatRecords) {
        DispatchQueue.main.async {
            modelContext.delete(record)
            do {
                try modelContext.save()
            } catch {
                print("Error deleting chat: \(error.localizedDescription)")
            }
        }
    }
    
    private func addNewChat() {
        let currentLanguage = Locale.preferredLanguages.first ?? "zh-Hans"
        
        let chatName: String = currentLanguage.hasPrefix("zh") ? "新群聊" : "New Group Chat"
        let welcomeText: String = currentLanguage.hasPrefix("zh") ? "欢迎加入新群聊👏" : "Welcome to the new group chat! 👏"
        
        let newChat = ChatRecords(
            name: chatName,
            type: "chat",
            lastEdited: Date()
        )
        
        let welcomeMessage = ChatMessages(
            role: "information",
            text: welcomeText,
            reasoning: "",
            modelDisplayName: "System",
            timestamp: Date(),
            record: newChat
        )
        
        do {
            modelContext.insert(newChat)
            modelContext.insert(welcomeMessage)
            try modelContext.save()
            
            DispatchQueue.main.async {
                navigationPath.append(newChat) // 触发跳转
            }
            
        } catch {
            print("Error saving new chat: \(error.localizedDescription)")
        }
    }
}
