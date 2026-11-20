import SwiftUI

/// 统一列表容器：insetGrouped + 透明滚动背景 + 分组底色。
///
/// 所有页面内容都用它，禁止再出现「带边框圆角的大卡片包 Section」。
struct AppList<Content: View>: View {
    @ViewBuilder var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        List {
            content()
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appGroupedBackground)
        .scrollIndicators(.hidden)
        // 悬空 TabBar 用 safeAreaInset 避让，但滚到底时最后一行仍要能和底栏拉开距离，
        // 否则「连接日志」这类末行会贴着胶囊下沿。
        .contentMargins(.bottom, 88, for: .scrollContent)
    }
}

/// 图标圆底：36×36，语义灰填充。禁止品牌色实心底。
struct AppIconCircle: View {
    var symbol: String
    var tint: Color = .appBrand
    var size: CGFloat = Spacing.iconCircle

    var body: some View {
        ZStack {
            Circle().fill(Color.appTertiaryFill)
            Image(systemName: symbol)
                .font(Typography.subheadline.weight(.semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }
}

/// 列表行右侧箭头。
struct AppChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(Typography.caption.weight(.semibold))
            .foregroundStyle(Color(uiColor: .tertiaryLabel))
    }
}
