import SwiftUI

enum StoreSection: String, CaseIterable, Identifiable {
    case laundry
    case net

    var id: String { rawValue }

    var title: String {
        switch self {
        case .laundry: return "洗衣"
        case .net: return "校园网"
        }
    }

    var symbol: String {
        switch self {
        case .laundry: return "washer.fill"
        case .net: return "wifi"
        }
    }
}

/// 两栏外壳：内容全屏铺开，底部一个悬浮玻璃胶囊。
/// 两个页面都保留在视图树里（只切 opacity / allowsHitTesting），
/// 这样来回切换时滚动位置、输入框内容、跑着的计时器都不会丢。
struct StoreShell: View {
    @EnvironmentObject private var laundry: LaundryStore
    @EnvironmentObject private var net: CampusNetStore

    @State private var section: StoreSection = .laundry
    @State private var visited: Set<StoreSection> = [.laundry]
    @Namespace private var indicator

    private let barHeight: CGFloat = 46

    var body: some View {
        ZStack(alignment: .bottom) {
            FlatBackground()

            ForEach(StoreSection.allCases) { item in
                if visited.contains(item) {
                    page(item)
                        .opacity(section == item ? 1 : 0)
                        .allowsHitTesting(section == item)
                        .zIndex(section == item ? 1 : 0)
                }
            }

            tabBar
        }
        .task { await net.autoDetectOnLaunch() }
    }

    @ViewBuilder
    private func page(_ item: StoreSection) -> some View {
        switch item {
        case .laundry:
            LaundryStoreHome()
        case .net:
            CampusNetStoreHome()
        }
    }

    private func select(_ target: StoreSection) {
        guard target != section else { return }
        visited.insert(target)
        withAnimation(.spring(response: 0.34, dampingFraction: 0.92)) {
            section = target
        }
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(StoreSection.allCases) { item in
                let selected = section == item
                Button {
                    select(item)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 15, weight: .semibold))
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(selected ? Flat.accent : Flat.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: barHeight - 10)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: (barHeight - 10) / 2, style: .continuous)
                                .fill(Flat.accent.opacity(0.13))
                                .matchedGeometryEffect(id: "storeIndicator", in: indicator)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: (barHeight - 10) / 2, style: .continuous))
                }
                .buttonStyle(PressScaleStyle(scale: 0.95))
            }
        }
        .padding(.horizontal, 5)
        .frame(height: barHeight)
        .liquidGlassSurface(radius: barHeight / 2, interactive: true)
        .padding(.horizontal, 24)
        .padding(.bottom, 6)
    }
}
