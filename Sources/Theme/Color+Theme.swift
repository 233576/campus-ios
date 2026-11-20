import SwiftUI

/// 全局语义色。视图里只允许出现这里的名字，禁止 hex / Color(red:)。
extension Color {
    static let appBrand = Color.accentColor

    static var appSuccess: Color { Color(uiColor: .systemGreen) }
    static var appWarning: Color { Color(uiColor: .systemOrange) }
    static var appDanger: Color { Color(uiColor: .systemRed) }

    static var appGroupedBackground: Color { Color(uiColor: .systemGroupedBackground) }
    static var appSecondaryBackground: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    static var appTertiaryFill: Color { Color(uiColor: .tertiarySystemFill) }
    static var appSeparator: Color { Color(uiColor: .separator) }
}

extension ShapeStyle where Self == Color {
    static var appBrand: Color { Color.appBrand }
    static var appSuccess: Color { Color.appSuccess }
    static var appWarning: Color { Color.appWarning }
    static var appDanger: Color { Color.appDanger }
}
