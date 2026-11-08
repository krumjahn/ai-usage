// Native macOS artwork for the staged menu-bar interaction video.
// Offscreen rendering only: no windows, collector, preferences, or activity database.
import AppKit

_ = NSApplication.shared
NSApp.setActivationPolicy(.prohibited)

let folder = URL(fileURLWithPath: "promo/assets/mac")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
func bitmap(_ name: String, width: Int, height: Int, draw: () -> Void) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width * 2, pixelsHigh: height * 2,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    draw()
    NSGraphicsContext.restoreGraphicsState()
    try rep.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent(name + ".png"))
}
func label(_ text: String, x: CGFloat, bold: Bool = false, mono: Bool = false) {
    let font = mono ? NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium) : NSFont.systemFont(ofSize: 14, weight: bold ? .semibold : .regular)
    (text as NSString).draw(at: NSPoint(x: x, y: 8), withAttributes: [.font: font, .foregroundColor: NSColor.black.withAlphaComponent(0.86)])
}
try bitmap("menu-bar", width: 1600, height: 32) {
    NSColor(srgbRed: 0.92, green: 0.95, blue: 0.96, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: 1600, height: 32).fill()
    let symbols: [(String, CGFloat)] = [("applelogo", 22), ("wifi", 1340), ("magnifyingglass", 1381), ("switch.2", 1421)]
    for (name, x) in symbols {
        if let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil) {
            symbol.draw(in: NSRect(x: x, y: 8, width: 18, height: 18))
        }
    }
    label("Finder", x: 57, bold: true)
    for (title, x) in [("File", 122.0), ("Edit", 167), ("View", 212), ("Go", 264), ("Window", 306), ("Help", 385)] { label(title, x: x) }
    label("2h 14m", x: 1249, mono: true)
    label("Sun 9:41 AM", x: 1479)
}
for (name, bundle) in [("finder", "com.apple.finder"), ("safari", "com.apple.Safari"), ("notes", "com.apple.Notes"), ("settings", "com.apple.systempreferences")] {
    guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) else { continue }
    let icon = NSWorkspace.shared.icon(forFile: url.path)
    try bitmap(name, width: 64, height: 64) { icon.draw(in: NSRect(x: 0, y: 0, width: 64, height: 64)) }
}
let cursor = NSCursor.arrow
let size = cursor.image.size
try bitmap("cursor", width: Int(size.width), height: Int(size.height)) {
    cursor.image.draw(in: NSRect(origin: .zero, size: size))
}
print("Cursor size:",size,"hotspot:",cursor.hotSpot)
