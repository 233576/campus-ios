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
/// - 选中块用 `matchedGeometryEffect` 滑动，指示器跟着指头走，不重新布局。
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
        withAnimation(.spring(response: 0.32, dampingFraction: 0.94)) {
            section = target
        }
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(CampusSection.allCases) { item in
                let selected = section == item
                Button {
                    select(item)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(height: 18)
                        Text(item.title)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(selected ? Flat.accent : Flat.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(Flat.accent.opacity(0.15))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .strokeBorder(Flat.accent.opacity(0.45), lineWidth: 1)
                                }
                                .matchedGeometryEffect(id: "sectionIndicator", in: indicator)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(CampusTabButtonStyle())
            }
        }
        .padding(5)
        .background {
            // 玻璃是「模糊 + 极薄的一层白 + 顶部镜面高光」，白薄涂必须跟随外观，
            // 否则暗色模式下就是一整块白板。
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Flat.surfaceHigh)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Flat.specular, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Flat.glassShadow, radius: 20, x: 0, y: 10)
        .padding(.horizontal, 58)
        .padding(.bottom, 8)
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
