# Monetization

Ads (`Extensions/Ads`), the Pro purchase (`ProductBaseBilling`) and the paywall
(`ProductBasePremium`).

## Ads

### Info.plist

```xml
<key>GADApplicationIdentifier</key>
<string>$(GAD_APPLICATION_ID)</string>   <!-- set per configuration in an .xcconfig -->
<key>SKAdNetworkItems</key>
<array> … Google's current list … </array>
<key>NSUserTrackingUsageDescription</key>   <!-- only if you request ATT -->
```

Use `TestAdUnits.applicationID` for Debug. **A missing `GADApplicationIdentifier` crashes the
app at launch** — that is the SDK, not the Base.

### Configuration

```swift
#if DEBUG
let adsConfig = AdsConfig.testAds()
#else
let adsConfig = AdsConfig(bannerAdUnitID: "ca-app-pub-…/…", interstitialAdUnitID: "…",
                          rewardedAdUnitID: "…", isReleaseBuild: true)
#endif
let ads = GoogleAdsController(config: adsConfig, premiumState: billing, logger: logger)
```

A release build that still carries test unit ids **disables ads** and logs an error instead of
shipping test ads.

### Lifecycle

```swift
.task { await ads.initialize() }   // first screen: gathers UMP consent, then starts the SDK
```

`adsAvailable` is `false` until consent allows requests **and** `PremiumState` is `.free`.
`.unknown` (cold start, App Store not yet answered) suppresses ads — a paying user never sees one.

### Formats

- **Banner**: `AppBannerAd(adsController: ads)` — collapses to nothing when unavailable.
- **Interstitial**: call `recordQualifyingAction()` when the user completes something, and
  `await ads.showInterstitial()` at a natural pause. `InterstitialPolicy` (default: 3 actions and
  3 minutes) returns `.throttled` otherwise.
- **Rewarded**: `await ads.showRewarded()` → `.earned(amount:type:)` or `.dismissed`.

### Privacy options

When `ads.privacyOptionsRequired` is true (GDPR regions) the product **must** offer a settings
row that calls `ads.showPrivacyOptions()`.

## Pro purchase

1. Create a **non-consumable** in App Store Connect.
2. For local testing, add a `.storekit` configuration file and select it in the scheme's
   *Run ▸ Options ▸ StoreKit Configuration* (the demo does this).
3. `let billing = StoreKitBillingManager(config: BillingConfig(proProductID: "…"), logger: logger)`
4. `await billing.start()` at launch.

`restorePurchases()` must be reachable from the UI — App Review rejects non-consumable apps
without a Restore button. `PremiumScreen` includes one.

## Paywall

```swift
PremiumScreen(
    content: PremiumContent(title: "Go Pro", subtitle: "…", benefits: ["No ads", "…"]),
    viewModel: PremiumViewModel(billingManager: billing)
)
```

The price is `ProProduct.displayPrice`, localised by the App Store. Never hardcode one.
