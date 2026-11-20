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
        GlassGroup(spacing: 14) {
            HStack(spacing: 2) {
                ForEach(LaundryTab.allCases) { item in
                    segmentButton(item)
                }
            }
            .padding(4)
            .frame(height: barHeight)
            .liquidGlassSurface(radius: barHeight / 2)
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

    private func segmentButton(_ item: LaundryTab) -> some View {
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
            .foregroundStyle(selected ? Color.white : GlassPalette.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: barHeight - 8)
            .background {
                if selected {
                    let shape = Capsule(style: .continuous)
                    ZStack {
                        shape.fill(
                            LinearGradient(colors: [GlassPalette.accent, GlassPalette.accent.opacity(0.82)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        shape.fill(
                            LinearGradient(colors: [Color.white.opacity(0.32), Color.clear],
                                           startPoint: .top, endPoint: .center)
                        )
                    }
                    .matchedGeometryEffect(id: "laundrySegment", in: segment)
                    .shadow(color: GlassPalette.accent.opacity(0.30), radius: 8, y: 3)
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(PressScaleStyle(scale: 0.95))
    }
}
