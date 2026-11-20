import SwiftUI

/// 校园网首页 —— 与洗衣同一套 App Store 排法：状态 Hero 打头，横向账号货架，
/// 上报设备做成三格，工具与设置收进分组清单。
struct CampusNetStoreHome: View {
    @EnvironmentObject private var store: CampusNetStore

    @State private var showingAccounts = false
    @State private var showingProfiles = false
    @State private var showingPortal = false
    @State private var showingLogs = false
    @State private var showingSettings = false

    var body: some View {
        StorePage(title: "校园网",
                  subtitle: "GiWiFi · 连上 Wi-Fi 自动认证",
                  trailing: AnyView(StoreAvatarButton(symbol: "person.2.fill") {
                      showingAccounts = true
                  })) {
            hero
            accountShelf
            deviceShelf
            toolGroup
            infoGroup
            moreGroup
        }
        .sheet(isPresented: $showingAccounts) {
            AccountsView().environmentObject(store)
        }
        .sheet(isPresented: $showingProfiles) {
            ProfileEditorView(profile: nil).environmentObject(store)
        }
        .sheet(isPresented: $showingPortal) {
            PortalWebView(url: portalURL,
                          userAgent: GiWifiProtocol.browserUserAgent(for: store.currentProfile)) {
                showingPortal = false
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showingLogs) {
            CampusNetLogView().environmentObject(store)
        }
        .sheet(isPresented: $showingSettings) {
            CampusNetSettingsView().environmentObject(store)
        }
        .alert(store.rebindAlertTitle,
               isPresented: Binding(get: { store.errorText != nil || store.needsRebind },
                                    set: { if !$0 { store.clearError() } })) {
            if store.needsRebind {
                Button("立即换绑到本机") { Task { await store.rebindDevice() } }
            }
            Button("关闭", role: .cancel) { store.clearError() }
        } message: {
            Text(alertMessage)
        }
    }

    private var alertMessage: String {
        var parts: [String] = []
        if let error = store.errorText { parts.append(error) }
        if store.needsRebind {
            parts.append("这一条要先把账号从原来那台设备换绑过来，才能继续上网。")
        }
        if !store.detail.isEmpty { parts.append(store.detail) }
        return parts.joined(separator: "\n\n")
    }

    private var portalURL: URL {
        let raw = store.settings.portalOverride
        if !raw.isEmpty, let url = GiWifiClient.normalizedPortalURL(raw) { return url }
        return URL(string: GiWifiProtocol.defaultPortal) ?? URL(string: "http://100.100.9.2/gportal/web/login")!
    }

    // MARK: Hero

    private var hero: some View {
        StoreHero(eyebrow: store.state.title,
                  title: heroTitle,
                  subtitle: store.detail,
                  symbol: store.state == .online ? "wifi" : "wifi.slash",
                  tint: heroTint,
                  footnote: store.portal.isEmpty ? nil : "网关 \(store.portal)",
                  primaryTitle: store.state == .online ? "重新认证" : "立即认证",
                  primaryAction: { Task { await store.login() } },
                  secondaryTitle: store.autoRunning ? "停止守护" : "自动守护",
                  secondaryAction: { store.setAutoReconnect(!store.settings.autoReconnect) })
    }

    private var heroTitle: String {
        switch store.state {
        case .online: return "已经连上了"
        case .checking: return "正在检测"
        case .connecting: return "正在认证"
        case .offline: return "还没认证"
        case .failed: return "认证没成功"
        case .idle: return "连上校园网 Wi-Fi"
        }
    }

    private var heroTint: Color {
        switch store.state {
        case .online: return Flat.green
        case .checking, .connecting: return Flat.accent
        case .offline: return Flat.orange
        case .failed: return Flat.red
        case .idle: return Flat.accent
        }
    }

    // MARK: 货架

    private var accountShelf: some View {
        StoreShelf(title: "账号",
                   subtitle: store.accounts.isEmpty ? "还没有账号" : "\(store.accounts.count) 个",
                   actionTitle: "管理",
                   action: { showingAccounts = true }) {
            Button {
                showingAccounts = true
            } label: {
                addTile
            }
            .buttonStyle(PressScaleStyle())

            ForEach(store.accounts) { account in
                let selected = account.id == store.settings.currentAccountID
                StoreTile(title: account.displayName,
                          subtitle: account.subtitle,
                          symbol: selected ? "person.crop.circle.fill.badge.checkmark" : "person.crop.circle",
                          tint: selected ? Flat.accent : Flat.textSecondary,
                          badge: selected ? "当前" : nil,
                          badgeTint: Flat.accent) {
                    Task { await store.loginAccount(account.id) }
                }
            }
        }
    }

    private var addTile: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Flat.accent)
            Text("添加账号")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Flat.accent)
        }
        .frame(width: 108, height: 108)
        .background(Flat.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                .foregroundStyle(Flat.accent.opacity(0.45))
        }
    }

    private var deviceShelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("上报设备")
                        .font(.system(size: 20, weight: .bold))
                        .tracking(-0.3)
                        .foregroundStyle(Flat.textPrimary)
                    Text("btype / staType / staModel 与 UA 会一起切换")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Flat.textTertiary)
                }
                Spacer()
                Button("自定义") { showingProfiles = true }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Flat.accent)
            }
            .padding(.horizontal, 20)

            HStack(spacing: 10) {
                ForEach(DeviceKind.allCases) { kind in
                    let selected = store.currentProfile.kind == kind && store.currentProfile.isBuiltin
                    Button {
                        store.selectKind(kind)
                    } label: {
                        VStack(spacing: 7) {
                            Image(systemName: kind.symbol)
                                .font(.system(size: 20, weight: .semibold))
                            Text(kind.title)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(selected ? Flat.accent : Flat.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 84)
                        .background(selected ? Flat.accent.opacity(0.12) : Flat.surface.opacity(0.55),
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(selected ? Flat.accent.opacity(0.45) : Flat.hairline, lineWidth: 1)
                        }
                    }
                    .buttonStyle(PressScaleStyle(scale: 0.95))
                }
            }
            .padding(.horizontal, 20)

            Text(store.currentProfile.staModel)
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(Flat.textTertiary)
                .padding(.horizontal, 20)
        }
    }

    // MARK: 分组

    private var toolGroup: some View {
        StoreGroup(title: "认证") {
            StoreRow(icon: "arrow.clockwise",
                     tint: Flat.cyan,
                     title: "检测状态",
                     detail: "读服务端会话，不会触发认证",
                     showsChevron: false,
                     action: { Task { await store.refreshState() } })
            StoreDivider()
            StoreRow(icon: "safari.fill",
                     tint: Flat.purple,
                     title: "内置网页",
                     detail: "UA 固定为当前设备档案",
                     action: { showingPortal = true })
            StoreDivider()
            StoreRow(icon: "text.insert",
                     tint: Flat.accent,
                     title: "网页表单登录",
                     detail: "绕开接口认证，直接提交网关表单",
                     showsChevron: false,
                     action: { Task { await store.webLoginNow() } })
            StoreDivider()
            StoreRow(icon: "arrow.left.arrow.right.circle.fill",
                     tint: Flat.orange,
                     title: store.rebinding ? "正在换绑…" : "换绑到本机",
                     detail: store.rebindAvailable ? "账号还绑在别的设备上" : "把账号绑到当前这个终端",
                     showsChevron: false,
                     action: { Task { await store.rebindDevice() } })
        }
    }

    private var infoGroup: some View {
        StoreGroup(title: "连接信息") {
            StoreRow(icon: "person.fill",
                     tint: Flat.textSecondary,
                     title: "当前账号",
                     value: store.currentAccountName.isEmpty ? "未添加" : store.currentAccountName,
                     showsChevron: false)
            StoreDivider()
            StoreRow(icon: "iphone.gen3",
                     tint: Flat.textSecondary,
                     title: "设备档案",
                     value: store.currentProfile.kind.title,
                     showsChevron: false)
            StoreDivider()
            StoreRow(icon: "number",
                     tint: Flat.textSecondary,
                     title: "服务端 MAC",
                     value: store.serverMac.isEmpty ? "—" : store.serverMac,
                     showsChevron: false)
            StoreDivider()
            StoreRow(icon: "antenna.radiowaves.left.and.right",
                     tint: Flat.textSecondary,
                     title: "网关",
                     value: store.portal.isEmpty ? "—" : store.portal,
                     showsChevron: false)
        }
    }

    private var moreGroup: some View {
        StoreGroup(title: "其它") {
            StoreRow(icon: "text.alignleft",
                     tint: Flat.textSecondary,
                     title: "运行日志",
                     detail: "\(store.logs.count) 条",
                     action: { showingLogs = true })
            StoreDivider()
            StoreRow(icon: "gearshape.fill",
                     tint: Flat.textSecondary,
                     title: "设置",
                     detail: "自动守护 · Portal · 服务类型",
                     action: { showingSettings = true })
        }
    }
}
