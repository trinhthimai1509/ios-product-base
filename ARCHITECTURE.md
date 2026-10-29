# Architecture

Why the Base is shaped the way it is, and how each Android decision translates to iOS.

## Principles (shared with Android Product Base)

1. **Mechanism in the Base, policy in the product.** The Base knows *how* to show an ad, buy Pro,
   schedule a reminder; the product decides *when*.
2. **Every module is optional.** Linking is opt-in per library product; vendor SDKs live in
   separate packages so they are not even resolved unless used.
3. **Seams, not switches.** Products change behaviour through protocols, initialiser arguments,
   closures and labels — never by editing Base source.
4. **Honest state.** `PremiumStatus.unknown`, `PurchaseState.unknown`, `PremiumMessage.couldNotCheck`
   exist because "we have not asked yet" is neither yes nor no.
5. **Pure decisions, thin plumbing.** Rules that matter (ad availability, interstitial frequency,
   paywall messages, error mapping) are pure functions with tests; SDK glue stays thin.

## Android → iOS mapping

| Concern | Android Product Base | iOS Product Base |
|---|---|---|
| Modularisation | Gradle modules, `settings.gradle.kts` include | SPM library products; vendor SDKs in `Extensions/*` packages |
| Consumption | Composite build from a sibling checkout at a tag | Local package reference to a sibling checkout at a tag |
| Build conventions | `build-logic` convention plugins | `Package.swift` settings: Swift 6 mode, `ExistentialAny` |
| DI | Hilt modules, `@Inject` | Initialiser injection + one composition root (`AppContainer`) |
| Observable state | `StateFlow` / `Flow` | `@MainActor @Observable` classes |
| Async | Coroutines, `suspend` | Swift Concurrency, `async`/`await`, `AsyncStream` |
| UI | Jetpack Compose + Material 3 | SwiftUI |
| Theme | `ProductBaseTheme(...)` composable, `CompositionLocal`s | `.productBaseTheme(_:themeMode:)`, `@Environment(\.appTheme)` |
| Colour roles | M3 `ColorScheme` | `ColorPalette` with the same role names and default values |
| Dynamic colour (Android 12) | `dynamicColor` | — (no platform equivalent; omitted) |
| Preferences | DataStore | `UserDefaults`, behind `AppPreferences` |
| Database | Room converters + migration policy | SwiftData `PersistentStore.makeContainer` + "never delete" policy |
| HTTP | OkHttp + Retrofit + kotlinx-serialization | `URLSession` + `Codable`, typed `throws(NetworkError)` |
| Connectivity | `ConnectivityManager` | `NWPathMonitor` |
| Telemetry | `core:telemetry` + `core:telemetry-firebase` | `ProductBaseTelemetry` + `Extensions/TelemetryFirebase` |
| Ads | GMA + UMP | GMA 12 + UMP 3 (Swift names, async APIs) |
| Purchases | Play Billing, one in-app product | StoreKit 2, one non-consumable; adds App Store-required **Restore** |
| Review | Play In-App Review | `AppStore.requestReview(in:)` |
| Notifications | Channels, `POST_NOTIFICATIONS`, WorkManager | Authorization, `UNCalendarNotificationTrigger`, `threadIdentifier` |
| Strings | `res/values` with `pb_*` prefixes, overridable | String catalogs (`en`, `vi`) + overridable `…Labels` values |
| Lint/format | Spotless + Android Lint | Swift 6 strict concurrency, `swift format` |
| Demo | `demo` app module | `Demo/ProductBaseDemo.xcodeproj` |

## Concurrency model

Everything a view reads is `@MainActor`. Protocols for observable capabilities
(`AppPreferences`, `PremiumState`, `BillingManager`, `AdsController`) are `@MainActor` and
`Observable`, so a view or a computed property that reads them re-renders when they change —
`GoogleAdsController.adsAvailable` is a computed property over `PremiumState.status` and
re-evaluates with no subscription code. Non-UI services (`HTTPClient`, `ReminderScheduler`,
`Logger`, `Analytics`) are `Sendable` value types usable from any context.

## Package layout

```
ios-product-base/
├── Package.swift                 ← dependency-free root package (13 library products)
├── Core/<Module>/{Sources,Tests}
├── Feature/<Module>/{Sources,Tests}
├── Extensions/
│   ├── Ads/Package.swift                 ← GoogleMobileAds + UMP
│   └── TelemetryFirebase/Package.swift   ← Firebase Analytics + Crashlytics
└── Demo/ProductBaseDemo.xcodeproj        ← capability catalog
```

Extension packages depend on the root package by relative path (`../..`), which is why consumers
take the Base as a sibling checkout rather than a remote URL.
