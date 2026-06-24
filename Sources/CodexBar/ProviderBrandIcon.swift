import AppKit
import CodexBarCore

@MainActor
enum ProviderBrandIcon {
    private static let size = NSSize(width: 16, height: 16)
    private static var cache: [UsageProvider: NSImage] = [:]

    /// Lazy-loaded resource bundle for provider icons.
    private static let resourceBundle: Bundle? = {
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            return Bundle.module
        }
        // SwiftPM creates a CodexBar_CodexBar.bundle for resources in the CodexBar target.
        if let bundleURL = Bundle.main.url(forResource: "CodexBar_CodexBar", withExtension: "bundle"),
           let bundle = Bundle(url: bundleURL)
        {
            return bundle
        }
        // Fallback to main bundle for development/testing.
        return Bundle.main
    }()

    static func image(for provider: UsageProvider) -> NSImage? {
        if let cached = self.cache[provider] {
            return cached
        }

        let baseName = ProviderDescriptorRegistry.descriptor(for: provider).branding.iconResourceName
        guard let bundle = self.resourceBundle else {
            return nil
        }
        guard let url = bundle.url(forResource: baseName, withExtension: "svg"),
              let image = NSImage(contentsOf: url)
        else {
            return nil
        }

        image.size = self.size
        image.isTemplate = true
        self.cache[provider] = image
        return image
    }

    static func resetCacheForTesting() {
        self.cache.removeAll()
    }

    /// Returns the provider's brand icon tinted with its brand color (non-template),
    /// for use when the user opts into colorful menu bar icons.
    static func coloredImage(for provider: UsageProvider) -> NSImage? {
        guard let base = self.image(for: provider) else { return nil }
        let color = ProviderBrandColorResolver.shared.color(for: provider).nsColor
        return base.codexBarTinted(with: color)
    }
}

extension NSImage {
    /// Produces a copy of a template image filled with `color`, returned as a
    /// non-template image so the color survives menu bar rendering.
    func codexBarTinted(with color: NSColor) -> NSImage {
        let result = NSImage(size: self.size)
        result.lockFocus()
        let rect = NSRect(origin: .zero, size: self.size)
        self.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
        color.set()
        NSGraphicsContext.current?.compositingOperation = .sourceAtop
        NSBezierPath(rect: rect).fill()
        result.unlockFocus()
        result.isTemplate = false
        return result
    }
}
