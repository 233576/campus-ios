import SwiftUI

/// 启动刷新偏好。
///
/// 两个模块各自独立存储（洗衣 `laundry_*`、校园网 `campus_*`），
/// 一个是「立即刷新」，一个是「延迟 N 秒再刷新」。
///
/// 这里只决定**什么时候触发**查询，不参与查询本身。
enum LaunchRefresh {
    static let immediatelySuffix = "_launch_refresh_immediately"
    static let delaySuffix = "_launch_refresh_delay"

    static let defaultDelay: Double = 2
    static let delayRange: ClosedRange<Double> = 1...10

    /// 读取某个模块的启动延迟秒数：立即刷新返回 0。
    static func delay(for module: String) -> Double {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: module + immediatelySuffix) { return 0 }
        let stored = defaults.double(forKey: module + delaySuffix)
        return stored > 0 ? stored : defaultDelay
    }
}
