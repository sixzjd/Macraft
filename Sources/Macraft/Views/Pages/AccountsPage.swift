import SwiftUI
import AppKit

// MARK: - Account model
struct GameAccount: Identifiable {
    let id = UUID()
    var name: String
    var isMicrosoft: Bool
    var uuid: String = UUID().uuidString
}

// MARK: - Accounts Page
struct AccountsPage: View {
    @State private var accounts: [GameAccount] = [
        GameAccount(name: "Steve", isMicrosoft: false)
    ]
    @State private var showAddSheet = false
    @State private var showMicrosoftSheet = false

    var body: some View {
        PageContainer(title: "账户", subtitle: "管理你的 Minecraft 游戏账户，支持离线与微软正版") {
            VStack(spacing: MCTheme.Space.lg) {
                addCard
                accountsList
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddOfflineAccountSheet { name in
                accounts.append(GameAccount(name: name, isMicrosoft: false))
                showAddSheet = false
            }
        }
        .sheet(isPresented: $showMicrosoftSheet) {
            MicrosoftLoginSheet { name in
                accounts.append(GameAccount(name: name, isMicrosoft: true))
                showMicrosoftSheet = false
            }
        }
    }

    private var addCard: some View {
        Card {
            VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
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
                        Text("支持离线模式与微软正版登录")
                            .font(MCTheme.Font.caption(12))
                            .foregroundStyle(MCTheme.Palette.textTertiary)
                    }
                    Spacer()
                }
                HStack(spacing: MCTheme.Space.md) {
                    PrimaryButton(title: "离线账户", systemImage: "person") {
                        showAddSheet = true
                    }
                    GhostButton(title: "微软正版登录", systemImage: "logo.windows") {
                        showMicrosoftSheet = true
                    }
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

// MARK: - Account Row
struct AccountRow: View {
    let account: GameAccount
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: MCTheme.Space.lg) {
            RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                .fill(account.isMicrosoft ? Color(hex: 0xDBEAFE) : MCTheme.Palette.accentSoft)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: account.isMicrosoft ? "logo.windows" : "person.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(account.isMicrosoft ? MCTheme.Palette.info : MCTheme.Palette.accent)
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

// MARK: - Add Offline Account Sheet
struct AddOfflineAccountSheet: View {
    let onConfirm: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var newName = ""

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
                PrimaryButton(title: "确认添加", systemImage: "checkmark") {
                    let trimmed = newName.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    onConfirm(trimmed)
                }
                .disabled(newName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(MCTheme.Space.xxl)
        .frame(width: 400)
        .background(MCTheme.Palette.surface)
    }
}

// MARK: - Microsoft Login Sheet
struct MicrosoftLoginSheet: View {
    let onSuccess: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var step: LoginStep = .idle
    @State private var deviceCode = ""
    @State private var playerName = ""
    @State private var errorMessage = ""
    @State private var copied = false
    @State private var pollTimer: Timer?
    @State private var internalDeviceCode = ""
    @State private var pollInterval: TimeInterval = 5

    enum LoginStep {
        case idle
        case loading
        case waitingForCode
        case authenticating
        case done
        case error
    }

    var body: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.xl) {
            Text("微软正版登录")
                .font(MCTheme.Font.title(18))
                .foregroundStyle(MCTheme.Palette.textPrimary)

            switch step {
            case .idle:
                idleView
            case .loading:
                loadingView
            case .waitingForCode:
                codeView
            case .authenticating:
                authenticatingView
            case .done:
                doneView
            case .error:
                errorView
            }
        }
        .padding(MCTheme.Space.xxl)
        .frame(width: 460)
        .background(MCTheme.Palette.surface)
        .onDisappear { pollTimer?.invalidate() }
    }

    private var idleView: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
            Text("使用微软设备代码流登录 Xbox Live / Minecraft 正版账户。\n点击开始后将自动打开微软验证页面。")
                .font(MCTheme.Font.body(13))
                .foregroundStyle(MCTheme.Palette.textSecondary)

            HStack {
                Spacer()
                GhostButton(title: "取消") { dismiss() }
                PrimaryButton(title: "开始登录", systemImage: "arrow.right") {
                    startDeviceFlow()
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: MCTheme.Space.lg) {
            ProgressView()
                .controlSize(.large)
                .tint(MCTheme.Palette.accent)
            Text("正在获取设备代码…")
                .font(MCTheme.Font.body(13))
                .foregroundStyle(MCTheme.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MCTheme.Space.xl)
    }

    private var codeView: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
            Text("请在浏览器中输入以下代码：")
                .font(MCTheme.Font.body(13))
                .foregroundStyle(MCTheme.Palette.textSecondary)

            HStack(spacing: MCTheme.Space.md) {
                Text(deviceCode)
                    .font(MCTheme.Font.mono(24))
                    .foregroundStyle(MCTheme.Palette.accent)
                    .frame(maxWidth: .infinity)
                    .padding(MCTheme.Space.lg)
                    .background(
                        RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                            .fill(MCTheme.Palette.accentSoft)
                    )

                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(deviceCode, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                } label: {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(copied ? MCTheme.Palette.success : MCTheme.Palette.accent)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                                .fill(MCTheme.Palette.accentSoft)
                        )
                }
                .buttonStyle(.plain)
                .help("复制代码")
            }

            Text("已自动打开 microsoft.com/link，输入代码后点击“下一步”。\n登录成功后此处将自动完成验证。")
                .font(MCTheme.Font.caption(12))
                .foregroundStyle(MCTheme.Palette.textTertiary)

            HStack {
                Spacer()
                GhostButton(title: "取消") {
                    pollTimer?.invalidate()
                    dismiss()
                }
            }
        }
    }

    private var authenticatingView: some View {
        VStack(spacing: MCTheme.Space.lg) {
            ProgressView()
                .controlSize(.large)
                .tint(MCTheme.Palette.accent)
            Text("正在获取账户信息…")
                .font(MCTheme.Font.body(13))
                .foregroundStyle(MCTheme.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MCTheme.Space.xl)
    }

    private var doneView: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
            HStack(spacing: MCTheme.Space.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(MCTheme.Palette.success)
                Text("登录成功！")
                    .font(MCTheme.Font.headline(15))
                    .foregroundStyle(MCTheme.Palette.textPrimary)
            }

            VStack(alignment: .leading, spacing: MCTheme.Space.sm) {
                Text("游戏昵称")
                    .font(MCTheme.Font.callout(13))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                TextField("输入你的游戏内昵称", text: $playerName)
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
                PrimaryButton(title: "完成", systemImage: "checkmark") {
                    let name = playerName.trimmingCharacters(in: .whitespaces)
                    onSuccess(name.isEmpty ? "Player" : name)
                }
            }
        }
    }

    private var errorView: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
            HStack(spacing: MCTheme.Space.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(MCTheme.Palette.warning)
                Text("登录失败")
                    .font(MCTheme.Font.headline(15))
                    .foregroundStyle(MCTheme.Palette.textPrimary)
            }
            Text(errorMessage)
                .font(MCTheme.Font.body(13))
                .foregroundStyle(MCTheme.Palette.textSecondary)
            HStack {
                Spacer()
                GhostButton(title: "取消") { dismiss() }
                PrimaryButton(title: "重试", systemImage: "arrow.clockwise") {
                    startDeviceFlow()
                }
            }
        }
    }

    // MARK: - OAuth Device Code Flow
    private static let clientId = "00000000402B5328"
    private static let scope = "XboxLive.signin offline_access"

    private func startDeviceFlow() {
        step = .loading
        errorMessage = ""

        var request = URLRequest(url: URL(string: "https://login.microsoftonline.com/consumers/oauth2/v2.0/devicecode")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "client_id=\(Self.clientId)&scope=\(Self.scope.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? Self.scope)"
        request.httpBody = body.data(using: .utf8)

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                if let userCode = json?["user_code"] as? String,
                   let devCode = json?["device_code"] as? String,
                   let uri = json?["verification_uri"] as? String {
                    let interval = json?["interval"] as? TimeInterval ?? 5

                    await MainActor.run {
                        self.deviceCode = userCode
                        self.internalDeviceCode = devCode
                        self.pollInterval = interval
                        self.step = .waitingForCode
                        if let url = URL(string: uri) {
                            NSWorkspace.shared.open(url)
                        }
                        startPolling()
                    }
                } else {
                    let errDesc = json?["error_description"] as? String ?? "未知错误"
                    await MainActor.run {
                        self.errorMessage = errDesc
                        self.step = .error
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "网络请求失败：\(error.localizedDescription)"
                    self.step = .error
                }
            }
        }
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { _ in
            pollForToken()
        }
    }

    private func pollForToken() {
        var request = URLRequest(url: URL(string: "https://login.microsoftonline.com/consumers/oauth2/v2.0/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body = "grant_type=urn:ietf:params:oauth:grant-type:device_code&client_id=\(Self.clientId)&device_code=\(internalDeviceCode)"
        request.httpBody = body.data(using: .utf8)

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                if let _ = json?["access_token"] as? String {
                    // 登录成功
                    await MainActor.run {
                        pollTimer?.invalidate()
                        step = .done
                        playerName = "Player\(Int.random(in: 100...999))"
                    }
                } else if let error = json?["error"] as? String {
                    if error == "authorization_pending" {
                        // 用户还未完成验证，继续等待
                        return
                    } else if error == "expired_token" {
                        await MainActor.run {
                            pollTimer?.invalidate()
                            errorMessage = "代码已过期，请重新开始登录。"
                            step = .error
                        }
                    } else if error == "authorization_declined" {
                        await MainActor.run {
                            pollTimer?.invalidate()
                            errorMessage = "用户拒绝了授权。"
                            step = .error
                        }
                    }
                }
            } catch {
                // 网络错误时静默重试
            }
        }
    }
}
