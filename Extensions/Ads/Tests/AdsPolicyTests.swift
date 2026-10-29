import ProductBaseCommon
import Testing

@testable import ProductBaseAds

struct AdsAvailabilityTests {
    @Test func freeUserWithConsentSeesAds() {
        #expect(adsAvailable(adsEnabled: true, misconfiguredForRelease: false, consentAllowsRequests: true, premiumStatus: .free))
    }

    @Test(arguments: [PremiumStatus.unknown, .premium])
    func unknownOrPremiumVetoes(status: PremiumStatus) {
        #expect(!adsAvailable(adsEnabled: true, misconfiguredForRelease: false, consentAllowsRequests: true, premiumStatus: status))
    }

    @Test func everyOtherConditionVetoes() {
        #expect(!adsAvailable(adsEnabled: false, misconfiguredForRelease: false, consentAllowsRequests: true, premiumStatus: .free))
        #expect(!adsAvailable(adsEnabled: true, misconfiguredForRelease: true, consentAllowsRequests: true, premiumStatus: .free))
        #expect(!adsAvailable(adsEnabled: true, misconfiguredForRelease: false, consentAllowsRequests: false, premiumStatus: .free))
    }

    @Test func releaseWithTestUnitsIsMisconfigured() {
        var config = AdsConfig.testAds()
        #expect(!config.misconfiguredForRelease)
        config.isReleaseBuild = true
        #expect(config.misconfiguredForRelease)
    }
}

struct InterstitialFrequencyGovernorTests {
    final class Clock: @unchecked Sendable {
        var now = ContinuousClock.now
    }

    @Test func needsQualifyingActionsEvenForTheFirstAd() {
        let clock = Clock()
        var governor = InterstitialFrequencyGovernor(
            policy: InterstitialPolicy(minInterval: .seconds(60), minQualifyingActions: 2), now: { clock.now }
        )

        #expect(!governor.canShow())
        governor.recordQualifyingAction()
        #expect(!governor.canShow())
        governor.recordQualifyingAction()
        #expect(governor.canShow())
    }

    @Test func showingResetsBothConditions() {
        let clock = Clock()
        var governor = InterstitialFrequencyGovernor(
            policy: InterstitialPolicy(minInterval: .seconds(60), minQualifyingActions: 1), now: { clock.now }
        )
        governor.recordQualifyingAction()
        governor.recordShown()

        governor.recordQualifyingAction()
        clock.now = clock.now.advanced(by: .seconds(59))
        #expect(!governor.canShow())

        clock.now = clock.now.advanced(by: .seconds(1))
        #expect(governor.canShow())
    }
}
