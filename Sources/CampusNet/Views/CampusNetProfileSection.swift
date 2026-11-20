import SwiftUI

/// 校园网设置里的「自定义机型」Section。
///
/// 单独成文件，一是把设置页压在 300 行以内，二是这块自带 sheet 与右键菜单，
/// 独立出来以后更好测。
struct CampusNetProfileSection: View {
    @EnvironmentObject private var store: CampusNetStore
    @State private var editing: TerminalProfile?

    var body: some View {
        Section {
            if store.customProfiles.isEmpty {
                Text("没有自定义机型。内置的手机 / 平板 / 电脑已经够用，需要特定型号再来这里加。")
                    .font(Typography.footnote)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(store.customProfiles) { profile in
                    row(profile)
                }
            }

            Button {
                editing = TerminalProfile(name: "",
                                          btype: DeviceKind.phone.btype,
                                          staType: DeviceKind.phone.staType,
                                          staModel: DeviceKind.phone.defaultModel,
                                          macOverride: "")
            } label: {
                Label("新建自定义机型", systemImage: "plus.circle")
                    .font(Typography.body)
            }
        } header: {
            Text("自定义机型")
        }
        .sheet(item: $editing) { profile in
            ProfileEditorView(profile: profile).environmentObject(store)
        }
    }

    private func row(_ profile: TerminalProfile) -> some View {
        Button {
            editing = profile
        } label: {
            HStack(spacing: Spacing.m) {
                AppIconCircle(symbol: profile.kind.symbol, tint: .appBrand)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(profile.name.isEmpty ? "未命名" : profile.name)
                        .font(Typography.rowTitle)
                    Text(profile.subtitle)
                        .font(Typography.rowSubtitle)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: Spacing.s)
                if profile.id == store.settings.selectedProfileID {
                    Image(systemName: "checkmark")
                        .font(Typography.subheadline.weight(.semibold))
                        .foregroundStyle(Color.appBrand)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                store.selectProfile(profile.id)
            } label: {
                Label("设为当前", systemImage: "checkmark")
            }
            Button(role: .destructive) {
                store.deleteProfile(profile.id)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}
