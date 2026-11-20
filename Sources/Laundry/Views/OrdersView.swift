import SwiftUI

/// 订单页：查历史、查支付状态、撤销未启动的订单。
///
/// 性能相关：
/// - 筛选 + 按月分组的结果缓存在 `@State`，只在订单数、筛选、关键词变化时重算，
///   不再每次 `body` 求值都跑三遍 `filter`（原来是 O(n²)）；
/// - 行视图 `OrderRow` 是独立 `Equatable` struct，配合 `.equatable()`；
/// - 倒计时在 `OrderCountdown` 内部用 `TimelineView` 自驱，整页不读 `store.now`；
/// - 筛选条从 `.toolbar(.principal)` 移到列表第一行，避免与右上角按钮抢宽度、
///   也避免大标题折叠时和分段控件叠在一起。
struct OrdersView: View {
    @EnvironmentObject private var store: LaundryStore

    @State private var cancelling: PGOrder?
    @State private var query = ""
    @State private var filter: OrderFilter = .all
    @State private var groups: [OrderGroup] = []

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

    struct OrderGroup: Identifiable {
        var month: String
        var orders: [PGOrder]

        var id: String { month }
    }

    var body: some View {
        AppList {
            Section {
                Picker("筛选", selection: $filter) {
                    ForEach(OrderFilter.allCases) { item in
                        Text(item.title).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.page,
                                          bottom: Spacing.xs, trailing: Spacing.page))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if let pending = store.pending {
                pendingSection(pending)
            }

            if groups.isEmpty {
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
                ForEach(groups) { group in
                    Section(group.month) {
                        ForEach(group.orders) { order in
                            OrderRow(order: order)
                                .equatable()
                                .swipeActions(edge: .trailing) {
                                    if order.isUnpaid {
                                        Button("撤销", role: .destructive) { cancelling = order }
                                    }
                                }
                        }
                    }
                }
            }
        }
        .appNavigation(title: "订单", subtitle: store.loggedIn ? "共 \(store.orders.count) 条" : "登录后可查看")
        .toolbarBackground(.automatic, for: .navigationBar)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "搜索订单号或洗衣机")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                GlassToolbarButton(symbol: "arrow.clockwise", label: "刷新") {
                    Task { await store.refreshOrders() }
                }
                .disabled(store.isBusy)
            }
        }
        .refreshable { await store.refreshOrders() }
        .onAppear { rebuild() }
        .onChange(of: rebuildKey) { rebuild() }
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

    // MARK: - 缓存

    /// 只在影响结果的三件事变化时重算分组。
    private var rebuildKey: String {
        "\(store.orders.count)-\(filter.rawValue)-\(query)"
    }

    private func rebuild() {
        let keyword = query.trimmingCharacters(in: .whitespaces)
        let matched = store.orders.filter { order in
            guard filter.match(order) else { return false }
            guard !keyword.isEmpty else { return true }
            return order.orderNo.localizedCaseInsensitiveContains(keyword)
                || order.machineName.localizedCaseInsensitiveContains(keyword)
                || order.shopName.localizedCaseInsensitiveContains(keyword)
        }

        var order: [String] = []
        var bucket: [String: [PGOrder]] = [:]
        for item in matched {
            let prefix = String(item.createTime.prefix(7))
            let key = prefix.isEmpty ? "更早" : prefix
            if bucket[key] == nil {
                bucket[key] = []
                order.append(key)
            }
            bucket[key]?.append(item)
        }

        groups = order.map { OrderGroup(month: $0, orders: bucket[$0] ?? []) }
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
}
