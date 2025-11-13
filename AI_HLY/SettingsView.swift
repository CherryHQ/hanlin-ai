//
//  SettingsView.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 10/2/25.
//

import SwiftUI
import SwiftData
import SafariServices

struct SettingsView: View {
    
    @State private var isPushed: Bool = false  // 监听是否进入子页面
    @State private var showSafariGuide: Bool = false
    @State private var showSafariCost: Bool = false
    
    @Query var apiKeys: [APIKeys]
    @Query var searchKeys: [SearchKeys]
    
    var body: some View {
        
        let noAPIKeys = apiKeys
            .filter { $0.company != "LOCAL" }
            .allSatisfy { $0.key?.isEmpty ?? true }
        
        let noSearchKeys = searchKeys
            .allSatisfy { $0.key?.isEmpty ?? true }
        
        NavigationStack {
            List {
                Section(header: Text("Personalization")) {
                    NavigationLink(destination: UserInfoView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("User Information", systemImage: "person")
                    }
                    NavigationLink(destination: PromptRepoView().onAppear { isPushed = true }.onDisappear { isPushed = false}.toolbar(.hidden, for: .tabBar)) {
                        Label("Prompt Library", systemImage: "tray.full")
                    }
                    NavigationLink(destination: MemoryArchiveView().onAppear { isPushed = true }.onDisappear { isPushed = false}.toolbar(.hidden, for: .tabBar)) {
                        Label("Memory Archive", systemImage: "archivebox")
                    }
                    NavigationLink(destination: TranslationDicView().onAppear { isPushed = true }.onDisappear { isPushed = false}.toolbar(.hidden, for: .tabBar)) {
                        Label("Translation Dictionary", systemImage: "character.book.closed")
                    }
                }
                if noAPIKeys {
                    Section {
                        Text("Guideline: Click on \"Model Key\" in the \"Model\" section below to set the large model key and enable the vendor status.")
                            .font(.caption)
                            .foregroundColor(.hlBluefont)
                    }
                }
                Section(header: Text("Models")) {
                    NavigationLink(destination: APIKeysView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Model Keys", systemImage: "key.2.on.ring")
                    }
                    NavigationLink(destination: SelectEmbeddingModelView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Embedding Models", systemImage: "compass.drawing")
                    }
                    NavigationLink(destination: SelectOptimizationModelView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Optimization Models", systemImage: "hammer")
                    }
                    NavigationLink(destination: SelectTTSModelView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Speech Model", systemImage: "waveform")
                    }
                }
                if noSearchKeys {
                    Section {
                        Text("Guide: Click “Network Search” under “Tools” to set the search engine key and select the search engine to use.")
                            .font(.caption)
                            .foregroundColor(.hlBluefont)
                    }
                }
                Section(header: Text("Tools")) {
                    NavigationLink(destination: SearchSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Network Search", systemImage: "magnifyingglass")
                    }
                    NavigationLink(destination: KnowledgeSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Knowledge Backpack", systemImage: "backpack")
                    }
                    NavigationLink(destination: CanvasSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Information Canvas", systemImage: "pencil.and.outline")
                    }
                    NavigationLink(destination: MapSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Map & Planning", systemImage: "map")
                    }
                    NavigationLink(destination: WeatherSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Weather Enquiry", systemImage: "cloud.sun")
                    }
                    NavigationLink(destination: CalendarSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Calendar & Reminder", systemImage: "calendar")
                    }
                    NavigationLink(destination: HealthSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Healthy & Living", systemImage: "heart")
                    }
                    NavigationLink(destination: CodeSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Code Execution", systemImage: "apple.terminal")
                    }
                }
                Section(header: Text("Help")) {
                    Button(action: {
                        showSafariGuide = true
                    }) {
                        Label {
                            Text("Software Guide")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "text.rectangle.page")
                        }
                    }
                    Button(action: {
                        showSafariCost = true
                    }) {
                        Label {
                            Text("Cost")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "creditcard")
                        }
                    }
                }
                Section(header: Text("General")) {
                    Button(action: openLanguageSettings) {
                        Label {
                            Text("Language Settings")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "globe")
                        }
                    }
                    NavigationLink(destination: FeedBackView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Haptic Feedback", systemImage: "iphone.gen3.radiowaves.left.and.right")
                    }
                }
                Section(header: Text("Software")) {
                    NavigationLink(destination: SoftwareIntroView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Software Introduction", systemImage: "text.book.closed")
                    }
                    NavigationLink(destination: UpdateNotesView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Update Notes", systemImage: "newspaper")
                    }
                    NavigationLink(destination: VersionInfoView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Software Information", systemImage: "info.circle")
                    }
                    NavigationLink(destination: ContactUsView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        Label("Contact Us", systemImage: "envelope")
                    }
                }
            }
            .navigationTitle("Settings")
            .onChange(of: isPushed) {
                NotificationCenter.default.post(name: .hideTabBar, object: isPushed)  // 发送通知，控制TabBar显示/隐藏
            }
            .safeAreaInset(edge: .bottom) { // 额外填充底部一个灰色区域
                Color(.clear)
                    .frame(height: 70)
            }
        }
        .fullScreenCover(isPresented: $showSafariGuide) {
            SafariView(url: URL(string: "https://docs.qq.com/aio/DT2pMUFRVWVNsZmtj")!)
                .background(BlurView(style: .systemThinMaterial))
                .edgesIgnoringSafeArea(.all)
        }
        .fullScreenCover(isPresented: $showSafariCost) {
            SafariView(url: URL(string: "https://docs.qq.com/smartsheet/DT3dzT1JlSFVvU05n?viewId=vUQPXH&tab=db_KULEGz")!)
                .background(BlurView(style: .systemThinMaterial))
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    /// 打开系统的“语言与地区”设置
    private func openLanguageSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url)
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        print("加载的 URL: \(url.absoluteString)") // 调试日志
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
