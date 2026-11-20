import SwiftUI

/// 相邻玻璃控件的融合容器。
///
/// 只有需要「互相吸到一起」的浮动控件（工具栏按钮组、底部按钮 + 徽标）
/// 才该包一层；单个按钮不需要。iOS 26 以下直接透传。
struct GlassContainer<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: () -> Content

    init(spacing: CGFloat = Spacing.m, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content() }
        } else {
            content()
        }
        #else
        content()
        #endif
    }
}
