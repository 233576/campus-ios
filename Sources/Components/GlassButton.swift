import SwiftUI

/// 三态玻璃按钮。
///
/// - primary：主操作，玻璃醒目态（iOS 26）/ 实心品牌色（低版本）
/// - secondary：次要操作，普通玻璃（低版本为浅灰）
/// - plain：纯文字
///
/// 玻璃只允许出现在这些浮动控件上，列表行里一律用 secondary 的实心降级。
enum GlassButtonRole {
    case primary
    case secondary
    case plain
}

struct GlassButtonStyle: ButtonStyle {
    var role: GlassButtonRole = .primary
    var fullWidth: Bool = true

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
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.9), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch role {
        case .primary: return .white
        case .secondary: return .appBrand
        case .plain: return .appBrand
        }
    }

    @ViewBuilder
    private var background: some View {
        let shape = Capsule(style: .continuous)
        switch role {
        case .primary:
            #if compiler(>=6.2)
            if #available(iOS 26.0, *), !reduceTransparency {
                Color.clear
                    .glassEffect(.regular.tint(.appBrand.opacity(0.55)).interactive(), in: shape)
            } else {
                shape.fill(Color.appBrand)
            }
            #else
            shape.fill(Color.appBrand)
            #endif
        case .secondary:
            #if compiler(>=6.2)
            if #available(iOS 26.0, *), !reduceTransparency {
                Color.clear.glassEffect(.regular.interactive(), in: shape)
            } else {
                shape.fill(Color.appTertiaryFill)
            }
            #else
            shape.fill(Color.appTertiaryFill)
            #endif
        case .plain:
            Color.clear
        }
    }
}
