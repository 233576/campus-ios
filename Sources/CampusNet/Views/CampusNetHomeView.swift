import SwiftUI
import UIKit

/// 校园网主页：账号、连接状态、四个动作、上报设备、自动守护、连接信息。
///
/// 全部走 AppList Section；「立即认证」用 safeAreaInset 固定在底部。
/// 原来的顶部自绘分段已随模块外壳一起删除，这里是 TabView 的一级页面。
struct CampusNetHomeView: View {
    @EnvironmentObject var store: CampusNetStore

    @State var showAccounts = false
    @State private var showingProfileEditor = false
    @State var showingPortalWeb = false
    /// 底部认证栏是否可见。点过「立即认证」就先收起来。
    @State private var isActionBarVisible = true

    var body: some View {
        AppList {
            accountSection
            statusSection
            linksSection
            actionSection
            deviceSection
            autoSection
            infoSection
        }
        .appNavigation(title: "GiWiFi 助手", subtitle: "校园网 · 一键认证")
        .toolbarBackground(.automatic, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                GlassToolbarLink(symbol: "gearshape", label: "校园网设置", value: CampusRoute.settings)
            }
        }
        .refreshable { await store.refreshState() }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if isActionBarVisible {
                bottomBar
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 26)),
                        removal: .opacity.combined(with: .offset(y: 26))
                    ))
            }
        }
        .onAppear { showActionBar() }
        .onChange(of: store.state) { _, state in
            if state != .connecting { showActionBar() }
        }
        .sheet(isPresented: $showAccounts) {
            AccountsView(isPicker: true).environmentObject(store)
        }
        .sheet(isPresented: $showingProfileEditor) {
            ProfileEditorView(profile: nil).environmentObject(store)
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
                    Task { await store.rebindDevice() }
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

    // MARK: - 状态

    private var statusSection: some View {
        Section {
            HStack(spacing: Spacing.l) {
                ZStack {
                    Circle()
                        .fill(store.state == .online
                              ? Color.appSuccess.opacity(0.18)
                              : Color(uiColor: .quaternarySystemFill))
                    Image(systemName: symbol)
                        .font(Typography.title3.weight(.semibold))
                        .foregroundStyle(stateColor)
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(store.state.title)
                        .font(Typography.sectionTitle)
                    Text(store.detail)
                        .font(Typography.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Spacing.xs)

                StatusBadge(store.state == .online ? "在线" : "离线",
                            kind: store.state == .online ? .success : .neutral)
            }
            .padding(.vertical, Spacing.xs)
        }
    }

    // MARK: - 四个动作

    private var actionSection: some View {
        Section {
            actionRow(symbol: "arrow.clockwise", title: "检测状态") {
                Task { await store.refreshState() }
            }
            actionRow(symbol: "safari", title: "内置网页") { openPortal() }
            actionRow(symbol: "text.insert", title: "网页表单登录") {
                Task { await store.webLoginNow() }
            }
            actionRow(symbol: "iphone.and.arrow.forward",
                      title: store.needsRebind ? "换绑到本机（需要确认）" : "换绑到本机") {
                Task { await store.rebindDevice() }
            }
        } header: {
            Text("操作")
        }
    }

    private func actionRow(symbol: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.m) {
                Image(systemName: symbol)
                    .font(Typography.subheadline)
                    .foregroundStyle(Color.appBrand)
                    .frame(width: 22)
                Text(title).font(Typography.body)
                Spacer(minLength: Spacing.s)
                AppChevron()
            }
            .frame(minHeight: Spacing.rowMinHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(store.state == .connecting)
    }

    // MARK: - 上报设备

    private var deviceSection: some View {
        Section {
            Picker("上报设备", selection: Binding(
                get: { store.currentProfile.kind },
                set: { store.selectKind($0) }
            )) {
                ForEach(DeviceKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            Button("自定义机型") { showingProfileEditor = true }
                .font(Typography.body)
                .foregroundStyle(Color.appBrand)
                .frame(maxWidth: .infinity, minHeight: Spacing.rowMinHeight)

            infoRow("上报值", "\(store.currentProfile.kind.btype) · \(store.currentProfile.kind.staType)")
            infoRow("机型串", store.currentProfile.staModel)
        } header: {
            Text("上报设备")
        } footer: {
            Text("报文字段 btype/staType/staModel 与浏览器 UA 会一起切换。")
                .font(Typography.caption2)
        }
    }

    // MARK: - 自动守护

    private var autoSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { store.settings.autoReconnect },
                set: { store.setAutoReconnect($0) }
            )) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("自动守护").font(Typography.rowTitle)
                    Text(store.autoRunning
                         ? "每 \(Int(store.settings.reconnectInterval)) 秒检测，掉线自动认证"
                         : "关闭时只能手动认证")
                        .font(Typography.rowSubtitle)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("守护")
        }
    }

    // MARK: - 连接信息

    private var infoSection: some View {
        Section("连接信息") {
            infoRow("设备档案", "\(store.currentProfile.kind.title) · \(store.currentProfile.staModel)")
            infoRow("服务端 MAC", store.serverMac.isEmpty ? "未获取" : store.serverMac)
            infoRow("Portal", store.portal.isEmpty ? "未探测" : store.portal)
            infoRow("浏览器 UA", store.currentProfile.kind.userAgent)
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Text(title)
                .font(Typography.footnote)
                .foregroundStyle(.secondary)
                .frame(width: 76, alignment: .leading)
            Text(value)
                .font(Typography.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.xxs)
    }

    // MARK: - 底部主按钮


    // MARK: - 底部遮罩显隐

    /// 隐藏底部操作栏：向下淡出 26pt，接近临界阻尼，顺滑到位不弹跳。
    private func hideActionBar() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86, blendDuration: 0.3)) {
            isActionBarVisible = false
        }
    }

    /// 恢复底部操作栏，动画与隐藏保持对称。
    private func showActionBar() {
        guard !isActionBarVisible else { return }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86, blendDuration: 0.3)) {
            isActionBarVisible = true
        }
    }

    private var bottomBar: some View {
        Button {
            hideActionBar()
            Task { await store.login() }
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
        .opacity(store.state == .connecting || store.settings.username.isEmpty ? 0.5 : 1)
        .padding(.horizontal, Spacing.page)
        .padding(.vertical, Spacing.s)
        .background(.bar)
    }

    // MARK: - 派生

    private var portalURL: URL? {
        let raw = store.settings.portalOverride.isEmpty
            ? GiWifiProtocol.defaultPortal
            : store.settings.portalOverride
        return GiWifiClient.normalizedPortalURL(raw)
    }


    private var buttonTitle: String {
        switch store.state {
        case .online: return "重新认证"
        case .connecting: return "认证中…"
        default: return "立即认证"
        }
    }

    private var symbol: String {
        switch store.state {
        case .online: return "checkmark"
        case .checking, .connecting: return "arrow.triangle.2.circlepath"
        case .failed: return "exclamationmark"
        case .offline, .idle: return "wifi.slash"
        }
    }

    private var stateColor: Color {
        switch store.state {
        case .online: return .appBrand
        case .checking, .connecting: return .appBrand
        case .failed: return .appDanger
        case .offline, .idle: return .secondary
        }
    }
}

extension CampusNetHomeView {
    func openPortal() {
        store.clearError()
        showingPortalWeb = true
    }
}
