//
//  ListViewComponents.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 11/2/25.
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
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    Text(formattedDate(record.lastEdited))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // 如果存在匹配片段，则显示出来
                if let snippet = matchedSnippet {
                    Text(snippet)
                        .font(.caption)
                        .lineLimit(2)
                        .truncationMode(.tail)
                } else {
                    if let highlightedDescription = highlightedText(record.infoDescription ?? "", searchText: searchText) {
                        Text(highlightedDescription)
                            .font(.caption)
                            .foregroundColor(Color(.systemGray))
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("No Messages Yet")
                            .font(.caption)
                            .foregroundColor(Color(.systemGray))
                            .lineLimit(2)
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
            // 如果是今天，显示具体时间
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else if let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date()),
                  calendar.isDate(date, inSameDayAs: twoDaysAgo) {
            return "前天"
        } else {
            // 超过前天，显示“月-日”
            dateFormatter.dateFormat = "MM-dd"
            return dateFormatter.string(from: date)
        }
    }
    
    private func highlightedText(_ text: String, searchText: String) -> AttributedString? {
        var attributedString = AttributedString(text)
        attributedString.font = .caption
        
        // 检查开头是否为 "[草稿]" 或 "[图像]" 并做颜色处理
        if text.hasPrefix("[草稿]") {
            if let draftRange = attributedString.range(of: "[草稿]") {
                attributedString[draftRange].foregroundColor = .hlRed
            }
        } else if text.hasPrefix("[图像]") {
            if let imageRange = attributedString.range(of: "[图像]") {
                attributedString[imageRange].foregroundColor = .hlGreen
            }
        }
        
        // 如果 searchText 非空，则对其中匹配的部分进行高亮
        if !searchText.isEmpty,
           let range = attributedString.range(of: searchText, options: .caseInsensitive) {
            attributedString[range].foregroundColor = Color(.hlBlue)
            attributedString[range].font = .systemFont(ofSize: UIFont.systemFontSize, weight: .bold)
        }
        
        return attributedString
    }
    
    private func highlightedChatName() -> Text {
        // 如果名称为空，则返回默认“Unknown”
        guard let name = record.name, !name.isEmpty else {
            return Text("Unknown")
                .font(.headline)
                .foregroundColor(.primary)
        }
        
        // 去除搜索词前后空格，并提前处理空搜索
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedSearch.isEmpty {
            return Text(name).font(.headline)
        }
        
        // 构建富文本对象
        var attributedName = AttributedString(name)
        let lowerName = name.lowercased()
        let lowerSearch = trimmedSearch.lowercased()
        
        // 遍历查找所有匹配项，并设置高亮颜色
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
    
    let availableIcons = getIconList()
    let availableColors = getColorList()
    
    let iconColumns = [GridItem(.adaptive(minimum: 60), spacing: 12)]  // 图标：每行自适应
    let colorColumns = [GridItem(.adaptive(minimum: 40), spacing: 12)] // 颜色：每行自适应，最小宽度更小
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 预览消息栏
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
                            .lineLimit(1)
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
                
                // 图标选择
                VStack(alignment: .leading) {
                    ScrollView {
                        LazyVGrid(columns: iconColumns, spacing: 20) {
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
                
                // 颜色选择
                VStack(alignment: .leading) {
                    ScrollView {
                        LazyVGrid(columns: colorColumns, spacing: 20) {
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

