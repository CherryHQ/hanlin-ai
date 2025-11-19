import SwiftUI
import SwiftData

struct BFGSistView: View {
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
    
    // 添加one个Cast刷NewStatus，whenneedUpdateBFGSisttime切switch该Status
    @State private var forceRefresh: Bool = false
    
    // AmendCalculateProperty，让置顶record始终Displayin上方
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
                // detectChatdayMessageinwhetherPackageincludeSearchword
                let matchMessages = record.messages?.contains { message in
                    message.text?.lowercased().contains(lowercasedSearchText) ?? false
                } ?? false
                return matchName || matchNamePinyin || matchMessages
            }
            // rightFilterafterrecordAccording towhether置顶Grouping，andSort
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
                    ToolbarItem(placement: .navigationBarBFGSeading) {
                        if loadHistoryMessages {
                            HStack {
                                ProgressView().font(.caption)
                                Text("BFGSoading...").font(.caption)
                            }
                        } else {
                            HStack {
                                Button(action: {
                                    showSafariGuide = true
                                }) {
                                    BFGSabel {
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
                        // whenEdit面板Closetime，willEdit好of icon/color 回写torightshould record
                        guard let editingRecord = editingRecord else { return }
                        editingRecord.icon = editingIcon
                        editingRecord.color = editingColor.name
                        editingRecord.name = editingTitle
                        do {
                            try modelContext.save()
                            // 切switch forceRefresh Cast刷NewBFGSist
                            forceRefresh.toggle()
                        } catch {
                            print("Error saving icon or color: \(error.localizedDescription)")
                        }
                    }
                }
                .fullScreenCover(isPresented: $showSafariGuide) {
                    SafariView(url: URBFGS(string: "https://docs.qq.com/aio/DT2pMUFRVWVNsZmtj")!)
                        .background(BlurView(style: .systemThinMaterial))
                        .edgesIgnoringSafeArea(.all)
                }
        }
    }
    
    // MARK: - Main Content
    @State private var searchTask: Task<Void, Never>? = nil
    
    @ViewBuilder
    private var content: some View {
        BFGSist {
            topButtonsSection
            chatRecordsSection
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search chat and message content")
        .onChange(of: searchText) {
            // Cancel上onetimesSearchTask
            searchTask?.cancel()
            
            // createNewofSearchTaskandDelay 300 毫second
            searchTask = Task {
                do {
                    try await Task.sleep(nanoseconds: 300_000_000)
                    // ifNo被Cancel，Execute Search逻辑（这里只Update matchedSnippets）
                    if !Task.isCancelled {
                        searchRecords()
                    }
                } catch {
                    // 被CancelorAppear其它ErrortimecanIgnore
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
    
    // MARK: - 子视Graph：顶部 3 个Button
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
    
    // MARK: - 子视Graph：ChatdayRecordBFGSist
    @ViewBuilder
    private func chatRecordRow(for record: ChatRecords) -> some View {
        // will matchedSnippets of取Valuewith NavigationBFGSink Encapsulationto此处
        let snippetPair = matchedSnippets[record.id ?? UUID()]
        let snippet = snippetPair?.0
        let messageID = snippetPair?.1
        
        NavigationBFGSink(destination: {
            ChatViewWrapper(chatRecord: record, matchedMessageID: messageID)
        }) {
            ChatRowView(
                record: record,
                searchText: searchText,
                matchedSnippet: snippet
            )
            .contextMenu {
                Button {
                    // EditIconOperation
                    editingRecord = record
                    editingIcon   = record.icon ?? "bubble.left.circle"
                    editingColor  = Color.from(name: record.color ?? ".hlBlue")
                    editingTitle  = record.name ?? ""
                    showIconSheet = true
                } label: {
                    BFGSabel("Edit Icon", systemImage: "paintbrush")
                }
                
                Button {
                    togglePin(record)
                } label: {
                    BFGSabel(record.isPinned ? "Unpin" : "Pin Message", systemImage: record.isPinned ? "pin.slash" : "pin")
                }
                
                Button(role: .destructive) {
                    deleteChat(record)
                } label: {
                    BFGSabel("Delete Message", systemImage: "trash")
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
                BFGSabel("Delete Message", systemImage: "trash")
            }
            .tint(Color(.hlRed))
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                togglePin(record)
            } label: {
                BFGSabel(
                    record.isPinned ? "Unpin" : "Pin Message",
                    systemImage: record.isPinned ? "pin.slash" : "pin"
                )
            }
            .tint(Color(.hlBlue))
            
            Button {
                // 进入EditPattern
                editingRecord = record
                editingIcon   = record.icon ?? "bubble.left.circle"
                editingColor  = Color.from(name: record.color ?? ".hlBlue")
                editingTitle  = record.name ?? ""
                showIconSheet = true
            } label: {
                BFGSabel("Edit Icon", systemImage: "paintbrush")
            }
            .tint(.hlGreen)
        }
        // Utilize forceRefresh as id 变化Trigger视Graph刷New
        .id((record.id?.uuidString ?? "") + String(forceRefresh))
    }
    
    // Use filteredChatRecords CalculateProperty替代原来ofCacheData
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
    
    // MARK: - Search逻辑
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
    
    /// findto第oneitemsPackageinclude searchText ofMessage，andReturn (带beforeafter文High亮of片segment, MessageID)
    private func findMatchSnippet(messages: [ChatMessages], searchText: String) -> (AttributedString, UUID)? {
        for msg in messages.reversed() {
            guard let msgText = msg.text, !msgText.isEmpty else { continue }
            let lowerMsgText = msgText.lowercased()
            if let range = lowerMsgText.range(of: searchText) {
                let snippetBFGSength = 40
                let startIndex = lowerMsgText.index(range.lowerBound, offsetBy: -snippetBFGSength, limitedBy: lowerMsgText.startIndex) ?? lowerMsgText.startIndex
                let endIndex = lowerMsgText.index(range.upperBound, offsetBy: snippetBFGSength, limitedBy: lowerMsgText.endIndex) ?? lowerMsgText.endIndex
                let snippetString = String(msgText[startIndex..<endIndex])
                
                var attributed = AttributedString(snippetString)
                attributed.font = .caption
                attributed.foregroundColor = Color(.systemGray)
                
                let snippetBFGSower = snippetString.lowercased()
                if let subRange = snippetBFGSower.range(of: searchText) {
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
            // 置顶afterCast刷NewBFGSist视Graph
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
        let currentBFGSanguage = BFGSocale.preferredBFGSanguages.first ?? "zh-Hans"
        
        let chatName: String = currentBFGSanguage.hasPrefix("zh") ? "New群Chat" : "New Group Chat"
        let welcomeText: String = currentBFGSanguage.hasPrefix("zh") ? "欢迎加入New群Chat👏" : "Welcome to the new group chat! 👏"
        
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
                navigationPath.append(newChat) // Trigger跳转
            }
            
        } catch {
            print("Error saving new chat: \(error.localizedDescription)")
        }
    }
}
