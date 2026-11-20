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

    @ViewBuilder
    private func legacy(_ content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .topLeading) {
                if let subtitle {
                    Text(subtitle)
                        .font(Typography.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, Spacing.page)
                        .padding(.top, Spacing.xxl)
                        .allowsHitTesting(false)
                }
            }
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
        }
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
        }
        .accessibilityLabel(label)
    }
}
