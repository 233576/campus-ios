import SwiftUI

/// 三种语义，三种视觉，不许混用。
///
/// | 语义 | 组件 | 右侧 | 点击后 |
/// | --- | --- | --- | --- |
/// | 跳转 | `NavigationRow` | `chevron.right` | 必然 push 一个子页面 |
/// | 原地动作 | `ActionRow` | 动作图标（无 chevron） | 必然原地执行并给反馈 |
/// | 主要动作 | `GlassButtonStyle` | — | 提交表单 / 执行主操作 |
///
/// 以前「检测状态」「换绑到本机」也挂了 chevron，用户以为是跳转，
/// 点了却原地执行，观感割裂。现在 chevron 只有一个含义：有下一页。

// MARK: - 跳转

/// 列表行 + chevron，只用于 push。
struct NavigationRow<Destination: Hashable>: View {
    var symbol: String
    var title: String
    var detail: String?
    var badge: String?
    var value: Destination

    init(symbol: String,
         title: String,
         detail: String? = nil,
         badge: String? = nil,
         value: Destination) {
        self.symbol = symbol
        self.title = title
        self.detail = detail
        self.badge = badge
        self.value = value
    }

    var body: some View {
        NavigationLink(value: value) {
            HStack(spacing: Spacing.m) {
                AppIconCircle(symbol: symbol)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title).font(Typography.rowTitle)
                    if let detail {
                        Text(detail)
                            .font(Typography.rowSubtitle)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: Spacing.s)

                if let badge {
                    Text(badge)
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, Spacing.xxs)
            .frame(minHeight: Spacing.rowMinHeight)
        }
    }
}

// MARK: - 原地动作

/// 列表行 + 动作图标（无 chevron），点击原地执行。
///
/// 执行中显示 `ProgressView` 并自动禁用；执行结果由调用方弹 Toast。
struct ActionRow: View {
    var symbol: String
    var title: String
    var detail: String?
    var trailingSymbol: String
    var tint: Color
    var isBusy: Bool
    var isEnabled: Bool
    var action: () -> Void

    init(symbol: String,
         title: String,
         detail: String? = nil,
         trailingSymbol: String = "arrow.clockwise",
         tint: Color = .appBrand,
         isBusy: Bool = false,
         isEnabled: Bool = true,
         action: @escaping () -> Void) {
        self.symbol = symbol
        self.title = title
        self.detail = detail
        self.trailingSymbol = trailingSymbol
        self.tint = tint
        self.isBusy = isBusy
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                AppIconCircle(symbol: symbol, tint: tint)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title).font(Typography.rowTitle)
                    if let detail {
                        Text(detail)
                            .font(Typography.rowSubtitle)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: Spacing.s)

                if isBusy {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: trailingSymbol)
                        .font(Typography.subheadline)
                        .foregroundStyle(tint)
                }
            }
            .padding(.vertical, Spacing.xxs)
            .frame(minHeight: Spacing.rowMinHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isBusy)
        .opacity(isEnabled ? 1 : 0.45)
    }
}

// MARK: - 破坏性动作

/// 重置 / 恢复默认这类动作，用系统红或橙色 + 无 chevron。
struct DestructiveRow: View {
    var symbol: String
    var title: String
    var detail: String?
    var role: ButtonRole?
    var action: () -> Void

    init(symbol: String,
         title: String,
         detail: String? = nil,
         role: ButtonRole? = .destructive,
         action: @escaping () -> Void) {
        self.symbol = symbol
        self.title = title
        self.detail = detail
        self.role = role
        self.action = action
    }

    private var tint: Color { role == .destructive ? .appDanger : .appWarning }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                AppIconCircle(symbol: symbol, tint: tint)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(Typography.rowTitle)
                        .foregroundStyle(tint)
                    if let detail {
                        Text(detail)
                            .font(Typography.rowSubtitle)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: Spacing.s)

                Image(systemName: "arrow.counterclockwise")
                    .font(Typography.subheadline)
                    .foregroundStyle(tint)
            }
            .padding(.vertical, Spacing.xxs)
            .frame(minHeight: Spacing.rowMinHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
