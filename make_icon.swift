import AppKit

let size: CGFloat = 1024

func drawIcon() -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    defer { img.unlockFocus() }

    let bounds = NSRect(x: 0, y: 0, width: size, height: size)
    let squircle = NSBezierPath(roundedRect: bounds, xRadius: size * 0.2237, yRadius: size * 0.2237)

    // 蓝色渐变背景（squircle）
    let top = NSColor(calibratedRed: 0.40, green: 0.74, blue: 1.00, alpha: 1)
    let bottom = NSColor(calibratedRed: 0.00, green: 0.42, blue: 0.95, alpha: 1)
    let grad = NSGradient(colors: [top, bottom])!
    grad.draw(in: squircle, angle: -90)

    // 白色文件夹（带阴影）
    let folder = NSBezierPath()
    folder.appendRoundedRect(NSRect(x: 200, y: 250, width: 624, height: 440), xRadius: 44, yRadius: 44)
    folder.appendRoundedRect(NSRect(x: 200, y: 670, width: 300, height: 100), xRadius: 26, yRadius: 26)

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
    shadow.shadowBlurRadius = 36
    shadow.shadowOffset = NSSize(width: 0, height: -24)
    NSGraphicsContext.saveGraphicsState()
    shadow.set()
    NSColor.white.setFill()
    folder.fill()
    NSGraphicsContext.restoreGraphicsState()

    // 文件夹上的彩虹渐变条（水平渐变，稳健且示意「颜色定制」）
    let barRect = NSRect(x: 296, y: 430, width: 432, height: 84)
    let bar = NSBezierPath(roundedRect: barRect, xRadius: 20, yRadius: 20)
    let barColors: [NSColor] = [
        NSColor(calibratedRed: 1.00, green: 0.23, blue: 0.19, alpha: 1),
        NSColor(calibratedRed: 1.00, green: 0.58, blue: 0.00, alpha: 1),
        NSColor(calibratedRed: 1.00, green: 0.80, blue: 0.00, alpha: 1),
        NSColor(calibratedRed: 0.20, green: 0.78, blue: 0.35, alpha: 1),
        NSColor(calibratedRed: 0.00, green: 0.48, blue: 1.00, alpha: 1),
        NSColor(calibratedRed: 0.69, green: 0.32, blue: 0.87, alpha: 1),
    ]
    let barGrad = NSGradient(colors: barColors)!
    barGrad.draw(in: bar, angle: 0)

    return img
}

func savePNG(_ image: NSImage, pixels: Int, to path: String) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    rep.size = NSSize(width: pixels, height: pixels)
    let ctx = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
               from: .zero, operation: .copy, fraction: 1.0)
    ctx?.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    let png = rep.representation(using: .png, properties: [:])!
    try? png.write(to: URL(fileURLWithPath: path))
}

let appiconset = "Sources/FolderCustomizer/Assets.xcassets/AppIcon.appiconset"
try? FileManager.default.createDirectory(atPath: appiconset, withIntermediateDirectories: true)

let master = drawIcon()
let entries: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for (name, px) in entries {
    savePNG(master, pixels: px, to: "\(appiconset)/\(name)")
}
print("AppIcon sizes written to \(appiconset)")
