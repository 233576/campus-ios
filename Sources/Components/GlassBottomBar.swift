import SwiftUI

/// 底部固定操作条。
///
/// 全 App 只有这一种底部固定栏实现：`safeAreaInset(edge: .bottom)` + 1px 分隔线 +
/// 向内收的留白。禁止再用 ZStack / overlay / offset 悬浮一个按钮盖在内容上 ——
/// 那样滚动到底永远差一截。
struct GlassBottomBar<Content: View>: View {
    @ViewBuilder var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1 / UIScreen.main.scale)

            content()
                .padding(.horizontal, Spacing.l)
                .padding(.top, Spacing.s)
                .padding(.bottom, Spacing.xs)
        }
        .background(.ultraThinMaterial)
    }
}
