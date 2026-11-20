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
/// 与系统 TabBar 的区别：左右留边、底部留边、26 圆角，内容从它下方滚过。
///
/// 版本要求里明确禁掉的三件事，这里一件都没做：不加 `.shadow`（离屏渲染）、
/// 不加 `.blur`、不用不透明纯色底（那样内容透不出来，就没有悬空感）。
struct FloatingTabBar<Tab: Hashable>: View {
    var items: [FloatingTabItem<Tab>]
    @Binding var selection: Tab

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
        .padding(.horizontal, FloatingTabBarMetrics.horizontalInset)
        .padding(.bottom, FloatingTabBarMetrics.bottomInset)
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
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    /// 容器材质。Tab 项本身不带任何玻璃 —— 玻璃只能有一层。
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
        shape
            .fill(.ultraThinMaterial)
            .overlay {
                shape.strokeBorder(Color.appSeparator, lineWidth: 1)
            }
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
