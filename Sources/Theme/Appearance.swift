import SwiftUI

/// 外观三档。存在 UserDefaults（`AppStorage`），默认跟随系统。
///
/// 全局只有一个读取点：`CampusApp` 把它映射成 `.preferredColorScheme`；
/// 设置页只负责写这个 rawValue。
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }

    /// `system` 返回 nil，交给系统；其余强制对应外观。
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    static let storageKey = "appearanceMode"
    static let defaultValue: String = AppearanceMode.system.rawValue
}
