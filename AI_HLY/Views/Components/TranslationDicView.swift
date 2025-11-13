//
//  TranslationDicView.swift
//  AI_Hanlin
//
//  Created by 哆啦好多梦 on 8/4/25.
//

import SwiftUI
import SwiftData

extension TranslationDic: Identifiable { }

struct TranslationDicView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 采用 SwiftData @Query 获取所有翻译记录，按更新时间降序排列
    @Query(sort: [SortDescriptor(\TranslationDic.timestamp, order: .reverse)])
    private var translationEntries: [TranslationDic]
    
    // 当前选择的语言索引、翻译内容
    @State private var contentOne: String = ""
    @State private var contentTwo: String = ""
    
    // Toast 提示相关状态
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // 编辑词条
    @State private var editingTranslation: TranslationDic? = nil
    
    var body: some View {
        List {
            // MARK: 信息提示区
            Section {
                VStack(alignment: .center) {
                    Image(systemName: "character.book.closed")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.hlBluefont)
                        .padding()
                    
                    Text("Setting up a translation dictionary will make the results of \"instant translation\" more personalized, especially for certain proprietary translation knowledge. Adding collocations to the translation dictionary can quickly optimize your translation results.")
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            // MARK: 翻译输入区
            Section(header: Text("Input Translation Dictionary")) {
                
                TextField("Content 1", text: $contentOne)
                
                HStack {
                    Spacer()
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(.hlBluefont)
                        .bold()
                    Spacer()
                }
                
                TextField("Content 2", text: $contentTwo)
                
                Button(action: {
                    addTranslation()
                }, label: {
                    HStack {
                        Spacer()
                        Text("Save Translation Mappings")
                            .foregroundColor(.hlBluefont)
                            .bold()
                        Spacer()
                    }
                })
                .padding(.vertical, 4)
            }
            
            // MARK: 翻译词典列表
            Section(header: Text("Translation Dictionary")) {
                if translationEntries.isEmpty {
                    Text("No translation record")
                        .foregroundColor(.gray)
                } else {
                    ForEach(translationEntries) { entry in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.contentOne ?? "")
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(entry.contentTwo ?? "")
                            Text("更新时间：\(entry.timestamp, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                editingTranslation = entry
                            } label: {
                                Label("Edit", systemImage: "paintbrush")
                            }
                            .tint(.hlGreen)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                if let index = translationEntries.firstIndex(where: { $0.id == entry.id }) {
                                    deleteTranslation(at: IndexSet(integer: index))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(.hlRed)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)    // 原生分组列表风格
        .navigationTitle("Translation Dictionary")
        .overlay(toastOverlay)
        .sheet(item: $editingTranslation) { translation in
            EditTranslationView(translation: translation)
        }
    }
    
    /// 新增翻译记录
    private func addTranslation() {
        
        // 校验内容不能为空
        guard !contentOne.isEmpty, !contentTwo.isEmpty else {
            toastMessage = "内容不能为空"
            withAnimation { showToast = true }
            return
        }
        
        let newTranslation = TranslationDic(
            contentOne: contentOne,
            contentTwo: contentTwo,
            timestamp: Date()
        )
        
        modelContext.insert(newTranslation)
        do {
            try modelContext.save()
            contentOne = ""
            contentTwo = ""
            toastMessage = "保存成功！"
            withAnimation { showToast = true }
        } catch {
            toastMessage = "保存失败：\(error.localizedDescription)"
            withAnimation { showToast = true }
        }
    }
    
    /// 删除翻译记录
    private func deleteTranslation(at offsets: IndexSet) {
        for index in offsets {
            let item = translationEntries[index]
            modelContext.delete(item)
        }
        do {
            try modelContext.save()
        } catch {
            toastMessage = "删除失败"
            withAnimation { showToast = true }
        }
    }
    
    /// 日期格式化器用于展示更新时间
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter
    }()
    
    /// Toast 提示视图
    @ViewBuilder
    private var toastOverlay: some View {
        VStack {
            if showToast {
                Text(toastMessage)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .transition(.opacity)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { showToast = false }
                        }
                    }
            }
            Spacer()
        }
        .padding(.top, 50)
    }
}

struct EditTranslationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var translation: TranslationDic
    
    // 当前编辑选项
    @State private var contentOne: String = ""
    @State private var contentTwo: String = ""
    
    // Toast 提示相关状态
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Edit Translation")) {
                    TextField("Content 1", text: $contentOne)
                    
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.up.arrow.down")
                            .foregroundColor(.hlBluefont)
                            .bold()
                        Spacer()
                    }
                    
                    TextField("Content 2", text: $contentTwo)
                }
            }
            .navigationTitle("Edit Translation")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEdits()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 初始化编辑内容
                contentOne = translation.contentOne ?? ""
                contentTwo = translation.contentTwo ?? ""
            }
            .overlay(
                VStack {
                    if showToast {
                        Text(toastMessage)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .transition(.opacity)
                    }
                    Spacer()
                }
                .padding(.top, 50)
            )
        }
    }
    
    private func saveEdits() {
        
        guard !contentOne.isEmpty, !contentTwo.isEmpty else {
            toastMessage = "内容不能为空"
            withAnimation { showToast = true }
            return
        }
        
        translation.contentOne = contentOne
        translation.contentTwo = contentTwo
        translation.timestamp = Date()
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            toastMessage = "保存失败: \(error.localizedDescription)"
            withAnimation { showToast = true }
        }
    }
}
