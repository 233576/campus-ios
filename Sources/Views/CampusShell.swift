import SwiftUI

/// 全 App 的一级导航：七个 Tab 全部平铺在系统 TabView 上。
///
/// 之前的「模块内顶部自绘分段 + 底部自绘胶囊」是双重导航，已彻底删除。
/// 底部栏完全交给系统渲染，不设置任何 UITabBarAppearance。
enum AppTab: String, CaseIterable, Identifiable {
    case laundry
    case orders
    case laundryLogs
    case laundrySettings
    case campusNet
    case netLogs
    case netSettings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .laundry: return "洗衣"
        case .orders: return "订单"
        case .laundryLogs: return "洗衣日志"
        case .laundrySettings: return "洗衣设置"
        case .campusNet: return "校园网"
        case .netLogs: return "校园网日志"
        case .netSettings: return "校园网设置"
        }
    }

    var symbol: String {
        switch self {
        case .laundry: return "washer.fill"
        case .orders: return "list.bullet.rectangle.portrait.fill"
        case .laundryLogs: return "text.alignleft"
        case .laundrySettings: return "gearshape.fill"
        case .campusNet: return "wifi"
        case .netLogs: return "doc.text.magnifyingglass"
        case .netSettings: return "slider.horizontal.3"
        }
    }
}

struct CampusShell: View {
    @EnvironmentObject private var laundry: LaundryStore
    @EnvironmentObject private var campusNet: CampusNetStore

    @State private var tab: AppTab = .laundry
    @State private var didAutoDetect = false

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                LaundryView()
                    .task(perform: autoDetectOnce)
            }
            .tag(AppTab.laundry)
            .tabItem { Label(AppTab.laundry.title, systemImage: AppTab.laundry.symbol) }

            NavigationStack { OrdersView() }
                .tag(AppTab.orders)
                .tabItem { Label(AppTab.orders.title, systemImage: AppTab.orders.symbol) }

            NavigationStack { LaundryLogView() }
                .tag(AppTab.laundryLogs)
                .tabItem { Label(AppTab.laundryLogs.title, systemImage: AppTab.laundryLogs.symbol) }

            NavigationStack { LaundrySettingsView() }
                .tag(AppTab.laundrySettings)
                .tabItem { Label(AppTab.laundrySettings.title, systemImage: AppTab.laundrySettings.symbol) }

            NavigationStack { CampusNetHomeView() }
                .tag(AppTab.campusNet)
                .tabItem { Label(AppTab.campusNet.title, systemImage: AppTab.campusNet.symbol) }

            NavigationStack { CampusNetLogView() }
                .tag(AppTab.netLogs)
                .tabItem { Label(AppTab.netLogs.title, systemImage: AppTab.netLogs.symbol) }

            NavigationStack { CampusNetSettingsView() }
                .tag(AppTab.netSettings)
                .tabItem { Label(AppTab.netSettings.title, systemImage: AppTab.netSettings.symbol) }
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
