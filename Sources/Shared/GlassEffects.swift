import SwiftUI

/// 液态玻璃的统一入口。
///
/// iOS 26 直接走系统原生的 `.glassEffect(_:in:)`：它带实时的背景折射、边缘高光和
/// 触摸形变。**不要在它上面盖任何半透明底色** —— 一旦叠了色，折射就被盖掉，
/// 玻璃退化成一块塑料板。想要更实一点，只调 `Glass.tint`，别加 background。
///
/// 更早的系统（iOS 17–25）退回「材质 + 细边」，保持同样的层级观感。
/// 用 `#if compiler(>=6.2)` 包住调用：Xcode 26 才认识 `.glassEffect`，
/// 老工具链编译时这段整块剔除，不会因为找不到符号而失败。
extension View {
    @ViewBuilder
    func liquidGlassSurface(radius: CGFloat,
                            tint: Color? = nil,
                            interactive: Bool = false,
                            tintOpacity: Double = 0.28) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            let glass: Glass = {
                var base: Glass = .regular
                if let tint { base = base.tint(tint.opacity(tintOpacity)) }
                return interactive ? base.interactive() : base
            }()
            self.glassEffect(glass, in: shape)
        } else {
            legacyGlass(radius: radius, tint: tint)
        }
        #else
        legacyGlass(radius: radius, tint: tint)
        #endif
    }

    /// 老系统上的玻璃：系统材质负责模糊，细边负责厚度。
    func legacyGlass(radius: CGFloat, tint: Color?) -> some View {
        modifier(LegacyGlass(radius: radius, tint: tint))
    }
}

/// 把相邻的玻璃包在一起，让它们共用一张背景采样、边缘能自然融合。
/// 单独一块玻璃看不出效果，两块挨着时才像真的液态玻璃。
struct GlassGroup<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: () -> Content

    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
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

struct LegacyGlass: ViewModifier {
    var radius: CGFloat
    var tint: Color?

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(Flat.surface)
                    if let tint { shape.fill(tint.opacity(0.10)) }
                }
            }
            .overlay {
                shape.strokeBorder(Flat.glassEdge, lineWidth: 0.8)
            }
            .clipShape(shape)
            .shadow(color: Flat.glassShadow, radius: 14, x: 0, y: 6)
    }
}
