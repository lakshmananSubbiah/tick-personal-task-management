import SwiftUI

/// Design tokens for Tick's glassy, Things/Linear-inspired look.
enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }

    enum Radius {
        static let row: CGFloat = 10
        static let card: CGFloat = 16
        static let pill: CGFloat = 8
    }

    /// Preset palette offered when creating a project.
    static let projectColors: [String] = [
        "#0A84FF", "#30D158", "#FF9F0A", "#FF375F",
        "#BF5AF2", "#64D2FF", "#FFD60A", "#FF6482"
    ]
}

extension Color {
    /// Decode a `#RRGGBB` (or `#RRGGBBAA`) hex string. Falls back to accent.
    init(hex: String) {
        let raw = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: raw).scanHexInt64(&value)

        let r, g, b, a: Double
        switch raw.count {
        case 6:
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1
        case 8:
            r = Double((value & 0xFF000000) >> 24) / 255
            g = Double((value & 0x00FF0000) >> 16) / 255
            b = Double((value & 0x0000FF00) >> 8) / 255
            a = Double(value & 0x000000FF) / 255
        default:
            self = .accentColor
            return
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

/// Decoded representation of a `Project.iconToken` (`"sf:..."` or `"emoji:..."`).
enum ProjectIcon {
    case symbol(String)
    case emoji(String)

    init(token: String) {
        if let value = token.dropPrefix("sf:") {
            self = .symbol(value)
        } else if let value = token.dropPrefix("emoji:") {
            self = .emoji(value)
        } else {
            self = .symbol("folder")
        }
    }
}

private extension String {
    func dropPrefix(_ prefix: String) -> String? {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : nil
    }
}

/// Renders a `ProjectIcon` tinted by the project's color.
struct ProjectIconView: View {
    let token: String
    let colorHex: String
    var size: CGFloat = 14

    var body: some View {
        switch ProjectIcon(token: token) {
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(Color(hex: colorHex))
        case .emoji(let char):
            Text(char)
                .font(.system(size: size))
        }
    }
}
