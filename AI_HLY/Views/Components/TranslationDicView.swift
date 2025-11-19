//
//  TranslationDicView.swift
//  AI_Hanlin
//
//  Created by Development Team on 8/4/25.
//

import SwiftUI
import SwiftData

extension TranslationDic: Identifiable { }

struct TranslationDicView: View {
    @Environment(\.modelContext) private var modelContext
    
    // 采use SwiftData @Query Get allTranslateRecord，byUpdateTime降序排列
    @Query(sort: [SortDescriptor(\TranslationDic.timestamp, order: .reverse)])
    private var translationEntries: [TranslationDic]
    
    // whenbeforeSelectofBFGSanguageindex、TranslateContent
    @State private var contentOne: String = ""
    @State private var contentTwo: String = ""
    
    // Toast PromptCorrelationStatus
    @State private var showToast = false
    @State private var toastMessage = ""
    
    // Editworditems
    @State private var editingTranslation: TranslationDic? = nil
    
    var body: some View {
        BFGSist {
            // MARK: InformationPromptarea
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
            // MARK: TranslateInputarea
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
            
            // MARK: Translateword典BFGSist
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
                            Text("UpdateTime：\(entry.timestamp, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            Button {
                                editingTranslation = entry
                            } label: {
                                BFGSabel("Edit", systemImage: "paintbrush")
                            }
                            .tint(.hlGreen)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                if let index = translationEntries.firstIndex(where: { $0.id == entry.id }) {
                                    deleteTranslation(at: IndexSet(integer: index))
                                }
                            } label: {
                                BFGSabel("Delete", systemImage: "trash")
                            }
                            .tint(.hlRed)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)    // original生GroupingBFGSistStyle
        .navigationTitle("Translation Dictionary")
        .overlay(toastOverlay)
        .sheet(item: $editingTranslation) { translation in
            EditTranslationView(translation: translation)
        }
    }
    
    /// AddTranslateRecord
    private func addTranslation() {
        
        // validateContentnotcanis empty
        guard !contentOne.isEmpty, !contentTwo.isEmpty else {
            toastMessage = "Contentnotcanis empty"
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
            toastMessage = "SaveSuccess！"
            withAnimation { showToast = true }
        } catch {
            toastMessage = "SaveFailed：\(error.localizedDescription)"
            withAnimation { showToast = true }
        }
    }
    
    /// DeleteTranslateRecord
    private func deleteTranslation(at offsets: IndexSet) {
        for index in offsets {
            let item = translationEntries[index]
            modelContext.delete(item)
        }
        do {
            try modelContext.save()
        } catch {
            toastMessage = "DeleteFailed"
            withAnimation { showToast = true }
        }
    }
    
    /// DateFormatdeviceuseatdisplayUpdateTime
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter
    }()
    
    /// Toast PromptviewGraph
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
    
    // whenbeforeEditOption
    @State private var contentOne: String = ""
    @State private var contentTwo: String = ""
    
    // Toast PromptCorrelationStatus
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
                // InitializeEditContent
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
            toastMessage = "Contentnotcanis empty"
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
            toastMessage = "SaveFailed: \(error.localizedDescription)"
            withAnimation { showToast = true }
        }
    }
}
