// Run from the repository root: swift Design/GenerateIcon.swift
// Original vector artwork, rasterized at each native macOS icon size.
import AppKit

let output = URL(fileURLWithPath: "App/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
var entries = [[String: String]]()
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = points * scale
        let image = NSImage(size: NSSize(width: pixels, height: pixels))
        image.lockFocus()
        let transform = NSAffineTransform()
        transform.scale(by: CGFloat(pixels) / 1024)
        transform.concat()
        let tile = NSBezierPath(roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 204, yRadius: 204)
        NSColor(srgbRed: 0.95, green: 0.94, blue: 0.91, alpha: 1).setFill()
        tile.fill()
        NSColor.black.withAlphaComponent(0.10).setStroke()
        tile.lineWidth = 2
        tile.stroke()
        NSColor(srgbRed: 0.19, green: 0.20, blue: 0.19, alpha: 1).setStroke()
        let dial = NSBezierPath()
        dial.appendArc(withCenter: NSPoint(x: 500, y: 512), radius: 226, startAngle: 40, endAngle: 320)
        dial.lineWidth = 60
        dial.lineCapStyle = .round
        dial.stroke()
        let tick = NSBezierPath()
        tick.move(to: NSPoint(x: 666, y: 512))
        tick.line(to: NSPoint(x: 758, y: 512))
        tick.lineWidth = 60
        tick.lineCapStyle = .round
        tick.stroke()
        image.unlockFocus()
        let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
        // NSImage drawing can inherit the display scale: normalize the bitmap.
        let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                     isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSImage(size: image.size, flipped: false) { rect in
            rep.draw(in: rect)
            return true
        }.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels))
        NSGraphicsContext.restoreGraphicsState()
        let name = "icon_\(points)x\(points)@\(scale)x.png"
        try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
        entries.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}
let metadata: [String: Any] = ["images": entries, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("Contents.json"))
try Data("{\"info\":{\"author\":\"xcode\",\"version\":1}}".utf8).write(to: output.deletingLastPathComponent().appendingPathComponent("Contents.json"))
