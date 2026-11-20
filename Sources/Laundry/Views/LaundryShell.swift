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
/// 底部导航归 `CampusShell`，模块内用顶部玻璃分段：四段均分宽度。
/// 不用横向 ScrollView —— 那样每段宽度按文字长短，滚动手势还会吃掉点击。
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
        HStack(spacing: 2) {
            ForEach(LaundryTab.allCases) { item in
                let selected = tab == item
                Button {
                    guard tab != item else { return }
                    // 只改目标值：动画从当前呈现值接上，连点也不会跳。
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
                                .matchedGeometryEffect(id: "laundrySegment", in: segment)
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
