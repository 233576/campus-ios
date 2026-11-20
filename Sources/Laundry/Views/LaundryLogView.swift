import SwiftUI
import UIKit

/// 日志页：请求与响应原文，方便排查。
///
/// 时间戳等宽定宽、内容自适应；分隔线交给系统，不再给每行套圆角边框。
struct LaundryLogView: View {
    @EnvironmentObject private var store: LaundryStore

    @State private var query = ""
    @State private var confirmingClear = false

    var body: some View {
        AppList {
            if filtered.isEmpty {
                Section {
                    AppEmptyState(
                        title: "还没有日志",
                        message: "点「查询这台洗衣机」之后，这里会记录每一步请求。",
                        symbol: "text.alignleft"
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(filtered, id: \.self) { line in
                        HStack(alignment: .top, spacing: Spacing.s) {
                            Text(prefix(of: line))
                                .font(Typography.mono)
                                .foregroundStyle(.secondary)
                                .frame(width: 56, alignment: .leading)
                            Text(body(of: line))
                                .font(Typography.callout)
                                .foregroundStyle(tint(of: line))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, Spacing.xxs)
                    }
                }
            }
        }
        .appNavigation(title: "日志", subtitle: "\(store.logs.count) 行")
        .toolbar(.hidden, for: .tabBar)
        .searchable(text: $query, prompt: "搜索日志")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                GlassContainer(spacing: Spacing.s) {
                    HStack(spacing: Spacing.s) {
                        GlassToolbarButton(symbol: "doc.on.doc", label: "复制") {
                            UIPasteboard.general.string = store.logs.joined(separator: "\n")
                            store.noticeMessage = "日志已复制"
                        }
                        GlassToolbarButton(symbol: "trash", label: "清空", tint: .appDanger) {
                            confirmingClear = true
                        }
                    }
                }
            }
        }
        .confirmationDialog("清空全部日志？", isPresented: $confirmingClear, titleVisibility: .visible) {
            Button("清空", role: .destructive) { store.clearLogs() }
            Button("取消", role: .cancel) {}
        } message: {
            Text("清空后无法恢复。")
        }
    }

    private var filtered: [String] {
        let keyword = query.trimmingCharacters(in: .whitespaces)
        guard !keyword.isEmpty else { return store.logs }
        return store.logs.filter { $0.localizedCaseInsensitiveContains(keyword) }
    }

    private func prefix(of line: String) -> String {
        if let space = line.firstIndex(of: " ") {
            return String(line[line.startIndex..<space])
        }
        return ""
    }

    private func body(of line: String) -> String {
        if let space = line.firstIndex(of: " ") {
            return String(line[line.index(after: space)...])
        }
        return line
    }

    private func tint(of line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("失败") || lower.contains("error") || lower.contains("异常") {
            return .appDanger
        }
        if lower.contains("警告") || lower.contains("warn") || lower.contains("重试") {
            return .appWarning
        }
        return .primary
    }
}
