import io

P = r"C:\Users\Chen\Documents\deepseek-harness\default-workspace\campus-glass\Sources\CampusNet\Views\CampusNetHomeView.swift"
t = io.open(P, encoding="utf-8").read()

# 次级按钮：紫/橙 -> 统一的浅灰底
t = t.replace(".buttonStyle(FlatButtonStyle(tint: Flat.purple, filled: false, height: 42))",
              ".buttonStyle(FlatButtonStyle(tint: Flat.accent, filled: false, height: 42))")
t = t.replace(".buttonStyle(FlatButtonStyle(tint: Flat.orange, filled: store.needsRebind, height: 42))",
              ".buttonStyle(FlatButtonStyle(tint: Flat.accent, filled: store.needsRebind, height: 42))")
t = t.replace(".tint(Flat.orange)", ".tint(Flat.accent)")

# 三类设备按钮：未选中=透明+灰，选中=浅蓝底+蓝
old = """                        .foregroundStyle(selected ? Flat.accent : Flat.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .flatPill(selected: selected)"""
new = """                        .foregroundStyle(selected ? Flat.accent : Flat.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selected ? Flat.accent.opacity(0.12) : Color.clear)
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(selected ? Color.clear : Flat.separator, lineWidth: 0.5)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))"""
assert old in t
t = t.replace(old, new)

io.open(P, "w", encoding="utf-8", newline="\n").write(t)
print("home ok", len(t))
