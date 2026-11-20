import SwiftUI

/// 正在洗涤的倒计时卡片。
///
/// 数据只来自 `/order/list` 的 `createTime` + `markMinutes`（官方没有「剩余时间」接口）。
/// 时间由卡片自己的 `TimelineView` 每秒推进，不再由父页面传入 `store.now` ——
/// 父页面因此不会被每秒的计时回调带着重算整张列表。
struct WashProgressCard: View {
    var order: PGOrder
    var alert: DeviceAlert? = nil

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            content(now: context.date)
        }
        .padding(18)
        .flatCard()
    }

    private func content(now: Date) -> some View {
        let remaining = order.remaining(now: now)
        let isDone = remaining <= 0
        let tint: Color = isDone ? Color.appSuccess : Color.appBrand

        return VStack(alignment: .leading, spacing: 14) {
            if let alert {
                alertBar(alert)
            }

            HStack(spacing: 12) {
                AppIconCircle(symbol: isDone ? "checkmark" : "drop.fill",
                              tint: tint,
                              size: Spacing.iconCircleLarge)

                VStack(alignment: .leading, spacing: 3) {
                    Text(isDone ? "洗好了" : "正在洗涤")
                        .font(Typography.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text(subtitle)
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text("\(order.minutes) 分钟")
                    .font(Typography.caption.weight(.medium))
                    .foregroundStyle(.tertiary)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(order.remainingText(now: now))
                    .font(Typography.pageTitle.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(isDone ? Color.appSuccess : Color.primary)
                Text(isDone ? "已完成" : "后洗好")
                    .font(Typography.subheadline)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(order.finishText(now: now))
                    .font(Typography.footnote)
                    .foregroundStyle(.tertiary)
            }

            FlatProgressBar(progress: order.progress(now: now), tint: tint, height: 8)

            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(Typography.caption2)
                Text(order.createTime.isEmpty ? "—" : "开始于 \(order.createTime)")
                    .font(Typography.caption2)
                Spacer(minLength: 0)
                if !order.orderNo.isEmpty {
                    Text(order.orderNo)
                        .font(Typography.caption2.monospaced())
                        .lineLimit(1)
                }
            }
            .foregroundStyle(.tertiary)
        }
    }

    /// 「设备异常，已暂停」这类服务端提示，样式比照官方 App 顶部那条蓝色横幅。
    private func alertBar(_ alert: DeviceAlert) -> some View {
        let tint: Color = alert.isWarning ? Color.appWarning : Color.appBrand

        return HStack(alignment: .top, spacing: 10) {
            Image(systemName: alert.isWarning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .font(Typography.subheadline.weight(.semibold))
                .foregroundStyle(tint)

            VStack(alignment: .leading, spacing: 3) {
                Text(alert.title)
                    .font(Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primary)
                Text(alert.detail)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if alert.isWarning {
                    Text("检查洗衣机门是否关紧；仍然异常就联系商家点「故障上报」。")
                        .font(Typography.caption2)
                        .foregroundStyle(.tertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                .fill(tint.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.m, style: .continuous)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
        )
    }

    private var subtitle: String {
        var parts: [String] = []
        if !order.functionName.isEmpty { parts.append(order.functionName) }
        if !order.title.isEmpty { parts.append(order.title) }
        if !order.shopName.isEmpty { parts.append(order.shopName) }
        return parts.isEmpty ? "洗衣机" : parts.joined(separator: " · ")
    }
}
