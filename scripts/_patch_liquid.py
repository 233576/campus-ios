import io

ROOT = r"C:\Users\Chen\Documents\deepseek-harness\default-workspace\campus-glass\Sources"

# ============ 1. FlatTheme：渐变底 + 液态玻璃卡片 + 果冻按钮 ============
p = ROOT + r"\Shared\FlatTheme.swift"
t = io.open(p, encoding="utf-8").read()

t = t.replace("    static let radius: CGFloat = 16\n    static let cardRadius: CGFloat = 16",
              "    static let radius: CGFloat = 20\n    static let cardRadius: CGFloat = 20")

# 1a. 背景：微渐变（暗色也留一点冷调，不然玻璃发灰）
old_bg = """/// 全局底色：干净的浅灰（暗色为纯黑），不铺任何渐变和光斑。
struct FlatBackground: View {
    var body: some View {
        GlassPalette.background.ignoresSafeArea()
    }
}"""
new_bg = """/// 全局底：一层极浅的斜向渐变。
///
/// 玻璃全靠背后有东西可折射 —— 纯色底上不管怎么调材质都只是一块灰板，
/// 所以这里必须留一层很淡的冷色过渡（浅灰 → 浅蓝）。
struct FlatBackground: View {
    @Environment(\\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(
            colors: scheme == .dark
                ? [Color(red: 0.06, green: 0.06, blue: 0.08), Color(red: 0.03, green: 0.05, blue: 0.09)]
                : [Color(red: 0.95, green: 0.95, blue: 0.97), Color(red: 0.90, green: 0.95, blue: 1.00)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}"""
assert old_bg in t
t = t.replace(old_bg, new_bg)

# 1b. 卡片：ultraThinMaterial + 圆角 20 + 玻璃边缘高光 + 弥散阴影
old_card = """    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(GlassPalette.separator, lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)
    }"""
new_card = """    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(.ultraThinMaterial, in: shape)
            .clipShape(shape)
            .overlay {
                // 边缘高光：左上最亮、右下几乎透明，模拟玻璃把光折过来
                shape.stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.85), Color.white.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
            .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 8)
    }"""
assert old_card in t
t = t.replace(old_card, new_card)

# 1c. 强调卡：同样玻璃，只把描边换成 tint
old_tint = """    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(GlassPalette.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(tint.opacity(0.35), lineWidth: 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }"""
new_tint = """    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(.ultraThinMaterial, in: shape)
            .clipShape(shape)
            .overlay {
                shape.stroke(tint.opacity(0.35), lineWidth: 1)
            }
            .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 8)
    }"""
assert old_tint in t
t = t.replace(old_tint, new_tint)

# 1d. 输入框：也是一层薄材质
t = t.replace("""            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
            }
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(GlassPalette.separator, lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))""",
"""            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.55), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))""")

# 1e. 按钮：实心 = 蓝色竖向渐变 + 顶部高光 + 蓝色辉光；次要 = 薄材质
old_btn = """            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(filled ? tint : GlassPalette.surfaceHigh)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)"""
new_btn = """            .background {
                let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
                if filled {
                    shape.fill(
                        LinearGradient(
                            colors: [Color.blue, Color(red: 0, green: 0.40, blue: 0.90)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                } else {
                    shape.fill(.ultraThinMaterial)
                }
            }
            .overlay {
                let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
                shape.stroke(
                    LinearGradient(
                        colors: filled
                            ? [Color.white.opacity(0.65), Color.white.opacity(0.05)]
                            : [Color.white.opacity(0.75), Color.white.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: filled ? Color.blue.opacity(0.4) : Color.black.opacity(0.05),
                    radius: filled ? 10 : 6,
                    x: 0,
                    y: filled ? 5 : 3)
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.9), value: configuration.isPressed)"""
assert old_btn in t
t = t.replace(old_btn, new_btn)

# 1f. 分隔线：玻璃卡里用白 30%
t = t.replace("""struct FlatDivider: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(GlassPalette.separator)
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}""",
"""struct FlatDivider: View {
    var inset: CGFloat = 0

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.35))
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}""")

io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("theme ok", len(t))

# ============ 2. 分段控件：systemGray6 底 + 白色滑块 ============
for rel in [r"\Laundry\Views\LaundryShell.swift", r"\CampusNet\Views\CampusNetShell.swift"]:
    p = ROOT + rel
    t = io.open(p, encoding="utf-8").read()
    t = t.replace(".background(GlassPalette.surfaceHigh)\n        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))",
                  ".background(Color(UIColor.systemGray6))\n        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))")
    t = t.replace(".shadow(color: Color.black.opacity(0.10), radius: 3, x: 0, y: 1)",
                  ".shadow(color: Color.black.opacity(0.10), radius: 2, x: 0, y: 1)")
    io.open(p, "w", encoding="utf-8", newline="\n").write(t)
    print("segment", rel)

# ============ 3. 底部 TabBar：ultraThinMaterial + 白 30% 细线 ============
p = ROOT + r"\Views\CampusShell.swift"
t = io.open(p, encoding="utf-8").read()
t = t.replace("""            .frame(height: 48)
            .padding(.top, 4)
            .background(GlassPalette.surface)
        }
        .background(GlassPalette.surface)""",
"""            .frame(height: 48)
            .padding(.top, 4)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.30))
                .frame(height: 0.5)
        }""")
t = t.replace("""        VStack(spacing: 0) {
            FlatDivider()
            HStack(spacing: 0) {""", """        VStack(spacing: 0) {
            HStack(spacing: 0) {""")
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("tabbar ok", len(t))

# ============ 4. 设备选择：选中 blue 0.15 + blue 0.3 描边 ============
p = ROOT + r"\CampusNet\Views\CampusNetHomeView.swift"
t = io.open(p, encoding="utf-8").read()
t = t.replace("""                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selected ? Flat.accent.opacity(0.12) : Flat.surfaceHigh)
                        }""",
"""                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selected ? Color.blue.opacity(0.15) : Color.clear)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(selected ? Color.blue.opacity(0.30) : Color.white.opacity(0.45),
                                        lineWidth: 1)
                        }""")
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("device ok", len(t))
