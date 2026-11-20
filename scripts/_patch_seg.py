import io

ROOT = r"C:\Users\Chen\Documents\deepseek-harness\default-workspace\campus-glass\Sources"

SEGMENT = '''    private var segmentBar: some View {
        HStack(spacing: 0) {
            ForEach(%(TAB)s.allCases) { item in
                segmentButton(item)
            }
        }
        .padding(2)
        .frame(height: 34)
        .background(GlassPalette.surfaceHigh)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func segmentButton(_ item: %(TAB)s) -> some View {
        let selected = tab == item
        return Button {
            guard tab != item else { return }
            withAnimation(.easeInOut(duration: 0.18)) {
                tab = item
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: item.symbol)
                    .font(.system(size: 12, weight: .medium))
                Text(item.title)
                    .font(.system(size: 13, weight: selected ? .semibold : .regular))
            }
            .foregroundStyle(selected ? GlassPalette.textPrimary : GlassPalette.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(GlassPalette.surface)
                        .shadow(color: Color.black.opacity(0.06), radius: 2, x: 0, y: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
'''

for rel, tab in [(r"\Laundry\Views\LaundryShell.swift", "LaundryTab"),
                 (r"\CampusNet\Views\CampusNetShell.swift", "CampusNetTab")]:
    p = ROOT + rel
    text = io.open(p, encoding="utf-8").read()
    idx = text.index("    private var segmentBar: some View {")
    out = text[:idx] + (SEGMENT % {"TAB": tab})
    io.open(p, "w", encoding="utf-8", newline="\n").write(out)
    print("segment", rel, len(out))
