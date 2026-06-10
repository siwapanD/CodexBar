import AppKit
import CodexBarCore

/// Renders a single horizontal "strip" template image that shows every enabled
/// provider's brand glyph followed by its menu-bar percentage, e.g. `◆ 45%  ◇ 80%`.
///
/// Used by the merged status item when "Show all providers" is enabled so the menu
/// bar reflects every selected provider in one clickable item instead of just the
/// primary one.
enum MergedBrandPercentIcon {
    struct Entry {
        let brand: NSImage
        let text: String?
    }

    private static let minHeight: CGFloat = 18
    private static let iconSize: CGFloat = 15
    private static let iconTextGap: CGFloat = 2
    private static let groupGap: CGFloat = 7
    private static let horizontalPadding: CGFloat = 1
    private static let scale: CGFloat = 2

    private static var textFont: NSFont {
        NSFont.menuBarFont(ofSize: 0)
    }

    private static func textAttributes(color: NSColor) -> [NSAttributedString.Key: Any] {
        [
            .font: self.textFont,
            .foregroundColor: color,
        ]
    }

    /// - Parameters:
    ///   - colored: when `true` the result is a non-template image (so brand colors survive),
    ///     and `textColor` is used for the percentages. When `false` the result is a template
    ///     image tinted monochrome by AppKit and `textColor` should be opaque black.
    static func image(
        entries: [Entry],
        colored: Bool = false,
        textColor: NSColor = .black) -> NSImage?
    {
        guard !entries.isEmpty else { return nil }

        let attributes = self.textAttributes(color: textColor)
        let font = self.textFont
        // Adapt height so tall glyphs are never clipped, with a floor matching the
        // standard 18pt template icon height.
        let lineHeight = ceil(font.ascender - font.descender)
        let height = max(self.minHeight, lineHeight)
        struct Measured {
            let brand: NSImage
            let attributed: NSAttributedString?
            let textWidth: CGFloat
            let groupWidth: CGFloat
        }

        var measured: [Measured] = []
        var totalWidth: CGFloat = self.horizontalPadding * 2
        for (index, entry) in entries.enumerated() {
            var groupWidth = self.iconSize
            var attributed: NSAttributedString?
            var textWidth: CGFloat = 0
            if let text = entry.text, !text.isEmpty {
                let string = NSAttributedString(string: text, attributes: attributes)
                textWidth = ceil(string.size().width)
                attributed = string
                groupWidth += self.iconTextGap + textWidth
            }
            measured.append(
                Measured(
                    brand: entry.brand,
                    attributed: attributed,
                    textWidth: textWidth,
                    groupWidth: groupWidth))
            totalWidth += groupWidth
            if index < entries.count - 1 {
                totalWidth += self.groupGap
            }
        }

        let canvasWidth = ceil(max(totalWidth, self.iconSize))
        let outputSize = NSSize(width: canvasWidth, height: height)

        let image = self.renderImage(size: outputSize, isTemplate: !colored) {
            var cursorX = self.horizontalPadding
            for item in measured {
                let iconRect = NSRect(
                    x: cursorX,
                    y: ((height - self.iconSize) / 2).rounded(),
                    width: self.iconSize,
                    height: self.iconSize)
                item.brand.draw(
                    in: iconRect,
                    from: .zero,
                    operation: .sourceOver,
                    fraction: 1.0,
                    respectFlipped: true,
                    hints: [.interpolation: NSImageInterpolation.high])
                cursorX += self.iconSize
                if let attributed = item.attributed {
                    cursorX += self.iconTextGap
                    let textSize = attributed.size()
                    let textRect = NSRect(
                        x: cursorX,
                        y: ((height - textSize.height) / 2).rounded(),
                        width: item.textWidth,
                        height: ceil(textSize.height))
                    attributed.draw(in: textRect)
                    cursorX += item.textWidth
                }
                cursorX += self.groupGap
            }
        }
        return image
    }

    private static func renderImage(size: NSSize, isTemplate: Bool = true, _ draw: () -> Void) -> NSImage {
        let image = NSImage(size: size)
        if let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width * self.scale),
            pixelsHigh: Int(size.height * self.scale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0)
        {
            rep.size = size
            image.addRepresentation(rep)
            NSGraphicsContext.saveGraphicsState()
            if let ctx = NSGraphicsContext(bitmapImageRep: rep) {
                NSGraphicsContext.current = ctx
                draw()
            }
            NSGraphicsContext.restoreGraphicsState()
        } else {
            image.lockFocus()
            draw()
            image.unlockFocus()
        }
        image.isTemplate = isTemplate
        return image
    }
}
