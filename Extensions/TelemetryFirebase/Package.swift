// swift-tools-version: 6.0

import PackageDescription

// The only package in this repository that may see a Firebase type. Binds the
// `ProductBaseTelemetry` contracts to Firebase Analytics and Crashlytics.
// A separate package so that apps without Firebase never resolve it.

let package = Package(
    name: "ProductBaseTelemetryFirebase",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ProductBaseTelemetryFirebase", targets: ["ProductBaseTelemetryFirebase"]),
    ],
    dependencies: [
        .package(name: "ProductBase", path: "../.."),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "12.0.0"),
    ],
    targets: [
        .target(
            name: "ProductBaseTelemetryFirebase",
            dependencies: [
                .product(name: "ProductBaseCommon", package: "ProductBase"),
                .product(name: "ProductBaseTelemetry", package: "ProductBase"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
            ],
            path: "Sources",
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
