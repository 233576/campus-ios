import SwiftUI

/// 旧主题兼容层。
///
/// View 层已全部切到 `Theme/` 与 `Components/`，这里只保留尚未迁移的
/// 少数视图还在引用的符号，实现全部转发到语义色与系统材质，
/// 不再出现任何写死的 hex、rgb 或 `.system(size:)`。
enum Flat {
    static let background = Color.appGroupedBackground
    static let surface = Color.appSecondaryBackground
    static let surfaceHigh = Color(uiColor: .secondarySystemGroupedBackground)
    static let surfaceLow = Color(uiColor: .tertiarySystemGroupedBackground)
    static let stroke = Color.appSeparator
    static let strokeStrong = Color(uiColor: .separator)
    static let hairline = Color.appSeparator
    static let glassEdge = Color.appSeparator
    static let glassShadow = Color.black.opacity(0.08)
    static let sheenTop = Color.white.opacity(0.35)
    static let sheenBottom = Color.white.opacity(0.08)

    static let accent = Color.appBrand
    static let green = Color.appSuccess
    static let orange = Color.appWarning
    static let red = Color.appDanger
    static let purple = Color(uiColor: .systemPurple)
    static let cyan = Color(uiColor: .systemTeal)

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    static let textTertiary = Color(uiColor: .tertiaryLabel)

    static let cardRadius: CGFloat = Radius.card
    static let fieldRadius: CGFloat = Radius.control
    static let controlRadius: CGFloat = Radius.control

    static var specular: LinearGradient {
        LinearGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.10)],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
    }

    static let well = Color(uiColor: .tertiarySystemFill)
}

/// 页面底色。
struct FlatBackground: View {
    var body: some View {
        Color.appGroupedBackground.ignoresSafeArea()
    }
}

/// 卡片：系统材质 + 细描边，不再有品牌色叠加。
struct FlatCardModifier: ViewModifier {
    var radius: CGFloat = Radius.card
    var fill: Color = Color.appSecondaryBackground
    var elevated: Bool = true

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.appSeparator, lineWidth: 0.5)
            }
            .shadow(color: elevated ? Color.black.opacity(0.04) : .clear,
                    radius: 10, x: 0, y: 4)
    }
}

extension View {
    func flatCard(radius: CGFloat = Radius.card,
                  fill: Color = Color.appSecondaryBackground,
                  elevated: Bool = true) -> some View {
        modifier(FlatCardModifier(radius: radius, fill: fill, elevated: elevated))
    }

    func tintedCard(_ tint: Color, radius: CGFloat = Radius.card) -> some View {
        modifier(FlatCardModifier(radius: radius, fill: tint.opacity(0.10), elevated: false))
    }

    func flatField(radius: CGFloat = Radius.control,
                   fill: Color = Color(uiColor: .tertiarySystemFill)) -> some View {
        self
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.appSeparator, lineWidth: 0.5)
            }
    }

    func flatPill(selected: Bool = false, tint: Color = Color.appBrand) -> some View {
        self
            .background(selected ? tint.opacity(0.14) : Color(uiColor: .secondarySystemFill),
                        in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(selected ? tint.opacity(0.55) : Color.clear, lineWidth: 1)
            }
    }
}

/// 旧按钮样式：实心品牌色（primary）或浅灰（secondary）。
struct FlatButtonStyle: ButtonStyle {
    var tint: Color = .appBrand
    var filled: Bool = true
    var radius: CGFloat = Radius.control
    var height: CGFloat = Spacing.rowMinHeight

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(filled ? Color.white : tint)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(filled ? tint : Color(uiColor: .tertiarySystemFill))
            }
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.9), value: configuration.isPressed)
    }
}

/// 圆形状态标。
struct FlatStatusMark: View {
    var symbol: String
    var tint: Color = .appBrand
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle().fill(tint.opacity(0.14))
            Image(systemName: symbol)
                .font(Typography.headline)
                .foregroundStyle(tint)
        }
        .frame(width: size, height: size)
    }
}

/// 细进度条。
struct FlatProgressBar: View {
    var progress: Double
    var tint: Color = .appBrand
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(uiColor: .tertiarySystemFill))
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

struct FlatSectionHeader: View {
    var title: String
    var trailing: AnyView?

    init(title: String, trailing: AnyView? = nil) {
        self.title = title
        self.trailing = trailing
    }

    var body: some View {
        HStack {
            Text(title).font(Typography.sectionTitle)
            Spacer(minLength: Spacing.s)
            if let trailing { trailing }
        }
    }
}

struct FlatDivider: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Color.appSeparator)
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}
