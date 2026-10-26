import AppKit
import SwiftTerm

/// A terminal color scheme: 16 ANSI colors plus default text, background, cursor and selection.
struct Theme {
    let name: String
    let background: UInt32
    let foreground: UInt32
    let cursor: UInt32
    let selection: UInt32
    /// 8 normal + 8 bright ANSI colors.
    let ansi: [UInt32]

    static let defaultName = "Vivid"
    private static let defaultsKey = "colorScheme"

    /// The saved scheme, falling back to the default.
    static var current: Theme {
        get {
            let saved = UserDefaults.standard.string(forKey: defaultsKey)
            return all.first { $0.name == saved } ?? all[0]
        }
        set { UserDefaults.standard.set(newValue.name, forKey: defaultsKey) }
    }

    var nsBackground: NSColor { Self.nsColor(background) }
    var nsForeground: NSColor { Self.nsColor(foreground) }
    var nsCursor: NSColor { Self.nsColor(cursor) }
    var nsSelection: NSColor { Self.nsColor(selection) }
    var termColors: [Color] { ansi.map(Self.termColor) }

    private static func rgb(_ hex: UInt32) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        (CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255, CGFloat(hex & 0xFF) / 255)
    }

    private static func nsColor(_ hex: UInt32) -> NSColor {
        let c = rgb(hex)
        return NSColor(srgbRed: c.r, green: c.g, blue: c.b, alpha: 1)
    }

    private static func termColor(_ hex: UInt32) -> Color {
        let c = rgb(hex)
        return Color(red: UInt16(c.r * 65535), green: UInt16(c.g * 65535), blue: UInt16(c.b * 65535))
    }

    // ANSI palettes follow each scheme's published terminal values (iTerm2-Color-Schemes).
    // Background/foreground are nudged from the published values so that, for every scheme,
    // text vs. background is >= 10:1 and text vs. `edit`'s current-line bar (a 50% gray blend
    // over the background) is >= 7.5:1, with the bar >= 1.5:1 against the background.
    static let all: [Theme] = [
        Theme(name: defaultName, background: 0x000000, foreground: 0xF2F2F2, cursor: 0xAEAFAD, selection: 0x373B41, ansi: [
            0x000000, 0xE5382E, 0x1FBF4F, 0xF2B600, 0x2563FF, 0xBE3DFF, 0x00BFD0, 0xE0E0E0,
            0x808080, 0xFF5547, 0x3DE46C, 0xFFD426, 0x5C8DFF, 0xD66FFF, 0x35DDEB, 0xFFFFFF,
        ]),
        Theme(name: "Dracula", background: 0x242631, foreground: 0xF8F8F2, cursor: 0xF8F8F2, selection: 0x44475A, ansi: [
            0x21222C, 0xFF5555, 0x50FA7B, 0xF1FA8C, 0xBD93F9, 0xFF79C6, 0x8BE9FD, 0xF8F8F2,
            0x6272A4, 0xFF6E6E, 0x69FF94, 0xFFFFA5, 0xD6ACFF, 0xFF92DF, 0xA4FFFF, 0xFFFFFF,
        ]),
        Theme(name: "Nord", background: 0x0B0D12, foreground: 0xD8DEE9, cursor: 0xECEFF4, selection: 0x434C5E, ansi: [
            0x3B4252, 0xBF616A, 0xA3BE8C, 0xEBCB8B, 0x81A1C1, 0xB48EAD, 0x88C0D0, 0xE5E9F0,
            0x596377, 0xBF616A, 0xA3BE8C, 0xEBCB8B, 0x81A1C1, 0xB48EAD, 0x8FBCBB, 0xECEFF4,
        ]),
        Theme(name: "Gruvbox Dark", background: 0x0D0D0D, foreground: 0xECDCB4, cursor: 0xEBDBB2, selection: 0x504945, ansi: [
            0x282828, 0xCC241D, 0x98971A, 0xD79921, 0x458588, 0xB16286, 0x689D6A, 0xA89984,
            0x928374, 0xFB4934, 0xB8BB26, 0xFABD2F, 0x83A598, 0xD3869B, 0x8EC07C, 0xEBDBB2,
        ]),
        Theme(name: "Solarized Dark", background: 0x002A35, foreground: 0xF6F7F7, cursor: 0x93A1A1, selection: 0x073642, ansi: [
            0x073642, 0xDC322F, 0x859900, 0xB58900, 0x268BD2, 0xD33682, 0x2AA198, 0xEEE8D5,
            0x002B36, 0xCB4B16, 0x586E75, 0x657B83, 0x839496, 0x6C71C4, 0x93A1A1, 0xFDF6E3,
        ]),
        Theme(name: "Solarized Light", background: 0xFDF6E3, foreground: 0x20292C, cursor: 0x586E75, selection: 0xEEE8D5, ansi: [
            0x073642, 0xDC322F, 0x859900, 0xB58900, 0x268BD2, 0xD33682, 0x2AA198, 0xEEE8D5,
            0x002B36, 0xCB4B16, 0x586E75, 0x657B83, 0x839496, 0x6C71C4, 0x93A1A1, 0xFDF6E3,
        ]),
        Theme(name: "Tokyo Night", background: 0x1A1A25, foreground: 0xE7EBFC, cursor: 0xC0CAF5, selection: 0x33467C, ansi: [
            0x15161E, 0xF7768E, 0x9ECE6A, 0xE0AF68, 0x7AA2F7, 0xBB9AF7, 0x7DCFFF, 0xA9B1D6,
            0x414868, 0xF7768E, 0x9ECE6A, 0xE0AF68, 0x7AA2F7, 0xBB9AF7, 0x7DCFFF, 0xC0CAF5,
        ]),
        Theme(name: "Catppuccin Mocha", background: 0x080810, foreground: 0xD0D9F5, cursor: 0xF5E0DC, selection: 0x45475A, ansi: [
            0x45475A, 0xF38BA8, 0xA6E3A1, 0xF9E2AF, 0x89B4FA, 0xF5C2E7, 0x94E2D5, 0xBAC2DE,
            0x585B70, 0xF38BA8, 0xA6E3A1, 0xF9E2AF, 0x89B4FA, 0xF5C2E7, 0x94E2D5, 0xA6ADC8,
        ]),
        Theme(name: "Rosé Pine", background: 0x100E18, foreground: 0xE0DEF4, cursor: 0xE0DEF4, selection: 0x403D52, ansi: [
            0x26233A, 0xEB6F92, 0x31748F, 0xF6C177, 0x9CCFD8, 0xC4A7E7, 0xEBBCBA, 0xE0DEF4,
            0x6E6A86, 0xEB6F92, 0x31748F, 0xF6C177, 0x9CCFD8, 0xC4A7E7, 0xEBBCBA, 0xE0DEF4,
        ]),
        Theme(name: "Kanagawa Wave", background: 0x07070B, foreground: 0xDDD8BB, cursor: 0xDCD7BA, selection: 0x2D4F67, ansi: [
            0x090618, 0xC34043, 0x76946A, 0xC0A36E, 0x7E9CD8, 0x957FB8, 0x6A9589, 0xC8C093,
            0x727169, 0xE82424, 0x98BB6C, 0xE6C384, 0x7FB4CA, 0x938AA9, 0x7AA89F, 0xDCD7BA,
        ]),
    ]
}
