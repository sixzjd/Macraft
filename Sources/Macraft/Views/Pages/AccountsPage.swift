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
/// 按照 PCL2 的授权代码流实现：login.live.com OAuth → Xbox Live → XSTS → Minecraft
/// 使用系统浏览器登录（避免 WKWebView 被微软拦截），用户手动粘贴授权码
struct MicrosoftLoginSheet: View {
    let onSuccess: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var step: LoginStep = .idle
    @State private var errorMessage = ""
    @State private var statusText = ""
    @State private var codeInput = ""

    enum LoginStep {
        case idle
        case waitingCode  // 等待用户粘贴授权码
        case exchanging   // 正在兑换 token
        case done
        case error
    }

    // PCL2 使用的 Client ID 和端点
    private static let clientId = "00000000402b5328"
    private static let authUrl = "https://login.live.com/oauth20_authorize.srf?client_id=00000000402b5328&response_type=code&redirect_uri=https://login.live.com/oauth20_desktop.srf&response_mode=query&scope=service::user.auth.xboxlive.com::MBI_SSL"
    private static let tokenUrl = "https://login.live.com/oauth20_token.srf"
    private static let redirectUri = "https://login.live.com/oauth20_desktop.srf"

    var body: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.xl) {
            Text("微软正版登录")
                .font(MCTheme.Font.title(18))
                .foregroundStyle(MCTheme.Palette.textPrimary)

            switch step {
            case .idle:
                idleView
            case .waitingCode:
                waitingCodeView
            case .exchanging:
                exchangingView
            case .done:
                doneView
            case .error:
                errorView
            }
        }
        .padding(MCTheme.Space.xxl)
        .frame(width: 480)
        .background(MCTheme.Palette.surface)
    }

    private var idleView: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
            Text("点击开始后将在系统浏览器中打开微软登录页面。\n请使用已购买 Minecraft Java 版的微软账户登录。")
                .font(MCTheme.Font.body(13))
                .foregroundStyle(MCTheme.Palette.textSecondary)

            HStack {
                Spacer()
                GhostButton(title: "取消") { dismiss() }
                PrimaryButton(title: "开始登录", systemImage: "logo.windows") {
                    openBrowserForLogin()
                }
            }
        }
    }

    private var waitingCodeView: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
            // 步骤说明
            VStack(alignment: .leading, spacing: MCTheme.Space.sm) {
                Label("已在浏览器中打开登录页面", systemImage: "1.circle.fill")
                    .font(MCTheme.Font.body(13))
                    .foregroundStyle(MCTheme.Palette.success)
                Label("在浏览器中登录你的微软账户", systemImage: "2.circle.fill")
                    .font(MCTheme.Font.body(13))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
                Label("登录成功后，复制浏览器地址栏中的链接粘贴到下方", systemImage: "3.circle.fill")
                    .font(MCTheme.Font.body(13))
                    .foregroundStyle(MCTheme.Palette.textSecondary)
            }

            Text("登录成功后浏览器会跳转到一个以 oauth20_desktop.srf 开头的页面，\n请复制地址栏中的完整链接（或其中的 code= 后面的内容）粘贴到下方：")
                .font(MCTheme.Font.caption(12))
                .foregroundStyle(MCTheme.Palette.textTertiary)

            // 粘贴区域
            TextField("粘贴链接或授权码…", text: $codeInput)
                .textFieldStyle(.plain)
                .font(MCTheme.Font.body(13))
                .padding(MCTheme.Space.md)
                .background(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .fill(MCTheme.Palette.backgroundDeep)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .strokeBorder(MCTheme.Palette.borderStrong, lineWidth: 1)
                )

            HStack {
                GhostButton(title: "重新打开浏览器", systemImage: "safari") {
                    openBrowserForLogin()
                }
                Spacer()
                GhostButton(title: "取消") { dismiss() }
                PrimaryButton(title: "确认登录", systemImage: "arrow.right") {
                    submitCode()
                }
                .disabled(codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var exchangingView: some View {
        VStack(spacing: MCTheme.Space.lg) {
            ProgressView()
                .controlSize(.large)
                .tint(MCTheme.Palette.accent)
            Text(statusText)
                .font(MCTheme.Font.body(13))
                .foregroundStyle(MCTheme.Palette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MCTheme.Space.xxl)
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
            Text("欢迎，\(playerName)！已成功获取 Minecraft 正版账户授权。")
                .font(MCTheme.Font.body(13))
                .foregroundStyle(MCTheme.Palette.textSecondary)
            HStack {
                Spacer()
                PrimaryButton(title: "完成", systemImage: "checkmark") {
                    onSuccess(playerName.isEmpty ? "Player" : playerName)
                }
            }
        }
    }

    @State private var playerName = ""

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
                .font(MCTheme.Font.body(12))
                .foregroundStyle(MCTheme.Palette.textSecondary)
                .lineLimit(6)
            HStack {
                Spacer()
                GhostButton(title: "取消") { dismiss() }
                PrimaryButton(title: "重试", systemImage: "arrow.clockwise") {
                    codeInput = ""
                    openBrowserForLogin()
                }
            }
        }
    }

    // MARK: - 打开系统浏览器登录
    private func openBrowserForLogin() {
        if let url = URL(string: Self.authUrl) {
            NSWorkspace.shared.open(url)
            step = .waitingCode
            loginLog("Browser opened for login")
        }
    }

    // MARK: - 从用户输入中提取授权码
    private func submitCode() {
        let input = codeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        var code = input

        // 如果用户粘贴了完整 URL，提取 code 参数
        if input.contains("oauth20_desktop.srf") || input.contains("code=") {
            if let url = URL(string: input),
               let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let codeParam = components.queryItems?.first(where: { $0.name == "code" })?.value {
                code = codeParam
            } else {
                // 尝试用正则提取 code= 后面的内容
                if let range = input.range(of: "code="),
                   let endRange = input.range(of: "&", range: range.upperBound..<input.endIndex) {
                    code = String(input[range.upperBound..<endRange.lowerBound])
                } else if let range = input.range(of: "code=") {
                    code = String(input[range.upperBound...])
                }
            }
        }

        guard !code.isEmpty else {
            errorMessage = "未能从输入中提取到授权码，请确认粘贴了完整的链接"
            step = .error
            return
        }

        loginLog("Code extracted: \(code.prefix(20))...")
        step = .exchanging
        statusText = "正在验证授权码…"
        exchangeCodeForTokens(code: code)
    }

    // MARK: - Token Exchange Chain (PCL2 流程)
    private func exchangeCodeForTokens(code: String) {
        Task {
            do {
                loginLog("=== LOGIN START ===")
                loginLog("code: \(code.prefix(20))...")

                // Step 1: 授权码 → Microsoft Token
                let msToken = try await getMicrosoftToken(code: code)
                loginLog("Step 1 OK: MS token obtained (\(msToken.prefix(20))...)")
                await MainActor.run { statusText = "正在获取 Xbox Live 令牌…" }

                // Step 2: Microsoft Token → Xbox Live Token
                let (xblToken, userHash) = try await getXboxLiveToken(msToken: msToken)
                loginLog("Step 2 OK: XBL token obtained, uhs=\(userHash)")
                await MainActor.run { statusText = "正在获取 XSTS 令牌…" }

                // Step 3: Xbox Live → XSTS Token
                let xstsToken = try await getXstsToken(xblToken: xblToken)
                loginLog("Step 3 OK: XSTS token obtained")
                await MainActor.run { statusText = "正在获取 Minecraft 令牌…" }

                // Step 4: XSTS → Minecraft Token
                let mcToken = try await getMinecraftToken(userHash: userHash, xstsToken: xstsToken)
                loginLog("Step 4 OK: MC token obtained")
                await MainActor.run { statusText = "正在获取游戏档案…" }

                // Step 5: 获取 Minecraft 档案（用户名）
                let name = try await getMinecraftProfile(mcToken: mcToken)
                loginLog("Step 5 OK: profile name = \(name)")

                await MainActor.run {
                    playerName = name
                    step = .done
                }
            } catch {
                loginLog("ERROR: \(error.localizedDescription)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    step = .error
                }
            }
        }
    }

    private func loginLog(_ msg: String) {
        let line = "[\(Date())] \(msg)\n"
        let logPath = "/tmp/macraft_login.log"
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath) {
                if let handle = FileHandle(forWritingAtPath: logPath) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                FileManager.default.createFile(atPath: logPath, contents: data)
            }
        }
    }

    private func getMicrosoftToken(code: String) async throws -> String {
        var req = URLRequest(url: URL(string: Self.tokenUrl)!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        // 使用 URLComponents 正确编码表单参数
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "client_id", value: Self.clientId),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "redirect_uri", value: Self.redirectUri),
            URLQueryItem(name: "scope", value: "service::user.auth.xboxlive.com::MBI_SSL")
        ]
        req.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        loginLog("Token request body: \(components.percentEncodedQuery?.prefix(100) ?? "nil")...")

        let (data, response) = try await URLSession.shared.data(for: req)
        let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0
        loginLog("Token response: HTTP \(httpStatus), \(data.count) bytes")

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let raw = String(data: data.prefix(300), encoding: .utf8) ?? "无响应"
            loginLog("Token response NOT JSON: \(raw)")
            throw NSError(domain: "OAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Microsoft 服务返回了无法解析的响应 (HTTP \(httpStatus))：\(raw.prefix(100))"])
        }
        guard let token = json["access_token"] as? String else {
            let desc = json["error_description"] as? String ?? json["error"] as? String ?? "无法获取 Microsoft 令牌"
            loginLog("Token error: \(desc)")
            throw NSError(domain: "OAuth", code: 1, userInfo: [NSLocalizedDescriptionKey: desc])
        }
        return token
    }

    private func getXboxLiveToken(msToken: String) async throws -> (String, String) {
        var req = URLRequest(url: URL(string: "https://user.auth.xboxlive.com/user/authenticate")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "Properties": [
                "AuthMethod": "RPS",
                "SiteName": "user.auth.xboxlive.com",
                "RpsTicket": "d=\(msToken)"
            ],
            "RelyingParty": "http://auth.xboxlive.com",
            "TokenType": "JWT"
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: req)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["Token"] as? String,
              let displayClaims = json["DisplayClaims"] as? [String: Any],
              let xui = displayClaims["xui"] as? [[String: Any]],
              let uhs = xui.first?["uhs"] as? String else {
            throw NSError(domain: "OAuth", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法获取 Xbox Live 令牌"])
        }
        return (token, uhs)
    }

    private func getXstsToken(xblToken: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://xsts.auth.xboxlive.com/xsts/authorize")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "Properties": [
                "SandboxId": "RETAIL",
                "UserTokens": [xblToken]
            ],
            "RelyingParty": "rp://api.minecraftservices.com/",
            "TokenType": "JWT"
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: req)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["Token"] as? String else {
            throw NSError(domain: "OAuth", code: 3, userInfo: [NSLocalizedDescriptionKey: "无法获取 XSTS 令牌"])
        }
        return token
    }

    private func getMinecraftToken(userHash: String, xstsToken: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://api.minecraftservices.com/authentication/login_with_xbox")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["identityToken": "XBL3.0 x=\(userHash);\(xstsToken)"]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: req)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let token = json["access_token"] as? String else {
            throw NSError(domain: "OAuth", code: 4, userInfo: [NSLocalizedDescriptionKey: "无法获取 Minecraft 令牌"])
        }
        return token
    }

    private func getMinecraftProfile(mcToken: String) async throws -> String {
        var req = URLRequest(url: URL(string: "https://api.minecraftservices.com/minecraft/profile")!)
        req.setValue("Bearer \(mcToken)", forHTTPHeaderField: "Authorization")

        let (data, _) = try await URLSession.shared.data(for: req)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String else {
            throw NSError(domain: "OAuth", code: 5, userInfo: [NSLocalizedDescriptionKey: "该账户未拥有 Minecraft Java 版"])
        }
        return name
    }
}

