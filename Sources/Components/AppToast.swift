import SwiftUI

/// 轻量结果提示。动作类交互（检测状态、换绑、保存）执行完用它给反馈，
/// 而不是弹 alert 打断。
///
/// 用法：
/// ```swift
/// @State private var toast: String?
/// ...
/// .appToast($toast)
/// ```
struct ToastModifier: ViewModifier {
    @Binding var text: String?
    var duration: Double = 2.4

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let text {
                    ToastBubble(text: text)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.bottom, Spacing.xxl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .task(id: text) {
                            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                            guard !Task.isCancelled else { return }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                self.text = nil
                            }
                        }
                        .allowsHitTesting(false)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.9), value: text)
    }
}

private struct ToastBubble: View {
    var text: String

    var body: some View {
        Text(text)
            .font(Typography.footnote)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Spacing.l)
            .padding(.vertical, Spacing.s)
            .background {
                Capsule(style: .continuous)
                    .fill(Color(uiColor: .darkGray).opacity(0.92))
            }
            .accessibilityAddTraits(.isStaticText)
    }
}

extension View {
    /// 绑定一个可空字符串，非空时在底部浮出气泡，`duration` 秒后自动消失。
    func appToast(_ text: Binding<String?>, duration: Double = 2.4) -> some View {
        modifier(ToastModifier(text: text, duration: duration))
    }
}
