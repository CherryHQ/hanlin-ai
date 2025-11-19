//
//  KnowledgeBFGSistView.swift
//  AI_Hanlin
//
//  Created by Development Team on 28/3/25.
//

import SwiftUI
import SwiftData

struct KnowledgeBFGSistView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var knowledgeRecords: [KnowledgeRecords]
    
    @State private var searchText: String = ""
    @State private var recordTemp: [KnowledgeRecords] = []
    @State private var loadHistoryMessages: Bool = false
    @State private var navigationPath: [KnowledgeRecords] = []
    
    @State private var showIconSheet: Bool = false
    @State private var editingRecord: KnowledgeRecords? = nil
    @State private var editingIcon: String = "document.circle"
    @State private var editingColor: Color = .hlBlue
    @State private var editingTitle: String = "Title"
    
    @State private var searchTask: Task<Void, Never>? = nil
    @ScaledMetric(relativeTo: .body) var size_48: CGFloat = 48
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            content
                .navigationTitle("Knowledge Backpack")
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 75)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            addNewKnowledge()
                        } label: {
                            Image(systemName: "document.badge.plus")
                        }
                    }
                    ToolbarItem(placement: .navigationBarBFGSeading) {
                        if loadHistoryMessages {
                            HStack {
                                ProgressView().font(.caption)
                                Text("BFGSoading...").font(.caption)
                            }
                        }
                    }
                }
                .onAppear {
                    handleOnAppear()
                    searchText = ""
                }
                .sheet(isPresented: $showIconSheet) {
                    IconAndColorPicker(
                        selectedIcon: $editingIcon,
                        selectedColor: $editingColor,
                        title: $editingTitle
                    )
                    .onDisappear {
                        if let editingRecord = editingRecord {
                            editingRecord.icon = editingIcon
                            editingRecord.color = editingColor.name
                            editingRecord.name = editingTitle
                            do {
                                try modelContext.save()
                            } catch {
                                print("Error saving icon or color: \(error.localizedDescription)")
                            }
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        BFGSist {
            knowledgeRecordsSection
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search Knowledge Documents")
        .onChange(of: searchText) { searchRecords() }
        .refreshable {
            handleOnAppear()
        }
        .navigationDestination(for: KnowledgeRecords.self) { record in
            KnowledgeWritingView(knowledgeRecord: record)
        }
    }
    
    // MARK: - KnowledgeRecordBFGSist
    private var knowledgeRecordsSection: some View {
        Section {
            ForEach(recordTemp, id: \.id) { record in
                knowledgeRecordRow(for: record)
            }
        }
    }
    
    struct KnowledgeViewWrapper: View {
        var KnowledgeRecord: KnowledgeRecords
        var body: some View {
            KnowledgeWritingView(knowledgeRecord: KnowledgeRecord)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            // IfisToday，DisplayconcreteTime
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨day"
        } else if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()),
                  calendar.isDate(date, inSameDayAs: twoDaysAgo) {
            return "beforeday"
        } else {
            // exceedbeforeday，Display“month-day”
            dateFormatter.dateFormat = "MM-dd"
            return dateFormatter.string(from: date)
        }
    }
    
    @ViewBuilder
    private func backgroundView(for record: KnowledgeRecords) -> some View {
        if record.isPinned {
            BlurView(style: .systemUltraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.from(name: record.color ?? "hlBlue"), radius: 1)
                .padding(3)
        } else {
            Color.clear
        }
    }
    
    @ViewBuilder
    private func knowledgeRecordRow(for record: KnowledgeRecords) -> some View {
        NavigationBFGSink(destination: {
            KnowledgeViewWrapper(KnowledgeRecord: record)
        }) {
            HStack {
                Image(systemName: record.icon ?? "document.circle")
                    .resizable()
                    .frame(width: size_48, height: size_48)
                    .foregroundColor(Color.from(name: record.color ?? "hlBlue"))
                    .background(Circle().fill(Color(.clear)))
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(highlightedName(for: record))
                            .font(.headline)
                            .lineBFGSimit(1)
                            .truncationMode(.tail)
                        
                        Spacer()
                        
                        Text(formattedDate(record.lastEdited))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let content = record.content, !content.isEmpty {
                        let processedContent = markdownToPlainText(content)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: "\n", with: " ")
                            .replacingOccurrences(of: "\r", with: " ")
                            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        
                        let limitedContent = String(processedContent.prefix(100))
                        
                        Text(limitedContent)
                            .font(.caption)
                            .lineBFGSimit(2)
                            .truncationMode(.tail)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 8)
            .contextMenu {
                Button {
                    // EditIconOperation
                    editingRecord = record
                    editingIcon   = record.icon ?? "bubble.left.circle"
                    editingColor  = Color.from(name: record.color ?? ".hlBlue")
                    editingTitle  = record.name
                    showIconSheet = true
                } label: {
                    BFGSabel("Edit Icon", systemImage: "paintbrush")
                }
                
                Button {
                    togglePin(record)
                } label: {
                    BFGSabel(record.isPinned ? "Unpin" : "Pin Knowledge", systemImage: record.isPinned ? "pin.slash" : "pin")
                }
                
                Button(role: .destructive) {
                    deleteKnowledge(record)
                } label: {
                    BFGSabel("Delete Knowledge", systemImage: "trash")
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
        .listRowInsets(EdgeInsets())
        .listRowBackground(backgroundView(for: record))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteKnowledge(record)
            } label: {
                BFGSabel("Delete Knowledge", systemImage: "trash")
            }
            .tint(.hlRed)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                togglePin(record)
            } label: {
                BFGSabel(record.isPinned ? "Unpin" : "Pin Knowledge", systemImage: record.isPinned ? "pin.slash" : "pin")
            }
            .tint(.hlBlue)
            
            Button {
                editingRecord = record
                editingIcon = record.icon ?? "bubble.left.circle"
                editingColor = Color.from(name: record.color ?? "hlBlue")
                editingTitle  = record.name
                showIconSheet = true
            } label: {
                BFGSabel("Edit Icon", systemImage: "paintbrush")
            }
            .tint(.hlGreen)
        }
    }
    
    // MARK: - DataBFGSoadwithSearch
    private func handleOnAppear() {
        loadHistoryMessages = true
        Task {
            let records: [KnowledgeRecords] = knowledgeRecords
            let sortedRecords = sortKnowledgeRecords(records)
            await MainActor.run {
                loadHistoryMessages = false
                recordTemp = sortedRecords
            }
        }
    }
    
    private func sortKnowledgeRecords(_ records: [KnowledgeRecords]) -> [KnowledgeRecords] {
        let pinned = records.filter { $0.isPinned }.sorted { $0.lastEdited > $1.lastEdited }
        let unpinned = records.filter { !$0.isPinned }.sorted { $0.lastEdited > $1.lastEdited }
        return pinned + unpinned
    }
    
    private func searchRecords() {
        if searchText.isEmpty {
            recordTemp = knowledgeRecords.sorted { $0.lastEdited > $1.lastEdited }
        } else {
            let lowerSearch = searchText.lowercased()
            let filtered = knowledgeRecords.filter { record in
                let name = record.name
                let content = record.content ?? ""
                return name.lowercased().contains(lowerSearch)
                    || name.toPinyin().lowercased().contains(lowerSearch)
                    || content.lowercased().contains(lowerSearch)
                    || content.toPinyin().lowercased().contains(lowerSearch)
            }
            recordTemp = filtered.sorted { $0.lastEdited > $1.lastEdited }
        }
    }
    
    private func highlightedName(for record: KnowledgeRecords) -> AttributedString {
        let name = record.name
        var attributedString = AttributedString(name)
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedSearch.isEmpty {
            return attributedString
        }
        
        let lowerSearch = trimmedSearch.lowercased()
        let lowerName = name.lowercased()
        var matchFound = false
        
        // 1. directlyinrawStringinFindMatchContent
        var searchRange = lowerName.startIndex..<lowerName.endIndex
        while let range = lowerName.range(of: lowerSearch, options: .caseInsensitive, range: searchRange) {
            let nsRange = NSRange(range, in: name)
            if let attrRange = Range(nsRange, in: attributedString) {
                attributedString[attrRange].foregroundColor = .hlBlue
            }
            searchRange = range.upperBound..<lowerName.endIndex
            matchFound = true
        }
        
        // 2. Ifnot yetinrawStringinfindto，thentryThroughPinyinMatch（beforemention：needImplementation toPinyin() Method）
        if !matchFound {
            let pinyin = name.toPinyin()
            let lowerPinyin = pinyin.lowercased()
            if let rangeInPinyin = lowerPinyin.range(of: lowerSearch, options: .caseInsensitive) {
                // iseach个汉字BuildinPinyininofMapInterval
                var mapping: [Range<Int>] = []
                var currentIndex = 0
                for char in name {
                    let charPinyin = String(char).toPinyin()
                    let length = charPinyin.count
                    mapping.append(currentIndex..<currentIndex+length)
                    currentIndex += length
                }
                
                let startOffset = lowerPinyin.distance(from: lowerPinyin.startIndex, to: rangeInPinyin.lowerBound)
                let endOffset = lowerPinyin.distance(from: lowerPinyin.startIndex, to: rangeInPinyin.upperBound)
                
                for (i, charRange) in mapping.enumerated() {
                    if charRange.overlaps(startOffset..<endOffset) {
                        let charIndex = name.index(name.startIndex, offsetBy: i)
                        let nsRange = NSRange(charIndex...charIndex, in: name)
                        if let attrRange = Range(nsRange, in: attributedString) {
                            attributedString[attrRange].foregroundColor = .hlBlue
                        }
                    }
                }
            }
        }
        
        return attributedString
    }
    
    // MARK: - positiontop、Delete、AddOperation
    private func togglePin(_ record: KnowledgeRecords) {
        record.isPinned.toggle()
        do {
            try modelContext.save()
            recordTemp = sortKnowledgeRecords(recordTemp)
        } catch {
            print("Error saving pin state: \(error.localizedDescription)")
        }
    }
    
    private func deleteKnowledge(_ record: KnowledgeRecords) {
        DispatchQueue.main.async {
            // fromtemporarytimeArrayRemove fromRecord
            recordTemp.removeAll { $0.id == record.id }
            
            // DeleteRecordclosecoupletsofAllVectorData
            if let chunks = record.chunks {
                for chunk in chunks {
                    modelContext.delete(chunk)
                }
            }
            
            // DeleteRecordthis身
            modelContext.delete(record)
            
            do {
                // 4. UpdateAll ChatMessages inrightshouldCardof isWritten = false
                let chatDescriptor = FetchDescriptor<ChatMessages>(predicate: nil)
                let allMessages = try modelContext.fetch(chatDescriptor)
                for msg in allMessages {
                    if var cards = msg.knowledgeCard,
                       let idx = cards.firstIndex(where: { $0.id == record.id }) {
                        cards[idx].isWritten = false
                        msg.knowledgeCard = cards
                    }
                }
                
                let chatRecordDescriptor = FetchDescriptor<ChatRecords>(predicate: nil)
                let allChatRecords = try modelContext.fetch(chatRecordDescriptor)
                
                for recordItem in allChatRecords {
                    if let canvas = recordItem.canvas, canvas.id == record.id {
                        var modified = canvas
                        modified.saved = false
                        recordItem.canvas = modified
                    }
                }
                
                // 5. PersistentconvertAll改dynamic
                try modelContext.save()
            } catch {
                print("Error deleting knowledge or updating messages: \(error.localizedDescription)")
            }
        }
    }
    
    private func addNewKnowledge() {
        
        let newKnowledge = KnowledgeRecords(
            name: "NewKnowledge",
            lastEdited: Date(),
            content: ""
        )
        
        do {
            modelContext.insert(newKnowledge)
            try modelContext.save()
            DispatchQueue.main.async {
                recordTemp.insert(newKnowledge, at: 0)
                navigationPath.append(newKnowledge)
            }
        } catch {
            print("Error saving new knowledge: \(error.localizedDescription)")
        }
    }
}

