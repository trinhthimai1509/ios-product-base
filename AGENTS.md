# Agent instructions

For Claude, ChatGPT, or any other coding agent working in this repository.

## What this repository is

iOS Product Base is **reusable infrastructure**, not a consumer product. It is consumed by
separate product repositories via a pinned Git tag — see [VERSIONING.md](VERSIONING.md). Nothing
here is a shippable end-user app except `Demo/`, which exists only to exercise the modules.

It mirrors [Android Product Base](https://github.com/trinhthimai1509/android-product-base). A
change to a module's responsibility or public surface here should be checked against the Android
counterpart — the two are meant to stay conceptually aligned (see [ARCHITECTURE.md](ARCHITECTURE.md)).

## Before changing code

1. Read [README.md](README.md) and whichever of [ARCHITECTURE.md](ARCHITECTURE.md),
   [MODULE_CATALOG.md](MODULE_CATALOG.md) or [PRODUCT_INTEGRATION.md](PRODUCT_INTEGRATION.md) is
   relevant to the module you're touching.
2. Check [MODULE_CATALOG.md](MODULE_CATALOG.md) for the module's stated responsibility and public
   surface before adding to it.

## Rules

1. **Do not add product-specific business logic.** Domain models, product copy, product screens
   and business rules belong in a consumer app.
2. **Do not modify public APIs casually.** A changed signature breaks every consumer pinned to a
   tag that includes it.
3. **Never add a third-party dependency to the root `Package.swift`.** A module that needs a
   vendor SDK is a new package under `Extensions/`.
4. **Add or update tests for behaviour changes** ([TESTING.md](TESTING.md)). Pure decision logic
   is extracted so it is testable without the SDK — keep it that way.
5. **Swift 6 strict concurrency stays on.** No `@preconcurrency` imports or `nonisolated(unsafe)`
   without a comment saying why it is sound.
6. **Keep documentation synchronized with architecture changes**, in the same change.
7. **Do not commit credentials or machine-local files**: no `GoogleService-Info.plist`, no real ad
   unit ids, no `xcuserdata`, no absolute paths, no `._*` AppleDouble files.
8. **Version/tag changes must be intentional** — see [VERSIONING.md](VERSIONING.md).

## Classify friction, don't patch around it

| Class | Meaning | What to do |
|---|---|---|
| **A** | Product-specific requirement | Build it in the consumer. Not a Base concern. |
| **B** | Missing/wrong documentation | The capability exists but isn't documented correctly. Fix the doc. |
| **C** | Missing broadly reusable capability | Several products would need it. Report it, don't add it unreviewed. |
| **D** | Base API or design defect | The seam exists but is wrong, unusable or unsafe. Report it with the failing usage. |
| **E** | Specialised extension candidate | Real but narrow — a candidate for a new optional package. Report it. |

**A is the common case.**
