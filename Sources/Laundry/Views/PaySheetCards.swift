import SwiftUI

/// 支付面板里的各张卡片。
///
/// 从 PaySheet 拆出来，主文件只留状态与动作，各卡片单独可读。
extension PaySheet {
    private var amountCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("待支付")
                .font(Typography.caption.weight(.medium))
                .foregroundStyle(Flat.textTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("¥")
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(Flat.textSecondary)
                Text(current.price.isEmpty ? "0.00" : current.price)
                    .font(Typography.pageTitle.weight(.bold))
                    .foregroundStyle(Flat.textPrimary)
                Spacer()
            }

            Text(current.skuName.isEmpty ? current.machineName : current.skuName)
                .font(Typography.subheadline.weight(.medium))
                .foregroundStyle(Flat.textPrimary)

            Text(current.machineName)
                .font(Typography.caption)
                .foregroundStyle(Flat.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .flatCard()
    }

    private var channelPicker: some View {
        HStack(spacing: 8) {
            chip("微信支付", tint: Flat.green, type: PGProtocol.payTypeWeChat)
            chip("支付宝", tint: Flat.accent, type: PGProtocol.payTypeAlipay)
            chip("余额", tint: Flat.orange, type: PGProtocol.payTypeWallet)
        }
    }

    func chip(_ title: String, tint: Color, type: Int) -> some View {
        Button {
            guard current.payType != type, !switching else { return }
            Task { await switchTo(type) }
        } label: {
            HStack(spacing: 5) {
                if switching && current.payType != type {
                    ProgressView().tint(tint).scaleEffect(0.6)
                }
                Text(title)
                    .font(Typography.footnote.weight(.semibold))
                    .foregroundStyle(current.payType == type ? tint : Flat.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: Flat.controlRadius, style: .continuous)
                .fill(current.payType == type ? tint.opacity(0.16) : Flat.surfaceHigh)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Flat.controlRadius, style: .continuous)
                .strokeBorder(current.payType == type ? tint.opacity(0.55) : Flat.stroke, lineWidth: 1)
        )
        .disabled(switching)
    }

    @ViewBuilder
    private var balanceCard: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Flat.orange.opacity(0.16)).frame(width: 40, height: 40)
                Image(systemName: "wallet.bifold.fill")
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(Flat.orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("账号余额")
                    .font(Typography.caption)
                    .foregroundStyle(Flat.textTertiary)
                Text("¥ \(balanceText)")
                    .font(Typography.body.weight(.semibold))
                    .foregroundStyle(Flat.textPrimary)
                Text("店铺余额 \(store.shopBalanceText)")
                    .font(Typography.caption2)
                    .foregroundStyle(store.shopBalanceTotal > 0 ? Flat.green : Flat.textTertiary)
            }

            Spacer()

            Button {
                showingRecharge = true
            } label: {
                Text("去充值")
                    .font(Typography.footnote.weight(.semibold))
                    .foregroundStyle(Flat.orange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Flat.orange.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .flatCard()
    }

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow("订单号", current.orderId, mono: true)
            FlatDivider(inset: 14)
            infoRow("网点", current.orgName.isEmpty ? "—" : current.orgName)
            FlatDivider(inset: 14)
            infoRow("支付方式", PGProtocol.payTitle(payType))
            FlatDivider(inset: 14)
            infoRow("支付串", current.prepayParam.isEmpty
                    ? "空（点重新取支付串）"
                    : "\(current.prepayParam.count) 字符")
            if !current.prepayParam.isEmpty {
                FlatDivider(inset: 14)
                Button {
                    showParam.toggle()
                } label: {
                    HStack {
                        Text(showParam ? "收起支付串" : "查看支付串全文")
                            .font(Typography.caption)
                            .foregroundStyle(Flat.accent)
                        Spacer()
                        Image(systemName: showParam ? "chevron.up" : "chevron.down")
                            .font(Typography.caption2.weight(.semibold))
                            .foregroundStyle(Flat.textTertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                if showParam {
                    Text(current.prepayParam)
                        .font(Typography.mono)
                        .foregroundStyle(Flat.textTertiary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }
            }
            if !store.lastPrepayRaw.isEmpty {
                FlatDivider(inset: 14)
                Button {
                    showRaw.toggle()
                } label: {
                    HStack {
                        Text(showRaw ? "收起原始响应" : "查看原始响应")
                            .font(Typography.caption)
                            .foregroundStyle(Flat.accent)
                        Spacer()
                        Image(systemName: showRaw ? "chevron.up" : "chevron.down")
                            .font(Typography.caption2.weight(.semibold))
                            .foregroundStyle(Flat.textTertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                if showRaw {
                    Text(store.lastPrepayRaw)
                        .font(Typography.mono)
                        .foregroundStyle(Flat.textTertiary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }
            }
        }
        .padding(.vertical, 2)
        .flatCard(fill: Flat.surfaceLow)
    }

    func infoRow(_ title: String, _ value: String, mono: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(Typography.footnote)
                .foregroundStyle(Flat.textTertiary)
            Spacer(minLength: 12)
            Text(value)
                .font(mono ? Typography.mono.weight(.medium)
                           : Typography.footnote.weight(.medium))
                .foregroundStyle(Flat.textSecondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var actionList: some View {
        VStack(spacing: 10) {
            if payType == PGProtocol.payTypeWallet {
                Button {
                    Task { await payWithWallet() }
                } label: {
                    HStack(spacing: 8) {
                        if paying {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Text(paying ? "支付中…" : "立即用余额支付")
                            .font(Typography.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(FlatButtonStyle(tint: Flat.accent, filled: true, height: 50))
                .disabled(paying)
            } else {
                Button {
                    openPayTarget()
                } label: {
                    Text("打开\(PGProtocol.payTitle(payType))付款")
                        .font(Typography.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(FlatButtonStyle(
                    tint: payType == PGProtocol.payTypeWeChat ? Flat.green : Flat.accent,
                    filled: true, height: 50))
                .disabled(switching)

                Button {
                    UIPasteboard.general.string = current.prepayParam
                    alertMessage = "支付串已复制（\(current.prepayParam.count) 字符）"
                } label: {
                    Text("复制支付串")
                        .font(Typography.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(FlatButtonStyle(tint: Flat.textSecondary, filled: false, height: 46))
            }

            Button {
                Task { await refreshStatus() }
            } label: {
                Text("我付好了，查状态")
                    .font(Typography.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
            }
            .buttonStyle(FlatButtonStyle(tint: Flat.green, filled: false, height: 46))

            HStack(spacing: 10) {
                Button("重新取支付串") {
                    Task { await reprepare() }
                }
                .buttonStyle(FlatButtonStyle(tint: Flat.accent, filled: false, height: 44))

                Button("撤销订单") {
                    Task { await cancelOrder() }
                }
                .buttonStyle(FlatButtonStyle(tint: Flat.red, filled: false, height: 44))
            }
        }
    }

}
