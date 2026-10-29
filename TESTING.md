# Testing

The Base uses **Swift Testing** (`import Testing`, `@Test`, `#expect`).

## What the Base tests

- Pure decision logic: ad availability, interstitial frequency, billing error mapping, paywall
  messages, network error mapping, reminder request mapping.
- Stateful mechanisms against fakes: onboarding progression, preferences persistence
  (per-test `UserDefaults` suite), paywall view model, SwiftData container round-trip, HTTP client
  against a stub `URLProtocol`.

SDK glue (StoreKit purchase sheet, GMA presentation, UMP forms) is verified manually in the demo.

## `ProductBaseTesting`

Link it to your **test target only**.

```swift
FakeAppPreferences(themeMode: .dark, onboardingCompleted: true)
FakePremiumState(status: .free)
RecordingLogger()      // .entries to assert a failure was logged
```

## Fakes you write in the product

Billing, ads and review fakes are deliberately not shipped (they would pull those modules into
every test target). They are a few lines each:

```swift
@MainActor @Observable
final class FakeBillingManager: BillingManager {
    var purchaseState: PurchaseState = .notPurchased
    var proProduct: ProProduct? = ProProduct(productID: "pro", displayName: "Pro", description: "", displayPrice: "$2.99")
    var nextOutcome: PurchaseOutcome = .purchased
    func start() async {}
    func refreshPurchases() async {}
    func restorePurchases() async {}
    func purchase() async -> PurchaseOutcome { nextOutcome }
}

@MainActor
final class FakeReviewManager: AppReviewManager {
    private(set) var requests = 0
    func requestReview() -> ReviewOutcome { requests += 1; return .requested }
}
```

For `AdsController`, conform a small `@Observable` class the same way.

## Running

```bash
xcodebuild test -scheme ProductBase-Package -destination 'platform=iOS Simulator,name=iPhone 17'
```

Use whichever simulator `xcrun simctl list devices available` shows.
