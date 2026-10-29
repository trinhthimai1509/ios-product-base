import Observation
import ProductBaseBilling

/// The marketing copy. The product writes all of it; the price comes from the App Store.
public struct PremiumContent: Sendable {
    public var title: String
    public var subtitle: String
    public var benefits: [String]
    public var footnote: String?

    public init(title: String, subtitle: String, benefits: [String], footnote: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.benefits = benefits
        self.footnote = footnote
    }
}

/// The few things worth telling the user after a purchase or restore attempt.
public enum PremiumMessage: Sendable, Equatable {
    case purchaseCompleted
    case purchasePending
    case alreadyOwned
    case nothingToRestore
    /// The App Store could not be reached, so ownership is still unknown.
    ///
    /// Distinct from ``nothingToRestore`` on purpose: telling a paying customer that no purchase
    /// was found, when the truth is that nobody asked, is the worst message this screen can show.
    case couldNotCheck
    case failed(BillingError)
}

/// Paywall state and actions. All decisions are in ``PremiumMessages``; this is plumbing.
@MainActor
@Observable
public final class PremiumViewModel {
    public var purchaseState: PurchaseState { billing.purchaseState }
    public var product: ProProduct? { billing.proProduct }
    public private(set) var isWorking = false
    public private(set) var message: PremiumMessage?

    @ObservationIgnored private let billing: any BillingManager

    public init(billingManager: any BillingManager) {
        self.billing = billingManager
    }

    public func purchase() async {
        guard !isWorking else { return }
        isWorking = true
        message = nil
        message = PremiumMessages.message(for: await billing.purchase())
        isWorking = false
    }

    /// Syncs with the App Store and reports what it found.
    public func restore() async {
        guard !isWorking else { return }
        isWorking = true
        message = nil
        await billing.restorePurchases()
        message = PremiumMessages.restoreMessage(for: billing.purchaseState)
        isWorking = false
    }

    public func dismissMessage() {
        message = nil
    }
}

/// What to tell the user after an action, as pure functions.
enum PremiumMessages {
    static func message(for outcome: PurchaseOutcome) -> PremiumMessage? {
        switch outcome {
        case .purchased: .purchaseCompleted
        case .pending: .purchasePending
        case .alreadyOwned: .alreadyOwned
        // Backing out is a decision, not a failure: no dialog.
        case .cancelled: nil
        case let .failed(error): .failed(error)
        }
    }

    static func restoreMessage(for state: PurchaseState) -> PremiumMessage {
        switch state {
        case .purchased: .purchaseCompleted
        case .pending: .purchasePending
        case .notPurchased: .nothingToRestore
        // "We could not ask" is not "you own nothing".
        case .unknown: .couldNotCheck
        }
    }
}
