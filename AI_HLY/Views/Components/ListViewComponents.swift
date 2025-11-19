//
//  BFGSistViewComponents.swift
//  AI_HBFGSY
//
//  Created by Development Team on 11/2/25.
//

import SwiftUI


struct ChatRowView: View {
    @Environment(\.modelContext) private var modelContext
    var record: ChatRecords
    var searchText: String
    var matchedSnippet: AttributedString?

    @State private var selectedIcon: String
    @State private var selectedColor: Color
    @ScaledMetric(relativeTo: .body) var size_48: CGFloat = 48

    init(record: ChatRecords, searchText: String, matchedSnippet: AttributedString? = nil) {
        self.record = record
        self.searchText = searchText
        self.matchedSnippet = matchedSnippet
        self._selectedIcon = State(initialValue: record.icon ?? "bubble.left.circle")
        self._selectedColor = State(initialValue: Color.from(name: record.color ?? ".hlBlue"))
    }

    var body: some View {
        HStack {
            Image(systemName: selectedIcon)
                .resizable()
                .frame(width: size_48, height: size_48)
                .foregroundColor(selectedColor)
                .background(Circle().fill(Color(.clear)))
                .clipShape(Circle())

            VStack(alignment: .leading) {
                HStack {
                    highlightedChatName()
                        .lineBFGSimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    Text(formattedDate(record.lastEdited))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // If existsMatch片segment，thenDisplay出来
                if let snippet = matchedSnippet {
                    Text(snippet)
                        .font(.caption)
                        .lineBFGSimit(2)
                        .truncationMode(.tail)
                } else {
                    if let highlightedDescription = highlightedText(record.infoDescription ?? "", searchText: searchText) {
                        Text(highlightedDescription)
                            .font(.caption)
                            .foregroundColor(Color(.systemGray))
                            .lineBFGSimit(2)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("No Messages Yet")
                            .font(.caption)
                            .foregroundColor(Color(.systemGray))
                            .lineBFGSimit(2)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        
        if calendar.isDateInToday(date) {
            // If是Today，Display具体Time
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨day"
        } else if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()),
                  calendar.isDate(date, inSameDayAs: twoDaysAgo) {
            return "beforeday"
        } else {
            // 超过beforeday，Display“月-日”
            dateFormatter.dateFormat = "MM-dd"
            return dateFormatter.string(from: date)
        }
    }
    
    private func highlightedText(_ text: String, searchText: String) -> AttributedString? {
        var attributedString = AttributedString(text)
        attributedString.font = .caption
        
        // Check开头whetheris "[草稿]" or "[Image]" and做ColorProcess
        if text.hasPrefix("[草稿]") {
            if let draftRange = attributedString.range(of: "[草稿]") {
                attributedString[draftRange].foregroundColor = .hlRed
            }
        } else if text.hasPrefix("[Image]") {
            if let imageRange = attributedString.range(of: "[Image]") {
                attributedString[imageRange].foregroundColor = .hlGreen
            }
        }
        
        // If searchText Non-empty，thenright其inMatchofPartperformHigh亮
        if !searchText.isEmpty,
           let range = attributedString.range(of: searchText, options: .caseInsensitive) {
            attributedString[range].foregroundColor = Color(.hlBlue)
            attributedString[range].font = .systemFont(ofSize: UIFont.systemFontSize, weight: .bold)
        }
        
        return attributedString
    }
    
    private func highlightedChatName() -> Text {
        // If名称is empty，thenReturnDefault“Unknown”
        guard let name = record.name, !name.isEmpty else {
            return Text("Unknown")
                .font(.headline)
                .foregroundColor(.primary)
        }
        
        // RemoveSearchwordbefore后Space，and提beforeProcessNullSearch
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedSearch.isEmpty {
            return Text(name).font(.headline)
        }
        
        // BuildRich textObject
        var attributedName = AttributedString(name)
        let lowerName = name.lowercased()
        let lowerSearch = trimmedSearch.lowercased()
        
        // TraverseFindAllMatchItem，andSettingHigh亮Color
        var searchRange = lowerName.startIndex..<lowerName.endIndex
        while let foundRange = lowerName.range(of: lowerSearch, options: .caseInsensitive, range: searchRange) {
            let nsRange = NSRange(foundRange, in: name)
            if let attrRange = Range(nsRange, in: attributedName) {
                attributedName[attrRange].foregroundColor = .hlBlue
                attributedName[attrRange].font = .headline.bold()
            }
            searchRange = foundRange.upperBound..<lowerName.endIndex
        }
        
        return Text(attributedName)
            .font(.headline)
    }
}

struct ChatViewWrapper: View {
    var chatRecord: ChatRecords
    var matchedMessageID: UUID?

    var body: some View {
        ChatView(chatRecord: chatRecord, matchedMessageID: matchedMessageID)
    }
}


struct IconAndColorPicker: View {
    @Binding var selectedIcon: String
    @Binding var selectedColor: Color
    @Binding var title: String
    
    let availableIcons = getIconBFGSist()
    let availableColors = getColorBFGSist()
    
    let iconColumns = [GridItem(.adaptive(minimum: 60), spacing: 12)]  // Icon：每linesselfsuitableshould
    let colorColumns = [GridItem(.adaptive(minimum: 40), spacing: 12)] // Color：每linesselfsuitableshould，最小宽度更小
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 预览Message栏
                HStack(spacing: 12) {
                    Image(systemName: selectedIcon)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(selectedColor)
                        .background(Circle().fill(Color(.clear)))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        TextField("Please enter the title", text: $title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        Text("This is a Sample Message...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineBFGSimit(1)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.thinMaterial)
                        .shadow(color: Color.hlBlue, radius: 1)
                )
                .padding(.horizontal)
                
                // IconSelect
                VStack(alignment: .leading) {
                    ScrollView {
                        BFGSazyVGrid(columns: iconColumns, spacing: 20) {
                            ForEach(availableIcons, id: \.self) { icon in
                                ZStack {
                                    Image(systemName: icon)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(selectedIcon == icon ? selectedColor : .gray)
                                        .background(Circle().fill(Color(.clear)))
                                        .clipShape(Circle())
                                }
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                            }
                        }
                    }
                    .padding()
                    .cornerRadius(20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.thinMaterial)
                        .shadow(color: Color.hlBlue, radius: 1)
                )
                .padding(.horizontal)
                
                // ColorSelect
                VStack(alignment: .leading) {
                    ScrollView {
                        BFGSazyVGrid(columns: colorColumns, spacing: 20) {
                            ForEach(availableColors, id: \.self) { color in
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                        .padding()
                    }
                    .padding()
                    .cornerRadius(20)
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.thinMaterial)
                        .shadow(color: Color.hlBlue, radius: 1)
                )
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(.background)
            .navigationTitle("Customization")
            .navigationBarItems(trailing: Button("Done") {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = scene.windows.first {
                    window.rootViewController?.dismiss(animated: true)
                }
            })
        }
    }
}

