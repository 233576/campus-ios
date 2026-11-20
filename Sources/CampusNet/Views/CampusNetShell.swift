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

/// 校园网模块外壳。底部导航归 `CampusShell`，模块内用顶部液态玻璃分段（均分宽度）。
struct CampusNetShell: View {
    @EnvironmentObject private var store: CampusNetStore
    @State private var tab: CampusNetTab = .home
    @Namespace private var segment

    private let barHeight: CGFloat = 44

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
        GlassGroup(spacing: 14) {
            HStack(spacing: 2) {
                ForEach(CampusNetTab.allCases) { item in
                    segmentButton(item)
                }
            }
            .padding(4)
            .frame(height: barHeight)
            .liquidGlassSurface(radius: barHeight / 2, tintOpacity: 0.04)
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(GlassPalette.edge.opacity(0.55), lineWidth: 0.8)
            }
            .shadow(color: GlassPalette.shadow, radius: 14, x: 0, y: 8)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private func segmentButton(_ item: CampusNetTab) -> some View {
        let selected = tab == item
        return Button {
            guard tab != item else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
                tab = item
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: item.symbol)
                    .font(.system(size: 13, weight: .semibold))
                Text(item.title)
                    .font(.system(size: 12.5, weight: .semibold))
            }
            .foregroundStyle(selected ? GlassPalette.accent : GlassPalette.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: barHeight - 8)
            .background {
                if selected {
                    Capsule(style: .continuous)
                        .fill(Color.dyn(light: 0xFFFFFF, dark: 0xFFFFFF, lightAlpha: 0.52, darkAlpha: 0.13))
                        .matchedGeometryEffect(id: "campusNetSegment", in: segment)
                        .shadow(color: GlassPalette.shadow.opacity(0.6), radius: 5, y: 2)
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(PressScaleStyle(scale: 0.95))
    }
}
