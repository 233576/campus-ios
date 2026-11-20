import SwiftUI

/// 统一导航标题：大标题 + 副标题，随滚动折叠为 inline。
///
/// iOS 26 直接用系统的 `.navigationSubtitle`（跟随滚动一起淡出）；
/// 低版本没有这个 API，退回到标题下方的一行小字（不参与滚动）。
struct AppNavigation: ViewModifier {
    var title: String
    var subtitle: String?

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), let subtitle {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.large)
                .navigationSubtitle(subtitle)
        } else {
            legacy(content)
        }
        #else
        legacy(content)
        #endif
    }

    /// iOS 18 没有 `.navigationSubtitle`。这里只渲染标题 —— 不再用 overlay 在
    /// 导航栏区域手工摆一行字，那会和折叠中的大标题、右上角按钮互相穿插。
    private func legacy(_ content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
    }
}

extension View {
    func appNavigation(title: String, subtitle: String? = nil) -> some View {
        modifier(AppNavigation(title: title, subtitle: subtitle))
    }
}

/// 工具栏里的玻璃按钮（复制、清空、刷新等）。
struct GlassToolbarButton: View {
    var symbol: String
    var label: String
    var tint: Color = .appBrand
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(Typography.body)
                .foregroundStyle(tint)
                .frame(width: Spacing.rowMinHeight, height: Spacing.rowMinHeight)
                .glassIconBackground()
        }
        .buttonStyle(TabPressStyle())
        .accessibilityLabel(label)
    }
}

/// 工具栏里的导航按钮：和 `GlassToolbarButton` 一样大，但走 NavigationLink。
struct GlassToolbarLink<Destination: Hashable>: View {
    var symbol: String
    var label: String
    var tint: Color = .appBrand
    var value: Destination

    var body: some View {
        NavigationLink(value: value) {
            Image(systemName: symbol)
                .font(Typography.body)
                .foregroundStyle(tint)
                .frame(width: Spacing.rowMinHeight, height: Spacing.rowMinHeight)
                .glassIconBackground()
        }
        .buttonStyle(TabPressStyle())
        .accessibilityLabel(label)
    }
}

/// 工具栏图标的独立玻璃底：圆形玻璃 + 0.5pt 内描边。
///
/// 系统默认会把相邻 toolbar 按钮合并成一条共享背景，那样两个图标会被裹进一个
/// 胶囊、左边留一大片空白，所以调用方会用 `sharedBackgroundVisibility(.hidden)`
/// 关掉共享背景，再由这里各画各的。
struct GlassIconBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background { surface }
            .overlay {
                Circle()
                    .strokeBorder(colorScheme == .dark
                                  ? Color.white.opacity(0.08)
                                  : Color.black.opacity(0.06),
                                  lineWidth: 0.5)
            }
    }

    @ViewBuilder
    private var surface: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular.interactive(), in: Circle())
        } else {
            Circle().fill(.ultraThinMaterial)
        }
        #else
        Circle().fill(.ultraThinMaterial)
        #endif
    }
}

extension View {
    func glassIconBackground() -> some View {
        modifier(GlassIconBackground())
    }
}
