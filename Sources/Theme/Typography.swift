import SwiftUI

/// 全部走 Dynamic Type 语义字体，禁用 .system(size:)。
enum Typography {
    static let pageTitle = Font.largeTitle.weight(.bold)
    static let sectionTitle = Font.title3.weight(.semibold)
    static let headline = Font.headline
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2

    static let rowTitle = Font.body
    static let rowSubtitle = Font.caption
    static let mono = Font.caption.monospacedDigit()
    static let monoValue = Font.body.monospacedDigit()
}
