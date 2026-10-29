import ProductBaseCommon
import StoreKit
import UIKit

/// The App Store rating prompt, as one call.
///
/// There is no counter, no engagement score and no automatic prompt — deliberately. The product
/// decides *when* (after a moment of success, never on launch, never mid-task).
@MainActor
public protocol AppReviewManager {
    func requestReview() -> ReviewOutcome
}

/// What happened. ``requested`` means the request was handed to the system — **not** that a
/// prompt appeared: iOS shows it at most three times a year and never says whether it did. Do not
/// thank, reward or re-prompt based on it.
public enum ReviewOutcome: Sendable, Equatable {
    case requested
    /// No foreground window scene to show it in (the app is backgrounding, for instance).
    case unavailable
}

/// ``AppReviewManager`` on `AppStore.requestReview(in:)`.
///
/// In a SwiftUI view, `@Environment(\.requestReview)` does the same job; this type exists for
/// call sites that are not views (a view model, a coordinator) and for faking in tests.
@MainActor
public final class StoreKitReviewManager: AppReviewManager {
    private let logger: any Logger

    public init(logger: any Logger) {
        self.logger = logger
    }

    public func requestReview() -> ReviewOutcome {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        guard let scene else {
            logger.info("Review", "No foreground scene; review not requested")
            return .unavailable
        }
        AppStore.requestReview(in: scene)
        return .requested
    }
}
