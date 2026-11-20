import SwiftUI
import UIKit

/// 一个 Tab 项。
struct FloatingTabItem<Tab: Hashable>: Identifiable {
    var tab: Tab
    var title: String
    var symbol: String

    var id: Tab { tab }
}

/// 悬空胶囊底栏。
///
/// 材质只有一层：iOS 26 用 `.glassEffect(.regular.interactive(), …)`，交互形变与
/// 边缘折射都由系统玻璃产生；玻璃上方不叠任何 `Color` / `.ultraThinMaterial`，
/// 叠上去就等于把玻璃盖死，暗色下会变成一块深灰板。
///
/// 悬空感靠三件事，不靠投影：左右 20 / 底部 8 的留边、26 圆角、内容从下方透出。
struct FloatingTabBar<Tab: Hashable>: View {
    var items: [FloatingTabItem<Tab>]
    @Binding var selection: Tab

    @Environment(\.colorScheme) private var colorScheme

    /// 选中态小胶囊的内边距 —— 紧贴内容，不铺满半条底栏。
    private let chipHorizontal: CGFloat = 14
    private let chipVertical: CGFloat = 6

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                button(item)
            }
        }
        .frame(height: FloatingTabBarMetrics.barHeight)
        .background { surface }
        .overlay { edgeHighlight }
        .padding(.horizontal, FloatingTabBarMetrics.horizontalInset)
        .padding(.bottom, FloatingTabBarMetrics.bottomInset)
        .animation(.spring(response: 0.4, dampingFraction: 0.65, blendDuration: 0.3),
                   value: selection)
    }

    private func button(_ item: FloatingTabItem<Tab>) -> some View {
        let selected = item.tab == selection

        return Button {
            guard !selected else { return }
            selection = item.tab
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: item.symbol)
                    .font(Typography.title2)
                    .symbolEffect(.bounce, value: selected)
                Text(item.title)
                    .font(Typography.caption2)
            }
            .foregroundStyle(selected ? Color.appBrand : Color(uiColor: .secondaryLabel))
            .padding(.horizontal, chipHorizontal)
            .padding(.vertical, chipVertical)
            .background {
                if selected {
                    Capsule(style: .continuous)
                        .fill(Color(uiColor: .tertiarySystemFill))
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(TabPressStyle())
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    /// 容器材质：只有玻璃一层，低版本才退到毛玻璃。
    @ViewBuilder
    private var surface: some View {
        let shape = RoundedRectangle(cornerRadius: FloatingTabBarMetrics.cornerRadius,
                                     style: .continuous)

        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular.interactive(), in: shape)
        } else {
            fallback(shape: shape)
        }
        #else
        fallback(shape: shape)
        #endif
    }

    private func fallback(shape: RoundedRectangle) -> some View {
        shape.fill(.ultraThinMaterial)
    }

    /// 0.5pt 内描边 —— 暗色下玻璃「立起来」的主要视觉线索。
    private var edgeHighlight: some View {
        RoundedRectangle(cornerRadius: FloatingTabBarMetrics.cornerRadius, style: .continuous)
            .strokeBorder(colorScheme == .dark
                          ? Color.white.opacity(0.08)
                          : Color.black.opacity(0.06),
                          lineWidth: 0.5)
    }
}

/// Tab 项的按压回弹。这是「Q 弹」手感的主要来源。
struct TabPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}

/// 底栏高度 + 留白，页面在需要自己预留空间时引用同一组值。
enum FloatingTabBarMetrics {
    static let barHeight: CGFloat = 52
    static let cornerRadius: CGFloat = 26
    static let horizontalInset: CGFloat = 20
    static let bottomInset: CGFloat = 8
    static let totalHeight: CGFloat = barHeight + bottomInset
}
