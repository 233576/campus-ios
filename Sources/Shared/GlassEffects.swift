import SwiftUI

/// 液态玻璃的统一入口。
///
/// iOS 26 直接走系统原生的 `.glassEffect(_:in:)` —— 它带实时的背景折射、边缘高光和
/// 触摸响应，效果和 Apple 自家控件一致，没有任何手写近似能比。
/// 更早的系统（iOS 17–25）退回「材质 + 极薄白 + 细边」，保持同样的层级观感。
///
/// 用 `#if compiler(>=6.2)` 包住调用：Xcode 26 才认识 `.glassEffect`，
/// 老工具链编译时这段会被整块剔除，不会因为找不到符号而失败。
extension View {
    @ViewBuilder
    func liquidGlassSurface(radius: CGFloat,
                            tint: Color? = nil,
                            interactive: Bool = false) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            let glass: Glass = {
                var base: Glass = .regular
                if let tint { base = base.tint(tint.opacity(0.35)) }
                return interactive ? base.interactive() : base
            }()
            self.glassEffect(
                glass,
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
        } else {
            legacyGlass(radius: radius, tint: tint)
        }
        #else
        legacyGlass(radius: radius, tint: tint)
        #endif
    }

    /// 老系统上的玻璃：系统材质负责模糊，极薄的一层白负责"磨砂"，细边负责厚度。
    func legacyGlass(radius: CGFloat, tint: Color?) -> some View {
        modifier(LegacyGlass(radius: radius, tint: tint))
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
