import SwiftUI

/// 校园网设置：只放常用项 —— 账号、外观、自动守护、连接信息、关于。
///
/// 技术参数（Portal / 网关名 / 协议 / 上报设备 / 换绑策略）全部收进「高级设置」二级页，
/// 主页一屏半内能看完。上报设备只在高级设置里出现一次，不再和主页重复。
struct CampusNetSettingsView: View {
    @EnvironmentObject private var store: CampusNetStore

    @AppStorage(AppearanceMode.storageKey) private var appearanceRaw = AppearanceMode.defaultValue
    @AppStorage("campus" + LaunchRefresh.immediatelySuffix) private var launchImmediately = false
    @AppStorage("campus" + LaunchRefresh.delaySuffix) private var launchDelay = LaunchRefresh.defaultDelay

    @State private var showingAccounts = false

    var body: some View {
        AppList {
            accountsSection
            appearanceSection
            guardSection
            advancedSection
            infoSection
            aboutSection
        }
        .appNavigation(title: "校园网设置")
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showingAccounts) {
            AccountsView().environmentObject(store)
        }
    }

    // MARK: - 账号

    private var accountsSection: some View {
        Section {
            ActionRow(symbol: "person.2.fill",
                      title: "账号管理",
                      detail: store.accounts.isEmpty
                          ? "添加校园网账号，支持多个账号切换登录"
                          : "\(store.accounts.count) 个账号 · 当前 \(store.currentAccountName)",
                      trailingSymbol: "person.badge.plus",
                      action: { showingAccounts = true })
        } header: {
            Text("账号")
        }
    }

    // MARK: - 外观

    private var appearanceSection: some View {
        Section {
            Picker("外观", selection: appearanceBinding) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.title).tag(mode.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .listRowInsets(EdgeInsets(top: Spacing.s, leading: Spacing.page,
                                      bottom: Spacing.s, trailing: Spacing.page))
        } header: {
            Text("外观")
        } footer: {
            Text("「跟随系统」随时随系统切换；选浅色或深色后整个 App 立即生效。")
        }
    }

    private var appearanceBinding: Binding<String> {
        Binding(
            get: { appearanceRaw },
            set: { value in
                withAnimation(.easeInOut(duration: 0.35)) { appearanceRaw = value }
            }
        )
    }

    // MARK: - 自动守护

    private var guardSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { store.settings.autoReconnect },
                set: { store.setAutoReconnect($0) }
            )) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("掉线自动重连").font(Typography.rowTitle)
                    Text(store.autoRunning
                         ? "每 \(Int(store.settings.reconnectInterval)) 秒检查一次"
                         : "关闭后只能手动认证")
                        .font(Typography.rowSubtitle)
                        .foregroundStyle(.secondary)
                }
            }

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

            Toggle(isOn: $launchImmediately) {
                Text("打开 App 后立即刷新").font(Typography.rowTitle)
            }

            Stepper(value: $launchDelay, in: LaunchRefresh.delayRange, step: 1) {
                LabeledContent("延迟刷新") {
                    Text("\(Int(launchDelay)) 秒")
                        .font(Typography.monoValue)
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(launchImmediately)
            .opacity(launchImmediately ? 0.5 : 1)
        } header: {
            Text("自动守护")
        } footer: {
            Text("开启后 App 在前台时会定期检查连接，掉线自动重新认证。\n立即刷新：进 App 就查一次状态；关闭则等设定的秒数后再查。")
                .font(Typography.caption2)
        }
    }

    // MARK: - 高级设置入口

    private var advancedSection: some View {
        Section {
            NavigationRow(symbol: "slider.horizontal.3",
                          title: "高级设置",
                          detail: "认证入口、网关名、协议参数、上报设备",
                          value: CampusRoute.advanced)
        } footer: {
            Text("这些参数改错会连不上，不确定时保持默认即可。")
                .font(Typography.caption2)
        }
    }

    // MARK: - 连接信息

    private var infoSection: some View {
        Section("连接信息") {
            infoRow("设备档案", "\(store.currentProfile.kind.title) · \(store.currentProfile.staModel)")
            infoRow("服务端 MAC", store.serverMac.isEmpty ? "未获取" : store.serverMac)
            infoRow("认证入口", store.portal.isEmpty ? "未探测" : store.portal)
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
                    Text("参考实现 xGiWifi").font(Typography.body)
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
