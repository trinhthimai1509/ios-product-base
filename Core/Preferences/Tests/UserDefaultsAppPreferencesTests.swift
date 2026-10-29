import Foundation
import ProductBaseCommon
import ProductBasePreferences
import Testing

@MainActor
struct UserDefaultsAppPreferencesTests {
    private let suiteName = "UserDefaultsAppPreferencesTests.\(UUID().uuidString)"

    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func freshStoreHasDocumentedDefaults() {
        let prefs = UserDefaultsAppPreferences(defaults: makeDefaults())

        #expect(prefs.themeMode == .system)
        #expect(prefs.onboardingCompleted == false)
        #expect(prefs.notificationsEnabled == true)
    }

    @Test func writesSurviveANewInstance() {
        let defaults = makeDefaults()
        let first = UserDefaultsAppPreferences(defaults: defaults)
        first.setThemeMode(.dark)
        first.setOnboardingCompleted(true)
        first.setNotificationsEnabled(false)

        let second = UserDefaultsAppPreferences(defaults: defaults)

        #expect(second.themeMode == .dark)
        #expect(second.onboardingCompleted == true)
        #expect(second.notificationsEnabled == false)
    }

    @Test func unreadableValueFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set("not-a-theme", forKey: "productbase.themeMode")
        defaults.set("yes", forKey: "productbase.onboardingCompleted")

        let prefs = UserDefaultsAppPreferences(defaults: defaults)

        #expect(prefs.themeMode == .system)
        #expect(prefs.onboardingCompleted == false)
    }

    @Test func keyPrefixIsolatesStores() {
        let defaults = makeDefaults()
        UserDefaultsAppPreferences(defaults: defaults, keyPrefix: "a.").setThemeMode(.light)

        #expect(UserDefaultsAppPreferences(defaults: defaults, keyPrefix: "b.").themeMode == .system)
    }
}
