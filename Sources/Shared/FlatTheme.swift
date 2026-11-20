import SwiftUI
import UIKit

// MARK: - 色板

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    /// 跟随系统外观。
    static func dyn(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }

    static func dyn(light: UInt32, dark: UInt32,
                    lightAlpha: Double = 1, darkAlpha: Double = 1) -> Color {
        .dyn(light: UIColor(Color(hex: light)).withAlphaComponent(lightAlpha),
             dark: UIColor(Color(hex: dark)).withAlphaComponent(darkAlpha))
    }
}

/// 液态玻璃色板，亮/暗两套值都写在同一个色里，跟随系统。
///
/// 玻璃要看得出「玻璃」，前提是底下有东西可折射：亮色模式靠冷白 + 低饱和光晕，
/// 暗色模式靠近黑 + 更明显的彩色光晕。同名的 `Flat.*` 让所有界面不用改调用点。
enum Flat {
    // MARK: 底色

    static let background = Color.dyn(light: 0xF3F5F8, dark: 0x0B0C10)

    /// 玻璃卡的白色薄涂（暗色下必须是极淡的一层白，压太厚就发灰）。
    static let surface = Color.dyn(
        light: UIColor.white.withAlphaComponent(0.55),
        dark: UIColor.white.withAlphaComponent(0.06)
    )
    static let surfaceHigh = Color.dyn(
        light: UIColor.white.withAlphaComponent(0.72),
        dark: UIColor.white.withAlphaComponent(0.10)
    )
    static let surfaceLow = Color.dyn(
        light: UIColor.white.withAlphaComponent(0.38),
        dark: UIColor.white.withAlphaComponent(0.04)
    )

    // MARK: 玻璃边缘

    static let stroke = Color.dyn(
        light: UIColor.white.withAlphaComponent(0.70),
        dark: UIColor.white.withAlphaComponent(0.14)
    )
    static let strokeStrong = Color.dyn(
        light: UIColor.white.withAlphaComponent(0.92),
        dark: UIColor.white.withAlphaComponent(0.24)
    )
    static let hairline = Color.dyn(
        light: UIColor.black.withAlphaComponent(0.06),
        dark: UIColor.white.withAlphaComponent(0.10)
    )

    // MARK: 强调色（暗色下提亮，保持同样的对比）

    static let accent = Color.dyn(light: 0x2F6BFF, dark: 0x5B8CFF)
    static let green = Color.dyn(light: 0x12A150, dark: 0x34D07A)
    static let orange = Color.dyn(light: 0xE08600, dark: 0xFFB33D)
    static let red = Color.dyn(light: 0xE03C3C, dark: 0xFF6B6B)
    static let purple = Color.dyn(light: 0x7A4DFF, dark: 0xA98BFF)
    static let cyan = Color.dyn(light: 0x0EA5B7, dark: 0x37D6E8)

    // MARK: 尺寸

    static let cardRadius: CGFloat = 22
    static let controlRadius: CGFloat = 16
    static let fieldRadius: CGFloat = 14

    // MARK: 文字

    static let textPrimary = Color.dyn(
        light: UIColor(Color(hex: 0x14161A)).withAlphaComponent(0.92),
        dark: UIColor.white.withAlphaComponent(0.94)
    )
    static let textSecondary = Color.dyn(
        light: UIColor(Color(hex: 0x14161A)).withAlphaComponent(0.56),
        dark: UIColor.white.withAlphaComponent(0.58)
    )
    static let textTertiary = Color.dyn(
        light: UIColor(Color(hex: 0x14161A)).withAlphaComponent(0.34),
        dark: UIColor.white.withAlphaComponent(0.36)
    )

    // MARK: 玻璃层细节

    /// 玻璃投影：亮色要极淡，暗色要够深才有浮起感。
    static let glassShadow = Color.dyn(
        light: UIColor.black.withAlphaComponent(0.08),
        dark: UIColor.black.withAlphaComponent(0.45)
    )

    /// 玻璃内部的对角白渐变（上亮下暗 = 厚度）。
    static let sheenTop = Color.dyn(
        light: UIColor.white.withAlphaComponent(0.55),
        dark: UIColor.white.withAlphaComponent(0.10)
    )
    static let sheenBottom = Color.dyn(
        light: UIColor.white.withAlphaComponent(0.24),
        dark: UIColor.white.withAlphaComponent(0.02)
    )

    /// 边缘镜面高光（描边自上而下由亮到暗）。
    static let specular = LinearGradient(
        colors: [
            Color.dyn(light: UIColor.white.withAlphaComponent(0.95),
                      dark: UIColor.white.withAlphaComponent(0.34)),
            Color.dyn(light: UIColor.white.withAlphaComponent(0.12),
                      dark: UIColor.white.withAlphaComponent(0.03))
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// 进度条轨道等「凹槽」。
    static let well = Color.dyn(
        light: UIColor.black.withAlphaComponent(0.07),
        dark: UIColor.white.withAlphaComponent(0.08)
    )
}

// MARK: - 背景

/// 底色 + 三团低饱和光晕。玻璃层压上去才有折射和厚度。
struct FlatBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let boost = scheme == .dark ? 1.5 : 1.0
        ZStack {
            Flat.background
            Circle()
                .fill(Flat.accent.opacity(0.20 * boost))
                .frame(width: 440, height: 440)
                .blur(radius: 130)
                .offset(x: -150, y: -300)
            Circle()
                .fill(Flat.cyan.opacity(0.18 * boost))
                .frame(width: 380, height: 380)
                .blur(radius: 140)
                .offset(x: 170, y: -50)
            Circle()
                .fill(Flat.purple.opacity(0.14 * boost))
                .frame(width: 460, height: 460)
                .blur(radius: 150)
                .offset(x: -80, y: 320)
        }
        .ignoresSafeArea()
    }
}

// MARK: - 玻璃层

/// 一块玻璃：材质模糊 + 白薄涂 + 对角光泽 + 顶部镜面高光 + 亮边 + 投影。
struct GlassLayer: ViewModifier {
    var radius: CGFloat
    var tint: Color?
    var base: Color?

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if let base {
                        shape.fill(base)
                    }
                    if let tint {
                        shape.fill(tint.opacity(0.16))
                    }
                    shape.fill(
                        LinearGradient(
                            colors: [Flat.sheenTop, Flat.sheenBottom],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
            .overlay {
                // 顶部亮、底部收 —— 这一层就是"玻璃边"的来源
                shape.strokeBorder(Flat.specular, lineWidth: 1)
            }
            .clipShape(shape)
            .shadow(color: Flat.glassShadow, radius: 18, x: 0, y: 10)
    }
}

// MARK: - 卡片

struct FlatCardModifier: ViewModifier {
    var radius: CGFloat = Flat.cardRadius
    var fill: Color = Flat.surface
    var tint: Color? = nil

    func body(content: Content) -> some View {
        content.modifier(
            GlassLayer(radius: radius, tint: tint, base: fill)
        )
    }
}

extension View {
    /// 液态玻璃卡片。
    func flatCard(radius: CGFloat = Flat.cardRadius, fill: Color = Flat.surface) -> some View {
        modifier(FlatCardModifier(radius: radius, fill: fill))
    }

    /// 带色调的玻璃卡（在线绿、异常橙）。
    func tintedCard(_ tint: Color, radius: CGFloat = Flat.cardRadius) -> some View {
        modifier(FlatCardModifier(radius: radius, fill: Flat.surface, tint: tint))
    }

    /// 内嵌输入框：比卡片更薄、更"凹"。
    func flatField(radius: CGFloat = Flat.fieldRadius,
                   fill: Color = Flat.surfaceLow) -> some View {
        modifier(FlatFieldModifier(radius: radius, fill: fill))
    }
}

struct FlatFieldModifier: ViewModifier {
    var radius: CGFloat = Flat.fieldRadius
    var fill: Color = Flat.surfaceLow

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
                ZStack {
                    shape.fill(.thinMaterial)
                    shape.fill(fill)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Flat.hairline, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - 按钮

/// 主按钮 = 实色渐变 + 顶部高光；次级按钮 = 玻璃 + 亮边。
/// 按下立刻缩到 0.96（不等点击完成才给反馈），松手用短弹簧回位。
struct FlatButtonStyle: ButtonStyle {
    var tint: Color = Flat.accent
    var filled: Bool = false
    var radius: CGFloat = Flat.controlRadius
    var height: CGFloat = 50

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .foregroundStyle(filled ? Color.white : Flat.textPrimary)
            .background {
                ZStack {
                    if filled {
                        shape.fill(
                            LinearGradient(
                                colors: [tint.opacity(0.92), tint],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        shape.fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.28), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                    } else {
                        shape.fill(.ultraThinMaterial)
                        shape.fill(Flat.surfaceHigh)
                    }
                }
            }
            .overlay {
                shape.strokeBorder(
                    filled ? Color.white.opacity(0.34) : Flat.stroke,
                    lineWidth: 1
                )
            }
            .clipShape(shape)
            .shadow(color: filled ? tint.opacity(0.28) : Flat.glassShadow,
                    radius: filled ? 14 : 10,
                    x: 0, y: filled ? 8 : 5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.86), value: configuration.isPressed)
    }
}

// MARK: - 胶囊 chip

struct FlatPill: ViewModifier {
    var selected: Bool = false
    var tint: Color = Flat.accent

    func body(content: Content) -> some View {
        let shape = Capsule(style: .continuous)
        content
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(selected ? tint.opacity(0.14) : Flat.surfaceHigh)
                }
            }
            .overlay {
                shape.strokeBorder(
                    selected ? tint.opacity(0.55) : Flat.stroke,
                    lineWidth: 1
                )
            }
            .clipShape(shape)
            .shadow(color: Flat.glassShadow.opacity(0.6), radius: 6, x: 0, y: 3)
    }
}

extension View {
    func flatPill(selected: Bool = false, tint: Color = Flat.accent) -> some View {
        modifier(FlatPill(selected: selected, tint: tint))
    }
}

// MARK: - 状态标识

/// 玻璃圆环 + 图标；颜色表达状态。
struct FlatStatusMark: View {
    var symbol: String
    var tint: Color
    var size: CGFloat = 60

    var body: some View {
        ZStack {
            Circle().fill(.ultraThinMaterial)
            Circle().fill(tint.opacity(0.16))
            Circle().strokeBorder(Flat.specular, lineWidth: 1)
            Image(systemName: symbol)
                .font(.system(size: size * 0.40, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
        .shadow(color: tint.opacity(0.18), radius: 12, y: 6)
    }
}

/// 细进度条：凹槽轨道 + 渐变填充。
struct FlatProgressBar: View {
    var progress: Double
    var tint: Color
    var height: CGFloat = 5

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Flat.well)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [tint.opacity(0.75), tint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, proxy.size.width * min(1, max(0, progress))))
            }
        }
        .frame(height: height)
    }
}

// MARK: - 分区标题

struct FlatSectionHeader: View {
    let title: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Flat.textSecondary)
            Spacer(minLength: 0)
            if let trailing { trailing }
        }
    }
}

// MARK: - 分隔线

struct FlatDivider: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Flat.hairline)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}
