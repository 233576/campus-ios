import SwiftUI

/// 洗衣 Tab 内部的二级页面。
///
/// 以前这三个页面被提到了 TabBar 一级，导致洗衣模块独占导航、
/// 校园网被挤到 More 里。现在它们只是各自 Tab 栈里的一层 push。
enum LaundryRoute: Hashable {
    case orders
    case logs
    case settings
}

/// 校园网 Tab 内部的二级页面。
enum CampusRoute: Hashable {
    case logs
    case settings
}

/// 二级页面的统一入口视图。
///
/// 放在这里而不是散在 Shell 里，是为了让 `navigationDestination` 只写一次，
/// 二级页自己仍然专注内容。
struct LaundryDestination: View {
    let route: LaundryRoute

    var body: some View {
        switch route {
        case .orders:
            OrdersView()
        case .logs:
            LaundryLogView()
        case .settings:
            LaundrySettingsView()
        }
    }
}

struct CampusDestination: View {
    let route: CampusRoute

    var body: some View {
        switch route {
        case .logs:
            CampusNetLogView()
        case .settings:
            CampusNetSettingsView()
        }
    }
}
