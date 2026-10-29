# Module catalog

Fifteen modules, as Swift Package library products. **A product links only what it needs**; a
product that is not linked is code the app never compiles. See
[PRODUCT_INTEGRATION.md](PRODUCT_INTEGRATION.md) for worked combinations.

| Module | One line | Third-party weight | Android counterpart |
|---|---|---|---|
| [`ProductBaseCommon`](#productbasecommon) | Theme mode, logging, premium status | none | `core:common` |
| [`ProductBaseDesignSystem`](#productbasedesignsystem) | SwiftUI theme + 13 components | none | `core:designsystem` |
| [`ProductBasePreferences`](#productbasepreferences) | Typed app preferences | none | `core:datastore` |
| [`ProductBaseDatabase`](#productbasedatabase) | SwiftData container + policy | none | `core:database` |
| [`ProductBaseNetwork`](#productbasenetwork) | URLSession client, errors, connectivity | none | `core:network` |
| [`ProductBaseTelemetry`](#productbasetelemetry) | Analytics + crash contracts | none | `core:telemetry` |
| [`ProductBaseTelemetryFirebase`](#productbasetelemetryfirebase) | The only module that sees Firebase | Firebase | `core:telemetry-firebase` |
| [`ProductBaseAds`](#productbaseads) | AdMob + UMP consent | Google Mobile Ads, UMP | `core:ads` |
| [`ProductBaseBilling`](#productbasebilling) | StoreKit 2 "Pro" purchase | none (StoreKit) | `core:billing` |
| [`ProductBaseReview`](#productbasereview) | App Store review prompt | none (StoreKit) | `core:review` |
| [`ProductBaseNotification`](#productbasenotification) | Permission, local reminders | none | `core:notification` |
| [`ProductBaseTesting`](#productbasetesting) | Shared fakes (test-only) | none | `core:testing` |
| [`ProductBaseOnboarding`](#productbaseonboarding) | Pager, skip/finish, persistence | none | `feature:onboarding` |
| [`ProductBaseSettings`](#productbasesettings) | Settings assembled from supplied rows | none | `feature:settings` |
| [`ProductBasePremium`](#productbasepremium) | Paywall mechanism | none | `feature:premium` |

**Universal rules**

- Every module that logs takes a `Logger` in its initialiser. The product creates exactly one.
- No module reads `Info.plist` values or `#if DEBUG` on the product's behalf. Configuration is
  passed in.
- No feature module depends on another feature module. Cross-feature navigation is the product's.
- Observable state is `@MainActor @Observable`; async work is `async`/`await`. No Combine.
- Components take **already-resolved, localised strings**. Base-owned strings (onboarding
  buttons, theme picker, paywall messages) ship in English and Vietnamese and are overridable
  through each feature's `…Labels` value.

---

## ProductBaseCommon

**Purpose.** The only module most others depend on: theme preference type, logging contract,
and the premium-status seam.

```swift
enum ThemeMode { case light, dark, system }

protocol Logger: Sendable { debug, info, warning, error }
struct OSLogLogger: Logger      // unified logging, for debug builds
struct NoOpLogger: Logger       // discards, for release builds

@MainActor protocol PremiumState: AnyObject, Observable { var status: PremiumStatus { get } }
enum PremiumStatus { case unknown, premium, free }
final class AlwaysFreePremiumState: PremiumState   // `.alwaysFree` — for apps that sell nothing
```

**Do not use for.** A dumping ground — no error hierarchy, no date utilities.

---

## ProductBaseDesignSystem

**Purpose.** The SwiftUI theme and the shared component vocabulary. Same colour roles and
default values as the Android Base, so one brand spec feeds both.

```swift
struct ProductBaseTheme { lightColors, darkColors: ColorPalette; lightSemanticColors,
                          darkSemanticColors: SemanticColors; spacing: Spacing;
                          radii: CornerRadii; typography: Typography }
extension View { func productBaseTheme(_ theme: ProductBaseTheme = .init(), themeMode: ThemeMode = .system) -> some View }

@Environment(\.appTheme) var theme      // AppTheme: colors, semanticColors, spacing, radii, typography — resolved for light/dark
```

Components: `PrimaryButton`, `SecondaryButton`, `AppCard`, `.appDialog(…)`, `AppScaffold`,
`SectionHeader`, `SettingsItem`, `SwitchSettingsItem`, `PremiumBadge`, `LoadingState`,
`EmptyState`, `ErrorState`. (`AppTopBar` has no counterpart: on iOS the bar is
`NavigationStack` + `.navigationTitle` + `.toolbar`.)

**Do not use for.** Product-specific components. Branding is parameters: [THEMING.md](THEMING.md).

---

## ProductBasePreferences

**Purpose.** The single owner of application preference keys.

```swift
@MainActor protocol AppPreferences: AnyObject, Observable {
    var themeMode: ThemeMode { get }            // default .system
    var onboardingCompleted: Bool { get }       // default false
    var notificationsEnabled: Bool { get }      // default true — the app's switch, not the OS permission
    func setThemeMode(_:); func setOnboardingCompleted(_:); func setNotificationsEnabled(_:)
}
final class UserDefaultsAppPreferences: AppPreferences   // init(defaults: = .standard, keyPrefix: = "productbase.")
```

An unreadable value falls back to the default instead of crashing. **Never for secrets** — use the
Keychain. Android's `dynamicColorEnabled` has no iOS equivalent and is intentionally absent.

---

## ProductBaseDatabase

**Purpose.** SwiftData container creation and the shared migration policy. **No models.**

```swift
enum PersistentStore {
    enum Location { case applicationSupport(name:), appGroup(identifier:name:), inMemory }
    static func makeContainer(schema: Schema, migrationPlan: (any SchemaMigrationPlan.Type)? = nil,
                              location: Location, cloudKit: … = .none, logger: any Logger) throws -> ModelContainer
}
```

A store that cannot be opened **throws** — it is never deleted and recreated. Once you ship a
second schema version, define `VersionedSchema`s and a `SchemaMigrationPlan` in the product.

---

## ProductBaseNetwork

**Purpose.** A typed `URLSession` client, an owned error type, and connectivity monitoring.
No API definitions, no DTOs, no cache, no retry.

```swift
struct NetworkConfig { baseURL; requestTimeout = 20s; resourceTimeout = 60s; defaultHeaders; enableHTTPLogging = false }
struct HTTPRequest { method, path, query, headers, body; static func get(_:query:); static func json(_:_:body:) }
struct HTTPClient { init(config:session:logger:makeDecoder:)
                    func send<T: Decodable>(_:as:) async throws(NetworkError) -> T
                    func send(_:) async throws(NetworkError) -> Data }
enum NetworkError: Error { noConnection, timeout, http(statusCode:body:), malformed, cancelled, unexpected; var isTransient }
extension Error { func toNetworkError() -> NetworkError }
protocol NetworkMonitor { var isOnline: AsyncStream<Bool> { get } }; struct PathNetworkMonitor
```

---

## ProductBaseTelemetry

**Purpose.** Analytics and crash-reporting **contracts**, with no-op implementations.

```swift
protocol Analytics: Sendable { func logScreenView(_:); func logEvent(_: AnalyticsEvent) }
struct AnalyticsEvent { name; parameters: [String: AnalyticsValue] }   // values are string/int/double/bool literals
protocol CrashReporter: Sendable { recordNonFatal(_:); log(_:); setCustomKey(_:value:) }
struct NoOpAnalytics, NoOpCrashReporter
```

---

## ProductBaseTelemetryFirebase

Package `Extensions/TelemetryFirebase`. The only code in this repository that may import Firebase.

```swift
FirebaseTelemetry.bootstrap(bundle: .main, logger:) -> TelemetryBindings   // analytics, crashReporter, isFirebaseConfigured
```

Without `GoogleService-Info.plist` in the app bundle it returns the **no-ops** instead of
crashing, so a fresh clone runs. Keep that plist out of version control. For Crashlytics symbol
upload add Firebase's `run` script build phase in the product.

---

## ProductBaseAds

Package `Extensions/Ads`. Google Mobile Ads and UMP consent behind a product-facing API.

```swift
@MainActor protocol AdsController: AnyObject, Observable {
    var adsAvailable: Bool { get }; var privacyOptionsRequired: Bool { get }; var bannerAdUnitID: String { get }
    func initialize() async
    func showPrivacyOptions() async -> ConsentOutcome
    func showInterstitial() async -> InterstitialOutcome
    func showRewarded() async -> RewardedOutcome
    func recordQualifyingAction()
}
final class GoogleAdsController: AdsController   // init(config: AdsConfig, premiumState:, logger:)
struct AppBannerAd: View                         // renders nothing when ads are unavailable

struct AdsConfig { banner/interstitial/rewarded ids, adsEnabled, interstitialPolicy, isReleaseBuild; static func testAds() }
struct InterstitialPolicy { minInterval = 180s, minQualifyingActions = 3 }
enum TestAdUnits { applicationID, banner, interstitial, rewarded }
```

**Required configuration.** `GADApplicationIdentifier` in Info.plist, the `SKAdNetworkItems`
list, a `PremiumState`, and a call to `initialize()` from the first screen. A release build with
test ad units disables ads rather than shipping them. Detail: [MONETIZATION.md](MONETIZATION.md).

---

## ProductBaseBilling

**Purpose.** One non-consumable "Pro / remove ads" product on StoreKit 2. Publishes the
`PremiumState` the Ads module reads.

```swift
@MainActor protocol BillingManager: AnyObject, Observable {
    var purchaseState: PurchaseState { get }   // unknown → notPurchased | pending | purchased
    var proProduct: ProProduct? { get }        // displayName, description, displayPrice (App Store-localised)
    func start() async; func refreshPurchases() async; func restorePurchases() async
    func purchase() async -> PurchaseOutcome   // purchased | pending | alreadyOwned | cancelled | failed(BillingError)
}
final class StoreKitBillingManager: BillingManager, PremiumState   // init(config: BillingConfig, logger:)
```

`refreshPurchases()` is silent; `restorePurchases()` is the App Review-required "Restore
Purchases" (calls `AppStore.sync()`, may prompt for sign-in). **Not** subscriptions, tiers or
server-side receipt validation.

---

## ProductBaseReview

```swift
@MainActor protocol AppReviewManager { func requestReview() -> ReviewOutcome }   // requested | unavailable
final class StoreKitReviewManager: AppReviewManager
```

`requested` means handed to iOS — **not** that a prompt appeared (iOS limits it to three a year
and never says). No counter, no engagement score, deliberately.

---

## ProductBaseNotification

**Purpose.** The notification permission and local reminders. iOS has no channels;
`threadIdentifier` groups notifications instead.

```swift
enum NotificationAuthorization { notDetermined, denied, authorized, provisional, ephemeral; var canDeliver }
protocol NotificationPermission { func status() async -> NotificationAuthorization; func request() async -> Bool }
struct ReminderRequest { id, triggerDate, repeatMatching: Set<Calendar.Component>?, title, body, threadIdentifier, deepLink, playsSound
                         static func deepLink(from userInfo:) -> URL? }
protocol ReminderScheduler { schedule(_:) async throws; cancel(id:) async; pendingIDs() async -> [String] }
struct UserNotificationPermission, UserNotificationReminderScheduler
```

No push notifications. iOS keeps at most 64 pending local notifications.

---

## ProductBaseTesting

Test-only. `FakeAppPreferences`, `FakePremiumState`, `RecordingLogger`. Capability fakes for
billing, ads and review are deliberately **not** here — see [TESTING.md](TESTING.md).

---

## ProductBaseOnboarding

```swift
struct OnboardingPage { title, description, illustration }   // init(title:description:) or with @ViewBuilder illustration
@MainActor @Observable final class OnboardingViewModel { pageIndex; isCompleted; next(pageCount:); goToPage(_:); skip(); finish() }
struct OnboardingScreen: View   // init(pages:viewModel:labels:) or the stateless init with callbacks
struct OnboardingLabels { skip, next, finish, pageIndicator; static var standard }
```

Navigate on `viewModel.isCompleted`, which is read back from preferences — not on the button.

---

## ProductBaseSettings

**The lightest feature module: the design system and nothing else. No state.**

```swift
struct SettingsSection { title, footer, rows: [SettingsRow] }   // empty sections are not rendered
enum SettingsRow { action, toggle, info, themePicker, link, share, openSystemSettings }
struct SettingsScreen: View   // init(title:sections:labels:)
extension Bundle { var versionDescription: String }   // "1.4.0 (212)"
```

Premium, privacy and notification rows are wired by the product — see
[PRODUCT_INTEGRATION.md](PRODUCT_INTEGRATION.md#settings-composition).

---

## ProductBasePremium

```swift
struct PremiumContent { title, subtitle, benefits, footnote }
enum PremiumMessage { purchaseCompleted, purchasePending, alreadyOwned, nothingToRestore, couldNotCheck, failed(BillingError) }
@MainActor @Observable final class PremiumViewModel { purchaseState; product; isWorking; message; purchase() async; restore() async; dismissMessage() }
struct PremiumScreen: View    // init(content:viewModel:labels:)
```

The price comes from the App Store, already localised — never format or hardcode one.
