import SwiftUI
import UIKit

/// 底部只有两个一级模块：洗衣、校园网。
///
/// 每个模块有自己的 `NavigationStack` 与独立的 `NavigationPath`，
/// 切 Tab 时各自的栈状态原样保留。订单 / 日志 / 设置全部是模块内的二级页面。
///
/// TabBar 完全交给系统渲染（iOS 26 是液态玻璃胶囊），这里不设置任何
/// `UITabBarAppearance` / `toolbarBackground`，也不做自绘底栏。
enum AppTab: Hashable {
    case laundry
    case campusNet

    /// Tab 标题固定为模块名，不带品牌后缀。
    var title: String {
        switch self {
        case .laundry: return "洗衣"
        case .campusNet: return "校园网"
        }
    }

    /// `washing.machine.fill` 是 iOS 26 新增符号，低版本回落到 `washer.fill`。
    var symbol: String {
        switch self {
        case .laundry:
            return UIImage(systemName: "washing.machine.fill") != nil
                ? "washing.machine.fill"
                : "washer.fill"
        case .campusNet:
            return "wifi"
        }
    }
}

struct CampusShell: View {
    @EnvironmentObject private var laundry: LaundryStore
    @EnvironmentObject private var campusNet: CampusNetStore

    @State private var tab: AppTab = .laundry
    @State private var laundryPath = NavigationPath()
    @State private var campusPath = NavigationPath()
    @State private var didAutoDetect = false

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack(path: $laundryPath) {
                LaundryView()
                    .navigationDestination(for: LaundryRoute.self) { route in
                        LaundryDestination(route: route)
                    }
                    .task { await autoDetectOnce() }
            }
            .tag(AppTab.laundry)
            .tabItem { Label(AppTab.laundry.title, systemImage: AppTab.laundry.symbol) }

            NavigationStack(path: $campusPath) {
                CampusNetHomeView()
                    .navigationDestination(for: CampusRoute.self) { route in
                        CampusDestination(route: route)
                    }
            }
            .tag(AppTab.campusNet)
            .tabItem { Label(AppTab.campusNet.title, systemImage: AppTab.campusNet.symbol) }
        }
        .tint(.appBrand)
    }

    /// 第一次进入洗衣 Tab 时自动检测一次连接状态；之后不再重复打扰。
    @MainActor
    private func autoDetectOnce() async {
        guard !didAutoDetect else { return }
        didAutoDetect = true
        await laundry.autoDetectOnLaunch()
    }
}
