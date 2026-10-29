import GoogleMobileAds
import Observation
import ProductBaseCommon
import UIKit
import UserMessagingPlatform

/// The product-facing advertising API. No Google type crosses it.
///
/// It decides whether ads *may* be shown (consent, premium, configuration, frequency). It never
/// decides whether one *should* — that is the product's call, made at a natural pause.
@MainActor
public protocol AdsController: AnyObject, Observable {
    /// Whether any ad may be requested right now. Observable; `AppBannerAd` reads it.
    var adsAvailable: Bool { get }
    /// Whether the product must offer a "Privacy options" entry (GDPR regions). Observable.
    var privacyOptionsRequired: Bool { get }
    var bannerAdUnitID: String { get }

    /// Gathers consent (showing the UMP form if required), then starts the SDK. Call once, from
    /// the first screen's `.task`. Safe to call again; later calls do nothing.
    func initialize() async
    /// Re-opens the consent form, from the product's "Privacy options" settings row.
    func showPrivacyOptions() async -> ConsentOutcome
    /// Shows an interstitial if the ``InterstitialPolicy`` allows it.
    func showInterstitial() async -> InterstitialOutcome
    func showRewarded() async -> RewardedOutcome
    /// Reports something the user did that counts toward the interstitial policy (finished a
    /// level, saved an entry). The product decides what counts.
    func recordQualifyingAction()
}

/// ``AdsController`` on Google Mobile Ads and the User Messaging Platform.
@MainActor
@Observable
public final class GoogleAdsController: AdsController {
    public private(set) var privacyOptionsRequired = false
    public var bannerAdUnitID: String { config.bannerAdUnitID }

    public var adsAvailable: Bool {
        ProductBaseAds.adsAvailable(
            adsEnabled: config.adsEnabled,
            misconfiguredForRelease: config.misconfiguredForRelease,
            consentAllowsRequests: canRequestAds,
            premiumStatus: premiumState.status
        )
    }

    private var canRequestAds = false

    @ObservationIgnored private let config: AdsConfig
    @ObservationIgnored private let premiumState: any PremiumState
    @ObservationIgnored private let logger: any Logger
    @ObservationIgnored private var governor: InterstitialFrequencyGovernor
    @ObservationIgnored private var initialization: Task<Void, Never>?
    @ObservationIgnored private var presenter: FullScreenPresenter?

    public init(config: AdsConfig, premiumState: any PremiumState, logger: any Logger) {
        self.config = config
        self.premiumState = premiumState
        self.logger = logger
        self.governor = InterstitialFrequencyGovernor(policy: config.interstitialPolicy)
        if config.misconfiguredForRelease {
            logger.error(tag, "Release build configured with test ad units — ads are disabled")
        }
    }

    public func initialize() async {
        if let initialization {
            return await initialization.value
        }
        let task = Task { await performInitialization() }
        initialization = task
        await task.value
    }

    private func performInitialization() async {
        guard config.adsEnabled, !config.misconfiguredForRelease else { return }
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            // Consent may still have been gathered in a previous session; canRequestAds says.
            logger.warning(tag, "Consent gathering failed", error: error)
        }
        refreshConsentState()
        guard canRequestAds else { return }
        await MobileAds.shared.start()
        logger.info(tag, "Mobile Ads started")
    }

    public func showPrivacyOptions() async -> ConsentOutcome {
        guard privacyOptionsRequired else { return .notRequired }
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            refreshConsentState()
            return .completed
        } catch {
            logger.warning(tag, "Privacy options form failed", error: error)
            return .failed(error.localizedDescription)
        }
    }

    public func recordQualifyingAction() {
        governor.recordQualifyingAction()
    }

    public func showInterstitial() async -> InterstitialOutcome {
        guard adsAvailable else { return .notAvailable }
        guard governor.canShow() else { return .throttled }
        do {
            let ad = try await InterstitialAd.load(with: config.interstitialAdUnitID, request: Request())
            let presenter = FullScreenPresenter()
            ad.fullScreenContentDelegate = presenter
            let result = await presenter.present { ad.present(from: nil) }
            switch result {
            case .dismissed:
                governor.recordShown()
                return .shown
            case let .failed(message):
                return .failed(message)
            }
        } catch {
            logger.warning(tag, "Interstitial failed to load", error: error)
            return .failed(error.localizedDescription)
        }
    }

    public func showRewarded() async -> RewardedOutcome {
        guard adsAvailable else { return .notAvailable }
        do {
            let ad = try await RewardedAd.load(with: config.rewardedAdUnitID, request: Request())
            let presenter = FullScreenPresenter()
            ad.fullScreenContentDelegate = presenter
            var earned: RewardedOutcome?
            let result = await presenter.present {
                ad.present(from: nil) {
                    earned = .earned(amount: ad.adReward.amount.intValue, type: ad.adReward.type)
                }
            }
            switch result {
            case .dismissed: return earned ?? .dismissed
            case let .failed(message): return .failed(message)
            }
        } catch {
            logger.warning(tag, "Rewarded ad failed to load", error: error)
            return .failed(error.localizedDescription)
        }
    }

    private func refreshConsentState() {
        canRequestAds = ConsentInformation.shared.canRequestAds
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private let tag = "Ads"
}

/// Turns the full-screen delegate callbacks into one awaitable result.
@MainActor
private final class FullScreenPresenter: NSObject, FullScreenContentDelegate {
    enum Result {
        case dismissed
        case failed(String)
    }

    private var continuation: CheckedContinuation<Result, Never>?

    func present(_ show: () -> Void) async -> Result {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            show()
        }
    }

    nonisolated func ad(
        _ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error
    ) {
        let message = error.localizedDescription
        MainActor.assumeIsolated { finish(.failed(message)) }
    }

    nonisolated func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        MainActor.assumeIsolated { finish(.dismissed) }
    }

    private func finish(_ result: Result) {
        continuation?.resume(returning: result)
        continuation = nil
    }
}
