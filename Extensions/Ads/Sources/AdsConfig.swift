import Foundation

/// Google's official iOS test ad units.
///
/// Public, documented values, not secrets. They exist so a debug build never requests a real ad
/// — an AdMob policy requirement, and the only way to develop without poisoning a real account.
public enum TestAdUnits {
    /// Goes in the app's Info.plist as `GADApplicationIdentifier` for debug builds.
    public static let applicationID = "ca-app-pub-3940256099942544~1458002511"
    public static let banner = "ca-app-pub-3940256099942544/2435281174"
    public static let interstitial = "ca-app-pub-3940256099942544/4411468910"
    public static let rewarded = "ca-app-pub-3940256099942544/1712485313"

    static let all: Set<String> = [applicationID, banner, interstitial, rewarded]
}

/// How often an interstitial may be shown. Both conditions must hold, and the defaults are
/// deliberately quiet: an interstitial that appears too often costs more in uninstalls and
/// one-star reviews than it earns.
///
/// This is the whole of the ad policy. There is no remote configuration and no session model —
/// a product that needs different numbers passes different numbers.
public struct InterstitialPolicy: Sendable, Equatable {
    public var minInterval: Duration
    public var minQualifyingActions: Int

    public init(minInterval: Duration = .seconds(180), minQualifyingActions: Int = 3) {
        self.minInterval = minInterval
        self.minQualifyingActions = minQualifyingActions
    }
}

/// The product's advertising configuration.
///
/// Ad unit ids are product-specific and never defaulted to anything real: the Base ships only
/// ``TestAdUnits``; production values come from the product's build configuration.
public struct AdsConfig: Sendable, Equatable {
    public var bannerAdUnitID: String
    public var interstitialAdUnitID: String
    public var rewardedAdUnitID: String
    /// A product-level switch, independent of premium and consent.
    public var adsEnabled: Bool
    public var interstitialPolicy: InterstitialPolicy
    /// `true` in release builds. A release build configured with test ad units disables ads
    /// instead of shipping them — pass `!isDebug` from the app (`#if DEBUG`).
    public var isReleaseBuild: Bool

    public init(
        bannerAdUnitID: String,
        interstitialAdUnitID: String,
        rewardedAdUnitID: String,
        adsEnabled: Bool = true,
        interstitialPolicy: InterstitialPolicy = InterstitialPolicy(),
        isReleaseBuild: Bool
    ) {
        self.bannerAdUnitID = bannerAdUnitID
        self.interstitialAdUnitID = interstitialAdUnitID
        self.rewardedAdUnitID = rewardedAdUnitID
        self.adsEnabled = adsEnabled
        self.interstitialPolicy = interstitialPolicy
        self.isReleaseBuild = isReleaseBuild
    }

    /// Every unit set to Google's test ids. For debug builds and the demo.
    public static func testAds(
        adsEnabled: Bool = true,
        interstitialPolicy: InterstitialPolicy = InterstitialPolicy()
    ) -> AdsConfig {
        AdsConfig(
            bannerAdUnitID: TestAdUnits.banner,
            interstitialAdUnitID: TestAdUnits.interstitial,
            rewardedAdUnitID: TestAdUnits.rewarded,
            adsEnabled: adsEnabled,
            interstitialPolicy: interstitialPolicy,
            isReleaseBuild: false
        )
    }

    var usesTestAdUnits: Bool {
        [bannerAdUnitID, interstitialAdUnitID, rewardedAdUnitID].contains(where: TestAdUnits.all.contains)
    }

    var misconfiguredForRelease: Bool { isReleaseBuild && usesTestAdUnits }
}

public enum InterstitialOutcome: Sendable, Equatable {
    case shown
    /// Ads are unavailable right now (premium, no consent, disabled, still loading).
    case notAvailable
    /// The ``InterstitialPolicy`` said not yet.
    case throttled
    case failed(String)
}

public enum RewardedOutcome: Sendable, Equatable {
    case earned(amount: Int, type: String)
    /// The user closed the ad before earning the reward.
    case dismissed
    case notAvailable
    case failed(String)
}

public enum ConsentOutcome: Sendable, Equatable {
    case completed
    case notRequired
    case failed(String)
}
