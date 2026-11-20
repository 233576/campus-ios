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

/// 校园助手主壳：内容区 + 悬浮底部液态玻璃胶囊（洗衣 / 校园网）。
///
/// 切换规则：
/// - 只有访问过的板块才会被实例化，之后一直留在视图树里（滚动位置、输入框都保住）。
/// - 切换时旧板块立刻淡出、新板块淡入，两边都从当前呈现值开始，连点也接得上。
/// - 选中块用 `matchedGeometryEffect` 滑动，指示器跟着指头走，不重新布局。
struct CampusShell: View {
    @EnvironmentObject private var laundry: LaundryStore
    @EnvironmentObject private var campusNet: CampusNetStore

    @State private var section: CampusSection = .laundry
    @State private var visited: Set<CampusSection> = [.laundry]
    @Namespace private var indicator

    private let barHeight: CGFloat = 52

    var body: some View {
        ZStack(alignment: .bottom) {
            FlatBackground()

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

            tabBar
        }
    }

    private func select(_ target: CampusSection) {
        guard target != section else { return }
        visited.insert(target)
        withAnimation(.spring(response: 0.32, dampingFraction: 0.94)) {
            section = target
        }
    }

    private var tabBar: some View {
        GlassGroup(spacing: 20) {
            HStack(spacing: 2) {
                ForEach(CampusSection.allCases) { item in
                    tabButton(item)
                }
            }
            .padding(5)
            .frame(height: barHeight)
            .liquidGlassSurface(radius: barHeight / 2, tintOpacity: 0.04)
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(GlassPalette.edge.opacity(0.55), lineWidth: 0.8)
            }
            .shadow(color: GlassPalette.shadow, radius: 22, x: 0, y: 12)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 8)
    }

    private func tabButton(_ item: CampusSection) -> some View {
        let selected = section == item
        return Button {
            select(item)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: item.symbol)
                    .font(.system(size: 17, weight: .semibold))
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(selected ? GlassPalette.accent : GlassPalette.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: barHeight - 10)
            .background {
                if selected {
                    Capsule(style: .continuous)
                        .fill(Color.dyn(light: 0xFFFFFF, dark: 0xFFFFFF, lightAlpha: 0.52, darkAlpha: 0.13))
                        .matchedGeometryEffect(id: "sectionIndicator", in: indicator)
                        .shadow(color: GlassPalette.shadow.opacity(0.6), radius: 6, y: 2)
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(CampusTabButtonStyle())
    }
}

/// 按下就缩，松手回弹；不延迟到点击完成才给反馈。
private struct CampusTabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.9), value: configuration.isPressed)
    }
}
