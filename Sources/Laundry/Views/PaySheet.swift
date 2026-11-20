import SwiftUI
import UIKit
import WebKit

/// 支付面板：微信 / 支付宝 / 余额，三个渠道都能在同一笔订单上切换（订单号不变）。
///
/// - 微信：拿 `prepayParam`，可能是 `mweb_url`（走应用内网页，网页里会自己唤起微信）、
///   `code_url`（画二维码）、`weixin://`（直接 open），也可能是 App 支付参数（没有 SDK 调不起来，只能提示）。
/// - 支付宝：拼 `alipays://platformapi/startapp?appId=20000125&orderSuffix=…`，同时出二维码。
/// - 余额：`/pay/unify/pay` 当场扣款。
struct PaySheet: View {
    let payment: PendingPayment

    @EnvironmentObject var store: LaundryStore
    @Environment(\.dismiss) private var dismiss

    @State var paying = false
    @State var switching = false
    @State var alertMessage: String?
    @State var showingRecharge = false
    @State var showingWebPay = false
    @State var webPayURL: URL?
    @State var showRaw = false
    @State var showParam = false

    var current: PendingPayment { store.pending ?? payment }
    var payType: Int { current.payType }
    var handoff: PGProtocol.PayHandoff {
        PGProtocol.handoff(param: current.prepayParam, payType: payType)
    }
    var balanceText: String {
        let text = store.user?.balanceText ?? ""
        return text.isEmpty ? "—" : text
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FlatBackground()

                ScrollView {
                    VStack(spacing: 14) {
                        amountCard
                        channelPicker
                        payArea
                        balanceCard
                        infoCard
                        actionList
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(PGProtocol.payTitle(payType))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                        .foregroundStyle(Flat.textSecondary)
                }
            }
            .sheet(isPresented: $showingRecharge) {
                RechargeView().environmentObject(store)
            }
            .sheet(isPresented: $showingWebPay) {
                if let url = webPayURL {
                    PayWebView(url: url) { showingWebPay = false }
                        .environmentObject(store)
                }
            }
            .alert("提示", isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )) {
                Button("好", role: .cancel) { alertMessage = nil }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    // MARK: - 卡片

    @ViewBuilder
    private var payArea: some View {
        if payType == PGProtocol.payTypeWallet {
            EmptyView()
        } else if current.prepayParam.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("没有拿到支付串")
                    .font(Typography.subheadline.weight(.semibold))
                    .foregroundStyle(Flat.textPrimary)
                Text(store.lastPrepayError ?? "点下面的「重新取支付串」再试一次。")
                    .font(Typography.caption)
                    .foregroundStyle(Flat.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .flatCard(fill: Flat.surfaceLow)
        } else {
            VStack(spacing: 12) {
                if let text = handoff.qr, handoff.showQR {
                    QRCodeView(text: text, size: 208)
                        .padding(.top, 4)
                    Text(payType == PGProtocol.payTypeWeChat
                         ? "用微信「扫一扫」扫这个码付款（也可以截屏后用相册识别）"
                         : "用支付宝「扫一扫」扫这个码付款")
                        .font(Typography.caption)
                        .foregroundStyle(Flat.textTertiary)
                        .multilineTextAlignment(.center)
                }

                if !handoff.note.isEmpty {
                    Text(handoff.note)
                        .font(Typography.caption2)
                        .foregroundStyle(Flat.orange)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(14)
            .flatCard()
        }
    }

    // MARK: - 动作

    func switchTo(_ type: Int) async {
        switching = true
        let error = await store.switchPayType(type)
        switching = false
        if let error = error {
            alertMessage = error
        } else if store.pending == nil {
            dismiss()
        }
    }

    func openPayTarget() {
        // 微信 App 支付参数：只有 OpenSDK 的 PayReq 能验签通过，
        // 拼 weixin://wap/pay 会被微信判「支付验证签名失败」。
        if payType == PGProtocol.payTypeWeChat {
            let fields = PGProtocol.payFields(current.prepayParam)
            if WeChatPay.parse(fields) != nil {
                WeChatPay.pay(fields) { ok, reason in
                    guard !ok else { return }
                    // SDK 发不出去（常见：服务端 sign 绑了官方包名）就退回上一版能用的 weixin://wap/pay
                    let fallback = handoff.schemes
                    if !fallback.isEmpty {
                        openSchemes(fallback, index: 0)
                    } else {
                        alertMessage = reason.isEmpty
                            ? "微信没有接受这次支付请求，可以换余额或用另一台手机扫码。"
                            : reason + "（也可以换余额，或点「复制支付串」发我）"
                    }
                }
                return
            }
        }

        let plan = handoff
        if !plan.schemes.isEmpty {
            openSchemes(plan.schemes, index: 0)
            return
        }
        if let web = plan.web {
            webPayURL = web
            showingWebPay = true
            return
        }
        if plan.isWechatAppParam {
            UIPasteboard.general.string = current.prepayParam
            alertMessage = "这是微信 App 支付参数，weixin://wap/pay 没被系统接受。参数已复制到剪贴板，"
                + "可以换余额、换支付宝，或者用另一台手机扫二维码。"
            return
        }
        alertMessage = "没有可用的跳转方式，先用另一台手机扫码吧"
    }

    /// 依次尝试多个 scheme（微信 wap/pay 有几种字段组合，能通一种就够）。
    func openSchemes(_ urls: [URL], index: Int) {
        guard index < urls.count else {
            UIPasteboard.general.string = current.prepayParam
            alertMessage = "系统没有接受任何一个\(PGProtocol.payTitle(payType))跳转链接。"
                + "支付串已复制到剪贴板；也可以换渠道，或用另一台手机扫码。"
            return
        }
        let url = urls[index]
        UIApplication.shared.open(url, options: [:]) { ok in
            if !ok {
                Task { @MainActor in
                    openSchemes(urls, index: index + 1)
                }
            }
        }
    }

    func payWithWallet() async {
        guard !paying else { return }
        paying = true
        let error = await store.payWithWallet()
        paying = false
        if let error = error {
            alertMessage = error
        } else {
            dismiss()
        }
    }

    func reprepare() async {
        switching = true
        await store.reopenPrepay()
        switching = false
        if let error = store.lastPrepayError {
            alertMessage = error
        }
    }

    func refreshStatus() async {
        switching = true
        let paid = await store.checkPendingPayment()
        switching = false
        if paid {
            dismiss()
        } else {
            alertMessage = "还没查到付款成功。等几秒再点一次，或者去「订单」页看一下。"
        }
    }

    func cancelOrder() async {
        guard !paying else { return }
        paying = true
        await store.cancelPending()
        paying = false
        dismiss()
    }
}

/// 应用内打开的支付网页（微信 H5 支付 / 支付宝网页版都在这里跑）。
private struct PayWebView: UIViewControllerRepresentable {
    let url: URL
    let onClose: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let controller = UIViewController()
        controller.view.backgroundColor = UIColor(Flat.background)

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        let web = WKWebView(frame: .zero, configuration: config)
        web.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) "
            + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1"
        web.translatesAutoresizingMaskIntoConstraints = false
        controller.view.addSubview(web)
        NSLayoutConstraint.activate([
            web.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
            web.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
            web.topAnchor.constraint(equalTo: controller.view.topAnchor),
            web.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
        ])
        web.load(URLRequest(url: url))

        let nav = UINavigationController(rootViewController: controller)
        controller.navigationItem.title = "付款"
        controller.navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "关闭", style: .plain, target: context.coordinator,
            action: #selector(Coordinator.close))
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onClose: onClose) }

    final class Coordinator: NSObject {
        private let onClose: () -> Void
        init(onClose: @escaping () -> Void) { self.onClose = onClose }
        @objc func close() { onClose() }
    }
}
