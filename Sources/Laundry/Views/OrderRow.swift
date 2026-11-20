import SwiftUI

/// 订单行。
///
/// 性能要点（这一版的重点都在这里）：
/// - 所有展示字段在 `init` 里一次算好，`body` 里不再做日期 / 金额格式化；
/// - 实现 `Equatable`，父视图用 `.equatable()` 挂上，`store.now` 每秒跳动时
///   这些行不会被重算；
/// - 倒计时单独拆成 `OrderCountdown`，由 `TimelineView` 自驱，不读 `store.now`。
struct OrderRow: View, Equatable {
    let title: String
    let subtitle: String
    let statusText: String
    let badge: StatusBadgeKind
    let amountText: String
    let shopName: String
    let isUnpaid: Bool
    let order: PGOrder

    init(order: PGOrder) {
        self.order = order
        self.title = order.title
        self.statusText = order.displayStatusText
        self.amountText = order.amountText
        self.shopName = order.shopName
        self.isUnpaid = order.isUnpaid
        self.badge = Self.badgeKind(order.status)

        var parts: [String] = []
        if !order.createTime.isEmpty { parts.append(order.createTime) }
        if !order.orderNo.isEmpty { parts.append(order.orderNo) }
        parts.append("#\(order.status)")
        self.subtitle = parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .top, spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title).font(Typography.rowTitle)
                    Text(subtitle)
                        .font(Typography.rowSubtitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: Spacing.xs)
                StatusBadge(statusText, kind: badge)
            }

            if order.isPaid {
                OrderCountdown(order: order)
            }

            HStack(spacing: Spacing.s) {
                Text(amountText)
                    .font(Typography.monoValue.weight(.semibold))
                if !shopName.isEmpty {
                    Text(shopName)
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }

    static func badgeKind(_ status: Int) -> StatusBadgeKind {
        switch status {
        case 0: return .warning
        case 1: return .neutral
        case 2: return .brand
        case 3: return .success
        case 5, 6: return .brand
        default: return .neutral
        }
    }

    static func == (lhs: OrderRow, rhs: OrderRow) -> Bool {
        lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
            && lhs.statusText == rhs.statusText
            && lhs.badge == rhs.badge
            && lhs.amountText == rhs.amountText
            && lhs.shopName == rhs.shopName
            && lhs.isUnpaid == rhs.isUnpaid
    }
}

/// 洗涤倒计时。整点自己走，不订阅 store，避免整张列表跟着每秒重算。
struct OrderCountdown: View {
    let order: PGOrder

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date
            let remaining = order.remaining(now: now)

            if remaining > 0 {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Text(order.remainingText(now: now))
                            .font(Typography.monoValue.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(Color.appBrand)
                        Text("后洗好").font(Typography.footnote).foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Text(order.finishText(now: now))
                            .font(Typography.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    ProgressView(value: order.progress(now: now))
                        .tint(Color.appBrand)
                }
            }
        }
    }
}
