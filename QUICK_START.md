# Quick start

The shortest path from nothing to a running iOS app built on this Base.

## The one rule that is not negotiable

**A consumer product must not modify Product Base source code.** Everything a product needs to
differ is a parameter, an initialiser argument, a closure, or a module it chooses not to link. If
you cannot find the seam, you have found a documentation gap or a Base defect — report it
([classification](PRODUCT_INTEGRATION.md#consumer-rules)), don't patch it locally.

## 0. Prerequisites

| Requirement | Value |
|---|---|
| Xcode | 26 or later (Swift 6 toolchain) |
| Deployment target | iOS 17.0 or later |

## 1. Lay out the workspace

```
workspace/
├── ios-product-base/      ← this repository, checked out at a tag, read-only
└── consumer-app/          ← your product
```

```bash
git clone --branch v0.1.0-alpha01 https://github.com/trinhthimai1509/ios-product-base.git
```

## 2. Create the app

In Xcode: *File ▸ New ▸ Project ▸ iOS App*, SwiftUI, Swift, save it in `consumer-app/`. Set the
deployment target to iOS 17 and **Swift Language Version to 6**.

## 3. Add the Base packages

*File ▸ Add Package Dependencies… ▸ Add Local…* and pick `../ios-product-base`. Then tick the
library products you need for the app target — only those. Repeat with
`../ios-product-base/Extensions/Ads` and/or `../ios-product-base/Extensions/TelemetryFirebase`
if you use them.

Xcode stores these as *relative* paths in the project (`XCLocalSwiftPackageReference`,
`relativePath = "../ios-product-base"`), so the project works on any machine and in CI with the
same sibling layout. Never commit an absolute path.

> **Why not a remote URL + tag?** SPM can only fetch the root package from a URL — it cannot
> reach the packages under `Extensions/`. A sibling checkout pinned to a tag works for all three
> and matches how the Android Base is consumed. A product that uses only root-package modules
> *may* depend on the URL with `exact: "0.1.0-alpha01"` instead.

## 4. The composition root

One file builds every capability once. Copy the shape of
[`Demo/ProductBaseDemo/App/AppContainer.swift`](Demo/ProductBaseDemo/App/AppContainer.swift):

```swift
import ProductBaseCommon
import ProductBasePreferences

@MainActor
final class AppContainer {
    let logger: any Logger
    let preferences = UserDefaultsAppPreferences()

    init() {
        #if DEBUG
        logger = OSLogLogger(subsystem: "com.example.tracker")
        #else
        logger = NoOpLogger()
        #endif
    }
}
```

## 5. The app

```swift
import ProductBaseDesignSystem
import ProductBaseOnboarding
import SwiftUI

@main
struct TrackerApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .productBaseTheme(.tracker, themeMode: container.preferences.themeMode)
        }
    }
}

struct RootView: View {
    let container: AppContainer
    @State private var onboarding: OnboardingViewModel

    init(container: AppContainer) {
        self.container = container
        _onboarding = State(initialValue: OnboardingViewModel(preferences: container.preferences))
    }

    var body: some View {
        if onboarding.isCompleted {
            NavigationStack { HomeView() }
        } else {
            OnboardingScreen(pages: TrackerOnboarding.pages, viewModel: onboarding)
        }
    }
}
```

`ProductBaseTheme.tracker` is your brand — see [THEMING.md](THEMING.md).

## 6. Run

⌘R. Then work through [NEW_APP_CHECKLIST.md](NEW_APP_CHECKLIST.md).
