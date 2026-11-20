import SwiftUI
import UIKit

/// 校园网主页里跨文件复用的分组：账号卡、连接状态卡、认证方式。
///
/// 拆出来是因为主页主文件要守住单文件上限；
/// 这里只依赖 `store` 与 `showAccounts` / `openPortal`（都在主文件里是 internal）。
extension CampusNetHomeView {
    // MARK: - 账号

    var accountSection: some View {
        Section {
            Button {
                showAccounts = true
            } label: {
                HStack(spacing: Spacing.m) {
                    AppIconCircle(symbol: "person.fill", tint: .appBrand)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(store.currentAccountName).font(Typography.rowTitle)
                        Text(store.settings.username.isEmpty
                             ? "点此添加或登录账号"
                             : store.settings.username)
                            .font(Typography.rowSubtitle)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: Spacing.s)
                    Text("\(store.accounts.count) 个账号")
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                    AppChevron()
                }
                .padding(.vertical, Spacing.xxs)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listSectionSpacing(Spacing.m)
    }

    // MARK: - 连接状态卡

    /// 卡片自带 16pt 内边距与圆角，行本身透明 —— 这样状态卡、按钮组、
    /// 说明文字之间才能用真实间距（24 / 8）收紧，而不是被 List 的默认行距撑开。
    var statusCard: some View {
        HStack(spacing: Spacing.l) {
            ZStack {
                Circle()
                    .fill(store.state == .online
                          ? Color.appSuccess.opacity(0.18)
                          : Color(uiColor: .quaternarySystemFill))
                Image(systemName: statusSymbol)
                    .font(Typography.title3.weight(.semibold))
                    .foregroundStyle(statusColor)
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(store.state.title)
                    .font(Typography.sectionTitle)
                Text(statusDetail)
                    .font(Typography.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Spacing.xs)

            StatusBadge(store.state == .online ? "在线" : "离线",
                        kind: store.state == .online ? .success : .neutral)
        }
        .padding(Spacing.l)
        .background(Color.appSecondaryBackground,
                    in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
    }

    /// 没有账号时不要指路「设置 → 账号管理」——账号卡就在这张卡上面，
    /// 用户不需要知道层级路径。
    var statusDetail: String {
        store.settings.username.isEmpty ? "先添加账号，再连接校园网" : store.detail
    }

    var statusSymbol: String {
        switch store.state {
        case .online: return "checkmark"
        case .checking, .connecting: return "arrow.triangle.2.circlepath"
        case .failed: return "exclamationmark"
        case .offline, .idle: return "wifi.slash"
        }
    }

    var statusColor: Color {
        switch store.state {
        case .online, .checking, .connecting: return .appBrand
        case .failed: return .appDanger
        case .offline, .idle: return .secondary
        }
    }

    var isCheckingNow: Bool {
        store.state == .checking || store.state == .connecting
    }

    // MARK: - 认证方式

    var methodSection: some View {
        Section {
            Button { openPortal() } label: {
                methodRow(symbol: "safari", title: "内置网页")
            }
            .buttonStyle(.plain)

            Button { Task { await webLogin() } } label: {
                methodRow(symbol: "text.insert", title: "网页表单登录")
            }
            .buttonStyle(.plain)
            .disabled(isCheckingNow)
        } header: {
            Text("认证方式")
        } footer: {
            Text("认证被拒绝、或者想换资料时，用这里打开学校认证页手动登录一次。")
                .font(Typography.caption2)
        }
        .listSectionSpacing(Spacing.xl)
    }

    private func methodRow(symbol: String, title: String) -> some View {
        HStack(spacing: Spacing.m) {
            AppIconCircle(symbol: symbol)
            Text(title).font(Typography.rowTitle)
            Spacer(minLength: Spacing.s)
            AppChevron()
        }
        .frame(minHeight: Spacing.rowMinHeight)
        .contentShape(Rectangle())
    }
}
