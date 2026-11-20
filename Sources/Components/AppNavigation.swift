import SwiftUI

/// 统一导航标题：大标题 + 副标题 + 滚动折叠。
///
/// 用它代替各页面手写的 navigationTitle，保证 7 个 Tab 看起来是一套东西。
struct AppNavigation: ViewModifier {
    var title: String
    var subtitle: String?

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if let subtitle {
                    ToolbarItem(placement: .principal) {
                        EmptyView()
                    }
                    .hidden()
                }
            }
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
