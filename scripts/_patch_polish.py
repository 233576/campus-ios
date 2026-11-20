import io

ROOT = r"C:\Users\Chen\Documents\deepseek-harness\default-workspace\campus-glass\Sources"

# ---------- 1. 卡片：圆角 16 + 轻浮阴影 ----------
p = ROOT + r"\Shared\FlatTheme.swift"
t = io.open(p, encoding="utf-8").read()
t = t.replace("    static let radius: CGFloat = 12\n    static let cardRadius: CGFloat = 12",
              "    static let radius: CGFloat = 16\n    static let cardRadius: CGFloat = 16")
t = t.replace("""            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(GlassPalette.separator, lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))""",
              """            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(GlassPalette.separator, lineWidth: 0.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)""")
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("theme ok")

# ---------- 2. 分段控件：标准 iOS 规格 ----------
for rel in [r"\Laundry\Views\LaundryShell.swift", r"\CampusNet\Views\CampusNetShell.swift"]:
    p = ROOT + rel
    t = io.open(p, encoding="utf-8").read()
    t = t.replace(".clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))",
                  ".clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))")
    t = t.replace("RoundedRectangle(cornerRadius: 7, style: .continuous)\n                        .fill(GlassPalette.surface)\n                        .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)",
                  "RoundedRectangle(cornerRadius: 6, style: .continuous)\n                        .fill(GlassPalette.surface)\n                        .shadow(color: Color.black.opacity(0.10), radius: 3, x: 0, y: 1)")
    io.open(p, "w", encoding="utf-8", newline="\n").write(t)
    print("segment ok", rel)

# ---------- 3. 首页：状态卡 / 操作列表 / 设备选择 ----------
p = ROOT + r"\CampusNet\Views\CampusNetHomeView.swift"
t = io.open(p, encoding="utf-8").read()

# 3a. 删掉状态卡里那条进度条
t = t.replace("""
            FlatProgressBar(progress: progress, tint: stateColor)
""", "")

# 3b. 在线/离线标签：实心浅灰底，不要空心框
t = t.replace("""                Text(store.state == .online ? "在线" : "离线")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(store.state == .online ? Flat.green : Flat.textTertiary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .flatPill(selected: store.state == .online,
                              tint: Flat.green)""",
"""                Text(store.state == .online ? "在线" : "离线")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(store.state == .online ? Flat.green : Flat.textSecondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(store.state == .online ? Flat.green.opacity(0.12) : Flat.surfaceHigh)
                    }""")

# 3c. 四个操作换成一张白卡里的 iOS 列表
start = t.index("    private var actionRow: some View {")
end = t.index("    // MARK: - 设备类型")
new_block = '''    private var actionRow: some View {
        VStack(spacing: 10) {
            Button {
                Task { await store.login() }
            } label: {
                HStack(spacing: 8) {
                    if store.state == .connecting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(buttonTitle)
                        .font(.headline)
                }
            }
            .buttonStyle(FlatButtonStyle(tint: Flat.accent, filled: true, height: 50))
            .disabled(store.state == .connecting)

            VStack(spacing: 0) {
                actionItem(symbol: "arrow.clockwise", title: "检测状态") {
                    Task { await store.refreshState() }
                }
                FlatDivider(inset: 52)
                actionItem(symbol: "safari", title: "内置网页") {
                    openPortal()
                }
                FlatDivider(inset: 52)
                actionItem(symbol: "text.insert", title: "网页表单登录") {
                    Task { await store.webLoginNow() }
                }
                FlatDivider(inset: 52)
                actionItem(symbol: "iphone.and.arrow.forward",
                           title: store.needsRebind ? "换绑到本机（需要确认）" : "换绑到本机") {
                    Task { await store.rebindDevice() }
                }
            }
            .flatCard()
            .disabled(store.state == .connecting)
        }
    }

    private func actionItem(symbol: String,
                            title: String,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Flat.accent)
                    .frame(width: 24)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Flat.textPrimary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Flat.textTertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

'''
t = t[:start] + new_block + t[end:]

# 3d. 设备三类：未选中浅灰底，选中浅蓝底
t = t.replace("""                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selected ? Flat.accent.opacity(0.12) : Color.clear)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(selected ? Color.clear : Flat.separator, lineWidth: 0.5)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))""",
"""                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selected ? Flat.accent.opacity(0.12) : Flat.surfaceHigh)
                        }""")

# 3e. 自定义机型：浅灰实心
t = t.replace("""                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .flatPill()""",
"""                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background {
                            Capsule(style: .continuous).fill(Flat.surfaceHigh)
                        }""")

io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("home ok", len(t))
