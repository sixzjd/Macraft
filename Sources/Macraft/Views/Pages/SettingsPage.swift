import SwiftUI

// MARK: - Settings Page
struct SettingsPage: View {
    @State private var appearance = 1
    @State private var javaPath = "/usr/bin/java"
    @State private var gameDirectory = "~/Library/Application Support/macraft"
    @State private var memoryGB = 4.0
    @State private var fullscreen = false
    @State private var showSnapshots = false

    var body: some View {
        PageContainer(title: "设置", subtitle: "调整 Macraft 的外观与游戏运行参数") {
            VStack(spacing: MCTheme.Space.lg) {
                appearanceSection
                javaSection
                gameSection
                aboutSection
            }
        }
    }

    private var appearanceSection: some View {
        Card {
            VStack(alignment: .leading, spacing: MCTheme.Space.xl) {
                SectionHeader(title: "外观")
                SettingsRow(label: "主题模式", hint: "当前使用浅色主题") {
                    Picker("", selection: $appearance) {
                        Text("跟随系统").tag(0)
                        Text("浅色").tag(1)
                        Text("深色").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                }
                SettingsToggleRow(label: "启动时进入全屏", isOn: $fullscreen)
            }
        }
    }

    private var javaSection: some View {
        Card {
            VStack(alignment: .leading, spacing: MCTheme.Space.xl) {
                SectionHeader(title: "Java 运行时")
                SettingsTextFieldRow(label: "Java 路径", text: $javaPath,
                                     placeholder: "/usr/bin/java")
                VStack(alignment: .leading, spacing: MCTheme.Space.md) {
                    HStack {
                        Text("分配内存")
                            .font(MCTheme.Font.callout(13))
                            .foregroundStyle(MCTheme.Palette.textPrimary)
                        Spacer()
                        Text(String(format: "%.1f GB", memoryGB))
                            .font(MCTheme.Font.mono(13))
                            .foregroundStyle(MCTheme.Palette.accent)
                    }
                    Slider(value: $memoryGB, in: 1...16, step: 0.5)
                        .tint(MCTheme.Palette.accent)
                }
            }
        }
    }

    private var gameSection: some View {
        Card {
            VStack(alignment: .leading, spacing: MCTheme.Space.xl) {
                SectionHeader(title: "游戏")
                SettingsTextFieldRow(label: "游戏目录", text: $gameDirectory,
                                     placeholder: "游戏文件存放位置")
                SettingsToggleRow(label: "显示快照版本", isOn: $showSnapshots)
            }
        }
    }

    private var aboutSection: some View {
        Card {
            VStack(alignment: .leading, spacing: MCTheme.Space.lg) {
                SectionHeader(title: "关于")
                HStack(spacing: MCTheme.Space.lg) {
                    Image(systemName: "cube.fill")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(MCTheme.Palette.accent)
                        .frame(width: 52, height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                                .fill(MCTheme.Palette.accentSoft)
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Macraft")
                            .font(MCTheme.Font.brand(18))
                            .foregroundStyle(MCTheme.Palette.textPrimary)
                        Text("版本 1.0.0 · 原生 macOS 启动器")
                            .font(MCTheme.Font.caption(12))
                            .foregroundStyle(MCTheme.Palette.textTertiary)
                        Text("使用 SwiftUI 构建，参考 PCL 的设计理念。")
                            .font(MCTheme.Font.caption(12))
                            .foregroundStyle(MCTheme.Palette.textTertiary)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Settings row helpers
struct SettingsRow<Control: View>: View {
    let label: String
    var hint: String? = nil
    @ViewBuilder var control: Control

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(MCTheme.Font.callout(13))
                    .foregroundStyle(MCTheme.Palette.textPrimary)
                if let hint {
                    Text(hint)
                        .font(MCTheme.Font.caption(11))
                        .foregroundStyle(MCTheme.Palette.textTertiary)
                }
            }
            Spacer()
            control
        }
    }
}

struct SettingsToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(MCTheme.Font.callout(13))
                .foregroundStyle(MCTheme.Palette.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .tint(MCTheme.Palette.accent)
                .labelsHidden()
        }
    }
}

struct SettingsTextFieldRow: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.sm) {
            Text(label)
                .font(MCTheme.Font.callout(13))
                .foregroundStyle(MCTheme.Palette.textPrimary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(MCTheme.Font.mono(13))
                .foregroundStyle(MCTheme.Palette.textPrimary)
                .padding(MCTheme.Space.md)
                .background(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .fill(MCTheme.Palette.backgroundDeep)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
                )
        }
    }
}
