import CodexBarCore
import SwiftUI

/// A per-provider color override row: pick any color for the provider's icon/accent, with a
/// reset-to-default action. The chosen color applies everywhere the brand color is used
/// (menu bar icon, provider switcher, charts).
@MainActor
struct ProviderColorSettingsView: View {
    let provider: UsageProvider
    @Bindable var settings: SettingsStore

    var body: some View {
        ProviderSettingsSection(title: L("provider_appearance_section")) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("provider_color_title"))
                        .font(.body)
                    Text(L("provider_color_subtitle"))
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                }
                Spacer(minLength: 8)
                if self.settings.hasBrandColorOverride(for: self.provider) {
                    Button(L("provider_color_reset")) {
                        self.settings.resetBrandColor(for: self.provider)
                    }
                    .buttonStyle(.link)
                }
                ColorPicker("", selection: self.colorBinding, supportsOpacity: false)
                    .labelsHidden()
            }
        }
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { self.settings.brandColor(for: self.provider).swiftUIColor },
            set: { newColor in
                if let color = ProviderColor(swiftUIColor: newColor) {
                    self.settings.setBrandColor(color, for: self.provider)
                }
            })
    }
}
