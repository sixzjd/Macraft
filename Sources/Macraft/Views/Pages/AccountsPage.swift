import SwiftUI

// MARK: - Account model
struct GameAccount: Identifiable {
    let id = UUID()
    var name: String
    var isMicrosoft: Bool
}

// MARK: - Accounts Page
struct AccountsPage: View {
    @State private var accounts: [GameAccount] = [
        GameAccount(name: "Steve", isMicrosoft: false)
    ]
    @State private var newName = ""
    @State private var showAddSheet = false

    var body: some View {
        PageContainer(title: "账户", subtitle: "管理你的 Minecraft 游戏账户") {
            VStack(spacing: MCTheme.Space.lg) {
                addCard
                accountsList
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddAccountSheet(newName: $newName) {
                let trimmed = newName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                accounts.append(GameAccount(name: trimmed, isMicrosoft: false))
                newName = ""
                showAddSheet = false
            }
        }
    }

    private var addCard: some View {
        Card {
            HStack(spacing: MCTheme.Space.lg) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(MCTheme.Palette.accent)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                            .fill(MCTheme.Palette.accentSoft)
                    )
                VStack(alignment: .leading, spacing: 3) {
                    Text("添加新账户")
                        .font(MCTheme.Font.headline(15))
                        .foregroundStyle(MCTheme.Palette.textPrimary)
                    Text("创建离线账户，或登录微软正版账户")
                        .font(MCTheme.Font.caption(12))
                        .foregroundStyle(MCTheme.Palette.textTertiary)
                }
                Spacer()
                PrimaryButton(title: "添加账户", systemImage: "plus") {
                    showAddSheet = true
                }
            }
        }
    }

    private var accountsList: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.sm) {
            SectionHeader(title: "我的账户", subtitle: "\(accounts.count) 个账户")
            ForEach(accounts) { account in
                AccountRow(account: account) {
                    accounts.removeAll { $0.id == account.id }
                }
            }
        }
    }
}

struct AccountRow: View {
    let account: GameAccount
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: MCTheme.Space.lg) {
            RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                .fill(MCTheme.Palette.accentSoft)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(MCTheme.Palette.accent)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(MCTheme.Font.headline(14))
                    .foregroundStyle(MCTheme.Palette.textPrimary)
                Text(account.isMicrosoft ? "微软正版账户" : "离线账户")
                    .font(MCTheme.Font.caption(12))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
            }

            Spacer()

            PillBadge(text: account.isMicrosoft ? "正版" : "离线",
                      color: account.isMicrosoft ? MCTheme.Palette.info : MCTheme.Palette.textSecondary)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(MCTheme.Palette.destructive.opacity(hovering ? 1 : 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(MCTheme.Space.lg)
        .background(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .fill(MCTheme.Palette.surface)
                .shadow(color: MCTheme.Palette.shadowSoft, radius: 6, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) { self.hovering = hovering }
        }
    }
}

struct AddAccountSheet: View {
    @Binding var newName: String
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.xl) {
            Text("添加离线账户")
                .font(MCTheme.Font.title(18))
                .foregroundStyle(MCTheme.Palette.textPrimary)

            VStack(alignment: .leading, spacing: MCTheme.Space.sm) {
                Text("游戏昵称")
                    .font(MCTheme.Font.callout(13))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                TextField("输入昵称，例如 Steve", text: $newName)
                    .textFieldStyle(.plain)
                    .font(MCTheme.Font.body(14))
                    .padding(MCTheme.Space.md)
                    .background(
                        RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                            .fill(MCTheme.Palette.backgroundDeep)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                            .strokeBorder(MCTheme.Palette.borderStrong, lineWidth: 1)
                    )
            }

            HStack {
                Spacer()
                GhostButton(title: "取消") { dismiss() }
                PrimaryButton(title: "确认添加", systemImage: "checkmark") { onConfirm() }
            }
        }
        .padding(MCTheme.Space.xxl)
        .frame(width: 400)
        .background(MCTheme.Palette.surface)
    }
}
