import SwiftUI
import UIKit

// Source of truth: tokens.css (light on :root, dark on [data-theme="dark"]).
// Palette primitives are documented hues from DESIGN-stripe.md; everything else is an alias or an alpha of one.

private extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255, green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255, opacity: alpha)
    }
    /// A colour that resolves per trait collection so light/dark follow the app's appearance setting.
    static func adaptive(_ light: Color, _ dark: Color) -> Color {
        Color(uiColor: UIColor { tc in tc.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    }
}

enum Palette {
    static let primary = Color(hex: 0x533afd)
    static let primaryDeep = Color(hex: 0x4434d4)
    static let primaryPress = Color(hex: 0x2e2b8c)
    static let primarySoft = Color(hex: 0x665efd)
    static let primarySubdued = Color(hex: 0xb9b9f9)
    static let brandDark = Color(hex: 0x1c1e54)
    static let ink = Color(hex: 0x0d253d)
    static let inkSecondary = Color(hex: 0x273951)
    static let inkMute = Color(hex: 0x64748d)
    static let onPrimary = Color.white
    static let canvas = Color.white
    static let canvasSoft = Color(hex: 0xf6f9fc)
    static let canvasCream = Color(hex: 0xf5e9d4)
    static let hairline = Color(hex: 0xe3e8ee)
    static let hairlineInput = Color(hex: 0xa8c3de)
    static let ruby = Color(hex: 0xea2261)
    static let magenta = Color(hex: 0xf96bee)
    static let lemon = Color(hex: 0x9b6829)
    static let shadowBlue = Color(hex: 0x003770)
}

/// Semantic aliases. Each resolves light/dark exactly as tokens.css does.
enum MColor {
    static let ground = Color.adaptive(Palette.canvasSoft, Palette.ink)
    static let surface = Color.adaptive(Palette.canvas, Palette.brandDark)
    static let surfacePressed = Color.adaptive(Palette.canvasSoft, Color.white.opacity(0.06))
    static let surfaceSelected = Color.adaptive(Palette.primary.opacity(0.08), Palette.primarySoft.opacity(0.18))
    static let text = Color.adaptive(Palette.ink, Palette.onPrimary)
    static let textSecondary = Color.adaptive(Palette.inkSecondary, Palette.hairline)
    static let textMute = Color.adaptive(Palette.inkMute, Palette.hairlineInput)
    static let textOnPrimary = Palette.onPrimary
    static let line = Color.adaptive(Palette.hairline, Color.white.opacity(0.12))
    static let lineInput = Color.adaptive(Palette.hairlineInput, Palette.hairlineInput.opacity(0.40))
    static let accent = Palette.primary
    static let accentPress = Palette.primaryPress
    static let accentText = Color.adaptive(Palette.primary, Palette.primarySubdued)
    static let accentTint = Color.adaptive(Palette.primary.opacity(0.08), Palette.primarySoft.opacity(0.18))
    static let accentSoftBg = Color.adaptive(Palette.primarySubdued, Palette.primarySubdued.opacity(0.16))
    static let accentSoftText = Color.adaptive(Palette.primaryDeep, Palette.primarySubdued)
    static let danger = Palette.ruby
    static let dangerTint = Color.adaptive(Palette.ruby.opacity(0.08), Palette.ruby.opacity(0.18))
    static let warn = Color.adaptive(Palette.lemon, Palette.canvasCream)
    static let warnTint = Color.adaptive(Palette.lemon.opacity(0.10), Palette.lemon.opacity(0.28))
    static let disabledBg = Color.adaptive(Palette.hairline, Color.white.opacity(0.08))
    static let disabledText = Color.adaptive(Palette.inkMute, Palette.hairlineInput.opacity(0.55))
    static let toastBg = Color.adaptive(Palette.brandDark, Palette.canvas)
    static let toastText = Color.adaptive(Palette.onPrimary, Palette.ink)
    static let toastSuccess = Color.adaptive(Palette.primarySubdued, Palette.primary)
    static let toastError = Palette.ruby
    static let toastInfo = Color.adaptive(Palette.hairlineInput, Palette.inkMute)
    static let scrim = Color.adaptive(Palette.ink.opacity(0.40), Palette.ink.opacity(0.72))
    static let meshBase = Palette.canvasCream
    static let emphasisBg = Color.adaptive(Palette.brandDark, Palette.canvas)
    static let emphasisText = Color.adaptive(Palette.onPrimary, Palette.ink)
    static let segmentSelected = Color.adaptive(Palette.canvas, Palette.hairlineInput.opacity(0.22))
    static let segmentTrack = Color.adaptive(Palette.hairline, Color.white.opacity(0.12))

    static func event(_ hue: EventHue) -> Color {
        switch hue {
        case .one: Palette.primary
        case .two: Palette.lemon
        case .three: Palette.magenta
        case .four: Color.adaptive(Palette.brandDark, Palette.canvasCream)
        }
    }
}

enum Space {
    static let xxs: CGFloat = 2, xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 12, lg: CGFloat = 16, xl: CGFloat = 24, xxl: CGFloat = 32, huge: CGFloat = 64
}

enum Radius {
    static let xs: CGFloat = 4, sm: CGFloat = 6, md: CGFloat = 8, lg: CGFloat = 12, xl: CGFloat = 16, pill: CGFloat = 9999
}

enum Dim {
    static let touch: CGFloat = 44, row: CGFloat = 56, button: CGFloat = 56, buttonCompact: CGFloat = 44, input: CGFloat = 48, amountInput: CGFloat = 64
    static let icon: CGFloat = 24, iconButton: CGFloat = 20, iconSm: CGFloat = 16, avatar: CGFloat = 40, avatarSm: CGFloat = 32
    static let calendarCell: CGFloat = 48, calendarNumeral: CGFloat = 28, dot: CGFloat = 8, timelineHour: CGFloat = 32, timelineGutter: CGFloat = 48
    static let bar: CGFloat = 8, edge: CGFloat = 4, keypadKey: CGFloat = 56, chart: CGFloat = 120, gutter: CGFloat = 16
}

// MARK: - Elevation (design.md levels 1 and 2; black alpha in dark per tokens.css)

struct ShadowLevel: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var level: Int
    func body(content: Content) -> some View {
        let dark = scheme == .dark
        switch level {
        case 2:
            content
                .shadow(color: dark ? .black.opacity(0.35) : Palette.shadowBlue.opacity(0.08), radius: 12, y: 8)
                .shadow(color: dark ? .black.opacity(0.20) : Palette.shadowBlue.opacity(0.04), radius: 3, y: 2)
        default:
            content.shadow(color: dark ? .black.opacity(0.35) : Palette.shadowBlue.opacity(0.08), radius: 1.5, y: 1)
        }
    }
}

extension View {
    func elevation(_ level: Int = 1) -> some View { modifier(ShadowLevel(level: level)) }

    /// design.md card: surface + hairline + Level 1, radius lg.
    func card(padding: CGFloat = Space.lg, fill: Color = MColor.surface, radius: CGFloat = Radius.lg) -> some View {
        self
            .padding(padding)
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(MColor.line, lineWidth: 1))
            .elevation(1)
    }
}
