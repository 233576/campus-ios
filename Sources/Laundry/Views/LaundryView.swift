import SwiftUI
import UIKit

/// 洗衣主页：账号 → 机器码 → 设备与套餐 → 最近用过 → 待支付。
///
/// 结构走 AppList（insetGrouped），不再用「大卡片套小卡片」。
/// 唯一保留的卡片是顶部洗涤进度 —— 它是全局状态，不属于任何分组。
struct LaundryView: View {
    @EnvironmentObject private var store: LaundryStore

    @State private var code = ""
    @State private var showingLogin = false
    @State private var showingScan = false
    @State private var showingPay = false
    @State private var showingRecharge = false
    @State private var confirming: PGSku?

    var body: some View {
        VStack(spacing: 0) {
            if let order = progressOrder {
                WashProgressCard(order: order, now: store.now, alert: store.activeAlert)
                    .padding(.horizontal, Spacing.page)
                    .padding(.top, Spacing.s)
                    .padding(.bottom, Spacing.xs)
            }
            AppList {
                accountSection
                navigationSection
                codeSection
                if let device = store.device {
                    LaundryDeviceSection(device: device, confirming: $confirming)
                } else {
                    emptySection
                }
                if !store.recentDevices.isEmpty {
                    LaundryRecentSection()
                }
                if let pending = store.pending {
                    LaundryPendingSection(pending: pending) { showingPay = true }
                }
            }
        }
        .appNavigation(title: "胖乖洗衣", subtitle: "洗衣机 · 扫码即用")
        .toolbarBackground(.automatic, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                GlassToolbarButton(symbol: "arrow.clockwise", label: "刷新") {
                    Task { await store.refreshAll() }
                }
                .disabled(store.isBusy)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .sheet(isPresented: $showingLogin) {
            LoginSheet {
                let target = code.trimmingCharacters(in: .whitespaces)
                guard !target.isEmpty else { return }
                Task { _ = await store.resolve(code: target) }
            }
            .environmentObject(store)
        }
        .onChange(of: store.needsLogin) { wanted in
            guard wanted else { return }
            store.needsLogin = false
            showingScan = false
            showingLogin = true
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
        .confirmationDialog(
            confirming.map { "确认下单：\($0.name) \($0.priceText)" } ?? "",
            isPresented: Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } }),
            titleVisibility: .visible
        ) {
            if let sku = confirming {
                Button("用\(PGProtocol.payTitle(store.settings.payType))付 \(sku.priceText)") {
                    confirming = nil
                    Task {
                        let ok = await store.placeOrder(sku: sku)
                        if ok { showingPay = true }
                    }
                }
                Button("取消", role: .cancel) { confirming = nil }
            }
        } message: {
            Text("付款后洗衣机才会启动；未付款的订单可以在订单页撤销。")
        }
        .alert("提示", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("知道了", role: .cancel) { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .alert("已完成", isPresented: Binding(
            get: { store.noticeMessage != nil },
            set: { if !$0 { store.noticeMessage = nil } }
        )) {
            Button("好", role: .cancel) { store.noticeMessage = nil }
        } message: {
            Text(store.noticeMessage ?? "")
        }
    }

    // MARK: - 分组

    private var accountSection: some View {
        Section {
            HStack(spacing: Spacing.m) {
                ZStack {
                    Circle().fill(Color(uiColor: .quaternarySystemFill))
                    Image(systemName: store.loggedIn ? "person.fill" : "person.crop.circle.badge.questionmark")
                        .font(Typography.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appBrand)
                }
                .frame(width: Spacing.iconCircleLarge, height: Spacing.iconCircleLarge)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(store.loggedIn ? store.phoneText : "未登录")
                        .font(Typography.rowTitle)
                    Text(accountSubtitle)
                        .font(Typography.rowSubtitle)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: Spacing.s)

                if store.loggedIn {
                    Button("充值") { showingRecharge = true }
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(Color.appWarning)
                        .buttonStyle(.plain)
                        .frame(minWidth: Spacing.rowMinHeight, minHeight: Spacing.rowMinHeight)
                } else {
                    Button("登录") { showingLogin = true }
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.m)
                        .frame(height: 32)
                        .background(Capsule().fill(Color.appBrand))
                        .buttonStyle(.plain)
                }
            }
            .padding(.vertical, Spacing.xs)
        } footer: {
            if store.loggedIn {
                Button("退出登录", role: .destructive) { store.logout() }
                    .font(Typography.footnote)
            }
        }
    }

    /// 模块内的二级页面入口。以前这三项占了 TabBar，现在只是栈里的一层。
    private var navigationSection: some View {
        Section {
            NavigationRow(symbol: "list.bullet.rectangle.portrait",
                          title: "我的订单",
                          badge: store.loggedIn ? "\(store.orders.count) 条" : nil,
                          value: LaundryRoute.orders)
            NavigationRow(symbol: "text.alignleft",
                          title: "请求日志",
                          badge: "\(store.logs.count) 行",
                          value: LaundryRoute.logs)
            NavigationRow(symbol: "gearshape",
                          title: "洗衣设置",
                          value: LaundryRoute.settings)
        }
    }

    private var accountSubtitle: String {
        guard store.loggedIn else { return "手机号 + 验证码，10 秒登录" }
        let vip = store.user?.hasVip == true ? " · 会员" : ""
        return "余额 \(store.user?.balanceText ?? "—") · 店铺 \(store.shopBalanceText)\(vip)"
    }

    private var codeSection: some View {
        Section {
            HStack(spacing: Spacing.s) {
                TextField("扫码得到的码，或直接粘贴", text: $code)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(Typography.body)

                Button {
                    if store.loggedIn {
                        showingScan = true
                    } else {
                        store.needsLogin = true
                    }
                } label: {
                    Image(systemName: "qrcode.viewfinder")
                        .font(Typography.body)
                        .foregroundStyle(Color.appBrand)
                        .frame(width: Spacing.rowMinHeight, height: Spacing.rowMinHeight)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("扫码")
            }
        } header: {
            HStack {
                Text("机器码")
                if !store.loggedIn {
                    StatusBadge("先登录", kind: .warning)
                }
            }
        } footer: {
            Text(store.loggedIn
                 ? "扫洗衣机身上的二维码，或手动输入机器码。"
                 : "登录后再扫码，未登录时无法查询机器状态。")
                .font(Typography.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    private var emptySection: some View {
        Section {
            AppEmptyState(
                title: "还没有选洗衣机",
                message: "扫码或输入机器码启动洗衣机，也可从「最近用过」中选择。",
                symbol: "washer"
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    private var progressOrder: PGOrder? {
        if let running = store.runningOrder { return running }
        if let paid = store.latestPaidOrder, let end = paid.endsAt,
           end.timeIntervalSince(store.now) > -300 {
            return paid
        }
        return nil
    }

    private var bottomBar: some View {
        GlassBottomBar {
            Button {
                if store.loggedIn {
                    let target = code
                    Task { _ = await store.resolve(code: target) }
                } else {
                    store.needsLogin = true
                }
            } label: {
                HStack(spacing: Spacing.s) {
                    if store.isBusy {
                        ProgressView().tint(.white)
                    }
                    Text(store.isBusy ? store.busyText : (store.loggedIn ? "查询这台洗衣机" : "登录后查询"))
                }
            }
            .buttonStyle(GlassButtonStyle(role: .primary))
            .disabled(store.isBusy || code.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
