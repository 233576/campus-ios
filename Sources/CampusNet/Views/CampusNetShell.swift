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
        HStack(spacing: 0) {
            ForEach(CampusNetTab.allCases) { item in
                segmentButton(item)
            }
        }
        .padding(2)
        .frame(height: 34)
        .background(GlassPalette.surfaceHigh)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func segmentButton(_ item: CampusNetTab) -> some View {
        let selected = tab == item
        return Button {
            guard tab != item else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                tab = item
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: item.symbol)
                    .font(.system(size: 12, weight: .medium))
                Text(item.title)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
            }
            .foregroundStyle(selected ? GlassPalette.textPrimary : GlassPalette.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(GlassPalette.surface)
                        .shadow(color: Color.black.opacity(0.10), radius: 3, x: 0, y: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
