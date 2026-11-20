import io
import os
import re

ROOT = r"C:\Users\Chen\Documents\deepseek-harness\default-workspace\campus-glass\Sources"

# ---------- 1. 内容底部留白：底部 TabBar 改成 safeAreaInset 后不再需要 78 ----------
targets = [
    r"\Laundry\Views\LaundryView.swift",
    r"\Laundry\Views\OrdersView.swift",
    r"\Laundry\Views\LaundryLogView.swift",
    r"\Laundry\Views\LaundrySettingsView.swift",
    r"\CampusNet\Views\CampusNetHomeView.swift",
    r"\CampusNet\Views\CampusNetLogView.swift",
    r"\CampusNet\Views\CampusNetSettingsView.swift",
]
for rel in targets:
    p = ROOT + rel
    t = io.open(p, encoding="utf-8").read()
    t = t.replace(".padding(.bottom, 78)", ".padding(.bottom, 16)")
    io.open(p, "w", encoding="utf-8", newline="\n").write(t)
    print("padding", rel)

# ---------- 2. 隐藏各页面 NavigationBar 的横幅标题 ----------
nav = [
    r"\CampusNet\Views\CampusNetHomeView.swift",
    r"\CampusNet\Views\CampusNetLogView.swift",
    r"\CampusNet\Views\CampusNetSettingsView.swift",
]
for rel in nav:
    p = ROOT + rel
    t = io.open(p, encoding="utf-8").read()
    t = t.replace('            .navigationTitle("GiWiFi")\n', "")
    t = t.replace('            .navigationTitle("运行日志")\n', "")
    t = t.replace('            .navigationTitle("设置")\n', "")
    t = t.replace("            .navigationBarTitleDisplayMode(.inline)\n", "")
    t = t.replace("            .toolbarBackground(Flat.background, for: .navigationBar)\n", "")
    t = t.replace("            .toolbarBackground(.visible, for: .navigationBar)\n",
                  "            .toolbar(.hidden, for: .navigationBar)\n")
    io.open(p, "w", encoding="utf-8", newline="\n").write(t)
    print("nav", rel)
