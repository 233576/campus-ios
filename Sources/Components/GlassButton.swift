import SwiftUI

/// 三态玻璃按钮。
///
/// - primary：主操作，玻璃醒目态（iOS 26）/ 实心品牌色（低版本）
/// - secondary：次要操作，普通玻璃（低版本为浅灰）
/// - plain：纯文字
///
/// 玻璃只允许出现在这些浮动控件上，列表行里一律用 secondary 的实心降级。
///
/// 禁用态不再靠外部 `.opacity(0.5)` 硬压 —— 那样在深色模式下会变成
/// 「灰底灰字」看不清。这里统一换成 `tertiarySystemFill` 底 + `tertiaryLabel` 字，
/// 深浅色都由系统保证对比度。
enum GlassButtonRole {
    case primary
    case secondary
    case plain
}

struct GlassButtonStyle: ButtonStyle {
    var role: GlassButtonRole = .primary
    var fullWidth: Bool = true

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.headline)
            .foregroundStyle(foreground)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(height: Spacing.rowMinHeight)
            .padding(.horizontal, fullWidth ? 0 : Spacing.l)
            .background { background }
            .clipShape(Capsule(style: .continuous))
            .opacity(configuration.isPressed && isEnabled ? 0.82 : 1)
            .scaleEffect(configuration.isPressed && isEnabled ? 0.985 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.9), value: configuration.isPressed)
    }

    private var foreground: Color {
        guard isEnabled else {
            return role == .plain ? Color(uiColor: .tertiaryLabel) : Color(uiColor: .tertiaryLabel)
        }
        switch role {
        case .primary: return .white
        case .secondary: return .appBrand
        case .plain: return .appBrand
        }
    }

    @ViewBuilder
    private var background: some View {
        let shape = Capsule(style: .continuous)

        if !isEnabled {
            shape.fill(Color(uiColor: .tertiarySystemFill))
        } else if role == .plain {
            Color.clear
        } else if reduceTransparency {
            shape.fill(role == .primary ? Color.appBrand : Color(uiColor: .secondarySystemFill))
        } else {
            glassBackground(shape: shape)
        }
    }

    @ViewBuilder
    private func glassBackground(shape: Capsule) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            switch role {
            case .primary:
                Color.clear
                    .glassEffect(.regular.tint(.appBrand.opacity(0.55)).interactive(), in: shape)
            default:
                Color.clear
                    .glassEffect(.regular.interactive(), in: shape)
            }
        } else {
            fallback(shape: shape)
        }
        #else
        fallback(shape: shape)
        #endif
    }

    @ViewBuilder
    private func fallback(shape: Capsule) -> some View {
        switch role {
        case .primary:
            shape.fill(Color.appBrand)
        default:
            shape.fill(Color(uiColor: .secondarySystemFill))
                .overlay { shape.strokeBorder(Color.appSeparator, lineWidth: 0.5) }
        }
    }
}
