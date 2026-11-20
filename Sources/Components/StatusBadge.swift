import SwiftUI

enum StatusBadgeKind {
    case neutral
    case success
    case warning
    case danger
    case brand

    var tint: Color {
        switch self {
        case .neutral: return Color(uiColor: .secondaryLabel)
        case .success: return .appSuccess
        case .warning: return .appWarning
        case .danger: return .appDanger
        case .brand: return .appBrand
        }
    }
}

/// 胶囊徽标：15% 语义色底 + 语义前景。
struct StatusBadge: View {
    var text: String
    var kind: StatusBadgeKind = .neutral

    init(_ text: String, kind: StatusBadgeKind = .neutral) {
        self.text = text
        self.kind = kind
    }

    var body: some View {
        Text(text)
            .font(Typography.caption2.weight(.semibold))
            .foregroundStyle(kind.tint)
            .padding(.horizontal, Spacing.s)
            .padding(.vertical, Spacing.xxs + 1)
            .background(Capsule(style: .continuous).fill(kind.tint.opacity(0.15)))
    }
}
