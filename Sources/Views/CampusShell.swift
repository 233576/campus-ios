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

    /// 底栏的渲染顺序与 `case` 声明顺序一致。
    static var items: [FloatingTabItem<AppTab>] {
        [AppTab.laundry, AppTab.campusNet].map {
            FloatingTabItem(tab: $0, title: $0.title, symbol: $0.symbol)
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
        ZStack {
            laundryStack
                .opacity(tab == .laundry ? 1 : 0)
                .allowsHitTesting(tab == .laundry)
                .accessibilityHidden(tab != .laundry)

            campusStack
                .opacity(tab == .campusNet ? 1 : 0)
                .allowsHitTesting(tab == .campusNet)
                .accessibilityHidden(tab != .campusNet)
        }
        .overlay(alignment: .bottom) {
            // 二级页面自己声明隐藏底栏，这里只负责按当前栈深度决定是否渲染。
            if showsTabBar {
                FloatingTabBar(items: AppTab.items, selection: $tab)
            }
        }
    }

    /// 两个栈的栈顶必须和当前 Tab 对应，二级页面才不会被底栏挡住。
    private var showsTabBar: Bool {
        switch tab {
        case .laundry: return laundryPath.isEmpty
        case .campusNet: return campusPath.isEmpty
        }
    }

    private var laundryStack: some View {
        NavigationStack(path: $laundryPath) {
            LaundryView()
                .navigationDestination(for: LaundryRoute.self) { route in
                    LaundryDestination(route: route)
                }
                .task { await autoDetectOnce() }
        }
    }

    private var campusStack: some View {
        NavigationStack(path: $campusPath) {
            CampusNetHomeView()
                .navigationDestination(for: CampusRoute.self) { route in
                    CampusDestination(route: route)
                }
        }
    }

    /// 第一次进入洗衣 Tab 时自动检测一次连接状态；之后不再重复打扰。
    @MainActor
    private func autoDetectOnce() async {
        guard !didAutoDetect else { return }
        didAutoDetect = true
        await laundry.autoDetectOnLaunch()
    }
}
