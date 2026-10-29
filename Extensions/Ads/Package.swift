// swift-tools-version: 6.0

import PackageDescription

// Google Mobile Ads + User Messaging Platform consent, behind a product-facing API.
// A separate package so that apps without ads never resolve the Google SDKs. See MONETIZATION.md.

let package = Package(
    name: "ProductBaseAds",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ProductBaseAds", targets: ["ProductBaseAds"]),
    ],
    dependencies: [
        .package(name: "ProductBase", path: "../.."),
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            from: "12.0.0"
        ),
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git",
            from: "3.0.0"
        ),
    ],
    targets: [
        .target(
            name: "ProductBaseAds",
            dependencies: [
                .product(name: "ProductBaseCommon", package: "ProductBase"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                .product(
                    name: "GoogleUserMessagingPlatform",
                    package: "swift-package-manager-google-user-messaging-platform"
                ),
            ],
            path: "Sources",
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
        .testTarget(
            name: "ProductBaseAdsTests",
            dependencies: ["ProductBaseAds"],
            path: "Tests",
            swiftSettings: [.enableUpcomingFeature("ExistentialAny")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
