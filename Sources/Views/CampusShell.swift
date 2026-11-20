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

    /// iOS 26 那种悬浮胶囊：一条细长的玻璃，选中项是一小块浅色底，图标在上文字在下。
    private var tabBar: some View {
        HStack(spacing: 2) {
            ForEach(CampusSection.allCases) { item in
                let selected = section == item
                Button {
                    select(item)
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 19, weight: .semibold))
                            .frame(height: 21)
                        Text(item.title)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(selected ? Flat.accent : Flat.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Flat.accent.opacity(0.12))
                                .matchedGeometryEffect(id: "sectionIndicator", in: indicator)
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(CampusTabButtonStyle())
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background {
            GlassCapsuleBacking()
        }
        .overlay {
            Capsule(style: .continuous)
                .strokeBorder(Flat.glassEdge, lineWidth: 0.8)
        }
        .clipShape(Capsule(style: .continuous))
        .shadow(color: Flat.glassShadow, radius: 18, x: 0, y: 8)
        .padding(.horizontal, 40)
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

/// 悬浮胶囊的玻璃背板：材质模糊 + 极薄底 + 顶部光泽。
///
/// 顺序很关键 —— 先材质（折射背后的内容），再压一层几乎透明的底色（把模糊压成磨砂），
/// 最后一道自上而下的白，做出玻璃的厚度。三层都是动态色，暗色下自动减薄。
struct GlassCapsuleBacking: View {
    var body: some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
            Capsule(style: .continuous)
                .fill(Flat.surface.opacity(0.72))
            Capsule(style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Flat.sheenTop.opacity(0.9), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
        }
    }
}
