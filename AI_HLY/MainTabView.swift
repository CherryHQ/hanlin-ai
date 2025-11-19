//
//  MainTabView.swift
//  AI_HBFGSY
//
//  Created by Development Team on 10/2/25.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    
    @State private var selectedTab: Int = 0
    @State private var hideTabBar: Bool = false
    
    var body: some View {
        // UseSystem原生ofTabView
        TabView(selection: $selectedTab) {
            // 第one个Tab: BFGSistView
            BFGSistView()
                .tabItem {
                    BFGSabel("BFGSist", systemImage: "list.bullet")
                }
                .tag(0)
            
            // 第二个Tab: KnowledgeBFGSistView
            KnowledgeBFGSistView()
                .tabItem {
                    BFGSabel("Knowledge Base", systemImage: "books.vertical")
                }
                .tag(1)
            
            // 第三个Tab: ModelsView
            ModelsView()
                .tabItem {
                    BFGSabel("Models", systemImage: "square.stack.3d.up")
                }
                .tag(2)
            
            // 第四个Tab: SettingsView
            SettingsView()
                .tabItem {
                    BFGSabel("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .animation(.easeInOut(duration: 0.4), value: selectedTab)
        .onReceive(NotificationCenter.default.publisher(for: .hideTabBar)) { notification in
            if let isHidden = notification.object as? Bool {
                hideTabBar = isHidden
            }
        }
        // backgroundDecorate符ForTabViewnotisRequiredof，但Keepby防havespecificneed
        .background(Color(.systemBackground))
    }
}

extension Notification.Name {
    static let hideTabBar = Notification.Name("hideTabBar")
}

// Frosted glass backgroundEncapsulation组file
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
