import SwiftUI
import UIKit

/// 设备与套餐分组。
struct LaundryDeviceSection: View {
    @EnvironmentObject private var store: LaundryStore

    var device: PGDeviceDetail
    @Binding var confirming: PGSku?

    var body: some View {
        Section {
            if device.hasDeviceError {
                alertRow(
                    symbol: "exclamationmark.triangle.fill",
                    tint: .appWarning,
                    title: "设备异常，已暂停",
                    message: device.deviceErrorText
                )
            }
            if !device.announcementContent.isEmpty {
                alertRow(
                    symbol: "megaphone.fill",
                    tint: .appBrand,
                    title: "公告",
                    message: device.announcementContent
                )
            }
            ForEach(store.skus) { sku in
                Button {
                    confirming = sku
                } label: {
                    skuRow(sku)
                }
                .buttonStyle(.plain)
            }
            if store.skus.isEmpty {
                Text("这台机器暂时没有可选套餐")
                    .font(Typography.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            HStack {
                Text(device.name.isEmpty ? "洗衣机" : device.name)
                Spacer()
                if !device.serviceTelephone.isEmpty {
                    Button {
                        if let url = URL(string: "tel://\(device.serviceTelephone)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(Typography.caption)
                            .foregroundStyle(Color.appBrand)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("致电客服")
                }
            }
        } footer: {
            if !device.subtitle.isEmpty {
                Text(device.subtitle)
                    .font(Typography.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func skuRow(_ sku: PGSku) -> some View {
        HStack(spacing: Spacing.m) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(sku.name.isEmpty ? "标准洗" : sku.name)
                    .font(Typography.rowTitle)
                if !sku.feature.isEmpty {
                    Text(sku.feature)
                        .font(Typography.rowSubtitle)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: Spacing.s)
            Text(sku.priceText)
                .font(Typography.monoValue.weight(.semibold))
                .foregroundStyle(sku.available ? Color.appBrand : Color.secondary)
            Image(systemName: "cart.badge.plus")
                .font(Typography.subheadline)
                .foregroundStyle(sku.available ? Color.appBrand : Color.secondary)
        }
        .contentShape(Rectangle())
        .opacity(sku.available ? 1 : 0.5)
    }

    private func alertRow(symbol: String, tint: Color, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.s) {
            Image(systemName: symbol)
                .font(Typography.caption.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: Spacing.l)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(Typography.footnote.weight(.semibold))
                Text(message)
                    .font(Typography.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}

/// 最近用过的洗衣机。
struct LaundryRecentSection: View {
    @EnvironmentObject private var store: LaundryStore

    var body: some View {
        Section("最近用过") {
            ForEach(store.recentDevices) { item in
                Button {
                    Task { await store.selectDevice(goodsId: item.goodsId) }
                } label: {
                    HStack(spacing: Spacing.m) {
                        AppIconCircle(symbol: "washer.fill", tint: .appBrand)
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(item.name.isEmpty ? "洗衣机" : item.name)
                                .font(Typography.rowTitle)
                                .lineLimit(1)
                            Text(item.orgName.isEmpty ? item.statusText : item.orgName)
                                .font(Typography.rowSubtitle)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer(minLength: Spacing.s)
                        if store.device?.goodsId == item.goodsId {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.appBrand)
                        } else {
                            Text("切换")
                                .font(Typography.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// 待支付订单。
struct LaundryPendingSection: View {
    var pending: PendingPayment
    var pay: () -> Void

    var body: some View {
        Section {
            HStack(spacing: Spacing.m) {
                AppIconCircle(symbol: "clock.badge.exclamationmark.fill", tint: .appWarning)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("有 1 笔待支付")
                        .font(Typography.rowTitle)
                    Text(pending.machineName.isEmpty ? pending.orderId : pending.machineName)
                        .font(Typography.rowSubtitle)
                        .foregroundStyle(.secondary)
                    Text("\(PGProtocol.payTitle(pending.payType)) · ¥\(pending.price.isEmpty ? "0.00" : pending.price)")
                        .font(Typography.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: Spacing.s)
                Button("去支付", action: pay)
                    .buttonStyle(GlassButtonStyle(role: .secondary, fullWidth: false))
                    .frame(height: 32)
            }
            .padding(.vertical, Spacing.xxs)
        }
    }
}
