import SwiftUI

/// 校园网模块内部的三个视图：主页 / 日志 / 设置。
enum CampusNetTab: String, CaseIterable, Identifiable {
    case home
    case logs
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "主页"
        case .logs: return "日志"
        case .settings: return "设置"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "bolt.horizontal.fill"
        case .logs: return "text.alignleft"
        case .settings: return "gearshape.fill"
        }
    }
}

/// 校园网模块外壳。底部导航归 `CampusShell`，模块内用顶部分段切换。
struct CampusNetShell: View {
    @EnvironmentObject private var store: CampusNetStore
    @State private var tab: CampusNetTab = .home

    var body: some View {
        VStack(spacing: 0) {
            segmentBar
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            await store.autoDetectOnLaunch()
        }
    }

    private var content: some View {
        Group {
            switch tab {
            case .home: CampusNetHomeView()
            case .logs: CampusNetLogView()
            case .settings: CampusNetSettingsView()
            }
        }
        .transition(.opacity)
    }

    private var segmentBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CampusNetTab.allCases) { item in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 1.0)) {
                            tab = item
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: item.symbol)
                                .font(.system(size: 12, weight: .semibold))
                            Text(item.title)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .foregroundStyle(tab == item ? Flat.accent : Flat.textSecondary)
                        .flatPill(selected: tab == item, tint: Flat.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}
