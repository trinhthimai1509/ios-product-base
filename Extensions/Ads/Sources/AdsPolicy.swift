import Foundation
import ProductBaseCommon

/// Whether an ad may be shown, as a pure function of the four things that decide it.
///
/// Every condition is a veto. ``PremiumStatus/unknown`` is a veto too, and that is the point:
/// during a cold start ownership is unknown until the App Store answers, and showing an ad in
/// that window means a user who paid to remove ads sees one every time they open the app.
func adsAvailable(
    adsEnabled: Bool,
    misconfiguredForRelease: Bool,
    consentAllowsRequests: Bool,
    premiumStatus: PremiumStatus
) -> Bool {
    adsEnabled && !misconfiguredForRelease && consentAllowsRequests && premiumStatus == .free
}

/// Decides whether an interstitial may be shown now.
///
/// Both conditions must hold, including for the very first interstitial of a session: a user who
/// has just opened the app has not done enough for an ad to be reasonable.
struct InterstitialFrequencyGovernor {
    private let policy: InterstitialPolicy
    private let now: () -> ContinuousClock.Instant
    private var lastShownAt: ContinuousClock.Instant?
    private var qualifyingActions = 0

    init(policy: InterstitialPolicy, now: @escaping () -> ContinuousClock.Instant = { .now }) {
        self.policy = policy
        self.now = now
    }

    mutating func recordQualifyingAction() {
        qualifyingActions += 1
    }

    func canShow() -> Bool {
        guard qualifyingActions >= policy.minQualifyingActions else { return false }
        guard let lastShownAt else { return true }
        return lastShownAt.duration(to: now()) >= policy.minInterval
    }

    /// Records that one was shown, which resets both conditions. Called only once the ad is on
    /// screen — counting a failed request would let a run of no-fills silence advertising.
    mutating func recordShown() {
        lastShownAt = now()
        qualifyingActions = 0
    }
}
