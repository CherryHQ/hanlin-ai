//
//  MainTabView.swift
//  AI_HLY
//
//  Created by 哆啦好多梦 on 10/2/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    
    @Binding var deepLinkTarget: String?
    @State private var selectedTab: Int = 0
    @State private var hideTabBar: Bool = false
    
    var body: some View {
        // 使用系统原生的TabView
        TabView(selection: $selectedTab) {
            // 第一个Tab: ListView
            ListView()
                .tabItem {
                    Label("列表", systemImage: "list.bullet")
                }
                .tag(0)
            
            // 第二个Tab: VisionView
            VisionView(selectedTab: $selectedTab)
                .toolbar(.hidden, for: .tabBar)
                .tabItem {
                    Label("视觉", systemImage: "eye")
                }
                .tag(1)
            
            // 第三个Tab: KnowledgeListView
            KnowledgeListView()
                .tabItem {
                    Label("知识库", systemImage: "books.vertical")
                }
                .tag(2)
            
            // 第四个Tab: ModelsView
            ModelsView()
                .tabItem {
                    Label("模型", systemImage: "square.stack.3d.up")
                }
                .tag(3)
            
            // 第五个Tab: SettingsView
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(4)
        }
        .animation(.easeInOut(duration: 0.4), value: selectedTab)
        .onReceive(NotificationCenter.default.publisher(for: .hideTabBar)) { notification in
            if let isHidden = notification.object as? Bool {
                hideTabBar = isHidden
            }
        }
        .onChange(of: deepLinkTarget) {
            if deepLinkTarget == "vision" {
                selectedTab = 1
                deepLinkTarget = nil // 清除状态，避免重复跳转
            }
        }
        // background修饰符对于TabView不是必需的，但保留以防有特定需要
        .background(Color(.systemBackground))
    }
}

extension Notification.Name {
    static let openVisionView = Notification.Name("openVisionView")
    static let hideTabBar = Notification.Name("hideTabBar")
}

// 毛玻璃背景封装组件
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

// Custom glass effect view that works on earlier iOS versions
struct GlassView: View {
    let style: UIBlurEffect.Style
    
    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                Rectangle()
                    .fill(Color.clear)
                    .glassEffect(in: .rect(cornerRadius: 26))
            } else {
                // Fallback implementation for earlier iOS versions
                BlurView(style: style)
            }
        }
        .allowsHitTesting(false)
    }
}
