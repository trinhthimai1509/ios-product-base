import ProductBaseCommon
import Testing

@MainActor
struct PremiumStateTests {
    @Test func alwaysFreeIsFreeImmediately() {
        let state: any PremiumState = .alwaysFree
        #expect(state.status == .free)
    }

    @Test func themeModeRoundTripsThroughRawValue() {
        for mode in ThemeMode.allCases {
            #expect(ThemeMode(rawValue: mode.rawValue) == mode)
        }
    }
}
