import SwiftUI

// MARK: - 页面骨架

/// App Store 式的页面：大标题挂在滚动区顶部，内容自己往下排，底部给悬浮胶囊留出空间。
struct StorePage<Content: View>: View {
    var title: String
    var subtitle: String?
    var trailing: AnyView?
    @ViewBuilder var content: () -> Content

    init(title: String,
         subtitle: String? = nil,
         trailing: AnyView? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.content = content
    }

    var body: some View {
        ZStack {
            FlatBackground()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    content()
                }
                .padding(.top, 6)
                .padding(.bottom, 118)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 34, weight: .bold))
                    .tracking(-0.9)
                    .foregroundStyle(Flat.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Flat.textTertiary)
                }
            }
            Spacer(minLength: 8)
            if let trailing { trailing }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Hero 大卡

struct StoreHero: View {
    var eyebrow: String?
    var title: String
    var subtitle: String
    var symbol: String
    var tint: Color
    var footnote: String?
    var primaryTitle: String?
    var primaryAction: (() -> Void)?
    var secondaryTitle: String?
    var secondaryAction: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    if let eyebrow {
                        Text(eyebrow.uppercased())
                            .font(.system(size: 11, weight: .heavy))
                            .tracking(1.1)
                            .foregroundStyle(tint)
                    }
                    Text(title)
                        .font(.system(size: 27, weight: .bold))
                        .tracking(-0.5)
                        .foregroundStyle(Flat.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Flat.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 12)
                Image(systemName: symbol)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 56, height: 56)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)

            if let footnote {
                Text(footnote)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Flat.textTertiary)
                    .padding(.horizontal, 18)
                    .padding(.top, 10)
            }

            if primaryTitle != nil || secondaryTitle != nil {
                HStack(spacing: 10) {
                    if let primaryTitle, let primaryAction {
                        Button(primaryTitle, action: primaryAction)
                            .buttonStyle(FlatButtonStyle(tint: tint, filled: true, radius: 14, height: 44))
                    }
                    if let secondaryTitle, let secondaryAction {
                        Button(secondaryTitle, action: secondaryAction)
                            .buttonStyle(FlatButtonStyle(tint: tint, filled: false, radius: 14, height: 44))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
        }
        .padding(.bottom, 18)
        .background {
            let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
            ZStack {
                shape.fill(tint.opacity(0.10))
                LinearGradient(colors: [tint.opacity(0.20), tint.opacity(0.02)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                    .clipShape(shape)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(tint.opacity(0.22), lineWidth: 1)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - 横向卡片区

struct StoreShelf<Content: View>: View {
    var title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?
    @ViewBuilder var content: () -> Content

    init(title: String,
         subtitle: String? = nil,
         actionTitle: String? = nil,
         action: (() -> Void)? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .tracking(-0.3)
                        .foregroundStyle(Flat.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Flat.textTertiary)
                    }
                }
                Spacer()
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Flat.accent)
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    content()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - 分组卡片

struct StoreGroup<Content: View>: View {
    var title: String?
    var footnote: String?
    @ViewBuilder var content: () -> Content

    init(title: String? = nil,
         footnote: String? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.footnote = footnote
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Flat.textTertiary)
                    .padding(.horizontal, 24)
            }
            VStack(spacing: 0) {
                content()
            }
            .flatCard(radius: 20)
            if let footnote {
                Text(footnote)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundStyle(Flat.textTertiary)
                    .padding(.horizontal, 24)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct StoreRow: View {
    var icon: String
    var tint: Color
    var title: String
    var detail: String?
    var value: String?
    var showsChevron: Bool = true
    var action: (() -> Void)?

    @ViewBuilder
    var body: some View {
        let row = HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Flat.textPrimary)
                if let detail {
                    Text(detail)
                        .font(.system(size: 11.5))
                        .foregroundStyle(Flat.textTertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            if let value {
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Flat.textSecondary)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Flat.textTertiary)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
        .contentShape(Rectangle())

        if let action {
            Button(action: action) { row }
                .buttonStyle(PressScaleStyle(scale: 0.995))
        } else {
            row
        }
    }
}

struct StoreDivider: View {
    var body: some View {
        Rectangle()
            .fill(Flat.hairline)
            .frame(height: 0.6)
            .padding(.leading, 58)
    }
}

// MARK: - 小卡片

/// 横向滚动里的小卡：图标 + 标题 + 副标题 + 右下角状态
struct StoreTile: View {
    var title: String
    var subtitle: String
    var symbol: String
    var tint: Color
    var badge: String?
    var badgeTint: Color = Flat.textTertiary
    var width: CGFloat = 168
    var action: (() -> Void)?

    var body: some View {
        let card = VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(badgeTint)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(badgeTint.opacity(0.13), in: Capsule())
                }
            }
            Spacer(minLength: 6)
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Flat.textPrimary)
                .lineLimit(1)
            Text(subtitle)
                .font(.system(size: 11.5))
                .foregroundStyle(Flat.textTertiary)
                .lineLimit(1)
        }
        .frame(width: width, height: 108, alignment: .topLeading)
        .flatCard(radius: 20)

        if let action {
            Button(action: action) { card }
                .buttonStyle(PressScaleStyle())
        } else {
            card
        }
    }
}

/// 数字格：大数字 + 小标签
struct StoreMetric: View {
    var value: String
    var label: String
    var tint: Color = Flat.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .tracking(-0.4)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Flat.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// 圆形图标按钮（大标题右侧那种）
struct StoreAvatarButton: View {
    var symbol: String
    var tint: Color = Flat.accent
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(tint.opacity(0.12), in: Circle())
                .overlay(Circle().strokeBorder(tint.opacity(0.18), lineWidth: 1))
        }
        .buttonStyle(PressScaleStyle(scale: 0.92))
    }
}
