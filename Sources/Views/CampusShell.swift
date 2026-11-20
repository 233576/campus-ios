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

/// 校园助手主壳：内容区 + 悬浮底部胶囊（洗衣 / 校园网）。
///
/// 切换规则：
/// - 只有访问过的板块才会被实例化，之后一直留在视图树里（滚动位置、输入框都保住）。
/// - 切换时旧板块立刻淡出、新板块淡入，两边都从当前呈现值开始，连点也接得上。
/// - 选中胶囊用 `matchedGeometryEffect` 滑动，指示器跟着指头走，不重新布局。
struct CampusShell: View {
    @EnvironmentObject private var laundry: LaundryStore
    @EnvironmentObject private var campusNet: CampusNetStore

    @State private var section: CampusSection = .laundry
    @State private var visited: Set<CampusSection> = [.laundry]
    @Namespace private var indicator

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
        withAnimation(.spring(response: 0.34, dampingFraction: 1.0)) {
            section = target
        }
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(CampusSection.allCases) { item in
                Button {
                    select(item)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 15, weight: .semibold))
                        Text(item.title)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(section == item ? Flat.textPrimary : Flat.textTertiary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background {
                        if section == item {
                            Capsule(style: .continuous)
                                .fill(Flat.accent.opacity(0.20))
                                .overlay(
                                    Capsule(style: .continuous)
                                        .strokeBorder(Flat.accent.opacity(0.55), lineWidth: 1)
                                )
                                .matchedGeometryEffect(id: "sectionIndicator", in: indicator)
                        }
                    }
                    .contentShape(Capsule(style: .continuous))
                }
                .buttonStyle(CampusTabButtonStyle())
            }
        }
        .padding(6)
        .background {
            // 底部导航本身就是一块玻璃：模糊 + 白薄涂 + 顶部镜面高光
            ZStack {
                Capsule(style: .continuous).fill(.ultraThinMaterial)
                Capsule(style: .continuous).fill(Color.white.opacity(0.55))
            }
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Flat.specular, lineWidth: 1)
        }
        .clipShape(Capsule(style: .continuous))
        .shadow(color: Flat.glassShadow, radius: 22, x: 0, y: 12)
        .padding(.bottom, 6)
    }
}

/// 按下就缩，松手回弹；不延迟到点击完成才给反馈。
private struct CampusTabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.9), value: configuration.isPressed)
    }
}
