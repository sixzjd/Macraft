import SwiftUI

// MARK: - Macraft Design System
// 现代 · 简约 · 高级感
// 参考 Linear / Raycast / Arc Browser 设计语言
// 浅色基调 · 大量留白 · 微妙阴影 · 克制色彩

enum MCTheme {

    // MARK: Spacing scale (8pt grid)
    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: Corner radius
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 999
    }

    // MARK: Colors — semantic tokens (light theme)
    enum Palette {
        // Base surfaces
        static let background      = Color(hex: 0xF8FAFB)
        static let backgroundDeep  = Color(hex: 0xF1F3F5)
        static let surface         = Color(hex: 0xFFFFFF)
        static let surfaceRaised   = Color(hex: 0xF9FAFB)
        static let surfaceHover    = Color(hex: 0xF3F4F6)

        // Accent — #10B981 柔和明亮绿
        static let accent          = Color(hex: 0x10B981)
        static let accentStrong    = Color(hex: 0x059669)
        static let accentPress     = Color(hex: 0x047857)
        static let accentSoft      = Color(hex: 0xECFDF5)

        // Text hierarchy
        static let textPrimary     = Color(hex: 0x111827)
        static let textSecondary   = Color(hex: 0x6B7280)
        static let textTertiary    = Color(hex: 0x9CA3AF)
        static let textOnAccent    = Color(hex: 0xFFFFFF)

        // Lines & separators
        static let border          = Color(hex: 0xE5E7EB)
        static let borderStrong    = Color(hex: 0xD1D5DB)

        // Status
        static let success         = Color(hex: 0x10B981)
        static let warning         = Color(hex: 0xD97706)
        static let destructive     = Color(hex: 0xDC2626)
        static let info            = Color(hex: 0x2563EB)

        // Shadows
        static let shadowSoft      = Color(hex: 0x000000, opacity: 0.04)
        static let shadowMedium    = Color(hex: 0x000000, opacity: 0.08)
    }

    // MARK: Typography
    enum Font {
        static func display(_ size: CGFloat = 28) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .default)
        }
        static func title(_ size: CGFloat = 20) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .default)
        }
        static func headline(_ size: CGFloat = 15) -> SwiftUI.Font {
            .system(size: size, weight: .semibold, design: .default)
        }
        static func body(_ size: CGFloat = 14) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .default)
        }
        static func callout(_ size: CGFloat = 13) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .default)
        }
        static func caption(_ size: CGFloat = 12) -> SwiftUI.Font {
            .system(size: size, weight: .regular, design: .default)
        }
        static func mono(_ size: CGFloat = 13) -> SwiftUI.Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }
        static func brand(_ size: CGFloat = 18) -> SwiftUI.Font {
            .system(size: size, weight: .bold, design: .rounded)
        }
    }
}

// MARK: - Color hex initializer
extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}

// MARK: - App background
struct AppBackground: View {
    var body: some View {
        MCTheme.Palette.background
            .ignoresSafeArea()
    }
}
