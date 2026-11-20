import SwiftUI
import UIKit

/// 底部只有两个一级模块：洗衣、校园网。
///
/// 每个模块有自己的 `NavigationStack` 与独立的 `NavigationPath`，
/// 切 Tab 时各自的栈状态原样保留。订单 / 日志 / 设置全部是模块内的二级页面。
///
/// 底栏不再用系统 TabView，原因是悬空胶囊需要左右留边、底部留边，
/// 系统 TabBar 做不到；同时自绘后「二级页面隐藏底栏」由 `path.isEmpty`
/// 直接决定，与 push / pop 在同一帧完成，不再出现返回时底栏晚一步出现的闪烁。
struct CampusShell: View {
    @EnvironmentObject private var laundry: LaundryStore
    @EnvironmentObject private var campusNet: CampusNetStore

    @State private var tab: AppTab = .laundry
    @State private var laundryPath = NavigationPath()
    @State private var campusPath = NavigationPath()
    @State private var didAutoDetectLaundry = false
    @State private var didAutoDetectCampus = false

    var body: some View {
        ZStack {
            laundryRoot
                .opacity(tab == .laundry ? 1 : 0)
                .allowsHitTesting(tab == .laundry)
                .accessibilityHidden(tab != .laundry)

            campusRoot
                .opacity(tab == .campusNet ? 1 : 0)
                .allowsHitTesting(tab == .campusNet)
                .accessibilityHidden(tab != .campusNet)
        }
        .tint(.appBrand)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsTabBar {
                FloatingTabBar(items: AppTab.items, selection: $tab)
            }
        }
    }

    // MARK: - 两个模块

    private var laundryRoot: some View {
        NavigationStack(path: $laundryPath) {
            LaundryView()
                .navigationDestination(for: LaundryRoute.self) { route in
                    LaundryDestination(route: route)
                }
                .task { await autoDetectLaundryOnce() }
        }
    }

    private var campusRoot: some View {
        NavigationStack(path: $campusPath) {
            CampusNetHomeView()
                .navigationDestination(for: CampusRoute.self) { route in
                    CampusDestination(route: route)
                }
                .task { await autoDetectCampusOnce() }
        }
    }

    /// 只有停在模块根页面时才显示底栏。二级页面整体消失，不会留半截容器。
    private var showsTabBar: Bool {
        switch tab {
        case .laundry: return laundryPath.isEmpty
        case .campusNet: return campusPath.isEmpty
        }
    }

    // MARK: - 启动自动检测

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

// MARK: - Tab

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

    static var items: [FloatingTabItem<AppTab>] {
        [AppTab.laundry, AppTab.campusNet].map {
            FloatingTabItem(tab: $0, title: $0.title, symbol: $0.symbol)
        }
    }
}
