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

/// 校园网模块外壳。底部导航归 `CampusShell`，模块内用顶部玻璃分段（均分宽度）。
struct CampusNetShell: View {
    @EnvironmentObject private var store: CampusNetStore
    @State private var tab: CampusNetTab = .home
    @Namespace private var segment

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
        HStack(spacing: 2) {
            ForEach(CampusNetTab.allCases) { item in
                let selected = tab == item
                Button {
                    guard tab != item else { return }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
                        tab = item
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 15, weight: .semibold))
                            .frame(height: 17)
                        Text(item.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selected ? Flat.accent : Flat.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Flat.accent.opacity(0.12))
                                .matchedGeometryEffect(id: "campusNetSegment", in: segment)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(PressScaleStyle(scale: 0.94))
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
        .background { GlassCapsuleBacking() }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Flat.glassEdge, lineWidth: 0.8)
        }
        .clipShape(Capsule(style: .continuous))
        .shadow(color: Flat.glassShadow.opacity(0.9), radius: 14, x: 0, y: 6)
        .padding(.horizontal, 22)
        .padding(.top, 2)
        .padding(.bottom, 8)
    }
}
