import SwiftUI
import UIKit

// MARK: - 动态色

extension UIColor {
    convenience init(hexValue: UInt32, alpha: Double = 1) {
        self.init(
            red: CGFloat((hexValue >> 16) & 0xFF) / 255,
            green: CGFloat((hexValue >> 8) & 0xFF) / 255,
            blue: CGFloat(hexValue & 0xFF) / 255,
            alpha: CGFloat(alpha)
        )
    }
}

extension Color {
    /// 随系统外观切换的语义色。不用 Asset Catalog，是因为这些值只在这里用一次。
    static func dyn(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        })
    }

    static func dyn(light: UInt32,
                    dark: UInt32,
                    lightAlpha: Double = 1,
                    darkAlpha: Double = 1) -> Color {
        .dyn(light: UIColor(hexValue: light, alpha: lightAlpha),
             dark: UIColor(hexValue: dark, alpha: darkAlpha))
    }
}

// MARK: - 色板

/// iOS 原生系统色板。
///
/// 三条规矩：
/// 1. 只有一个主色（`accent` = 系统蓝），其余全是灰阶；
/// 2. 卡片是纯色面 + 1px 分隔线，不用毛玻璃、不堆阴影；
/// 3. 状态色（绿/红/橙）只出现在文字和图标上，不做背景。
enum GlassPalette {
    static let background = Color.dyn(light: 0xF2F2F7, dark: 0x000000)
    static let groupedBackground = Color.dyn(light: 0xF2F2F7, dark: 0x000000)
    static let surface = Color.dyn(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let surfaceHigh = Color.dyn(light: 0xF2F2F7, dark: 0x2C2C2E)
    static let surfaceLow = Color.dyn(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let separator = Color.dyn(light: 0xE5E5EA, dark: 0x38383A)
    static let hairline = Color.dyn(light: 0xE5E5EA, dark: 0x38383A)
    static let edge = Color.dyn(light: 0xE5E5EA, dark: 0x38383A)

    static let accent = Color.dyn(light: 0x007AFF, dark: 0x0A84FF)
    static let green = Color.dyn(light: 0x34C759, dark: 0x30D158)
    static let orange = Color.dyn(light: 0xFF9500, dark: 0xFF9F0A)
    static let red = Color.dyn(light: 0xFF3B30, dark: 0xFF453A)
    static let purple = Color.dyn(light: 0x5856D6, dark: 0x5E5CE6)
    static let cyan = Color.dyn(light: 0x32ADE6, dark: 0x64D2FF)

    static let textPrimary = Color.dyn(light: 0x000000, dark: 0xFFFFFF)
    static let textSecondary = Color.dyn(light: 0x8E8E93, dark: 0x8E8E93)
    static let textTertiary = Color.dyn(light: 0xC7C7CC, dark: 0x48484A)

    static let radius: CGFloat = 12
    static let cardRadius: CGFloat = 12
    static let controlRadius: CGFloat = 10
    static let fieldRadius: CGFloat = 10

    static let shadow = Color.black.opacity(0.04)
    static let glassShadow = Color.black.opacity(0.04)
    static let glassEdge = separator
    static let sheenTop = Color.clear
    static let sheenBottom = Color.clear
    static let specular = LinearGradient(colors: [separator, separator], startPoint: .top, endPoint: .bottom)
    static let well = surfaceHigh

    /// 选中态/强调态的浅色底：系统蓝的 12% 叠在纯色面上。
    static let accentSoft = Color.dyn(light: 0x007AFF, dark: 0x0A84FF, lightAlpha: 0.12, darkAlpha: 0.18)
}

/// 旧名字的转发层。视图里大量写了 `Flat.xxx`，保留以免整体改写。
enum Flat {
    static let background = GlassPalette.background
    static let groupedBackground = GlassPalette.groupedBackground
    static let surface = GlassPalette.surface
    static let surfaceHigh = GlassPalette.surfaceHigh
    static let surfaceLow = GlassPalette.surfaceLow
    static let separator = GlassPalette.separator
    static let hairline = GlassPalette.hairline
    static let edge = GlassPalette.edge
    static let stroke = GlassPalette.separator
    static let strokeStrong = GlassPalette.textTertiary

    static let accent = GlassPalette.accent
    static let green = GlassPalette.green
    static let orange = GlassPalette.orange
    static let red = GlassPalette.red
    static let purple = GlassPalette.purple
    static let cyan = GlassPalette.cyan
    static let accentSoft = GlassPalette.accentSoft

    static let textPrimary = GlassPalette.textPrimary
    static let textSecondary = GlassPalette.textSecondary
    static let textTertiary = GlassPalette.textTertiary

    static let radius = GlassPalette.radius
    static let cardRadius = GlassPalette.cardRadius
    static let controlRadius = GlassPalette.controlRadius
    static let fieldRadius = GlassPalette.fieldRadius

    static let shadow = GlassPalette.shadow
    static let glassShadow = GlassPalette.glassShadow
    static let glassEdge = GlassPalette.glassEdge
    static let sheenTop = GlassPalette.sheenTop
    static let sheenBottom = GlassPalette.sheenBottom
    static let specular = GlassPalette.specular
    static let well = GlassPalette.well
    static let grayish = GlassPalette.surfaceHigh
}

// MARK: - 背景

/// 全局底色：干净的浅灰（暗色为纯黑），不铺任何渐变和光斑。
struct FlatBackground: View {
    var body: some View {
        GlassPalette.background.ignoresSafeArea()
    }
}

// MARK: - 卡片

/// 纯色卡片：一个面 + 一条 1px 边，没有模糊、没有厚投影。
struct FlatCardModifier: ViewModifier {
    var radius: CGFloat
    var fill: Color

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(GlassPalette.separator, lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

extension View {
    func flatCard(radius: CGFloat = GlassPalette.cardRadius,
                  fill: Color = GlassPalette.surface) -> some View {
        modifier(FlatCardModifier(radius: radius, fill: fill))
    }

    /// 带一点点强调色的卡片。底色仍是纯色，只把边框换成强调色的浅调。
    func tintedCard(_ tint: Color, radius: CGFloat = GlassPalette.cardRadius) -> some View {
        modifier(TintedCardModifier(radius: radius, tint: tint))
    }

    /// 分组列表的底色（Form / List 用）。
    func groupedListBackground() -> some View {
        scrollContentBackground(.hidden)
            .background(GlassPalette.groupedBackground)
    }

    // 兼容旧调用名。
    func glassListBackground() -> some View { groupedListBackground() }
    func flatListBackground() -> some View { groupedListBackground() }
}

struct TintedCardModifier: ViewModifier {
    var radius: CGFloat
    var tint: Color

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(GlassPalette.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(tint.opacity(0.35), lineWidth: 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - 输入框

struct FlatFieldModifier: ViewModifier {
    var radius: CGFloat
    var fill: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(GlassPalette.separator, lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

extension View {
    func flatField(radius: CGFloat = GlassPalette.fieldRadius,
                   fill: Color = GlassPalette.surfaceHigh) -> some View {
        modifier(FlatFieldModifier(radius: radius, fill: fill))
    }

    // 兼容旧调用名：以前这些是毛玻璃输入框。
    func glassField(radius: CGFloat = GlassPalette.fieldRadius) -> some View {
        flatField(radius: radius)
    }
}

// MARK: - 按钮

/// 主按钮：实心系统蓝 + 白字，圆角 10，无渐变无高光。
/// 次按钮：浅灰底 + 蓝字。
struct FlatButtonStyle: ButtonStyle {
    var tint: Color = GlassPalette.accent
    var filled: Bool = true
    var radius: CGFloat = GlassPalette.controlRadius
    var height: CGFloat = 50

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: filled ? 17 : 16, weight: .semibold))
            .foregroundStyle(filled ? Color.white : (tint == GlassPalette.accent ? GlassPalette.accent : GlassPalette.textPrimary))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(filled ? tint : GlassPalette.surfaceHigh)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct PressScaleStyle: ButtonStyle {
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - 胶囊 / 标签

/// iOS 分段控件式的胶囊：灰底，选中是白色滑块 + 强调色文字。
struct FlatPill: ViewModifier {
    var selected: Bool
    var tint: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                Capsule(style: .continuous)
                    .fill(selected ? GlassPalette.surface : Color.clear)
            }
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(selected ? Color.clear : GlassPalette.separator, lineWidth: 0.5)
            }
            .clipShape(Capsule(style: .continuous))
    }
}

extension View {
    func flatPill(selected: Bool, tint: Color = GlassPalette.accent) -> some View {
        modifier(FlatPill(selected: selected, tint: tint))
    }

    func glassPill(selected: Bool, tint: Color = GlassPalette.accent) -> some View {
        flatPill(selected: selected, tint: tint)
    }
}

// MARK: - 状态标记

struct FlatStatusMark: View {
    var symbol: String
    var tint: Color
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.12))
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 进度条

struct FlatProgressBar: View {
    var progress: Double
    var tint: Color = GlassPalette.accent
    var height: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(GlassPalette.surfaceHigh)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

// MARK: - 区块标题 / 分隔线

struct FlatSectionHeader: View {
    var title: String
    var trailing: AnyView?

    init(title: String, trailing: AnyView? = nil) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(GlassPalette.textSecondary)
                .textCase(.uppercase)
            Spacer(minLength: 8)
            if let trailing { trailing }
        }
        .padding(.horizontal, 4)
    }
}

struct FlatDivider: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(GlassPalette.separator)
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}
