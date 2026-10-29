# Product integration

How to compose Base capabilities into a real product, and the rules for doing it.

## Consumer rules

1. **Never modify Base source.** Not temporarily, not one line.
2. **Link only what you use.** Each unchecked library product is code you don't ship.
3. **One composition root.** Build every capability once in an `AppContainer` (see the demo) and
   pass it down. No singletons of Base types elsewhere.
4. **Pin a tag.** See [VERSIONING.md](VERSIONING.md).

When something doesn't fit, classify it:

| Class | Meaning | What to do |
|---|---|---|
| **A** | Product-specific requirement | Build it in the product. |
| **B** | Missing/wrong documentation | Report or fix the doc in the Base. |
| **C** | Missing broadly reusable capability | Report it with the use case. |
| **D** | Base API or design defect | Report it with the failing usage. |
| **E** | Specialised extension candidate | Report it; may become a new `Extensions/` package. |

## Common combinations

| Product | Link |
|---|---|
| Offline utility, no money | Common, DesignSystem, Preferences, Onboarding, Settings |
| + local data | … + Database |
| Ad-supported free app | … + Ads (with `PremiumState.alwaysFree`) |
| Free with "remove ads" | … + Ads + Billing + Premium |
| Content app with an API | … + Network |
| Anything with analytics | … + Telemetry (+ TelemetryFirebase) |

## Wiring premium into ads

```swift
let billing = StoreKitBillingManager(config: BillingConfig(proProductID: "com.example.pro"), logger: logger)
let ads = GoogleAdsController(config: adsConfig, premiumState: billing, logger: logger)
// No billing? premiumState: AlwaysFreePremiumState()
```

`StoreKitBillingManager` *is* the `PremiumState`; ads vanish the moment a purchase lands.

## Settings composition

`SettingsScreen` holds no state and knows no capability. The product decides which rows exist:

```swift
SettingsScreen(title: "Settings", sections: [
    SettingsSection("Display", rows: [.themePicker(themeMode: prefs.themeMode, onChange: prefs.setThemeMode)]),
    SettingsSection("Pro", rows: billing.purchaseState == .purchased ? [] : [
        .action(title: "Remove ads", systemImage: "sparkles") { showPaywall = true },
    ]),
    SettingsSection("Privacy", rows: ads.privacyOptionsRequired ? [
        .action(title: "Privacy options") { Task { await ads.showPrivacyOptions() } },
    ] : []),
    SettingsSection("About", rows: [.info(title: "Version", value: Bundle.main.versionDescription)]),
])
```

Empty sections are not rendered, so no filtering is needed.

## Navigation

The Base ships no router. Feature screens are plain views; put them in your `NavigationStack`,
`.sheet` or `.fullScreenCover` as the product requires.
