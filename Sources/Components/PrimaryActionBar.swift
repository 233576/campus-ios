import SwiftUI

/// 底部悬浮操作栏：玻璃胶囊底座 + 实色主按钮 +（可选）禁用原因。
///
/// 玻璃底座与 `FloatingTabBar` 用同一份写法——`glassEffect` 那一行逐字符一致，
/// 只有圆角数值不同（底栏 26，这里 22）。底座上不再叠任何 `Color` /
/// `.ultraThinMaterial`，否则暗色下会退化成一块灰板。
///
/// 按钮本身是实色，不参与玻璃，避免「玻璃叠玻璃」。
struct PrimaryActionBar: View {
    /// 按钮标题，忙碌时由调用方直接换文案。
    var title: String
    /// 忙碌态：显示菊花并禁用。
    var isBusy: Bool = false
    /// 是否禁用（不含忙碌，忙碌在内部一起算）。
    var isDisabled: Bool = false
    /// 禁用原因，`nil` 表示不需要提示。
    var hint: String?
    var action: () -> Void

    /// 按钮实际是否可点。
    private var blocked: Bool { isBusy || isDisabled }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Button(action: action) {
                HStack(spacing: Spacing.s) {
                    if isBusy {
                        ProgressView().tint(.white)
                    }
                    Text(title)
                        .font(Typography.headline)
                }
                .foregroundStyle(blocked ? Color(uiColor: .tertiaryLabel) : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background {
                    RoundedRectangle(cornerRadius: Radius.control, style: .continuous)
                        .fill(blocked
                              ? Color(uiColor: .tertiarySystemFill)
                              : Color.appBrand)
                }
            }
            .buttonStyle(.plain)
            .disabled(blocked)
        }
        .padding(.horizontal, Spacing.l)
        .padding(.vertical, Spacing.s)
        .frame(minHeight: 52)
        .background { surface }
        .padding(.horizontal, FloatingTabBarMetrics.horizontalInset)
        .padding(.bottom, FloatingTabBarMetrics.totalHeight + 10)
        .animation(.easeInOut(duration: 0.25), value: blocked)
    }

    /// 与 TabBar 同一份玻璃写法，只改圆角数值。
    @ViewBuilder
    private var surface: some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)

        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular.interactive(), in: shape)
        } else {
            shape.fill(.ultraThinMaterial)
        }
        #else
        shape.fill(.ultraThinMaterial)
        #endif
    }
}
