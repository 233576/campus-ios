import CoreGraphics

/// 8pt 栅格。视图里禁止写魔法数字间距。
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    /// 页面左右安全边距
    static let page: CGFloat = 16

    /// 列表行最小高度，保证可点区域 ≥ 44
    static let rowMinHeight: CGFloat = 44

    /// 图标圆底
    static let iconCircle: CGFloat = 36
    static let iconCircleLarge: CGFloat = 44
}
