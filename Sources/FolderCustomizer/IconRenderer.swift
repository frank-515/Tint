import AppKit
import UniformTypeIdentifiers

/// 把任意 NSImage 栅格化成指定像素尺寸的 CGImage，保证放缩后边缘清晰。
private func cgImage(from image: NSImage, pixels: Int) -> CGImage? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else { return nil }

    let ctx = NSGraphicsContext(bitmapImageRep: rep)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    image.draw(in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
               from: .zero, operation: .copy, fraction: 1.0)
    ctx?.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    return rep.cgImage
}

/// 系统通用文件夹图标，作为基底。
@MainActor
func systemFolderIcon(size: CGFloat) -> NSImage {
    let icon = NSWorkspace.shared.icon(for: .folder)
    icon.size = NSSize(width: size, height: size)
    return icon
}

/// 渲染结果缓存：body 每次刷新都会请求预览图，同一 (颜色, emoji, 透明度, 尺寸) 只渲染一次。
@MainActor
private final class IconRenderCache {
    static let shared = IconRenderCache()
    private var dict: [String: NSImage] = [:]

    func get(_ key: String) -> NSImage? { dict[key] }
    func put(_ key: String, _ image: NSImage) {
        if dict.count > 128 { dict.removeAll() }
        dict[key] = image
    }
}

/// 用文件夹图标作基底：先铺主题色，再用原图的亮度叠加回阴影/高光，最后叠加 emoji。
/// `base` 传 nil 时使用系统通用文件夹图标；传入某个文件夹的当前图标则在其上继续编辑。
@MainActor
func renderFolderIcon(color: NSColor, emoji: String?, emojiOpacity: CGFloat, size: CGFloat, base: NSImage? = nil) -> NSImage {
    if let base {
        return drawFolderIcon(color: color, emoji: emoji, emojiOpacity: emojiOpacity, size: size, baseIcon: base)
    }

    let srgb = color.usingColorSpace(.sRGB) ?? color
    let cacheKey = String(
        format: "%d,%d,%d,%d|%@|%d|%d",
        Int(srgb.redComponent * 255), Int(srgb.greenComponent * 255),
        Int(srgb.blueComponent * 255), Int(srgb.alphaComponent * 255),
        emoji ?? "", Int(emojiOpacity * 100), Int(size)
    )
    if let cached = IconRenderCache.shared.get(cacheKey) { return cached }

    let image = drawFolderIcon(color: color, emoji: emoji, emojiOpacity: emojiOpacity, size: size,
                               baseIcon: systemFolderIcon(size: size))
    IconRenderCache.shared.put(cacheKey, image)
    return image
}

@MainActor
private func drawFolderIcon(color: NSColor, emoji: String?, emojiOpacity: CGFloat, size: CGFloat, baseIcon: NSImage) -> NSImage {
    let base = baseIcon
    base.size = NSSize(width: size, height: size)
    let pixels = Int(size)

    guard let baseCG = cgImage(from: base, pixels: pixels) else { return base }

    let out = NSImage(size: NSSize(width: size, height: size))
    out.lockFocus()
    defer { out.unlockFocus() }

    guard let ctx = NSGraphicsContext.current?.cgContext else { return base }

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    // 只在文件夹不透明区域内作画
    ctx.saveGState()
    ctx.clip(to: rect, mask: baseCG)

    // 铺主题色
    ctx.setFillColor(color.cgColor)
    ctx.fill(rect)

    // 用原图亮度叠加回立体感（保持主题色相，恢复明暗）
    ctx.setBlendMode(.luminosity)
    ctx.draw(baseCG, in: rect)

    ctx.restoreGState()

    // 叠加 emoji（相对几何中心略微下移，落在文件夹主体上）
    if let emoji, !emoji.isEmpty {
        let fontSize = size * 0.34
        let str = NSAttributedString(string: emoji, attributes: [.font: NSFont.systemFont(ofSize: fontSize)])
        let s = str.size()
        ctx.saveGState()
        ctx.setAlpha(emojiOpacity)
        str.draw(at: NSPoint(x: (size - s.width) / 2, y: (size - s.height) / 2 - size * 0.06))
        ctx.restoreGState()
    }

    return out
}
