import SwiftUI

/// 统一导航标题：大标题 + 副标题。
///
/// 副标题走 iOS 26 的 `navigationSubtitle`；低版本自动省略，
/// 不自己画一层 overlay —— 那会跟大标题折叠打架。
struct AppNavigation: ViewModifier {
    var title: String
    var subtitle: String?

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.large)
            .modifier(SubtitleIfAvailable(subtitle: subtitle))
    }
}

private struct SubtitleIfAvailable: ViewModifier {
    var subtitle: String?

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), let subtitle {
            content.navigationSubtitle(subtitle)
        } else {
            content
        }
        #else
        content
        #endif
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
