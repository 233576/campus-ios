import SwiftUI

// MARK: - 动态色

extension Color {
    static func dyn(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }

    static func dyn(light: UInt32,
                    dark: UInt32,
                    lightAlpha: Double = 1,
                    darkAlpha: Double = 1) -> Color {
        dyn(light: UIColor(hexValue: light, alpha: lightAlpha),
            dark: UIColor(hexValue: dark, alpha: darkAlpha))
    }
}

extension UIColor {
    convenience init(hexValue: UInt32, alpha: Double = 1) {
        let r = CGFloat((hexValue >> 16) & 0xFF) / 255
        let g = CGFloat((hexValue >> 8) & 0xFF) / 255
        let b = CGFloat(hexValue & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: CGFloat(alpha))
    }
}

// MARK: - 色板

/// 液态玻璃下的一套色：玻璃本身是半透明白/黑，颜色只在需要表达状态时出现。
enum GlassPalette {
    static let background = Color.dyn(light: 0xEEF1F6, dark: 0x08090C)
    static let surface = Color.dyn(light: UIColor(white: 1, alpha: 0.55),
                                   dark: UIColor(white: 1, alpha: 0.06))
    static let surfaceHigh = Color.dyn(light: UIColor(white: 1, alpha: 0.72),
                                       dark: UIColor(white: 1, alpha: 0.10))
    static let surfaceLow = Color.dyn(light: UIColor(white: 1, alpha: 0.38),
                                      dark: UIColor(white: 1, alpha: 0.04))
    static let hairline = Color.dyn(light: UIColor(white: 0, alpha: 0.06),
                                    dark: UIColor(white: 1, alpha: 0.10))
    static let edge = Color.dyn(light: UIColor(white: 1, alpha: 0.85),
                                 dark: UIColor(white: 1, alpha: 0.22))

    static let accent = Color.dyn(light: 0x2F6BFF, dark: 0x6E9BFF)
    static let green = Color.dyn(light: 0x12A150, dark: 0x3ED684)
    static let orange = Color.dyn(light: 0xE08600, dark: 0xFFB33D)
    static let red = Color.dyn(light: 0xE03C3C, dark: 0xFF6F6F)
    static let purple = Color.dyn(light: 0x7A4DFF, dark: 0xB49BFF)
    static let cyan = Color.dyn(light: 0x0EA5B7, dark: 0x45E0F0)

    static let textPrimary = Color.dyn(light: UIColor(white: 0.05, alpha: 0.94),
                                       dark: UIColor(white: 1, alpha: 0.95))
    static let textSecondary = Color.dyn(light: UIColor(white: 0.10, alpha: 0.62),
                                         dark: UIColor(white: 1, alpha: 0.62))
    static let textTertiary = Color.dyn(light: UIColor(white: 0.10, alpha: 0.40),
                                        dark: UIColor(white: 1, alpha: 0.38))

    static let radius: CGFloat = 26
    static let controlRadius: CGFloat = 18

    static let shadow = Color.dyn(light: UIColor(white: 0.1, alpha: 0.10),
                                  dark: UIColor(white: 0, alpha: 0.55))
    static let well = Color.dyn(light: UIColor(white: 0, alpha: 0.06),
                                dark: UIColor(white: 1, alpha: 0.08))
}

/// 兼容层：旧视图里写的是 `Flat.xxx`，映射到同一套玻璃色，避免逐个文件改。
enum Flat {
    static let background = GlassPalette.background
    static let surface = GlassPalette.surface
    static let surfaceHigh = GlassPalette.surfaceHigh
    static let surfaceLow = GlassPalette.surfaceLow
    static let stroke = GlassPalette.edge
    static let strokeStrong = GlassPalette.edge
    static let hairline = GlassPalette.hairline
    static let accent = GlassPalette.accent
    static let green = GlassPalette.green
    static let orange = GlassPalette.orange
    static let red = GlassPalette.red
    static let purple = GlassPalette.purple
    static let cyan = GlassPalette.cyan
    static let cardRadius = GlassPalette.radius
    static let controlRadius = GlassPalette.controlRadius
    static let fieldRadius: CGFloat = 18
    static let textPrimary = GlassPalette.textPrimary
    static let textSecondary = GlassPalette.textSecondary
    static let textTertiary = GlassPalette.textTertiary
    static let glassShadow = GlassPalette.shadow
    static let glassEdge = GlassPalette.edge
    static let well = GlassPalette.well
    static let sheenTop = Color.white.opacity(0.5)
    static let sheenBottom = Color.white.opacity(0.02)
    static let specular = LinearGradient(
        colors: [Color.white.opacity(0.9), Color.white.opacity(0.05)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - 背景

/// 玻璃要有东西可折射。所以背景给三团大色斑 + 一层极淡的网格：
/// 内容滚过胶囊、光斑透过玻璃，才有「液态」的感觉；纯色底上玻璃看起来就是块灰板。
struct FlatBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let boost: Double = scheme == .dark ? 1.0 : 0.62
        ZStack {
            GlassPalette.background
            GeometryReader { proxy in
                let w = proxy.size.width
                let h = proxy.size.height
                ZStack {
                    blob(color: GlassPalette.accent, size: w * 1.05, opacity: 0.30 * boost)
                        .position(x: w * 0.18, y: h * 0.12)
                    blob(color: GlassPalette.cyan, size: w * 0.95, opacity: 0.26 * boost)
                        .position(x: w * 0.92, y: h * 0.30)
                    blob(color: GlassPalette.purple, size: w * 1.15, opacity: 0.24 * boost)
                        .position(x: w * 0.35, y: h * 0.86)
                    blob(color: GlassPalette.green, size: w * 0.8, opacity: 0.16 * boost)
                        .position(x: w * 0.88, y: h * 0.72)
                }
                .blur(radius: 70)
            }
        }
        .ignoresSafeArea()
    }

    private func blob(color: Color, size: CGFloat, opacity: Double) -> some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: size, height: size)
    }
}

// MARK: - 玻璃容器

struct GlassLayer: ViewModifier {
    var radius: CGFloat
    var tint: Color?
    var base: Color?

    func body(content: Content) -> some View {
        content.liquidGlassSurface(radius: radius, tint: tint)
    }
}

/// 玻璃卡片：真玻璃（折射 / 高光 / 边缘），不再叠任何底色。
struct FlatCardModifier: ViewModifier {
    var radius: CGFloat = GlassPalette.radius
    var fill: Color = GlassPalette.surface
    var tint: Color? = nil

    func body(content: Content) -> some View {
        content
            .liquidGlassSurface(radius: radius, tint: tint, tintOpacity: 0.16)
    }
}

extension View {
    func flatCard(radius: CGFloat = GlassPalette.radius, fill: Color = GlassPalette.surface) -> some View {
        modifier(FlatCardModifier(radius: radius, fill: fill))
    }

    func tintedCard(_ tint: Color, radius: CGFloat = GlassPalette.radius) -> some View {
        modifier(FlatCardModifier(radius: radius, fill: GlassPalette.surface, tint: tint))
    }

    /// 输入框：比卡片更薄的一层玻璃 + 内凹轨道。
    func flatField(radius: CGFloat = 18, fill: Color = GlassPalette.surfaceLow) -> some View {
        modifier(FlatFieldModifier(radius: radius, fill: fill))
    }
}

struct FlatFieldModifier: ViewModifier {
    var radius: CGFloat = 18
    var fill: Color = GlassPalette.surfaceLow

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background {
                let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    shape.fill(fill)
                    shape.fill(GlassPalette.well.opacity(0.5))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(GlassPalette.hairline, lineWidth: 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - 按钮

/// 主按钮 = 强调色玻璃（tint 拉满）；次级按钮 = 无色玻璃。
/// 按下立刻缩到 0.96，松手短弹簧回位 —— 反馈在按下那一刻给。
struct FlatButtonStyle: ButtonStyle {
    var tint: Color = GlassPalette.accent
    var filled: Bool = false
    var radius: CGFloat = GlassPalette.controlRadius
    var height: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .foregroundStyle(filled ? Color.white : GlassPalette.textPrimary)
            .background {
                if filled {
                    ZStack {
                        shape.fill(
                            LinearGradient(colors: [tint.opacity(0.95), tint],
                                           startPoint: .top,
                                           endPoint: .bottom)
                        )
                        shape.fill(
                            LinearGradient(colors: [Color.white.opacity(0.30), Color.clear],
                                           startPoint: .top,
                                           endPoint: .center)
                        )
                    }
                }
            }
            .modifier(OptionalGlass(radius: radius, tint: filled ? nil : tint, enabled: !filled))
            .overlay {
                if filled {
                    shape.strokeBorder(Color.white.opacity(0.30), lineWidth: 1)
                }
            }
            .clipShape(shape)
            .shadow(color: filled ? tint.opacity(0.30) : GlassPalette.shadow,
                    radius: filled ? 16 : 10,
                    x: 0, y: filled ? 9 : 5)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.86), value: configuration.isPressed)
    }
}

/// 只在不填充时补一层玻璃；填充态已经有实色渐变。
private struct OptionalGlass: ViewModifier {
    var radius: CGFloat
    var tint: Color?
    var enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.liquidGlassSurface(radius: radius, tint: tint, tintOpacity: 0.18)
        } else {
            content
        }
    }
}

struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.22, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

// MARK: - 胶囊

struct FlatPill: ViewModifier {
    var selected: Bool = false
    var tint: Color = GlassPalette.accent

    func body(content: Content) -> some View {
        let shape = Capsule(style: .continuous)
        content
            .liquidGlassSurface(radius: 22, tint: selected ? tint : nil, tintOpacity: selected ? 0.30 : 0.10)
            .overlay {
                if selected {
                    shape.strokeBorder(tint.opacity(0.50), lineWidth: 1)
                }
            }
            .clipShape(shape)
    }
}

extension View {
    func flatPill(selected: Bool = false, tint: Color = GlassPalette.accent) -> some View {
        modifier(FlatPill(selected: selected, tint: tint))
    }
}

// MARK: - 状态标识

struct FlatStatusMark: View {
    var symbol: String
    var tint: Color
    var size: CGFloat = 62

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.14))
                .frame(width: size, height: size)
                .liquidGlassSurface(radius: size / 2, tint: tint, tintOpacity: 0.22)
            Circle()
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
                .frame(width: size, height: size)
            Image(systemName: symbol)
                .font(.system(size: size * 0.40, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
        .shadow(color: tint.opacity(0.20), radius: 14, y: 7)
    }
}

struct FlatProgressBar: View {
    var progress: Double
    var tint: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(GlassPalette.well)
                Capsule()
                    .fill(LinearGradient(colors: [tint.opacity(0.70), tint],
                                         startPoint: .leading,
                                         endPoint: .trailing))
                    .frame(width: max(5, proxy.size.width * min(1, max(0, progress))))
                    .shadow(color: tint.opacity(0.35), radius: 4, y: 1)
            }
        }
        .frame(height: height)
    }
}

struct FlatSectionHeader: View {
    let title: String
    var trailing: AnyView? = nil

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(GlassPalette.textTertiary)
            Spacer(minLength: 0)
            if let trailing { trailing }
        }
    }
}

struct FlatDivider: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(GlassPalette.hairline)
            .frame(height: 0.8)
            .padding(.leading, inset)
    }
}
