import io

root = r"C:\Users\Chen\Documents\deepseek-harness\default-workspace\campus-glass\Sources"

NEW_LAUNDRY = '''    private var segmentBar: some View {
        GlassGroup(spacing: 14) {
            HStack(spacing: 2) {
                ForEach(LaundryTab.allCases) { item in
                    segmentButton(item)
                }
            }
            .padding(4)
            .frame(height: barHeight)
            .liquidGlassSurface(radius: barHeight / 2)
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(GlassPalette.edge.opacity(0.55), lineWidth: 0.8)
            }
            .shadow(color: GlassPalette.shadow, radius: 14, x: 0, y: 8)
        }
        .padding(.horizontal, 18)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private func segmentButton(_ item: LaundryTab) -> some View {
        let selected = tab == item
        return Button {
            guard tab != item else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
                tab = item
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: item.symbol)
                    .font(.system(size: 13, weight: .semibold))
                Text(item.title)
                    .font(.system(size: 12.5, weight: .semibold))
            }
            .foregroundStyle(selected ? Color.white : GlassPalette.textSecondary)
            .frame(maxWidth: .infinity)
            .frame(height: barHeight - 8)
            .background {
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
                    .matchedGeometryEffect(id: "laundrySegment", in: segment)
                    .shadow(color: GlassPalette.accent.opacity(0.30), radius: 8, y: 3)
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(PressScaleStyle(scale: 0.95))
    }
}
'''

NEW_NET = NEW_LAUNDRY.replace("LaundryTab", "CampusNetTab").replace("laundrySegment", "campusNetSegment")


def patch(path, new_tail, marker):
    text = io.open(path, encoding="utf-8").read()
    idx = text.index(marker)
    out = text[:idx] + new_tail
    io.open(path, "w", encoding="utf-8", newline="\n").write(out)
    print("patched", path, len(out))


patch(root + r"\Laundry\Views\LaundryShell.swift", NEW_LAUNDRY, "    private var segmentBar: some View {")
patch(root + r"\CampusNet\Views\CampusNetShell.swift", NEW_NET, "    private var segmentBar: some View {")
