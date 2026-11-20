import SwiftUI

/// 校园网「高级设置」：只有调参数时才进来。
///
/// 从原设置页拆出来的技术项 —— Portal 站点、网关名、协议参数、上报设备、保持在线。
/// 设置主页只留常用项，一屏半内能看完。
struct CampusAdvancedSettingsView: View {
    @EnvironmentObject private var store: CampusNetStore

    @State private var portal = GiWifiProtocol.defaultPortal
    @State private var nasName = ""
    @State private var confirmingReset = false
    @State private var showingProfileEditor = false
    @State private var toast: String?

    var body: some View {
        AppList {
            deviceSection
            portalFieldSection
            savePortalSection
            nasFieldSection
            saveNasSection
            protocolSection
            keepOnlineSection
        }
        .appNavigation(title: "高级设置")
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            portal = store.settings.portalOverride
            nasName = store.settings.nasName
        }
        .sheet(isPresented: $showingProfileEditor) {
            ProfileEditorView(profile: nil).environmentObject(store)
        }
        .appToast($toast)
        .alert("重新生成设备标识？", isPresented: $confirmingReset) {
            Button("取消", role: .cancel) {}
            Button("生成", role: .destructive) {
                store.resetAppUuid()
                toast = "已生成新的设备标识"
            }
        } message: {
            Text("下次认证会以新设备身份登录，可能需要重新换绑。")
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
            .listRowInsets(EdgeInsets(top: Spacing.s, leading: Spacing.page,
                                      bottom: Spacing.s, trailing: Spacing.page))

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

            ActionRow(symbol: "plus.circle",
                      title: "新建自定义机型",
                      trailingSymbol: "plus.circle",
                      action: { showingProfileEditor = true })
        } header: {
            Text("上报设备")
        } footer: {
            Text("只区分手机 / 平板 / 电脑，型号统一用苹果；内置网页登录的 UA 会跟着一起换。")
                .font(Typography.caption2)
        }
    }

    // MARK: - Portal

    private var portalFieldSection: some View {
        Section {
            TextField("留空则自动探测", text: $portal)
                .textContentType(.URL)
                .keyboardType(.URL)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(Typography.mono)
                .submitLabel(.done)
                .onSubmit { applyPortal() }

            DestructiveRow(symbol: "arrow.counterclockwise",
                           title: "恢复默认站点",
                           detail: GiWifiProtocol.defaultPortal,
                           role: nil) {
                portal = GiWifiProtocol.defaultPortal
                applyPortal()
            }
        } header: {
            Text("Portal 站点")
        } footer: {
            Text("留空自动探测当前网络的认证入口；填了就直接连这个地址。")
                .font(Typography.caption2)
        }
    }

    private var savePortalSection: some View {
        Section {
            Button("保存站点") { applyPortal() }
                .buttonStyle(GlassButtonStyle(role: .primary))
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: Spacing.s, leading: Spacing.page,
                                  bottom: Spacing.m, trailing: Spacing.page))
    }

    private func applyPortal() {
        let value = portal.trimmingCharacters(in: .whitespacesAndNewlines)
        store.updateSettings { $0.portalOverride = value }
        store.append("认证入口已更新：\(value.isEmpty ? "自动探测" : value)")
        toast = value.isEmpty ? "已改为自动探测" : "站点已保存"
    }

    // MARK: - 网关名

    private var nasFieldSection: some View {
        Section {
            TextField("留空自动获取", text: $nasName)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(Typography.mono)
                .submitLabel(.done)
                .onSubmit { applyNasName() }
        } header: {
            Text("网关名")
        } footer: {
            Text("认证被判定为「账号绑在别的设备上」时，多半是这里和真实网关对不上。留空时自动取服务端返回的网关名。")
                .font(Typography.caption2)
        }
    }

    private var saveNasSection: some View {
        Section {
            Button("保存网关名") { applyNasName() }
                .buttonStyle(GlassButtonStyle(role: .primary))
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: Spacing.s, leading: Spacing.page,
                                  bottom: Spacing.m, trailing: Spacing.page))
    }

    private func applyNasName() {
        let value = nasName.trimmingCharacters(in: .whitespacesAndNewlines)
        store.updateSettings { $0.nasName = value }
        store.append("网关名已更新：\(value.isEmpty ? "自动" : value)")
        toast = value.isEmpty ? "已改为自动获取" : "网关名已保存"
    }

    // MARK: - 协议参数

    private var protocolSection: some View {
        Section {
            Stepper(value: Binding(
                get: { store.settings.serviceType },
                set: { value in store.updateSettings { $0.serviceType = value } }
            ), in: 1...3) {
                LabeledContent("服务类型") {
                    Text("\(store.settings.serviceType)")
                        .font(Typography.monoValue)
                        .foregroundStyle(.secondary)
                }
            }

            LabeledContent("设备标识") {
                Text("…\(store.settings.appUuid.suffix(9))")
                    .font(Typography.mono)
                    .foregroundStyle(.secondary)
            }

            DestructiveRow(symbol: "arrow.triangle.2.circlepath",
                           title: "重新生成设备标识",
                           detail: "换一台「新设备」上报") {
                confirmingReset = true
            }
        } header: {
            Text("协议参数")
        } footer: {
            Text("每个账号有独立的设备标识，重新生成后需要重新认证一次。")
                .font(Typography.caption2)
        }
    }

    // MARK: - 保持在线

    private var keepOnlineSection: some View {
        Section {
            Toggle("设备冲突时自动换绑", isOn: Binding(
                get: { store.settings.autoRebind },
                set: { value in store.updateSettings { $0.autoRebind = value } }
            ))
        } header: {
            Text("保持在线")
        } footer: {
            Text("开启后遇到「账号已绑定其它设备」会自动换绑到本机；关闭时每次都需要你手动确认。")
                .font(Typography.caption2)
        }
    }
}
