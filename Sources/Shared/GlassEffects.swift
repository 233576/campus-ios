import SwiftUI

/// 统一的「面」。
///
/// 走到这一版，界面按 iOS 原生规矩来：**不再有任何毛玻璃**。
/// 卡片就是纯色面 + 一条 1px 边，靠留白和分隔线区分层级，
/// 而不是靠模糊、发光和阴影。
///
/// 保留这个名字是为了让几十处调用点不用改：语义从「玻璃」变成「面」，
/// 形状和圆角照旧。
extension View {
    @ViewBuilder
    func liquidGlassSurface(radius: CGFloat,
                            tint: Color? = nil,
                            interactive: Bool = false,
                            tintOpacity: Double = 0.28) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        self
            .background { shape.fill(tint.map { GlassPalette.surface } ?? GlassPalette.surface) }
            .overlay { shape.strokeBorder(GlassPalette.separator, lineWidth: 0.5) }
            .clipShape(shape)
    }

    func legacyGlass(radius: CGFloat, tint: Color?) -> some View {
        liquidGlassSurface(radius: radius, tint: tint)
    }
}

/// 以前用来把相邻玻璃归组做液体融合，现在没有玻璃了，直接透传。
struct GlassGroup<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: () -> Content

    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        content()
    }
}

struct LegacyGlass: ViewModifier {
    var radius: CGFloat
    var tint: Color?

    func body(content: Content) -> some View {
        content.liquidGlassSurface(radius: radius, tint: tint)
    }
}
