import SwiftUI

/// 洗衣模块内部的四个视图：洗衣 / 订单 / 日志 / 设置。
enum LaundryTab: String, CaseIterable, Identifiable {
    case laundry
    case orders
    case logs
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .laundry: return "洗衣"
        case .orders: return "订单"
        case .logs: return "日志"
        case .settings: return "设置"
        }
    }

    var symbol: String {
        switch self {
        case .laundry: return "washer.fill"
        case .orders: return "list.bullet.rectangle.portrait.fill"
        case .logs: return "text.alignleft"
        case .settings: return "gearshape.fill"
        }
    }
}

/// 洗衣模块外壳。
///
/// 底部导航归 `CampusShell`，模块内用顶部液态玻璃分段：四段均分宽度。
/// 不用横向 ScrollView —— 那样每段宽度按文字长短，滚动手势还会吃掉点击。
struct LaundryShell: View {
    @EnvironmentObject private var store: LaundryStore
    @State private var tab: LaundryTab = .laundry
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
        .onAppear {
            // 洗涤倒计时：每秒重算剩余时间，退到后台就停，回到前台接着走。
            store.startClock()
        }
        .onDisappear {
            store.stopClock()
        }
    }

    private var content: some View {
        Group {
            switch tab {
            case .laundry: LaundryView()
            case .orders: OrdersView()
            case .logs: LaundryLogView()
            case .settings: LaundrySettingsView()
            }
        }
        .transition(.opacity)
    }

    private var segmentBar: some View {
        HStack(spacing: 0) {
            ForEach(LaundryTab.allCases) { item in
                segmentButton(item)
            }
        }
        .padding(2)
        .frame(height: 34)
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func segmentButton(_ item: LaundryTab) -> some View {
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
                        .shadow(color: Color.black.opacity(0.10), radius: 2, x: 0, y: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
