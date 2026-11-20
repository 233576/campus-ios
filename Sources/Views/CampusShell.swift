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

    private let barHeight: CGFloat = 46

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
        HStack(spacing: 2) {
            ForEach(CampusSection.allCases) { item in
                let selected = section == item
                Button {
                    select(item)
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(height: 18)
                        Text(item.title)
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(selected ? Flat.accent : Flat.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Flat.accent.opacity(0.12))
                                .matchedGeometryEffect(id: "sectionIndicator", in: indicator)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(CampusTabButtonStyle())
            }
        }
        .padding(.horizontal, 4)
        .frame(height: barHeight - 8)
        .liquidGlass(radius: (barHeight - 8) / 2, strength: 16, edgeWidth: 14)
        .padding(.horizontal, 52)
        .padding(.bottom, 6)
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
