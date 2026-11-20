import io

p = r"C:\Users\Chen\Documents\deepseek-harness\default-workspace\campus-glass\Sources\Shared\FlatTheme.swift"
t = io.open(p, encoding="utf-8").read()

# SwiftUI 在 iOS 26 有同名类型 Glass，避开它
t = t.replace("enum Glass {", "enum GlassPalette {")
t = t.replace("typealias Flat = GlassCompat\nenum GlassCompat {", "enum Flat {")
t = t.replace("Glass.", "GlassPalette.")

io.open(p, "w", encoding="utf-8", newline="\n").write(t)
print("patched, Glass. occurrences left:", t.count("\nGlass."))
print("has GlassCompat:", "GlassCompat" in t)
print("has enum Flat:", "enum Flat {" in t)
