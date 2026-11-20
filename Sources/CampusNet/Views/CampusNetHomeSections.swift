import SwiftUI
import UIKit

/// 校园网主页的账号与二级页入口分组。
///
/// 拆出来是因为主页主文件已经到 330 行，超过单文件上限；
/// 这两块不依赖主页的任何私有状态（除了 `showAccounts`，已放开可见性）。
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
                        Text(store.settings.username.isEmpty ? "点此添加或登录账号" : store.settings.username)
                            .font(Typography.rowSubtitle)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: Spacing.s)
                    Text("\(store.accounts.count) 个账号")
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                    AppChevron()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 二级页入口

    var linksSection: some View {
        Section {
            NavigationLink(value: CampusRoute.logs) {
                HStack(spacing: Spacing.m) {
                    AppIconCircle(symbol: "doc.text.magnifyingglass", tint: .appBrand)
                    Text("连接日志").font(Typography.rowTitle)
                    Spacer(minLength: Spacing.s)
                    Text("\(store.logs.count) 行")
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, Spacing.xxs)
            }
            NavigationLink(value: CampusRoute.settings) {
                HStack(spacing: Spacing.m) {
                    AppIconCircle(symbol: "gearshape", tint: .appBrand)
                    Text("校园网设置").font(Typography.rowTitle)
                    Spacer(minLength: 0)
                }
                .padding(.vertical, Spacing.xxs)
            }
        }
    }

}

