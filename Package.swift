// swift-tools-version: 6.0

import PackageDescription

// iOS Product Base — the dependency-free modules.
//
// Every library below is its own product, so a consumer links only what it names. Modules that
// pull a third-party SDK (Google Mobile Ads, Firebase) are deliberately NOT here: they live in
// their own packages under `Extensions/`, so resolving this package never downloads them.
// See MODULE_CATALOG.md.

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
]

let package = Package(
    name: "ProductBase",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "ProductBaseCommon", targets: ["ProductBaseCommon"]),
        .library(name: "ProductBaseDesignSystem", targets: ["ProductBaseDesignSystem"]),
        .library(name: "ProductBasePreferences", targets: ["ProductBasePreferences"]),
        .library(name: "ProductBaseDatabase", targets: ["ProductBaseDatabase"]),
        .library(name: "ProductBaseNetwork", targets: ["ProductBaseNetwork"]),
        .library(name: "ProductBaseTelemetry", targets: ["ProductBaseTelemetry"]),
        .library(name: "ProductBaseBilling", targets: ["ProductBaseBilling"]),
        .library(name: "ProductBaseReview", targets: ["ProductBaseReview"]),
        .library(name: "ProductBaseNotification", targets: ["ProductBaseNotification"]),
        .library(name: "ProductBaseTesting", targets: ["ProductBaseTesting"]),
        .library(name: "ProductBaseOnboarding", targets: ["ProductBaseOnboarding"]),
        .library(name: "ProductBaseSettings", targets: ["ProductBaseSettings"]),
        .library(name: "ProductBasePremium", targets: ["ProductBasePremium"]),
    ],
    targets: [
        // MARK: Core

        .target(
            name: "ProductBaseCommon",
            path: "Core/Common/Sources",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProductBaseCommonTests",
            dependencies: ["ProductBaseCommon"],
            path: "Core/Common/Tests",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ProductBaseDesignSystem",
            dependencies: ["ProductBaseCommon"],
            path: "Core/DesignSystem/Sources",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ProductBasePreferences",
            dependencies: ["ProductBaseCommon"],
            path: "Core/Preferences/Sources",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProductBasePreferencesTests",
            dependencies: ["ProductBasePreferences", "ProductBaseTesting"],
            path: "Core/Preferences/Tests",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ProductBaseDatabase",
            dependencies: ["ProductBaseCommon"],
            path: "Core/Database/Sources",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProductBaseDatabaseTests",
            dependencies: ["ProductBaseDatabase"],
            path: "Core/Database/Tests",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ProductBaseNetwork",
            dependencies: ["ProductBaseCommon"],
            path: "Core/Network/Sources",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProductBaseNetworkTests",
            dependencies: ["ProductBaseNetwork", "ProductBaseTesting"],
            path: "Core/Network/Tests",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ProductBaseTelemetry",
            path: "Core/Telemetry/Sources",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProductBaseTelemetryTests",
            dependencies: ["ProductBaseTelemetry"],
            path: "Core/Telemetry/Tests",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ProductBaseBilling",
            dependencies: ["ProductBaseCommon"],
            path: "Core/Billing/Sources",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProductBaseBillingTests",
            dependencies: ["ProductBaseBilling"],
            path: "Core/Billing/Tests",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ProductBaseReview",
            dependencies: ["ProductBaseCommon"],
            path: "Core/Review/Sources",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ProductBaseNotification",
            dependencies: ["ProductBaseCommon"],
            path: "Core/Notification/Sources",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProductBaseNotificationTests",
            dependencies: ["ProductBaseNotification"],
            path: "Core/Notification/Tests",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ProductBaseTesting",
            dependencies: ["ProductBaseCommon", "ProductBasePreferences"],
            path: "Core/Testing/Sources",
            swiftSettings: swiftSettings
        ),

        // MARK: Feature

        .target(
            name: "ProductBaseOnboarding",
            dependencies: ["ProductBaseDesignSystem", "ProductBasePreferences"],
            path: "Feature/Onboarding/Sources",
            resources: [.process("Resources")],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProductBaseOnboardingTests",
            dependencies: ["ProductBaseOnboarding", "ProductBaseTesting"],
            path: "Feature/Onboarding/Tests",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ProductBaseSettings",
            dependencies: ["ProductBaseDesignSystem"],
            path: "Feature/Settings/Sources",
            resources: [.process("Resources")],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProductBaseSettingsTests",
            dependencies: ["ProductBaseSettings"],
            path: "Feature/Settings/Tests",
            swiftSettings: swiftSettings
        ),

        .target(
            name: "ProductBasePremium",
            dependencies: ["ProductBaseDesignSystem", "ProductBaseBilling"],
            path: "Feature/Premium/Sources",
            resources: [.process("Resources")],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "ProductBasePremiumTests",
            dependencies: ["ProductBasePremium"],
            path: "Feature/Premium/Tests",
            swiftSettings: swiftSettings
        ),
    ],
    swiftLanguageModes: [.v6]
)
