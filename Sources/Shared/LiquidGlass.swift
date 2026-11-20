import SwiftUI

/// 液态玻璃底座（Metal 版）。
///
/// 结构分三层：
/// 1. `.ultraThinMaterial` —— 系统提供的真实背景模糊（backdrop）
/// 2. 极薄的动态底色 + 可选色调 —— 把模糊压成磨砂，暗色模式下自动减薄
/// 3. `layerEffect(liquidGlass)` —— 按圆角 SDF 把边缘像素往中心折射，再补贴边高光和色散
///
/// 第 3 层的算法直接照搬 `xiaofangstudio/liquid-glass-web`：
/// 算 `roundedRectSDF` → `smoothStep(0, edgeWidth, inside)` → 沿法线偏移采样点。
struct LiquidGlassCapsule: ViewModifier {
    var radius: CGFloat
    var strength: CGFloat = 18
    var edgeWidth: CGFloat = 16
    var tint: Color?
    var opacity: Double = 0.55

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { proxy in
                    let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
                    ZStack {
                        shape.fill(.ultraThinMaterial)
                        shape.fill(Flat.surface.opacity(opacity / 0.55))
                        if let tint {
                            shape.fill(tint.opacity(0.10))
                        }
                    }
                    .layerEffect(
                        ShaderLibrary.liquidGlass(
                            .float2(proxy.size),
                            .float(radius),
                            .float(strength),
                            .float(edgeWidth)
                        ),
                        maxSampleOffset: CGSize(width: strength * 1.4, height: strength * 1.4)
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                // 外圈那一道几乎看不见的镜面边
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Flat.glassEdge, lineWidth: 0.8)
            }
            .shadow(color: Flat.glassShadow, radius: 16, x: 0, y: 8)
    }
}

extension View {
    /// 液态玻璃胶囊（pill）。`radius` 传高度的一半就是完整胶囊。
    func liquidGlass(radius: CGFloat,
                     strength: CGFloat = 18,
                     edgeWidth: CGFloat = 16,
                     tint: Color? = nil,
                     opacity: Double = 0.55) -> some View {
        modifier(LiquidGlassCapsule(radius: radius,
                                    strength: strength,
                                    edgeWidth: edgeWidth,
                                    tint: tint,
                                    opacity: opacity))
    }
}
