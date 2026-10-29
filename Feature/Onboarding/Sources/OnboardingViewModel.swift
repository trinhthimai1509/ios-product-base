import Observation
import ProductBasePreferences

/// Onboarding progression and its one piece of persistent state.
///
/// The mechanism is here; the content is not. This class never sees a page, a title or an
/// image — it counts, and it remembers that the user got to the end.
@MainActor
@Observable
public final class OnboardingViewModel {
    public private(set) var pageIndex = 0

    /// Read back from preferences rather than set optimistically, so a product that navigates
    /// on it navigates only once the flag is actually persisted.
    public var isCompleted: Bool { preferences.onboardingCompleted }

    @ObservationIgnored private let preferences: any AppPreferences

    public init(preferences: any AppPreferences) {
        self.preferences = preferences
    }

    /// Advances one page, or completes onboarding if this was the last one.
    ///
    /// - Parameter pageCount: how many pages the product supplied. A parameter rather than state
    ///   because that is what keeps this class content-free.
    public func next(pageCount: Int) {
        if pageIndex >= pageCount - 1 {
            complete()
        } else {
            pageIndex += 1
        }
    }

    /// Reports a swipe. The pager owns the gesture; this keeps the observable state in step.
    public func goToPage(_ index: Int) {
        pageIndex = max(0, index)
    }

    /// The user asked to get past this. Identical to ``finish()`` as far as storage is concerned
    /// — a skipped onboarding is a completed one. A separate call so call sites read correctly
    /// and a product can log the two differently.
    public func skip() { complete() }

    /// The user reached the end.
    public func finish() { complete() }

    private func complete() {
        preferences.setOnboardingCompleted(true)
    }
}
