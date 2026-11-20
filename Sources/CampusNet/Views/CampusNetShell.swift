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

/// 校园网模块外壳。底部导航归 `CampusShell`，模块内用顶部分段切换（均分宽度）。
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
        HStack(spacing: 4) {
            ForEach(CampusNetTab.allCases) { item in
                let selected = tab == item
                Button {
                    guard tab != item else { return }
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
                        tab = item
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 11, weight: .semibold))
                        Text(item.title)
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    .foregroundStyle(selected ? Flat.accent : Flat.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if selected {
                            Capsule(style: .continuous)
                                .fill(Flat.accent.opacity(0.15))
                                .overlay {
                                    Capsule(style: .continuous)
                                        .strokeBorder(Flat.accent.opacity(0.45), lineWidth: 1)
                                }
                                .matchedGeometryEffect(id: "campusNetSegment", in: segment)
                        }
                    }
                    .contentShape(Capsule(style: .continuous))
                }
                .buttonStyle(PressScaleStyle(scale: 0.95))
            }
        }
        .padding(4)
        .background {
            ZStack {
                Capsule(style: .continuous).fill(.ultraThinMaterial)
                Capsule(style: .continuous).fill(Flat.surfaceHigh)
            }
        }
        .overlay {
            Capsule(style: .continuous).strokeBorder(Flat.stroke, lineWidth: 1)
        }
        .clipShape(Capsule(style: .continuous))
        .shadow(color: Flat.glassShadow.opacity(0.8), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }
}
