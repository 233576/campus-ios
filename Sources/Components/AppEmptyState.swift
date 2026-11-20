import SwiftUI

/// 空状态。系统组件，不自绘卡片、不加边框。
struct AppEmptyState: View {
    var title: String
    var message: String
    var symbol: String
    var actionTitle: String?
    var action: (() -> Void)?

    init(title: String,
         message: String,
         symbol: String = "tray",
         actionTitle: String? = nil,
         action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.symbol = symbol
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(GlassButtonStyle(role: .secondary, fullWidth: false))
            }
        }
    }
}
