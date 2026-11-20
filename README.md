# 校园助手 · iOS

把两件事放进一个 App：**宿舍洗衣机**（胖乖生活 / qiekj）和**校园网认证**（GiWiFi）。
底部只有两个入口 —— 洗衣、校园网。没有广告、没有商城、没有信息流。

原生化实现：SwiftUI + XcodeGen，无第三方依赖（微信支付走官方 OpenSDK）。

| | 洗衣 | 校园网 |
| --- | --- | --- |
| 登录 | 手机号验证码 / 粘贴 token | 账号密码 / 网页表单登录 / 多账号 |
| 核心 | 扫码识别机器 → 选套餐 → 下单 → 支付 | 探测网关 → 认证 → 保活 → 换绑 |
| 状态 | 洗涤倒计时、设备异常提示、订单列表 | 在线时长、网关名记忆、43 自动换绑 |
| 支付 | 微信（payType 31）/ 支付宝 / 余额 | — |

## 目录

```
Sources/
  App/CampusApp.swift              入口，注入两个 Store
  Views/CampusShell.swift          顶部两 Tab + 悬浮胶囊导航
  Shared/                          共用：Crypto（MD5/SHA256/AES）、Keychain、FlatTheme
  Laundry/                         洗衣模块
    Core/  LaundryStore、PGClient、PGProtocol、Models、WeChatPay
    Views/ LaundryShell（顶部分段）、LaundryView、ScanSheet、PaySheet、OrdersView …
  CampusNet/                       校园网模块
    Core/  CampusNetStore、GiWifiClient、GiWifiProtocol、NetworkIdentity、TerminalProfile
    Views/ CampusNetShell（顶部分段）、CampusNetHomeView、PortalWebView、AccountsView …
```

两层导航：底部是全局的两个板块；每个板块内部用顶部分段切换子页（洗衣：洗衣/订单/日志/设置，校园网：主页/日志/设置），这样底部导航永远只有两个入口。

## 构建

CI（推荐）：

```bash
git push origin main     # 或 Actions 页面手动 Run workflow
```

workflow 会：装 XcodeGen → 下载 WeChat OpenSDK 2.0.9 → `xcodegen` → `xcodebuild`（无签名）→ 打包 `dist/Campus-unsigned.ipa`。

本机（macOS）：

```bash
bash scripts/build-ipa.sh
```

Windows 一键（建仓库 + 触发构建 + 回传 ipa）：

```powershell
$env:ZF_GITHUB_TOKEN = "ghp_xxx"
powershell -ExecutionPolicy Bypass -File scripts\publish-github.ps1 -Public
```

产物未签名，用 Sideloadly / AltStore / TrollStore 侧载，免费证书 7 天。

## 已知边界

- **洗衣**：扫码得到的 NQT 由官方扫码页 `/skip` 转成 goodsId；`/goods/scan/v2` 在 token 为空时会回 `code=-1 版本过低`（其实是无登录态的兜底文案，不是版本问题）。
- **洗衣支付**：微信渠道必须 `payType=31`，`prepayParam` 是**小程序 JSAPI** 参数（无 `partnerId`）。App 内优先用 OpenSDK 的 `PayReq`，解析不出时退到 `weixin://wap/pay`，再不行给二维码 + 「复制支付串」。
- **校园网**：`CHALLENGE_ERR_DENY` 基本都是 `nasName` 与真实网关不一致；`102` 是同一账号同 IP 短时间内重复 authLogin 的频控，重试前必须等 5 秒以上。
- 洗衣的局域网信息、校园网的定位权限只在需要时请求。

## 许可

洗衣模块参考 [pangguai-ios](https://github.com/233576/pangguai-ios)，校园网模块参考 [giwifi-ios](https://github.com/233576/giwifi-ios)，均为本项目自有实现。
