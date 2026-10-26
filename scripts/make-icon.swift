// Generates Resources/AppIcon.icns. Usage: swift scripts/make-icon.swift
import AppKit

func color(_ hex: UInt32, _ a: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 255) / 255, green: CGFloat((hex >> 8) & 255) / 255,
            blue: CGFloat(hex & 255) / 255, alpha: a)
}

/// Draws the icon on a 1024-unit canvas (the caller scales the context).
func drawIcon() {
    let ctx = NSGraphicsContext.current!.cgContext
    let body = NSRect(x: 100, y: 100, width: 824, height: 824)
    let squircle = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)

    // Drop shadow under the body.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 28, color: NSColor.black.withAlphaComponent(0.5).cgColor)
    color(0x0B0B1A).setFill()
    squircle.fill()
    ctx.restoreGState()

    ctx.saveGState()
    squircle.addClip()

    // Background: deep indigo to near-black.
    NSGradient(colors: [color(0x2E2E6B), color(0x14142E), color(0x07070F)],
               atLocations: [0, 0.45, 1], colorSpace: .sRGB)!.draw(in: body, angle: -90)

    // Soft violet glow behind the code.
    NSGradient(colors: [color(0x7C6CFF, 0.38), color(0x7C6CFF, 0)])!
        .draw(fromCenter: NSPoint(x: 560, y: 520), radius: 0, toCenter: NSPoint(x: 560, y: 520), radius: 430, options: [])

    // Menu bar strip, like edit's lavender bar.
    let bar = NSRect(x: body.minX, y: body.maxY - 112, width: body.width, height: 112)
    NSGradient(colors: [color(0xB4B4FF), color(0x8F8FF0)])!.draw(in: bar, angle: -90)
    for (i, w) in [96.0, 78.0, 96.0, 70.0].enumerated() {
        let x = 196 + [0, 128, 236, 362][i]
        color(0x1A1A3A, 0.85).setFill()
        NSBezierPath(roundedRect: NSRect(x: CGFloat(x), y: bar.midY - 14, width: w, height: 28), xRadius: 14, yRadius: 14).fill()
    }

    // Status bar strip.
    let status = NSRect(x: body.minX, y: body.minY, width: body.width, height: 64)
    NSGradient(colors: [color(0xA0A0F8), color(0x8484E8)])!.draw(in: status, angle: -90)
    color(0x1A1A3A, 0.85).setFill()
    NSBezierPath(roundedRect: NSRect(x: 230, y: status.midY - 11, width: 130, height: 22), xRadius: 11, yRadius: 11).fill()
    NSBezierPath(roundedRect: NSRect(x: 640, y: status.midY - 11, width: 154, height: 22), xRadius: 11, yRadius: 11).fill()

    // Code lines with glow: (indent, width, colour).
    let lines: [(CGFloat, CGFloat, UInt32)] = [
        (0, 250, 0xFF7AC6), (0, 130, 0x7CE7FF),
        (64, 330, 0xC3B8FF), (64, 210, 0x7CFFB2),
        (64, 280, 0xFFD479), (0, 170, 0x7CE7FF),
    ]
    var y = bar.minY - 118
    for (i, l) in lines.enumerated() {
        // Gutter tick.
        color(0xFFFFFF, 0.22).setFill()
        NSBezierPath(roundedRect: NSRect(x: 160, y: y, width: 26, height: 26), xRadius: 8, yRadius: 8).fill()
        let rect = NSRect(x: 232 + l.0, y: y, width: l.1, height: 26)
        ctx.saveGState()
        ctx.setShadow(offset: .zero, blur: 26, color: color(l.2, 0.85).cgColor)
        color(l.2).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 13, yRadius: 13).fill()
        ctx.restoreGState()
        // Cursor on the last line.
        if i == lines.count - 1 {
            let cursor = NSRect(x: rect.maxX + 22, y: y - 14, width: 34, height: 54)
            ctx.saveGState()
            ctx.setShadow(offset: .zero, blur: 40, color: color(0xFFFFFF, 0.95).cgColor)
            color(0xFFFFFF).setFill()
            NSBezierPath(roundedRect: cursor, xRadius: 6, yRadius: 6).fill()
            ctx.restoreGState()
        }
        y -= 88
    }

    // Glassy highlight over the top half.
    let gloss = NSBezierPath(ovalIn: NSRect(x: body.minX - 260, y: body.midY + 250, width: body.width + 520, height: 700))
    NSGradient(colors: [NSColor.white.withAlphaComponent(0.16), NSColor.white.withAlphaComponent(0)])!
        .draw(in: gloss, angle: -90)
    ctx.restoreGState()

    // Hairline edge.
    NSColor.white.withAlphaComponent(0.18).setStroke()
    let edge = NSBezierPath(roundedRect: body.insetBy(dx: 1, dy: 1), xRadius: 184, yRadius: 184)
    edge.lineWidth = 2
    edge.stroke()
}

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.current!.cgContext.scaleBy(x: CGFloat(pixels) / 1024, y: CGFloat(pixels) / 1024)
    drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let root = URL(fileURLWithPath: CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ".")
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for base in [16, 32, 128, 256, 512] {
    try! render(pixels: base).write(to: iconset.appendingPathComponent("icon_\(base)x\(base).png"))
    try! render(pixels: base * 2).write(to: iconset.appendingPathComponent("icon_\(base)x\(base)@2x.png"))
}
try! render(pixels: 1024).write(to: root.appendingPathComponent("build/icon-preview.png"))
print("iconset written")
