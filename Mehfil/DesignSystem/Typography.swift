import SwiftUI

// Type roles from tokens.css. Inter (design.md's sanctioned Sohne substitute) at 300/400.
// Weight 400 is permitted only on a row's primary label and trailing amount (NOTES ruling 3).

enum TypeRole {
    case displayHero, displayMd, headingLg, headingMd, headingSm
    case bodyLg, bodyMd, bodyMdStrong, bodyTabular, bodyTabularStrong
    case buttonMd, buttonSm, caption, micro, microCap

    var size: CGFloat {
        switch self {
        case .displayHero: 36
        case .displayMd: 26
        case .headingLg: 22
        case .headingMd: 20
        case .headingSm: 18
        case .bodyLg, .buttonMd: 16
        case .bodyMd, .bodyMdStrong: 15
        case .bodyTabular, .bodyTabularStrong, .buttonSm: 14
        case .caption: 13
        case .micro: 11
        case .microCap: 10
        }
    }
    var weight: Font.Weight {
        switch self {
        case .bodyMdStrong, .bodyTabularStrong, .buttonMd, .buttonSm, .caption, .microCap: .regular
        default: .light
        }
    }
    var lineHeight: CGFloat {
        switch self {
        case .displayHero, .headingLg: 1.1
        case .displayMd: 1.12
        case .buttonMd, .buttonSm: 1.0
        case .microCap: 1.15
        default: 1.4
        }
    }
    var tracking: CGFloat {
        switch self {
        case .displayHero: -0.72
        case .displayMd: -0.26
        case .headingLg: -0.22
        case .headingMd: -0.2
        case .bodyTabular, .bodyTabularStrong: -0.42
        case .caption: -0.39
        case .microCap: 0.1
        default: 0
        }
    }
    /// tnum on every money / numeric cell (design.md).
    var tabular: Bool {
        switch self {
        case .displayHero, .bodyTabular, .bodyTabularStrong, .caption: true
        default: false
        }
    }
    var textStyle: Font.TextStyle {
        switch self {
        case .displayHero: .largeTitle
        case .displayMd: .title
        case .headingLg: .title2
        case .headingMd: .title3
        case .headingSm: .headline
        case .bodyLg, .buttonMd: .callout
        case .bodyMd, .bodyMdStrong: .body
        case .bodyTabular, .bodyTabularStrong, .buttonSm: .subheadline
        case .caption: .footnote
        case .micro: .caption
        case .microCap: .caption2
        }
    }
    var font: Font {
        let name = weight == .regular ? "Inter-Regular" : "Inter-Light"
        let f = Font.custom(name, size: size, relativeTo: textStyle)
        return tabular ? f.monospacedDigit() : f
    }
}

struct TypeModifier: ViewModifier {
    let role: TypeRole
    func body(content: Content) -> some View {
        content
            .font(role.font)
            .tracking(role.tracking)
            .lineSpacing(max(0, role.size * role.lineHeight - role.size * 1.21)) // Inter's natural line box ≈ 1.21em
    }
}

extension View {
    func type(_ role: TypeRole) -> some View { modifier(TypeModifier(role: role)) }
}

extension Text {
    func role(_ role: TypeRole, _ color: Color = MColor.text) -> some View {
        self.type(role).foregroundStyle(color)
    }
}

/// Money in the design's `body-tabular-strong` role, always Indian grouping.
struct Money: View {
    var amount: Int
    var role: TypeRole = .bodyTabularStrong
    var color: Color = MColor.text
    init(_ amount: Int, _ role: TypeRole = .bodyTabularStrong, color: Color = MColor.text) { self.amount = amount; self.role = role; self.color = color }
    var body: some View { Text(Fmt.inr(amount)).role(role, color).monospacedDigit() }
}
