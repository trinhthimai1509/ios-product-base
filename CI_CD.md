# CI/CD

## This repository's own CI

`.github/workflows/ci.yml` runs on every pull request and push to `main`, on a macOS runner:

1. Root package tests on an iOS simulator
2. Ads extension tests
3. Firebase extension build
4. Demo app build (simulator, no signing)

No release, signing or publishing exists for this repository — consumers take it as source.

## How a consumer's CI obtains it

The repository is public; no token is needed. Check it out as a sibling of the consumer so the
relative package paths resolve:

```yaml
- uses: actions/checkout@v4
  with:
    path: consumer-app

- name: Checkout iOS Product Base
  uses: actions/checkout@v4
  with:
    repository: trinhthimai1509/ios-product-base
    ref: v0.1.0-alpha01          # pinned tag, never main
    path: ios-product-base

- name: Build
  working-directory: consumer-app
  run: xcodebuild build -scheme MyApp -destination 'generic/platform=iOS Simulator'
```

Because Xcode stores local packages as `relativePath = "../ios-product-base"`, this layout is
all the configuration a consumer needs.
