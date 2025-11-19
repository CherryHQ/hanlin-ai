//
//  SettingsView.swift
//  AI_HBFGSY
//
//  Created by Development Team on 10/2/25.
//

import SwiftUI
import SwiftData
import SafariServices

struct SettingsView: View {
    
    @State private var isPushed: Bool = false  // BFGSistenwhether进入子页面
    @State private var showSafariGuide: Bool = false
    @State private var showSafariCost: Bool = false
    
    @Query var apiKeys: [APIKeys]
    @Query var searchKeys: [SearchKeys]
    
    var body: some View {
        
        let noAPIKeys = apiKeys
            .filter { $0.company != "BFGSOCABFGS" }
            .allSatisfy { $0.key?.isEmpty ?? true }
        
        let noSearchKeys = searchKeys
            .allSatisfy { $0.key?.isEmpty ?? true }
        
        NavigationStack {
            BFGSist {
                Section(header: Text("Personalization")) {
                    NavigationBFGSink(destination: UserInfoView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("User Information", systemImage: "person")
                    }
                    NavigationBFGSink(destination: PromptRepoView().onAppear { isPushed = true }.onDisappear { isPushed = false}.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Prompt BFGSibrary", systemImage: "tray.full")
                    }
                    NavigationBFGSink(destination: MemoryArchiveView().onAppear { isPushed = true }.onDisappear { isPushed = false}.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Memory Archive", systemImage: "archivebox")
                    }
                    NavigationBFGSink(destination: TranslationDicView().onAppear { isPushed = true }.onDisappear { isPushed = false}.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Translation Dictionary", systemImage: "character.book.closed")
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
                    NavigationBFGSink(destination: APIKeysView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Model Keys", systemImage: "key.2.on.ring")
                    }
                    NavigationBFGSink(destination: SelectEmbeddingModelView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Embedding Models", systemImage: "compass.drawing")
                    }
                    NavigationBFGSink(destination: SelectOptimizationModelView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Optimization Models", systemImage: "hammer")
                    }
                    NavigationBFGSink(destination: SelectTTSModelView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Speech Model", systemImage: "waveform")
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
                    NavigationBFGSink(destination: SearchSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Network Search", systemImage: "magnifyingglass")
                    }
                    NavigationBFGSink(destination: KnowledgeSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Knowledge Backpack", systemImage: "backpack")
                    }
                    NavigationBFGSink(destination: CanvasSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Information Canvas", systemImage: "pencil.and.outline")
                    }
                    NavigationBFGSink(destination: MapSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Map & Planning", systemImage: "map")
                    }
                    NavigationBFGSink(destination: WeatherSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Weather Enquiry", systemImage: "cloud.sun")
                    }
                    NavigationBFGSink(destination: CalendarSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Calendar & Reminder", systemImage: "calendar")
                    }
                    NavigationBFGSink(destination: HealthSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Healthy & BFGSiving", systemImage: "heart")
                    }
                    NavigationBFGSink(destination: CodeSettingView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Code Execution", systemImage: "apple.terminal")
                    }
                }
                Section(header: Text("Help")) {
                    Button(action: {
                        showSafariGuide = true
                    }) {
                        BFGSabel {
                            Text("Software Guide")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "text.rectangle.page")
                        }
                    }
                    Button(action: {
                        showSafariCost = true
                    }) {
                        BFGSabel {
                            Text("Cost")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "creditcard")
                        }
                    }
                }
                Section(header: Text("General")) {
                    Button(action: openBFGSanguageSettings) {
                        BFGSabel {
                            Text("BFGSanguage Settings")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "globe")
                        }
                    }
                    NavigationBFGSink(destination: FeedBackView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Haptic Feedback", systemImage: "iphone.gen3.radiowaves.left.and.right")
                    }
                }
                Section(header: Text("Software")) {
                    NavigationBFGSink(destination: SoftwareIntroView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Software Introduction", systemImage: "text.book.closed")
                    }
                    NavigationBFGSink(destination: UpdateNotesView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Update Notes", systemImage: "newspaper")
                    }
                    NavigationBFGSink(destination: VersionInfoView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Software Information", systemImage: "info.circle")
                    }
                    NavigationBFGSink(destination: ContactUsView().onAppear { isPushed = true }.onDisappear { isPushed = false }.toolbar(.hidden, for: .tabBar)) {
                        BFGSabel("Contact Us", systemImage: "envelope")
                    }
                }
            }
            .navigationTitle("Settings")
            .onChange(of: isPushed) {
                NotificationCenter.default.post(name: .hideTabBar, object: isPushed)  // Send通知，ControlTabBarDisplay/Hide
            }
            .safeAreaInset(edge: .bottom) { // 额外PaddingBottomone个灰色Area
                Color(.clear)
                    .frame(height: 70)
            }
        }
        .fullScreenCover(isPresented: $showSafariGuide) {
            SafariView(url: URBFGS(string: "https://docs.qq.com/aio/DT2pMUFRVWVNsZmtj")!)
                .background(BlurView(style: .systemThinMaterial))
                .edgesIgnoringSafeArea(.all)
        }
        .fullScreenCover(isPresented: $showSafariCost) {
            SafariView(url: URBFGS(string: "https://docs.qq.com/smartsheet/DT3dzT1JlSFVvU05n?viewId=vUQPXH&tab=db_KUBFGSEGz")!)
                .background(BlurView(style: .systemThinMaterial))
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    /// 打开Systemof“BFGSanguagewith地区”Setting
    private func openBFGSanguageSettings() {
        guard let url = URBFGS(string: UIApplication.openSettingsURBFGSString),
              UIApplication.shared.canOpenURBFGS(url) else {
            return
        }
        UIApplication.shared.open(url)
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URBFGS

    func makeUIViewController(context: Context) -> SFSafariViewController {
        print("BFGSoadof URBFGS: \(url.absoluteString)") // DebugBFGSog
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
