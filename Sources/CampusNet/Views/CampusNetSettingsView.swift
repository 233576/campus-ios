import SwiftUI

/// 校园网设置：账号、上报设备、Portal、网关名、协议参数、保持在线、自定义机型、关于。
///
/// 全部走 AppList Section，一个 Section 一层；不再有「大卡片包小卡片」。
struct CampusNetSettingsView: View {
    @EnvironmentObject private var store: CampusNetStore

    @State private var portal = GiWifiProtocol.defaultPortal
    @State private var nasName = ""
    @State private var confirmingReset = false

    var body: some View {
        AppList {
            accountsSection
            deviceSection
            portalSection
            nasSection
            protocolSection
            keepOnlineSection
            CampusNetProfileSection()
            aboutSection
        }
        .appNavigation(title: "校园网设置")
        .onAppear {
            portal = store.settings.portalOverride
            nasName = store.settings.nasName
        }
        .alert("重新生成设备标识？", isPresented: $confirmingReset) {
            Button("取消", role: .cancel) {}
            Button("生成", role: .destructive) { store.resetAppUuid() }
        } message: {
            Text("下次认证会以新设备身份登录，可能需要重新换绑。")
        }
    }

    // MARK: - 账号

    private var accountsSection: some View {
        Section {
            NavigationLink {
                AccountsView().environmentObject(store)
            } label: {
                HStack(spacing: Spacing.m) {
                    AppIconCircle(symbol: "person.2.fill", tint: .appBrand)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("账号管理").font(Typography.rowTitle)
                        Text(store.accounts.isEmpty
                             ? "添加校园网账号，支持多个账号切换登录"
                             : "\(store.accounts.count) 个账号 · 当前 \(store.currentAccountName)")
                            .font(Typography.rowSubtitle)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, Spacing.xxs)
            }
        } header: {
            Text("账号")
        }
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

            LabeledContent("上报值") {
                Text("\(store.currentProfile.btype) · \(store.currentProfile.staType)")
                    .font(Typography.mono)
                    .foregroundStyle(.secondary)
            }
            LabeledContent("机型串") {
                Text(store.currentProfile.staModel)
                    .font(Typography.mono)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("上报设备")
        } footer: {
            Text("只区分手机 / 平板 / 电脑，型号统一用苹果；内置网页登录的 UA 会跟着一起换。")
                .font(Typography.caption2)
        }
    }

    // MARK: - Portal

    private var portalSection: some View {
        Section {
            HStack(spacing: Spacing.s) {
                TextField("http://100.100.9.2/gportal/web/login", text: $portal)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(Typography.mono)
                    .onSubmit { applyPortal() }
                    .submitLabel(.done)
            }

            Button("恢复默认站点") {
                portal = GiWifiProtocol.defaultPortal
                applyPortal()
            }
            .font(Typography.body)

            Button("保存站点") { applyPortal() }
                .font(Typography.body)
                .foregroundStyle(Color.appBrand)
        } header: {
            Text("Portal 站点")
        } footer: {
            Text("留空则走 APK 原始探测（115.159.209.137 → 302 跳转）。填了就直连该站点。")
                .font(Typography.caption2)
        }
    }

    private func applyPortal() {
        let value = portal.trimmingCharacters(in: .whitespacesAndNewlines)
        store.updateSettings { $0.portalOverride = value }
        store.append("Portal 站点已更新：\(value.isEmpty ? "自动探测" : value)")
    }

    // MARK: - 网关名

    private var nasSection: some View {
        Section {
            TextField("留空自动获取（如 GiWiFi_lnsfHG）", text: $nasName)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(Typography.mono)
                .onSubmit { applyNasName() }
                .submitLabel(.done)

            Button("保存网关名") { applyNasName() }
                .font(Typography.body)
                .foregroundStyle(Color.appBrand)
        } header: {
            Text("网关名 nasName")
        } footer: {
            Text("认证被拒 CHALLENGE_ERR_DENY 基本都是这里对不上。留空时先用 queryAuthState 返回的真实网关名，取不到再抓 Portal 页面。")
                .font(Typography.caption2)
        }
    }

    private func applyNasName() {
        let value = nasName.trimmingCharacters(in: .whitespacesAndNewlines)
        store.updateSettings { $0.nasName = value }
        store.append("网关名已更新：\(value.isEmpty ? "自动" : value)")
    }

    // MARK: - 协议参数

    private var protocolSection: some View {
        Section {
            Stepper(value: Binding(
                get: { store.settings.serviceType },
                set: { value in store.updateSettings { $0.serviceType = value } }
            ), in: 1...3) {
                LabeledContent("service_type") {
                    Text("\(store.settings.serviceType)")
                        .font(Typography.monoValue)
                        .foregroundStyle(.secondary)
                }
            }

            LabeledContent("设备标识 appUuid") {
                Text("…\(store.settings.appUuid.suffix(9))")
                    .font(Typography.mono)
                    .foregroundStyle(.secondary)
            }

            Button("重新生成设备标识") { confirmingReset = true }
                .font(Typography.body)
                .foregroundStyle(Color.appBrand)
        } header: {
            Text("协议参数")
        } footer: {
            Text("每个账号有独立的 appUuid，重新生成后需要重新认证一次。")
                .font(Typography.caption2)
        }
    }

    // MARK: - 保持在线

    private var keepOnlineSection: some View {
        Section {
            Toggle("掉线自动重连", isOn: Binding(
                get: { store.settings.autoReconnect },
                set: { store.setAutoReconnect($0) }
            ))

            Toggle("设备冲突时自动换绑", isOn: Binding(
                get: { store.settings.autoRebind },
                set: { value in store.updateSettings { $0.autoRebind = value } }
            ))

            Stepper(value: Binding(
                get: { Int(store.settings.reconnectInterval) },
                set: { value in store.updateSettings { $0.reconnectInterval = Double(value) } }
            ), in: 10...300, step: 5) {
                LabeledContent("检查间隔") {
                    Text("\(Int(store.settings.reconnectInterval)) 秒")
                        .font(Typography.monoValue)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("保持在线")
        }
    }

    // MARK: - 关于

    private var aboutSection: some View {
        Section {
            LabeledContent("版本") {
                Text(Self.appVersion)
                    .font(Typography.monoValue)
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://github.com/Mhenwa/xGiWifi")!) {
                HStack(spacing: Spacing.m) {
                    Text("参考实现 xGiWifi（Dart/Flutter）")
                        .font(Typography.body)
                    Spacer(minLength: Spacing.s)
                    Image(systemName: "arrow.up.right")
                        .font(Typography.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("关于")
        }
    }

    static var appVersion: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }
}
