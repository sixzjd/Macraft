import SwiftUI

// MARK: - Card
/// 纯白卡片 + 柔和投影 + 细边框，参考 Linear 风格
struct Card<Content: View>: View {
    var cornerRadius: CGFloat = MCTheme.Radius.lg
    var padding: CGFloat = MCTheme.Space.xl
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(MCTheme.Palette.surface)
                    .shadow(color: MCTheme.Palette.shadowSoft, radius: 12, x: 0, y: 4)
                    .shadow(color: MCTheme.Palette.shadowMedium, radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
            )
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isEnabled: Bool = true
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: MCTheme.Space.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(MCTheme.Font.callout(13))
            }
            .foregroundStyle(MCTheme.Palette.textOnAccent)
            .padding(.horizontal, MCTheme.Space.xl)
            .padding(.vertical, MCTheme.Space.md)
            .background(
                RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                    .fill(hovering ? MCTheme.Palette.accentStrong : MCTheme.Palette.accent)
            )
            .shadow(color: MCTheme.Palette.accent.opacity(hovering ? 0.3 : 0.2),
                    radius: hovering ? 12 : 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.45)
        .disabled(!isEnabled)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                self.hovering = hovering
            }
        }
    }
}

// MARK: - Secondary / Ghost Button
struct GhostButton: View {
    let title: String
    var systemImage: String? = nil
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: MCTheme.Space.sm) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .medium))
                }
                Text(title)
                    .font(MCTheme.Font.callout(13))
            }
            .foregroundStyle(hovering ? MCTheme.Palette.textPrimary : MCTheme.Palette.textSecondary)
            .padding(.horizontal, MCTheme.Space.lg)
            .padding(.vertical, MCTheme.Space.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                    .fill(hovering ? MCTheme.Palette.surfaceHover : MCTheme.Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                    .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { self.hovering = hovering }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.xs) {
            Text(title)
                .font(MCTheme.Font.headline(15))
                .foregroundStyle(MCTheme.Palette.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(MCTheme.Font.caption(12))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
            }
        }
    }
}

// MARK: - Pill Badge
struct PillBadge: View {
    let text: String
    var color: Color = MCTheme.Palette.accent

    var body: some View {
        Text(text)
            .font(MCTheme.Font.caption(11).weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, MCTheme.Space.sm + 2)
            .padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.1)))
    }
}

// MARK: - Stat Tile
struct StatTile: View {
    let label: String
    let value: String
    let systemImage: String
    var tint: Color = MCTheme.Palette.accent

    var body: some View {
        VStack(alignment: .leading, spacing: MCTheme.Space.md) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .fill(MCTheme.Palette.surface)
                        .shadow(color: MCTheme.Palette.shadowSoft, radius: 4, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: MCTheme.Radius.sm, style: .continuous)
                        .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(MCTheme.Font.title(22))
                    .foregroundStyle(MCTheme.Palette.textPrimary)
                Text(label)
                    .font(MCTheme.Font.caption(12))
                    .foregroundStyle(MCTheme.Palette.textTertiary)
            }
        }
        .padding(MCTheme.Space.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .fill(MCTheme.Palette.surface)
                .shadow(color: MCTheme.Palette.shadowSoft, radius: 8, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
        )
    }
}

// MARK: - Empty State
struct EmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: MCTheme.Space.lg) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(MCTheme.Palette.textTertiary)
            Text(title)
                .font(MCTheme.Font.headline(15))
                .foregroundStyle(MCTheme.Palette.textPrimary)
            Text(message)
                .font(MCTheme.Font.body(13))
                .foregroundStyle(MCTheme.Palette.textTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, MCTheme.Space.xxxl)
    }
}

// MARK: - Search Field
struct SearchField: View {
    @Binding var text: String
    var placeholder: String = "搜索…"

    var body: some View {
        HStack(spacing: MCTheme.Space.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(MCTheme.Palette.textTertiary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(MCTheme.Font.body(13))
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(MCTheme.Palette.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, MCTheme.Space.md)
        .padding(.vertical, MCTheme.Space.sm + 2)
        .background(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .fill(MCTheme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: MCTheme.Radius.md, style: .continuous)
                .strokeBorder(MCTheme.Palette.border, lineWidth: 1)
        )
    }
}

// MARK: - Selectable Filter Chip
struct SelectableChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(MCTheme.Font.caption(12).weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? MCTheme.Palette.textOnAccent : MCTheme.Palette.textSecondary)
                .padding(.horizontal, MCTheme.Space.md)
                .padding(.vertical, MCTheme.Space.xs + 2)
                .background(
                    Capsule().fill(isSelected ? MCTheme.Palette.accent : MCTheme.Palette.surfaceRaised)
                )
                .overlay(
                    Capsule().strokeBorder(isSelected ? Color.clear : MCTheme.Palette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
