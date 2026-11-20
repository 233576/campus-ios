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
    @State private var didAutoDetectLaundry = false
    @State private var didAutoDetectCampus = false

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack(path: $laundryPath) {
                LaundryView()
                    .navigationDestination(for: LaundryRoute.self) { route in
                        LaundryDestination(route: route)
                    }
                    .task { await autoDetectLaundryOnce() }
            }
            .tag(AppTab.laundry)
            .tabItem { Label(AppTab.laundry.title, systemImage: AppTab.laundry.symbol) }

            NavigationStack(path: $campusPath) {
                CampusNetHomeView()
                    .navigationDestination(for: CampusRoute.self) { route in
                        CampusDestination(route: route)
                    }
                    .task { await autoDetectCampusOnce() }
            }
            .tag(AppTab.campusNet)
            .tabItem { Label(AppTab.campusNet.title, systemImage: AppTab.campusNet.symbol) }
        }
        .tint(.appBrand)
    }

    /// 每个模块各自只在第一次进入时自动检测一次。
    ///
    /// 延迟秒数由用户在设置里选（0 = 立即），两个模块互不影响。
    @MainActor
    private func autoDetectLaundryOnce() async {
        guard !didAutoDetectLaundry else { return }
        didAutoDetectLaundry = true
        await laundry.autoDetectOnLaunch(delay: LaunchRefresh.delay(for: "laundry"))
    }

    @MainActor
    private func autoDetectCampusOnce() async {
        guard !didAutoDetectCampus else { return }
        didAutoDetectCampus = true
        await campusNet.autoDetectOnLaunch(delay: LaunchRefresh.delay(for: "campus"))
    }
}
