# iOS Product Base

[![CI](https://github.com/trinhthimai1509/ios-product-base/actions/workflows/ci.yml/badge.svg)](https://github.com/trinhthimai1509/ios-product-base/actions/workflows/ci.yml)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
![Version](https://img.shields.io/badge/version-v0.1.0--alpha01-orange)
![iOS](https://img.shields.io/badge/iOS-17%2B-green)

A reusable, source-consumed foundation for consumer iOS apps: SwiftUI design system, preferences,
SwiftData and HTTP plumbing, telemetry contracts, ads with consent, StoreKit 2 purchases, App Store
review, local notifications, onboarding, settings and a paywall — **fifteen modules, each of which
a product can leave out.**

It is the iOS sibling of [Android Product Base](https://github.com/trinhthimai1509/android-product-base):
same module set, same boundaries, same rules, same brand tokens — written the way an iOS app is
written (Swift Package Manager, SwiftUI, `@Observable`, Swift Concurrency, StoreKit 2), not
transliterated from Kotlin. [ARCHITECTURE.md](ARCHITECTURE.md) maps every Android concept to its
iOS counterpart.

This is a **reusable foundation, not a standalone app.** It is consumed by separate iOS product
repositories from a sibling checkout pinned to a Git tag (never `main` — see
[VERSIONING.md](VERSIONING.md)).

```
workspace/
├── ios-product-base/      ← this repository, read-only infrastructure
└── consumer-app/          ← your product
```

---

## Start here

| If you want to… | Read |
|---|---|
| Get a running app as fast as possible | **[QUICK_START.md](QUICK_START.md)** |
| Know what each module does, costs and requires | [MODULE_CATALOG.md](MODULE_CATALOG.md) |
| Compose capabilities into a real product | [PRODUCT_INTEGRATION.md](PRODUCT_INTEGRATION.md) |
| Ship ads, purchases or a paywall | [MONETIZATION.md](MONETIZATION.md) |
| Brand the app | [THEMING.md](THEMING.md) |
| Test product code built on the Base | [TESTING.md](TESTING.md) |
| Follow a checklist end to end | [NEW_APP_CHECKLIST.md](NEW_APP_CHECKLIST.md) |
| Understand *why* it is built this way, and how it maps to Android | [ARCHITECTURE.md](ARCHITECTURE.md) |
| Understand version pinning and upgrades | [VERSIONING.md](VERSIONING.md) |
| Work on the Base itself | [DEVELOPMENT.md](DEVELOPMENT.md) |
| Wire up CI, here or in a consumer | [CI_CD.md](CI_CD.md) |
| Brief a coding agent working in this repo | [AGENTS.md](AGENTS.md) |

## The rule

**Consumer products must not modify Product Base source code.** Friction gets classified and
reported, not patched locally — see [the classification table](PRODUCT_INTEGRATION.md#consumer-rules).

## What is in the box

Three Swift packages. The root package has **no third-party dependencies**; the two that pull a
vendor SDK are separate packages so an app that does not use them never even resolves them.

| Package | Library products |
|---|---|
| `ios-product-base/` (root) | `ProductBaseCommon` · `ProductBaseDesignSystem` · `ProductBasePreferences` · `ProductBaseDatabase` · `ProductBaseNetwork` · `ProductBaseTelemetry` · `ProductBaseBilling` · `ProductBaseReview` · `ProductBaseNotification` · `ProductBaseTesting` · `ProductBaseOnboarding` · `ProductBaseSettings` · `ProductBasePremium` |
| `Extensions/Ads` | `ProductBaseAds` — Google Mobile Ads + UMP consent |
| `Extensions/TelemetryFirebase` | `ProductBaseTelemetryFirebase` — the only code that sees Firebase |
| `Demo/` | `ProductBaseDemo.xcodeproj` — a capability catalog, never a product |

## Toolchain

Xcode 26+ · Swift 6 language mode (strict concurrency) · iOS 17 deployment target ·
Google Mobile Ads 12 · UMP 3 · Firebase 12.

## Verifying the Base itself

```bash
xcodebuild test -scheme ProductBase-Package -destination 'platform=iOS Simulator,name=iPhone 17'
(cd Extensions/Ads && xcodebuild test -scheme ProductBaseAds -destination 'platform=iOS Simulator,name=iPhone 17')
xcodebuild build -project Demo/ProductBaseDemo.xcodeproj -scheme ProductBaseDemo -destination 'generic/platform=iOS Simulator'
```

Open `Demo/ProductBaseDemo.xcodeproj` and run it to see every capability on a simulator. CI runs
the same commands — see [CI_CD.md](CI_CD.md).

## Consumer model

**Product Base = reusable infrastructure. Consumer app = product behaviour.** A consumer adds the
packages it needs as *local* package dependencies pointing at a sibling checkout, links the
library products it uses, builds its own composition root (see `Demo/ProductBaseDemo/App/AppContainer.swift`),
and owns everything product-specific — models, screens, navigation, copy, business rules.

## Versioning

Consumers pin a known tag — currently **`v0.1.0-alpha01`** once tagged — and upgrade
deliberately. **Do not consume `main` HEAD in CI.** Full policy: [VERSIONING.md](VERSIONING.md).

## License

[Apache 2.0](LICENSE).
# ios-product-base
