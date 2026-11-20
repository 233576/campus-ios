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
/// 「立即认证」上移到导航栏右上角，页面底部不再有通栏按钮。
struct CampusNetHomeView: View {
    @EnvironmentObject var store: CampusNetStore

    @State var showAccounts = false
    @State var showingPortalWeb = false
    @State var toast: String?

    var body: some View {
        AppList {
            accountSection
            connectionSection
            methodSection
            logsEntrySection
        }
        .appNavigation(title: "GiWiFi 助手", subtitle: "校园网 · 一键认证")
        .toolbarBackground(.automatic, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                plainToolbarItem(authenticateButton)
                plainToolbarItem(GlassToolbarLink(symbol: "gearshape",
                                                  label: "校园网设置",
                                                  value: CampusRoute.settings))
            }
        }
        .refreshable { await store.refreshState() }
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

    // MARK: - 导航栏认证按钮

    /// iOS 26 会给同一个 ToolbarItemGroup 的按钮合并共享玻璃背景。
    /// 那样两个图标会被裹进一个胶囊、左侧留出大片空白，所以这里逐个关掉共享背景，
    /// 让它们各自独立渲染。低版本没有这个 API，原样返回。
    @ViewBuilder
    private func plainToolbarItem<V: View>(_ content: V) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.sharedBackgroundVisibility(.hidden)
        } else {
            content
        }
        #else
        content
        #endif
    }

    private var canAuthenticate: Bool {
        !store.settings.username.isEmpty && store.state != .connecting
    }

    private var authenticateButton: some View {
        Button {
            Task { await authenticate() }
        } label: {
            Group {
                if store.state == .connecting {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(Typography.body)
                        .foregroundStyle(Color.appBrand)
                }
            }
            .frame(width: Spacing.rowMinHeight, height: Spacing.rowMinHeight)
        }
        .accessibilityLabel("立即认证")
        .disabled(!canAuthenticate)
        .opacity(canAuthenticate ? 1 : 0.4)
    }

    // MARK: - 状态 + 并排动作（原地执行）

    /// 状态卡 → 按钮组 24pt，按钮组 → 说明 8pt。整块是一行，行本身透明，
    /// 间距全部由 VStack 精确控制，不受 List 默认行距影响。
    private var connectionSection: some View {
        Section {
            VStack(spacing: 0) {
                statusCard

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
                .padding(.top, Spacing.l)

                if store.settings.username.isEmpty {
                    Text("先在「账号管理」里添加账号，这两个按钮才会有反应。")
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, Spacing.s)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .padding(.horizontal, Spacing.page)
        }
        .listSectionSpacing(Spacing.l)
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
        } else {
            toast = "认证请求已提交"
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
}
