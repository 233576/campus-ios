import SwiftUI

/// 组件预览：一屏铺开所有基础组件与状态，用来验收主题是不是一套。
///
/// 这是个纯展示页，不参与业务，接在「校园网设置 → 关于」里手动打开即可。
struct ComponentPreviewView: View {
    @State private var badgeKind: StatusBadgeKind = .brand
    @State private var demoText = ""

    var body: some View {
        AppList {
            buttonsSection
            badgesSection
            iconsSection
            rowsSection
            typographySection
            emptySection
        }
        .appNavigation(title: "组件预览", subtitle: "Theme & Components")
    }

    // MARK: - 按钮

    private var buttonsSection: some View {
        Section {
            Button("主操作 · 玻璃醒目态") {}
                .buttonStyle(GlassButtonStyle(role: .primary))

            Button("次操作 · 普通玻璃") {}
                .buttonStyle(GlassButtonStyle(role: .secondary))

            HStack(spacing: Spacing.m) {
                Button("小号次操作") {}
                    .buttonStyle(GlassButtonStyle(role: .secondary, fullWidth: false))
                Button("纯文字") {}
                    .buttonStyle(GlassButtonStyle(role: .plain, fullWidth: false))
                Spacer(minLength: 0)
            }
        } header: {
            Text("GlassButton")
        } footer: {
            Text("开启「减弱透明度」后 primary / secondary 会自动退化成实心色块。")
                .font(Typography.caption2)
        }
    }

    // MARK: - 徽标

    private var badgesSection: some View {
        Section {
            HStack(spacing: Spacing.s) {
                StatusBadge("在线", kind: .success)
                StatusBadge("离线", kind: .neutral)
                StatusBadge("待支付", kind: .warning)
                StatusBadge("失败", kind: .danger)
                StatusBadge("会员", kind: .brand)
                Spacer(minLength: 0)
            }
            .padding(.vertical, Spacing.xxs)
        } header: {
            Text("StatusBadge")
        }
    }

    // MARK: - 图标

    private var iconsSection: some View {
        Section {
            HStack(spacing: Spacing.l) {
                AppIconCircle(symbol: "washer.fill", tint: .appBrand)
                AppIconCircle(symbol: "wifi", tint: .appSuccess)
                AppIconCircle(symbol: "exclamationmark.triangle.fill", tint: .appWarning)
                AppIconCircle(symbol: "xmark", tint: .appDanger)
                AppIconCircle(symbol: "gearshape.fill", tint: .secondary, size: Spacing.iconCircleLarge)
                Spacer(minLength: 0)
            }
            .padding(.vertical, Spacing.xs)
        } header: {
            Text("AppIconCircle")
        } footer: {
            Text("36pt 圆底 + 语义色图标；列表行里一律用它，禁止品牌色实心块。")
                .font(Typography.caption2)
        }
    }

    // MARK: - 列表行

    private var rowsSection: some View {
        Section {
            HStack(spacing: Spacing.m) {
                AppIconCircle(symbol: "person.fill", tint: .appBrand)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("带图标的行").font(Typography.rowTitle)
                    Text("副标题说明文字").font(Typography.rowSubtitle).foregroundStyle(.secondary)
                }
                Spacer(minLength: Spacing.s)
                AppChevron()
            }
            .padding(.vertical, Spacing.xxs)

            LabeledContent("键") {
                Text("值").font(Typography.monoValue).foregroundStyle(.secondary)
            }

            TextField("输入框（等宽）", text: $demoText)
                .font(Typography.mono)

            Button("可点行") {}
                .font(Typography.body)
                .foregroundStyle(Color.appBrand)
        } header: {
            Text("AppList 行")
        }
    }

    // MARK: - 字阶

    private var typographySection: some View {
        Section {
            Text("pageTitle").font(Typography.pageTitle)
            Text("sectionTitle").font(Typography.sectionTitle)
            Text("headline").font(Typography.headline)
            Text("body").font(Typography.body)
            Text("callout").font(Typography.callout)
            Text("subheadline").font(Typography.subheadline)
            Text("footnote").font(Typography.footnote)
            Text("caption").font(Typography.caption)
            Text("caption2").font(Typography.caption2)
            Text("mono 0123456789").font(Typography.mono)
        } header: {
            Text("Typography")
        } footer: {
            Text("全部走 Dynamic Type，禁止 .system(size:)。")
                .font(Typography.caption2)
        }
    }

    // MARK: - 空状态

    private var emptySection: some View {
        Section {
            AppEmptyState(title: "还没有数据",
                          message: "空状态统一用 ContentUnavailableView，不画插图、不加边框。",
                          symbol: "tray",
                          actionTitle: "刷新一下") {}
                .frame(minHeight: 220)
                .listRowBackground(Color.clear)
        } header: {
            Text("AppEmptyState")
        }
    }
}
