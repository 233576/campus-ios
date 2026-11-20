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
/// 与系统 TabBar 的区别：左右留边、底部留边、四角 28 圆角，内容从它下方滚过。
///
/// 版本要求里明确禁掉的三件事，这里一件都没做：
/// 不加 `.shadow`（离屏渲染，会拖慢列表）、不加 `.blur`、不用不透明纯色底
/// （那样内容透不出来，就没有悬空感）。
struct FloatingTabBar<Tab: Hashable>: View {
    var items: [FloatingTabItem<Tab>]
    @Binding var selection: Tab

    private let barHeight: CGFloat = 56
    private let cornerRadius: CGFloat = 28

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                button(item)
            }
        }
        .frame(height: barHeight)
        .background { surface }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .padding(.top, Spacing.xs)
    }

    private func button(_ item: FloatingTabItem<Tab>) -> some View {
        let selected = item.tab == selection

        return Button {
            guard !selected else { return }
            selection = item.tab
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } label: {
            HStack(spacing: Spacing.xs) {
                Image(systemName: item.symbol)
                    .font(Typography.subheadline.weight(.semibold))
                Text(item.title)
                    .font(Typography.footnote.weight(.semibold))
            }
            .foregroundStyle(selected ? Color.appBrand : Color.secondary)
            .frame(maxWidth: .infinity)
            .frame(height: barHeight - Spacing.s * 2)
            .background {
                if selected {
                    Capsule(style: .continuous)
                        .fill(Color.appBrand.opacity(0.14))
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    /// 容器材质。Tab 项本身不带任何背景 —— 玻璃只能有一层。
    @ViewBuilder
    private var surface: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

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

/// 底栏高度 + 留白，页面在需要自己预留空间时引用同一个值。
enum FloatingTabBarMetrics {
    static let barHeight: CGFloat = 56
    static let horizontalInset: CGFloat = 16
    static let bottomInset: CGFloat = 12
    static let totalHeight: CGFloat = barHeight + bottomInset + 4
}
