import SwiftUI
import UIKit

/// 洗衣首页 —— App Store 那种排法：大标题 + 数据条 + 一张 Hero + 横向货架 + 分组清单。
/// 所有下层页面（订单 / 日志 / 设置 / 充值 / 登录 / 扫码 / 支付）都从这里以 sheet 打开，
/// 页面本身只有一条纵向滚动，没有第二层导航。
struct LaundryStoreHome: View {
    @EnvironmentObject private var store: LaundryStore

    @State private var code = ""
    @State private var showingLogin = false
    @State private var showingScan = false
    @State private var showingPay = false
    @State private var showingRecharge = false
    @State private var showingOrders = false
    @State private var showingLogs = false
    @State private var showingSettings = false
    @State private var confirming: PGSku?

    var body: some View {
        StorePage(title: "洗衣",
                  subtitle: "胖乖生活 · 扫码即用",
                  trailing: AnyView(StoreAvatarButton(symbol: store.loggedIn ? "person.fill" : "person.badge.key.fill") {
                      showingLogin = true
                  })) {
            statsCard
            hero
            codeRow

            if !store.recentDevices.isEmpty {
                StoreShelf(title: "最近用过",
                           subtitle: "\(store.recentDevices.count) 台",
                           actionTitle: "刷新",
                           action: { Task { await store.refreshDevices() } }) {
                    ForEach(store.recentDevices) { item in
                        StoreTile(title: item.name,
                                  subtitle: item.orgName,
                                  symbol: "washer.fill",
                                  tint: Flat.cyan,
                                  badge: item.statusText,
                                  badgeTint: item.isIdle ? Flat.green : Flat.orange) {
                            code = item.goodsId
                            Task { _ = await store.resolve(code: item.goodsId) }
                        }
                    }
                }
            }

            if let device = store.device {
                deviceSection(device)
            }

            if let pending = store.pending {
                pendingSection(pending)
            }

            quickGroup
            accountGroup
            moreGroup
        }
        .refreshable { await store.refreshAll() }
        .sheet(isPresented: $showingLogin) {
            LoginSheet {
                let target = code.trimmingCharacters(in: .whitespaces)
                guard !target.isEmpty else { return }
                Task { _ = await store.resolve(code: target) }
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showingScan) {
            ScanSheet { scanned in
                code = scanned
                Task { _ = await store.resolve(code: scanned) }
            }
        }
        .sheet(isPresented: $showingPay) {
            if let pending = store.pending {
                PaySheet(payment: pending).environmentObject(store)
            }
        }
        .sheet(isPresented: $showingRecharge) {
            RechargeView().environmentObject(store)
        }
        .sheet(isPresented: $showingOrders) {
            NavigationStack { OrdersView() }
                .environmentObject(store)
                .preferredColorScheme(nil)
        }
        .sheet(isPresented: $showingLogs) {
            NavigationStack {
                LaundryLogView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("完成") { showingLogs = false }
                        }
                    }
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                LaundrySettingsView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("完成") { showingSettings = false }
                        }
                    }
            }
            .environmentObject(store)
        }
        .onChange(of: store.needsLogin) { wanted in
            guard wanted else { return }
            store.needsLogin = false
            showingScan = false
            showingLogin = true
        }
        .confirmationDialog(
            confirming.map { "确认下单：\($0.name) \($0.priceText)" } ?? "",
            isPresented: Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } }),
            titleVisibility: .visible
        ) {
            if let sku = confirming {
                Button("用\(PGProtocol.payTitle(store.settings.payType))付 \(sku.priceText)") {
                    let target = sku
                    confirming = nil
                    Task {
                        let ok = await store.placeOrder(sku: target)
                        if ok { showingPay = true }
                    }
                }
                Button("取消", role: .cancel) { confirming = nil }
            }
        }
    }

    // MARK: 数据条

    private var statsCard: some View {
        HStack(spacing: 0) {
            StoreMetric(value: store.user?.balanceText ?? "—", label: "账号余额", tint: Flat.textPrimary)
            Rectangle().fill(Flat.hairline).frame(width: 0.6, height: 32)
            StoreMetric(value: store.shopBalanceText, label: "店铺余额", tint: Flat.orange)
                .padding(.leading, 14)
            Rectangle().fill(Flat.hairline).frame(width: 0.6, height: 32)
            StoreMetric(value: store.orders.isEmpty ? "—" : "\(store.orders.count)", label: "订单",
                        tint: Flat.textPrimary)
                .padding(.leading, 14)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 15)
        .flatCard(radius: 20)
        .padding(.horizontal, 20)
    }

    // MARK: Hero

    @ViewBuilder
    private var hero: some View {
        if let running = store.runningOrder {
            StoreHero(eyebrow: "正在洗涤",
                      title: running.remainingText(now: store.now),
                      subtitle: "\(running.machineName.isEmpty ? "洗衣机" : running.machineName) · \(running.functionName)",
                      symbol: "washer.fill",
                      tint: Flat.green,
                      footnote: running.finishText(now: store.now),
                      primaryTitle: "查看订单",
                      primaryAction: { showingOrders = true },
                      secondaryTitle: nil,
                      secondaryAction: nil)
        } else if let pending = store.pending {
            StoreHero(eyebrow: "待支付",
                      title: pending.price,
                      subtitle: "\(pending.machineName) · \(pending.skuName)",
                      symbol: "creditcard.fill",
                      tint: Flat.orange,
                      footnote: "订单号 \(pending.orderId)",
                      primaryTitle: "去支付",
                      primaryAction: { showingPay = true },
                      secondaryTitle: "撤销",
                      secondaryAction: { Task { await store.cancelPending() } })
        } else {
            StoreHero(eyebrow: store.loggedIn ? "准备就绪" : "还没登录",
                      title: store.loggedIn ? "扫洗衣机上的码" : "先用手机号登录",
                      subtitle: store.loggedIn
                        ? "扫机器码或直接输入编号，选套餐后下单"
                        : "登录后才能识别洗衣机、下单和付款",
                      symbol: store.loggedIn ? "qrcode.viewfinder" : "person.badge.key.fill",
                      tint: Flat.accent,
                      footnote: store.device.map { "当前设备：\($0.name) · \($0.orgName)" },
                      primaryTitle: store.loggedIn ? "扫码开洗" : "去登录",
                      primaryAction: {
                          if store.loggedIn { showingScan = true } else { showingLogin = true }
                      },
                      secondaryTitle: store.loggedIn ? "输入机器码" : nil,
                      secondaryAction: store.loggedIn ? { showingScan = true } : nil)
        }
    }

    private var codeRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "number")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Flat.textTertiary)
                TextField("机器码", text: $code)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Flat.textPrimary)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .onSubmit { query() }
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .flatField(radius: 14)

            Button {
                showingScan = true
            } label: {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Flat.accent)
                    .frame(width: 46, height: 46)
                    .flatCard(radius: 14, fill: Flat.accent.opacity(0.10))
            }
            .buttonStyle(PressScaleStyle(scale: 0.94))

            Button {
                query()
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 46, height: 46)
                    .background(Flat.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(PressScaleStyle(scale: 0.94))
        }
        .padding(.horizontal, 20)
    }

    private func query() {
        let target = code.trimmingCharacters(in: .whitespaces)
        guard !target.isEmpty else { return }
        Task { _ = await store.resolve(code: target) }
    }

    // MARK: 设备与套餐

    @ViewBuilder
    private func deviceSection(_ device: PGDeviceDetail) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if device.hasDeviceError {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Flat.orange)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("设备异常，已暂停")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Flat.textPrimary)
                        Text(device.deviceErrorText)
                            .font(.system(size: 12))
                            .foregroundStyle(Flat.textSecondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(Flat.orange.opacity(0.11), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
            }

            if !device.announcementContent.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Flat.cyan)
                    Text(device.announcementContent)
                        .font(.system(size: 12))
                        .foregroundStyle(Flat.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(Flat.cyan.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal, 20)
            }

            if !store.skus.isEmpty {
                StoreShelf(title: "选个套餐",
                           subtitle: "\(device.name) · \(device.orgName)") {
                    ForEach(store.skus) { sku in
                        skuTile(sku)
                    }
                }
            }
        }
    }

    private func skuTile(_ sku: PGSku) -> some View {
        let card = VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(sku.priceText)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(sku.available ? Flat.accent : Flat.textTertiary)
                Spacer()
                if !sku.available {
                    Text("不可用")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Flat.textTertiary)
                }
            }
            Text(sku.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Flat.textPrimary)
            Text(sku.feature.isEmpty ? sku.unit : sku.feature)
                .font(.system(size: 11.5))
                .foregroundStyle(Flat.textTertiary)
                .lineLimit(2)
            Spacer(minLength: 0)
            Text(sku.available ? "立即下单" : "—")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(sku.available ? Flat.accent : Flat.textTertiary)
        }
        .frame(width: 152, height: 132, alignment: .topLeading)
        .flatCard(radius: 20)

        return Button {
            guard sku.available else { return }
            confirming = sku
        } label: {
            card
        }
        .buttonStyle(PressScaleStyle())
    }

    @ViewBuilder
    private func pendingSection(_ pending: PendingPayment) -> some View {
        StoreGroup(title: "待处理") {
            StoreRow(icon: "clock.badge.exclamationmark.fill",
                     tint: Flat.orange,
                     title: "\(pending.skuName) · \(pending.price)",
                     detail: pending.machineName,
                     value: PGProtocol.payTitle(pending.payType),
                     action: { showingPay = true })
        }
    }

    // MARK: 分组

    private var quickGroup: some View {
        StoreGroup(title: "常用") {
            StoreRow(icon: "list.bullet.rectangle.portrait.fill",
                     tint: Flat.purple,
                     title: "我的订单",
                     detail: store.orders.isEmpty ? nil : "共 \(store.orders.count) 笔",
                     action: { showingOrders = true })
            StoreDivider()
            StoreRow(icon: "arrow.triangle.2.circlepath",
                     tint: Flat.cyan,
                     title: "刷新数据",
                     detail: "账号 · 设备 · 订单",
                     showsChevron: false,
                     action: { Task { await store.refreshAll() } })
            StoreDivider()
            StoreRow(icon: "washer.fill",
                     tint: Flat.green,
                     title: "我的洗衣机",
                     detail: store.device.map { "\($0.name) · \($0.orgName)" } ?? "还没选机器",
                     showsChevron: false,
                     action: { Task { await store.refreshDevices() } })
        }
    }

    private var accountGroup: some View {
        StoreGroup(title: "账户") {
            StoreRow(icon: "person.fill",
                     tint: Flat.accent,
                     title: store.loggedIn ? (store.user?.phone ?? "已登录") : "登录账号",
                     detail: store.loggedIn ? "点击切换或退出" : "手机号 + 短信验证码",
                     action: { showingLogin = true })
            StoreDivider()
            StoreRow(icon: "creditcard.fill",
                     tint: Flat.orange,
                     title: "充值店铺余额",
                     detail: "官方 H5 充值页",
                     action: { showingRecharge = true })
            StoreDivider()
            StoreRow(icon: "checkmark.seal.fill",
                     tint: Flat.green,
                     title: "默认支付方式",
                     value: PGProtocol.payTitle(store.settings.payType),
                     action: { showingSettings = true })
        }
    }

    private var moreGroup: some View {
        StoreGroup(title: "其它") {
            StoreRow(icon: "text.alignleft",
                     tint: Flat.textSecondary,
                     title: "运行日志",
                     detail: "\(store.logs.count) 行",
                     action: { showingLogs = true })
            StoreDivider()
            StoreRow(icon: "gearshape.fill",
                     tint: Flat.textSecondary,
                     title: "设置",
                     detail: "启动检测 · 自动刷新",
                     action: { showingSettings = true })
        }
    }
}
