import CodexBarCore
import Foundation

extension SettingsStore {
    /// The effective brand color for a provider: a user override if set, otherwise the default.
    func brandColor(for provider: UsageProvider) -> ProviderColor {
        if let hex = self.providerColorOverridesRaw[provider.rawValue],
           let color = ProviderColor(hex: hex)
        {
            return color
        }
        return ProviderDescriptorRegistry.descriptor(for: provider).branding.color
    }

    func hasBrandColorOverride(for provider: UsageProvider) -> Bool {
        self.providerColorOverridesRaw[provider.rawValue] != nil
    }

    func setBrandColor(_ color: ProviderColor, for provider: UsageProvider) {
        var overrides = self.providerColorOverridesRaw
        overrides[provider.rawValue] = color.hexString
        self.providerColorOverridesRaw = overrides
    }

    func resetBrandColor(for provider: UsageProvider) {
        guard self.providerColorOverridesRaw[provider.rawValue] != nil else { return }
        var overrides = self.providerColorOverridesRaw
        overrides.removeValue(forKey: provider.rawValue)
        self.providerColorOverridesRaw = overrides
    }

    /// Pushes the parsed overrides into the shared resolver so static UI helpers pick them up.
    func syncProviderColorOverrides() {
        var resolved: [String: ProviderColor] = [:]
        for (key, hex) in self.providerColorOverridesRaw {
            if let color = ProviderColor(hex: hex) {
                resolved[key] = color
            }
        }
        ProviderBrandColorResolver.shared.setOverrides(resolved)
    }
}
