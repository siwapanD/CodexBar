import CodexBarCore
import Testing
@testable import CodexBar

struct ProviderBrandColorResolverTests {
    @Test
    func `hex parses and round-trips`() {
        let color = ProviderColor(hex: "#FF8800")
        #expect(color != nil)
        #expect(color?.hexString == "#FF8800")
        // Accepts a value without the leading '#'.
        #expect(ProviderColor(hex: "00FF00")?.hexString == "#00FF00")
    }

    @Test
    func `invalid hex returns nil`() {
        #expect(ProviderColor(hex: "nope") == nil)
        #expect(ProviderColor(hex: "#FFF") == nil)
        #expect(ProviderColor(hex: "") == nil)
    }

    @Test
    func `resolver prefers override then falls back to default`() {
        let resolver = ProviderBrandColorResolver()
        let defaultColor = ProviderDescriptorRegistry.descriptor(for: .claude).branding.color
        #expect(resolver.color(for: .claude) == defaultColor)

        let custom = ProviderColor(red: 0.1, green: 0.2, blue: 0.3)
        resolver.setOverrides([UsageProvider.claude.rawValue: custom])
        #expect(resolver.color(for: .claude) == custom)
        // A provider without an override still resolves to its default.
        #expect(resolver.color(for: .codex) == ProviderDescriptorRegistry.descriptor(for: .codex).branding.color)

        resolver.setOverrides([:])
        #expect(resolver.color(for: .claude) == defaultColor)
    }
}
