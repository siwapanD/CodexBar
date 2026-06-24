import AppKit
import CodexBarCore
import SwiftUI

extension ProviderColor {
    /// Parses a `#RRGGBB` (or `RRGGBB`) hex string.
    init?(hex: String) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") { string.removeFirst() }
        guard string.count == 6, let value = UInt32(string, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255.0,
            green: Double((value >> 8) & 0xFF) / 255.0,
            blue: Double(value & 0xFF) / 255.0)
    }

    var hexString: String {
        func channel(_ value: Double) -> Int { max(0, min(255, Int((value * 255).rounded()))) }
        return String(format: "#%02X%02X%02X", channel(self.red), channel(self.green), channel(self.blue))
    }

    init?(swiftUIColor: Color) {
        guard let rgb = NSColor(swiftUIColor).usingColorSpace(.deviceRGB) else { return nil }
        self.init(
            red: Double(rgb.redComponent),
            green: Double(rgb.greenComponent),
            blue: Double(rgb.blueComponent))
    }

    var swiftUIColor: Color {
        Color(red: self.red, green: self.green, blue: self.blue)
    }

    var nsColor: NSColor {
        NSColor(deviceRed: self.red, green: self.green, blue: self.blue, alpha: 1)
    }
}

/// Central source of truth for the effective brand color of each provider: a user override when
/// present, otherwise the provider's default branding color. Kept thread-safe so static UI helpers
/// (menu bar icon, switcher, charts) can resolve colors without threading a `SettingsStore` through.
final class ProviderBrandColorResolver: @unchecked Sendable {
    static let shared = ProviderBrandColorResolver()

    private let lock = NSLock()
    private var overrides: [String: ProviderColor] = [:]

    func setOverrides(_ overrides: [String: ProviderColor]) {
        self.lock.lock()
        self.overrides = overrides
        self.lock.unlock()
    }

    func color(for provider: UsageProvider) -> ProviderColor {
        self.lock.lock()
        let override = self.overrides[provider.rawValue]
        self.lock.unlock()
        return override ?? ProviderDescriptorRegistry.descriptor(for: provider).branding.color
    }
}
