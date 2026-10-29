import Foundation
import ProductBaseSettings
import Testing

struct SettingsLabelsTests {
    @Test func standardLabelsResolveFromTheStringCatalog() {
        let labels = SettingsLabels.standard

        // A missing catalog entry resolves to its key; none of these may.
        for value in [labels.theme, labels.light, labels.dark, labels.system] {
            #expect(!value.hasPrefix("settings."))
        }
    }

    @Test func versionDescriptionFallsBackWhenKeysAreMissing() {
        #expect(Bundle(for: BundleToken.self).versionDescription.contains("("))
    }
}

private final class BundleToken {}
