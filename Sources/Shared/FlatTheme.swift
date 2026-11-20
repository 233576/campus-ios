import SwiftUI

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
}

/// 浅色 + 液态玻璃的色板。
///
/// 命名沿用 `Flat`，这样所有界面不用改调用点就整体换皮。
/// 底色不是纯白 —— 纯白上的玻璃看不出玻璃；用一层极浅的冷白 + 三团低饱和光晕，
/// 玻璃压上去才有折射和厚度。
enum Flat {
    /// 页面底色（冷白，略低于纯白，给玻璃留出对比）。
    static let background = Color(hex: 0xF3F5F8)
    /// 玻璃卡的基色（在 `.ultraThinMaterial` 之上再叠一层，控制通透度）。
    static let surface = Color.white.opacity(0.55)
    static let surfaceHigh = Color.white.opacity(0.72)
    static let surfaceLow = Color.white.opacity(0.38)

    /// 玻璃边缘：亮描边，模拟玻璃的折光边。
    static let stroke = Color.white.opacity(0.70)
    static let strokeStrong = Color.white.opacity(0.92)
    /// 浅色下真正需要的那条"阴影线"（玻璃底部的厚度感）。
    static let hairline = Color.black.opacity(0.06)

    static let accent = Color(hex: 0x2F6BFF)
    static let green = Color(hex: 0x12A150)
    static let orange = Color(hex: 0xE08600)
    static let red = Color(hex: 0xE03C3C)
    static let purple = Color(hex: 0x7A4DFF)
    static let cyan = Color(hex: 0x0EA5B7)

    static let cardRadius: CGFloat = 22
    static let controlRadius: CGFloat = 16
    static let fieldRadius: CGFloat = 14

    static let textPrimary = Color(hex: 0x14161A).opacity(0.92)
    static let textSecondary = Color(hex: 0x14161A).opacity(0.56)
    static let textTertiary = Color(hex: 0x14161A).opacity(0.34)

    /// 玻璃的投影：浅色背景上必须非常淡，否则立刻变"卡片堆"。
    static let glassShadow = Color.black.opacity(0.08)
    /// 玻璃顶部的高光渐变。
    static let specular = LinearGradient(
        colors: [Color.white.opacity(0.95), Color.white.opacity(0.12)],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - 背景

/// 冷白底 + 三团极淡光晕，玻璃层压上去才有折射。
struct FlatBackground: View {
    var body: some View {
        ZStack {
            Flat.background
            Circle()
                .fill(Flat.accent.opacity(0.20))
                .frame(width: 440, height: 440)
                .blur(radius: 130)
                .offset(x: -150, y: -300)
            Circle()
                .fill(Flat.cyan.opacity(0.18))
                .frame(width: 380, height: 380)
                .blur(radius: 140)
                .offset(x: 170, y: -50)
            Circle()
                .fill(Flat.purple.opacity(0.14))
                .frame(width: 460, height: 460)
                .blur(radius: 150)
                .offset(x: -80, y: 320)
        }
        .ignoresSafeArea()
    }
}

// MARK: - 玻璃层

/// 一块玻璃：材质模糊 + 白色薄涂 + 顶部镜面高光 + 亮边 + 极淡投影。
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
                            colors: [Color.white.opacity(0.55), Color.white.opacity(0.24)],
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

    /// 带色调的玻璃卡（用于状态块：在线绿、异常橙）。
    func tintedCard(_ tint: Color, radius: CGFloat = Flat.cardRadius) -> some View {
        modifier(FlatCardModifier(radius: radius, fill: Flat.surface, tint: tint))
    }

    /// 内嵌输入框：比卡片更薄、更"凹"，用一层浅色玻璃表达可输入。
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
                    shape.fill(Color.white.opacity(0.30))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
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
                        shape.fill(Color.white.opacity(0.55))
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
                    shape.fill(Color.white.opacity(selected ? 0.30 : 0.50))
                    if selected {
                        shape.fill(tint.opacity(0.18))
                    }
                }
            }
            .overlay {
                shape.strokeBorder(
                    selected ? tint.opacity(0.55) : Color.white.opacity(0.85),
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

/// 细进度条：浅色轨道 + 渐变填充。
struct FlatProgressBar: View {
    var progress: Double
    var tint: Color
    var height: CGFloat = 5

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.07))
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
