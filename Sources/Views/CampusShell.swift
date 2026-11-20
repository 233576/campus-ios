import SwiftUI

/// 顶层两个板块。
enum CampusSection: String, CaseIterable, Identifiable {
    case laundry
    case campusNet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .laundry: return "洗衣"
        case .campusNet: return "校园网"
        }
    }

    var symbol: String {
        switch self {
        case .laundry: return "washer.fill"
        case .campusNet: return "wifi"
        }
    }
}

/// 校园助手主壳：内容区 + 标准底部 TabBar。
///
/// 底栏走 `safeAreaInset`，内容自动避让，不再需要每个页面手写底部留白。
/// 选中态只改颜色，不做滑动指示块 —— iOS 原生 TabBar 就是这样，
/// 也顺带避免了切换后命中区域错位的问题。
struct CampusShell: View {
    @EnvironmentObject private var laundry: LaundryStore
    @EnvironmentObject private var campusNet: CampusNetStore

    @State private var section: CampusSection = .laundry
    @State private var visited: Set<CampusSection> = [.laundry]

    var body: some View {
        content
            .safeAreaInset(edge: .bottom, spacing: 0) { tabBar }
            .background(GlassPalette.background)
    }

    private var content: some View {
        ZStack {
            if visited.contains(.laundry) {
                LaundryShell()
                    .opacity(section == .laundry ? 1 : 0)
                    .allowsHitTesting(section == .laundry)
                    .accessibilityHidden(section != .laundry)
            }
            if visited.contains(.campusNet) {
                CampusNetShell()
                    .opacity(section == .campusNet ? 1 : 0)
                    .allowsHitTesting(section == .campusNet)
                    .accessibilityHidden(section != .campusNet)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func select(_ target: CampusSection) {
        guard target != section else { return }
        visited.insert(target)
        withAnimation(.easeInOut(duration: 0.18)) {
            section = target
        }
    }

    private var tabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(CampusSection.allCases) { item in
                    tabButton(item)
                }
            }
            .frame(height: 48)
            .padding(.top, 4)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.30))
                .frame(height: 0.5)
        }
    }

    private func tabButton(_ item: CampusSection) -> some View {
        let selected = section == item
        return Button {
            select(item)
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.symbol)
                    .font(.system(size: 21, weight: selected ? .semibold : .regular))
                    .frame(height: 24)
                Text(item.title)
                    .font(.system(size: 10, weight: selected ? .semibold : .medium))
            }
            .foregroundStyle(selected ? GlassPalette.accent : GlassPalette.textSecondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
