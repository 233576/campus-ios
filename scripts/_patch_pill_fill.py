import io
root = r"C:\Users\Chen\Documents\deepseek-harness\default-workspace\campus-glass\Sources"
files = [r"\Views\CampusShell.swift", r"\Laundry\Views\LaundryShell.swift", r"\CampusNet\Views\CampusNetShell.swift"]
old = ".fill(GlassPalette.surfaceHigh)"
new = ".fill(Color.dyn(light: 0xFFFFFF, dark: 0xFFFFFF, lightAlpha: 0.52, darkAlpha: 0.13))"
for rel in files:
    p = root + rel
    t = io.open(p, encoding="utf-8").read()
    assert old in t, rel
    t = t.replace(old, new)
    io.open(p, "w", encoding="utf-8", newline="\n").write(t)
    print("ok", rel)
