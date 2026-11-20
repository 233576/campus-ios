import io
import re

root = r"C:\Users\Chen\Documents\deepseek-harness\default-workspace\campus-glass\Sources"

# ---------- 1. CampusShell：选中项改成"淡玻璃块 + 强调色文字"，玻璃更透 ----------
p = root + r"\Views\CampusShell.swift"
t = io.open(p, encoding="utf-8").read()

t = t.replace(
    """            .padding(5)
            .frame(height: barHeight)
            .liquidGlassSurface(radius: barHeight / 2)""",
    """            .padding(5)
            .frame(height: barHeight)
            .liquidGlassSurface(radius: barHeight / 2, tintOpacity: 0.04)""",
)

old_bg = """            .background {
                if selected {
                    let shape = Capsule(style: .continuous)
                    ZStack {
                        shape.fill(
                            LinearGradient(colors: [GlassPalette.accent, GlassPalette.accent.opacity(0.82)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        shape.fill(
                            LinearGradient(colors: [Color.white.opacity(0.35), Color.clear],
                                           startPoint: .top, endPoint: .center)
                        )
                    }
                    .matchedGeometryEffect(id: "sectionIndicator", in: indicator)
                    .shadow(color: GlassPalette.accent.opacity(0.35), radius: 10, y: 4)
                }
            }"""
new_bg = """            .background {
                if selected {
                    Capsule(style: .continuous)
                        .fill(GlassPalette.surfaceHigh)
                        .matchedGeometryEffect(id: "sectionIndicator", in: indicator)
                        .shadow(color: GlassPalette.shadow.opacity(0.6), radius: 6, y: 2)
                }
            }"""
assert old_bg in t
t = t.replace(old_bg, new_bg)

t = t.replace(
    ".foregroundStyle(selected ? Color.white : GlassPalette.textSecondary)",
    ".foregroundStyle(selected ? GlassPalette.accent : GlassPalette.textSecondary)",
)
io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("campus shell ok", len(t))

# ---------- 2. 两个模块分段：同样的淡玻璃块 ----------
for rel, seg_id in [(r"\Laundry\Views\LaundryShell.swift", "laundrySegment"),
                    (r"\CampusNet\Views\CampusNetShell.swift", "campusNetSegment")]:
    p = root + rel
    t = io.open(p, encoding="utf-8").read()
    t = t.replace(
        """            .padding(4)
            .frame(height: barHeight)
            .liquidGlassSurface(radius: barHeight / 2)""",
        """            .padding(4)
            .frame(height: barHeight)
            .liquidGlassSurface(radius: barHeight / 2, tintOpacity: 0.04)""",
    )
    old = """            .background {
                if selected {
                    let shape = Capsule(style: .continuous)
                    ZStack {
                        shape.fill(
                            LinearGradient(colors: [GlassPalette.accent, GlassPalette.accent.opacity(0.82)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        shape.fill(
                            LinearGradient(colors: [Color.white.opacity(0.32), Color.clear],
                                           startPoint: .top, endPoint: .center)
                        )
                    }
                    .matchedGeometryEffect(id: "%s", in: segment)
                    .shadow(color: GlassPalette.accent.opacity(0.30), radius: 8, y: 3)
                }
            }""" % seg_id
    new = """            .background {
                if selected {
                    Capsule(style: .continuous)
                        .fill(GlassPalette.surfaceHigh)
                        .matchedGeometryEffect(id: "%s", in: segment)
                        .shadow(color: GlassPalette.shadow.opacity(0.6), radius: 5, y: 2)
                }
            }""" % seg_id
    assert old in t, rel
    t = t.replace(old, new)
    t = t.replace(
        ".foregroundStyle(selected ? Color.white : GlassPalette.textSecondary)",
        ".foregroundStyle(selected ? GlassPalette.accent : GlassPalette.textSecondary)",
    )
    io.open(p, "w", encoding="utf-8", newline="\n").write(t)
    print("segmented ok", rel, len(t))
