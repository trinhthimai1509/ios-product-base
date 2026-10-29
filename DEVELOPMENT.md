# Development

Working on the Base itself — not on a product built with it (for that, see
[QUICK_START.md](QUICK_START.md)).

## Environment

| | |
|---|---|
| Xcode | 26 or later |
| Swift | 6 language mode, strict concurrency |
| Deployment target | iOS 17.0 |

There are no other tools to install. Versions of the Google and Firebase SDKs are set by the
`from:` requirements in each extension's `Package.swift`; `Package.resolved` files are not
committed for these library packages, so consumers resolve them within those ranges.

## Repository structure

```
Package.swift            root package: Core/* and Feature/* modules, no third-party deps
Core/<Module>/           Sources/ and Tests/
Feature/<Module>/        Sources/ (with Resources/Localizable.xcstrings) and Tests/
Extensions/Ads/          separate package: Google Mobile Ads + UMP
Extensions/TelemetryFirebase/  separate package: Firebase
Demo/                    ProductBaseDemo.xcodeproj — capability catalog
```

## Verification

```bash
xcodebuild test -scheme ProductBase-Package -destination 'platform=iOS Simulator,name=iPhone 17'
(cd Extensions/Ads && xcodebuild test -scheme ProductBaseAds -destination 'platform=iOS Simulator,name=iPhone 17')
(cd Extensions/TelemetryFirebase && xcodebuild build -scheme ProductBaseTelemetryFirebase -destination 'generic/platform=iOS Simulator')
xcodebuild build -project Demo/ProductBaseDemo.xcodeproj -scheme ProductBaseDemo -destination 'generic/platform=iOS Simulator'
```

Then run the demo and walk every screen.

## Adding a module

1. Decide which package: no third-party dependency → root; otherwise a new `Extensions/<Name>`.
2. Add `Core|Feature/<Name>/Sources` (+ `Tests`), the target and library product.
3. Document it in [MODULE_CATALOG.md](MODULE_CATALOG.md) and the mapping in [ARCHITECTURE.md](ARCHITECTURE.md).
4. Exercise it in the demo.

## Rules before committing

- Zero warnings in Base sources. Strict concurrency findings are fixed, not suppressed.
- No product behaviour, credentials, `xcuserdata`, or absolute paths.
- **External drives (exFAT):** macOS writes `._*` AppleDouble files. They are git-ignored; run
  `dot_clean .` if any show up in `git status`.

## Rules before tagging

See [VERSIONING.md](VERSIONING.md). Run the full verification first; annotated tags only.
