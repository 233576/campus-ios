import SwiftUI
import UIKit

/// 设置页：账号、支付方式、自动检测、接口信息、关于。
///
/// 全部走 AppList Section，卡片嵌套层级归零；支付方式改标准 List 单选行。
struct LaundrySettingsView: View {
    @EnvironmentObject private var store: LaundryStore

    @State private var showingLogin = false
    @State private var showingRecharge = false
    @State private var copiedToken: String?

    var body: some View {
        AppList {
            accountSection
            paySection
            refreshSection
            endpointSection
            aboutSection
        }
        .appNavigation(title: "洗衣设置")
        .sheet(isPresented: $showingLogin) {
            LoginSheet().environmentObject(store)
        }
        .sheet(isPresented: $showingRecharge) {
            RechargeView().environmentObject(store)
        }
    }

    // MARK: - 账号

    private var accountSection: some View {
        Section {
            if store.loggedIn {
                HStack(spacing: Spacing.m) {
                    AppIconCircle(symbol: "person.fill", tint: .appBrand)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(store.phoneText).font(Typography.rowTitle)
                        Text("余额 \(store.user?.balanceText ?? "—") · 店铺 \(store.shopBalanceText)")
                            .font(Typography.rowSubtitle)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: Spacing.s)
                    StatusBadge(store.user?.hasVip == true ? "会员" : "普通",
                                kind: store.user?.hasVip == true ? .brand : .neutral)
                }
                .padding(.vertical, Spacing.xxs)

                Button("退出登录", role: .destructive) { store.logout() }
                    .font(Typography.body)
            } else {
                Button("手机号登录") { showingLogin = true }
                    .font(Typography.headline)
                    .frame(maxWidth: .infinity, minHeight: Spacing.rowMinHeight)
            }
        } header: {
            Text("账号")
        } footer: {
            Text(store.loggedIn
                 ? "登录凭证存在钥匙串，重新打开 App 会自动恢复。"
                 : "还没有登录。登录一次，之后打开 App 会自动检测状态。")
                .font(Typography.caption2)
        }
    }

    // MARK: - 支付方式

    private var paySection: some View {
        Section {
            payRow(title: "微信支付",
                   detail: "下单后出微信付款码 / 唤起微信",
                   symbol: "message.fill",
                   type: PGProtocol.payTypeWeChat)
            payRow(title: "支付宝",
                   detail: "下单后出支付宝付款码",
                   symbol: "a.circle.fill",
                   type: PGProtocol.payTypeAlipay)
            payRow(title: "余额支付",
                   detail: "直接扣余额，余额 ¥\(store.user?.balanceText ?? "—")",
                   symbol: "wallet.bifold.fill",
                   type: PGProtocol.payTypeWallet)

            Button("充值店铺余额") { showingRecharge = true }
                .font(Typography.body)
                .foregroundStyle(Color.appBrand)
                .frame(maxWidth: .infinity, minHeight: Spacing.rowMinHeight)
        } header: {
            Text("默认支付方式")
        } footer: {
            Text("支付面板里还能随时换渠道，订单号不变。余额不足时用微信/支付宝扫码即可。")
                .font(Typography.caption2)
        }
    }

    private func payRow(title: String, detail: String, symbol: String, type: Int) -> some View {
        Button {
            store.setPayType(type)
        } label: {
            HStack(spacing: Spacing.m) {
                AppIconCircle(symbol: symbol, tint: .appBrand)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title).font(Typography.rowTitle)
                    Text(detail)
                        .font(Typography.rowSubtitle)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: Spacing.s)
                if store.settings.payType == type {
                    Image(systemName: "checkmark")
                        .font(Typography.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appBrand)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - 自动检测

    private var refreshSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { store.settings.autoRefresh },
                set: { store.setAutoRefresh($0) }
            )) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("打开 App 等 2 秒自动查状态").font(Typography.rowTitle)
                    Text("关掉就只在你手动点的时候刷新")
                        .font(Typography.rowSubtitle)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("启动自动检测")
        }
    }

    // MARK: - 接口信息

    private var endpointSection: some View {
        Section("接口信息") {
            infoRow("服务地址", PGProtocol.base)
            infoRow("通道", PGProtocol.channel)
            infoRow("客户端版本", "\(PGProtocol.appVersion) (\(PGProtocol.versionCode))")
            infoRow("分类", PGProtocol.categoryCode)
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Text(title)
                .font(Typography.footnote)
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .leading)
            Text(value)
                .font(Typography.footnote)
                .textSelection(.enabled)
            Spacer(minLength: 0)
        }
        .padding(.vertical, Spacing.xxs)
    }

    // MARK: - 关于

    private var aboutSection: some View {
        Section {
            infoRow("版本", Self.appVersion)
            Button {
                let token = store.loginToken()
                guard !token.isEmpty else {
                    copiedToken = "还没登录，没有凭证"
                    return
                }
                UIPasteboard.general.string = token
                copiedToken = "已复制 \(token.count) 个字符"
            } label: {
                HStack {
                    Text("复制登录凭证（调试）").font(Typography.body)
                    Spacer()
                    if let copiedToken {
                        Text(copiedToken)
                            .font(Typography.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } header: {
            Text("关于")
        } footer: {
            Text("协议参考 Cumpus / wash / baotuquan-light 三个开源项目，只复刻了洗衣机（categoryCode=wash）这一条链路：扫码 → 选套餐 → 下单 → 扫码支付 → 查订单。")
                .font(Typography.caption2)
        }
    }

    static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}
