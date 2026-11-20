import SwiftUI
import UIKit

/// 校园网日志：时间戳等宽定宽，内容按语义着色。
struct CampusNetLogView: View {
    @EnvironmentObject private var store: CampusNetStore

    @State private var query = ""
    @State private var copied = false
    @State private var confirmingClear = false

    var body: some View {
        Group {
            if store.logs.isEmpty {
                AppEmptyState(title: "还没有日志",
                              message: "认证过程中的每一步都会记在这里，排查问题时可以直接复制。",
                              symbol: "text.alignleft")
            } else {
                AppList {
                    Section {
                        ForEach(filtered) { line in
                            row(line)
                        }
                    }
                }
            }
        }
        .appNavigation(title: "校园网日志")
        .searchable(text: $query, prompt: "搜索日志")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                GlassContainer(spacing: Spacing.s) {
                    HStack(spacing: Spacing.s) {
                        GlassToolbarButton(symbol: copied ? "checkmark" : "doc.on.doc",
                                           tint: .secondary) {
                            UIPasteboard.general.string = store.logText
                            copied = true
                        }
                        .accessibilityLabel("复制全部日志")

                        GlassToolbarButton(symbol: "trash", tint: .appDanger) {
                            confirmingClear = true
                        }
                        .accessibilityLabel("清空日志")
                    }
                }
            }
        }
        .confirmationDialog("清空全部日志？", isPresented: $confirmingClear, titleVisibility: .visible) {
            Button("清空", role: .destructive) { store.clearLogs() }
            Button("取消", role: .cancel) {}
        }
    }

    private var filtered: [LogLine] {
        let keyword = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return store.logs }
        return store.logs.filter {
            $0.text.localizedCaseInsensitiveContains(keyword)
                || $0.stamp.localizedCaseInsensitiveContains(keyword)
        }
    }

    private func row(_ line: LogLine) -> some View {
        HStack(alignment: .top, spacing: Spacing.m) {
            Text(line.stamp)
                .font(Typography.mono)
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)
            Text(line.text)
                .font(Typography.callout)
                .foregroundStyle(tint(for: line.text))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, Spacing.xxs)
    }

    private func tint(for text: String) -> Color {
        let lower = text.lowercased()
        if lower.contains("失败") || lower.contains("error") || lower.contains("denied") {
            return .appDanger
        }
        if lower.contains("警告") || lower.contains("warn") || lower.contains("重试") {
            return .appWarning
        }
        return .primary
    }
}
