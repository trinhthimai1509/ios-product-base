import ProductBaseOnboarding
import ProductBaseTesting
import Testing

@MainActor
struct OnboardingViewModelTests {
    @Test func nextAdvancesUntilTheLastPageThenCompletes() {
        let prefs = FakeAppPreferences()
        let viewModel = OnboardingViewModel(preferences: prefs)

        viewModel.next(pageCount: 3)
        viewModel.next(pageCount: 3)
        #expect(viewModel.pageIndex == 2)
        #expect(!viewModel.isCompleted)

        viewModel.next(pageCount: 3)
        #expect(viewModel.isCompleted)
        #expect(prefs.onboardingCompleted)
    }

    @Test func skipCompletesFromAnyPage() {
        let prefs = FakeAppPreferences()
        let viewModel = OnboardingViewModel(preferences: prefs)

        viewModel.skip()

        #expect(viewModel.isCompleted)
        #expect(viewModel.pageIndex == 0)
    }

    @Test func goToPageNeverGoesNegative() {
        let viewModel = OnboardingViewModel(preferences: FakeAppPreferences())

        viewModel.goToPage(-4)

        #expect(viewModel.pageIndex == 0)
    }

    @Test func completionIsReadBackFromStorage() {
        let viewModel = OnboardingViewModel(preferences: FakeAppPreferences(onboardingCompleted: true))
        #expect(viewModel.isCompleted)
    }
}
