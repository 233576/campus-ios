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
/// 底部导航被上级 `CampusShell` 占用（洗衣 / 校园网），所以模块内改用顶部
/// 分段切换。四段均分宽度：不再用横向 ScrollView —— 那样每段宽度按文字长短，
/// 又会被滚动手势吃掉点击。
struct LaundryShell: View {
    @EnvironmentObject private var store: LaundryStore
    @State private var tab: LaundryTab = .laundry
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
        HStack(spacing: 4) {
            ForEach(LaundryTab.allCases) { item in
                let selected = tab == item
                Button {
                    guard tab != item else { return }
                    // 只改目标值：动画从当前呈现值接上，连点也不会跳。
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
                                .matchedGeometryEffect(id: "laundrySegment", in: segment)
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
