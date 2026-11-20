import SwiftUI

/// 订单页：查历史、查支付状态、撤销未启动的订单。
///
/// 用 AppList + 月份分组；筛选条走 Picker(.segmented) 放在 .toolbar(.principal)，
/// 不再自绘顶部标题栏。
struct OrdersView: View {
    @EnvironmentObject private var store: LaundryStore

    @State private var cancelling: PGOrder?
    @State private var query = ""
    @State private var filter: OrderFilter = .all

    enum OrderFilter: String, CaseIterable, Identifiable {
        case all, unpaid, running, finished

        var id: String { rawValue }

        var title: String {
            switch self {
            case .all: return "全部"
            case .unpaid: return "待付"
            case .running: return "洗涤中"
            case .finished: return "已完成"
            }
        }

        func match(_ order: PGOrder) -> Bool {
            switch self {
            case .all: return true
            case .unpaid: return order.isUnpaid
            case .running: return order.status == 2
            case .finished: return order.status == 3
            }
        }
    }

    var body: some View {
        AppList {
            if let pending = store.pending {
                pendingSection(pending)
            }
            if filtered.isEmpty {
                Section {
                    AppEmptyState(
                        title: store.loggedIn ? "还没有订单记录" : "登录后才能看订单",
                        message: "在洗衣页扫码下单后，这里会出现记录。",
                        symbol: "list.bullet.rectangle"
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(months, id: \.self) { month in
                    Section(month) {
                        ForEach(orders(in: month)) { order in
                            orderRow(order)
                        }
                    }
                }
            }
        }
        .appNavigation(title: "订单", subtitle: store.loggedIn ? "共 \(store.orders.count) 条" : "登录后可查看")
        .toolbar(.hidden, for: .tabBar)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "搜索订单号或洗衣机")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("筛选", selection: $filter) {
                    ForEach(OrderFilter.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 320)
            }
            ToolbarItem(placement: .topBarTrailing) {
                GlassToolbarButton(symbol: "arrow.clockwise", label: "刷新") {
                    Task { await store.refreshOrders() }
                }
                .disabled(store.isBusy)
            }
        }
        .refreshable { await store.refreshOrders() }
        .confirmationDialog(
            cancelling.map { "撤销订单 \($0.orderNo.isEmpty ? $0.id : $0.orderNo)？" } ?? "",
            isPresented: Binding(get: { cancelling != nil }, set: { if !$0 { cancelling = nil } }),
            titleVisibility: .visible
        ) {
            if let order = cancelling {
                Button("撤销这笔订单", role: .destructive) {
                    cancelling = nil
                    Task { await store.cancel(order: order) }
                }
                Button("算了", role: .cancel) { cancelling = nil }
            }
        } message: {
            Text("未启动的订单可以撤销，已经出水的撤销不掉。")
        }
    }

    // MARK: - 行

    private func pendingSection(_ pending: PendingPayment) -> some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.s) {
                HStack(spacing: Spacing.s) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.appWarning)
                    Text("待支付").font(Typography.rowTitle)
                    Spacer()
                    Text(pending.price.isEmpty ? "—" : "¥\(pending.price)")
                        .font(Typography.monoValue.weight(.semibold))
                        .foregroundStyle(Color.appWarning)
                }
                Text(pending.machineName.isEmpty ? pending.orderId : pending.machineName)
                    .font(Typography.rowSubtitle)
                    .foregroundStyle(.secondary)
                HStack(spacing: Spacing.s) {
                    Button("我付好了") {
                        Task { await store.checkPendingPayment() }
                    }
                    .buttonStyle(GlassButtonStyle(role: .primary))

                    Button("撤销") {
                        Task { await store.cancelPending() }
                    }
                    .buttonStyle(GlassButtonStyle(role: .secondary))
                }
                .frame(height: 36)
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    private func orderRow(_ order: PGOrder) -> some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            HStack(alignment: .top, spacing: Spacing.s) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(order.title).font(Typography.rowTitle)
                    Text(subtitle(order))
                        .font(Typography.rowSubtitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: Spacing.xs)
                StatusBadge(order.displayStatusText, kind: badgeKind(order.status))
            }

            if order.isRunning(now: store.now) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    HStack(spacing: Spacing.xs) {
                        Text(order.remainingText(now: store.now))
                            .font(Typography.monoValue.weight(.semibold))
                            .foregroundStyle(Color.appBrand)
                        Text("后洗好").font(Typography.footnote).foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Text(order.finishText(now: store.now))
                            .font(Typography.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    ProgressView(value: order.progress(now: store.now))
                        .tint(Color.appBrand)
                }
            }

            HStack(spacing: Spacing.s) {
                Text(order.amountText)
                    .font(Typography.monoValue.weight(.semibold))
                if !order.shopName.isEmpty {
                    Text(order.shopName)
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                if order.isUnpaid {
                    Button("撤销订单") { cancelling = order }
                        .font(Typography.caption.weight(.semibold))
                        .foregroundStyle(Color.appDanger)
                        .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, Spacing.xxs)
    }

    private func subtitle(_ order: PGOrder) -> String {
        var parts: [String] = []
        if !order.createTime.isEmpty { parts.append(order.createTime) }
        if !order.orderNo.isEmpty { parts.append(order.orderNo) }
        parts.append("#\(order.status)")
        return parts.joined(separator: " · ")
    }

    private func badgeKind(_ status: Int) -> StatusBadgeKind {
        switch status {
        case 0: return .warning
        case 1: return .neutral
        case 2: return .brand
        case 3: return .success
        case 5, 6: return .brand
        default: return .neutral
        }
    }

    // MARK: - 过滤与分组

    private var filtered: [PGOrder] {
        let keyword = query.trimmingCharacters(in: .whitespaces)
        return store.orders.filter { order in
            guard filter.match(order) else { return false }
            guard !keyword.isEmpty else { return true }
            return order.orderNo.localizedCaseInsensitiveContains(keyword)
                || order.machineName.localizedCaseInsensitiveContains(keyword)
                || order.shopName.localizedCaseInsensitiveContains(keyword)
        }
    }

    private var months: [String] {
        var seen: [String] = []
        for order in filtered {
            let month = String(order.createTime.prefix(7))
            let key = month.isEmpty ? "更早" : month
            if !seen.contains(key) { seen.append(key) }
        }
        return seen
    }

    private func orders(in month: String) -> [PGOrder] {
        filtered.filter { order in
            let prefix = String(order.createTime.prefix(7))
            let key = prefix.isEmpty ? "更早" : prefix
            return key == month
        }
    }
}
