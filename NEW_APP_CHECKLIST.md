# New app checklist

## Project

- [ ] Workspace laid out as siblings; Base checked out at a **tag** ([QUICK_START.md](QUICK_START.md))
- [ ] App target: iOS 17+, Swift 6 language mode
- [ ] Base packages added as **local** references with relative paths; only needed products linked
- [ ] `.gitignore` covers `xcuserdata/`, `GoogleService-Info.plist`, `*.xcconfig` with secrets, `._*`

## Foundation

- [ ] `AppContainer` composition root with one `Logger` (`OSLogLogger` debug / `NoOpLogger` release)
- [ ] `.productBaseTheme(.yourBrand, themeMode:)` at the root ([THEMING.md](THEMING.md))
- [ ] App icon, accent colour, display name
- [ ] Onboarding pages written; navigation on `isCompleted`
- [ ] Settings rows: appearance, about/version, privacy policy link, support contact

## Capabilities (as needed)

- [ ] Database: `@Model`s, `VersionedSchema` from the first release, `SchemaMigrationPlan` on change
- [ ] Network: `NetworkConfig` with base URL; user-facing messages for every `NetworkError`
- [ ] Telemetry: Firebase plist (not committed), Crashlytics dSYM upload phase
- [ ] Notifications: permission asked at a meaningful moment; deep links handled
- [ ] Ads: real ids per configuration, `GADApplicationIdentifier`, `SKAdNetworkItems`, privacy options row
- [ ] Billing: non-consumable created, `.storekit` file for local testing, Restore reachable
- [ ] Review: requested only after a success moment

## Release

- [ ] Privacy manifest (`PrivacyInfo.xcprivacy`) for the app's own data use; App Privacy answers
      in App Store Connect cover the ad and analytics SDKs
- [ ] Release build checked: no test ad ids, logging off, Firebase configured
- [ ] Localisations complete for every shipped language
- [ ] Tested on the oldest supported iOS and on a small screen with large Dynamic Type
