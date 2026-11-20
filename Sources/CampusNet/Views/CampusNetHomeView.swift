import SwiftUI
import UIKit

/// 校园网主页：账号 → 连接状态 → 并排动作 → 认证方式 → 连接日志。
///
/// 层级按「看一眼 → 做一次 → 换个法子 → 翻记录」排：
/// 1. 账号（整卡可点，进账号管理）
/// 2. 连接状态（图标 + 标题 + 说明 + 在线徽标）
/// 3. 并排动作（检测状态 / 换绑到本机）—— 原地执行，不是跳转
/// 4. 认证方式（内置网页 / 网页表单登录）
/// 5. 连接日志
///
/// 上报设备宫格、自动守护、技术参数都搬去设置页，主页不再重复。
struct CampusNetHomeView: View {
    @EnvironmentObject var store: CampusNetStore

    @State var showAccounts = false
    @State var showingPortalWeb = false
    @State var toast: String?

    var body: some View {
        AppList {
            accountSection
            statusSection
            actionPairSection
            methodSection
            logsEntrySection
        }
        .appNavigation(title: "GiWiFi 助手", subtitle: "校园网 · 一键认证")
        .toolbarBackground(.automatic, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                GlassToolbarLink(symbol: "gearshape", label: "校园网设置", value: CampusRoute.settings)
            }
        }
        .refreshable { await store.refreshState() }
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
        .appToast($toast)
        .sheet(isPresented: $showAccounts) {
            AccountsView(isPicker: true).environmentObject(store)
        }
        .sheet(isPresented: $showingPortalWeb) {
            if let url = portalURL {
                PortalWebView(url: url,
                              userAgent: GiWifiProtocol.browserUserAgent(for: store.currentProfile)) {
                    Task { await store.refreshState() }
                }
            }
        }
        .alert(store.rebindAlertTitle, isPresented: Binding(
            get: { store.errorText != nil || store.needsRebind },
            set: { if !$0 { store.clearError() } }
        )) {
            if store.rebindAvailable {
                Button("立即换绑到本机") {
                    Task { await rebind() }
                }
            }
            if store.needsProfile || store.needsWebAuth {
                Button("内置网页登录") { openPortal() }
            }
            Button("取消", role: .cancel) { store.clearError() }
        } message: {
            if let error = store.errorText {
                Text(error)
            } else if store.needsRebind {
                Text("这一条要先把账号从原来那台设备换绑过来，才能继续上网。\n\n\(store.detail)")
            } else {
                Text(store.detail)
            }
        }
    }

    // MARK: - 并排动作（原地执行）

    private var actionPairSection: some View {
        Section {
            HStack(spacing: Spacing.m) {
                Button {
                    Task { await check() }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        if isCheckingNow {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("检测状态")
                    }
                }
                .buttonStyle(GlassButtonStyle(role: .secondary))
                .disabled(isCheckingNow || store.settings.username.isEmpty)

                Button {
                    Task { await rebind() }
                } label: {
                    HStack(spacing: Spacing.xs) {
                        if store.rebinding {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text("换绑到本机")
                    }
                }
                .buttonStyle(GlassButtonStyle(role: .secondary))
                .disabled(store.rebinding || store.settings.username.isEmpty)
            }
            .listRowInsets(EdgeInsets(top: Spacing.s, leading: Spacing.page,
                                      bottom: Spacing.s, trailing: Spacing.page))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } footer: {
            if store.settings.username.isEmpty {
                Text("先在「账号管理」里添加账号，这两个按钮才会有反应。")
                    .font(Typography.caption2)
            }
        }
    }

    var isCheckingNow: Bool {
        store.state == .checking || store.state == .connecting
    }

    // MARK: - 连接日志

    private var logsEntrySection: some View {
        Section {
            NavigationRow(symbol: "doc.text.magnifyingglass",
                          title: "连接日志",
                          badge: "\(store.logs.count) 行",
                          value: CampusRoute.logs)
        }
    }

    // MARK: - 底部主按钮

    private var bottomBar: some View {
        GlassBottomBar {
            Button {
                Task { await authenticate() }
            } label: {
                HStack(spacing: Spacing.s) {
                    if store.state == .connecting {
                        ProgressView().tint(.white)
                    }
                    Text(buttonTitle)
                }
            }
            .buttonStyle(GlassButtonStyle(role: .primary))
            .disabled(store.state == .connecting || store.settings.username.isEmpty)
        }
    }

    // MARK: - 动作

    private func check() async {
        await store.refreshState()
        switch store.state {
        case .online: toast = "状态：已在线"
        case .offline, .idle: toast = "状态：未认证"
        case .failed: toast = "检测失败，\(store.detail)"
        default: toast = store.detail
        }
    }

    func rebind() async {
        await store.rebindDevice()
        if let error = store.errorText {
            toast = error
        } else {
            toast = store.state == .online ? "已换绑并上线" : "换绑请求已发出"
        }
    }

    private func authenticate() async {
        await store.login()
        if let error = store.errorText {
            toast = error
        } else if store.state == .online {
            toast = "认证成功"
        }
    }

    func webLogin() async {
        await store.webLoginNow()
        if let error = store.errorText {
            toast = error
        } else {
            toast = "网页登录已提交"
        }
    }

    // MARK: - 派生

    private var portalURL: URL? {
        let raw = store.settings.portalOverride.isEmpty
            ? GiWifiProtocol.defaultPortal
            : store.settings.portalOverride
        return GiWifiClient.normalizedPortalURL(raw)
    }

    func openPortal() {
        store.clearError()
        showingPortalWeb = true
    }

    private var buttonTitle: String {
        switch store.state {
        case .online: return "重新认证"
        case .connecting: return "认证中…"
        default: return "立即认证"
        }
    }
}
