/// The user's appearance preference.
///
/// `system` follows the device setting. Persisted by `ProductBasePreferences` and applied by
/// `ProductBaseDesignSystem`; this type lives here so neither has to depend on the other.
public enum ThemeMode: String, CaseIterable, Sendable, Codable {
    case light
    case dark
    case system
}
