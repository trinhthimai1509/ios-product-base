import Foundation
import Observation
import ProductBaseCommon

/// The single owner of application preference keys, so two features cannot collide.
///
/// Implementations are `@Observable`: a SwiftUI view that reads ``themeMode`` re-renders when it
/// changes. Writes go through methods, not setters, so a fake can record them and so the
/// direction of data flow reads the same as in the Android Base.
///
/// Not for product-domain data (that is a database) and never for secrets — the default
/// implementation is plain `UserDefaults`. Secrets belong in the Keychain.
@MainActor
public protocol AppPreferences: AnyObject, Observable {
    /// Default ``ThemeMode/system``.
    var themeMode: ThemeMode { get }
    /// Default `false`.
    var onboardingCompleted: Bool { get }
    /// The *app's* switch, independent of the system notification permission. Default `true`.
    var notificationsEnabled: Bool { get }

    func setThemeMode(_ themeMode: ThemeMode)
    func setOnboardingCompleted(_ completed: Bool)
    func setNotificationsEnabled(_ enabled: Bool)
}

/// ``AppPreferences`` backed by `UserDefaults`.
///
/// Values are read once at init and cached, so reads are free and observation works; writes go
/// to both. An unreadable value (a key written by an older build with a different type) falls
/// back to the default rather than crashing.
@MainActor
@Observable
public final class UserDefaultsAppPreferences: AppPreferences {
    public private(set) var themeMode: ThemeMode
    public private(set) var onboardingCompleted: Bool
    public private(set) var notificationsEnabled: Bool

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let keys: Keys

    /// - Parameters:
    ///   - defaults: `.standard` in an app; a suite created per test in tests.
    ///   - keyPrefix: namespaces every key. Change it only with a migration — existing users
    ///     would otherwise lose their settings.
    public init(defaults: UserDefaults = .standard, keyPrefix: String = "productbase.") {
        self.defaults = defaults
        self.keys = Keys(prefix: keyPrefix)

        themeMode = defaults.string(forKey: keys.themeMode).flatMap(ThemeMode.init(rawValue:)) ?? .system
        onboardingCompleted = defaults.object(forKey: keys.onboardingCompleted) as? Bool ?? false
        notificationsEnabled = defaults.object(forKey: keys.notificationsEnabled) as? Bool ?? true
    }

    public func setThemeMode(_ themeMode: ThemeMode) {
        defaults.set(themeMode.rawValue, forKey: keys.themeMode)
        self.themeMode = themeMode
    }

    public func setOnboardingCompleted(_ completed: Bool) {
        defaults.set(completed, forKey: keys.onboardingCompleted)
        onboardingCompleted = completed
    }

    public func setNotificationsEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: keys.notificationsEnabled)
        notificationsEnabled = enabled
    }

    private struct Keys {
        let themeMode: String
        let onboardingCompleted: String
        let notificationsEnabled: String

        init(prefix: String) {
            themeMode = prefix + "themeMode"
            onboardingCompleted = prefix + "onboardingCompleted"
            notificationsEnabled = prefix + "notificationsEnabled"
        }
    }
}
