import Foundation
import Observation
import ProductBaseCommon

/// The one non-consumable "Pro / remove ads" product this module sells.
public struct BillingConfig: Sendable, Equatable {
    /// The product identifier from App Store Connect (or your `.storekit` file).
    public var proProductID: String

    public init(proProductID: String) {
        self.proProductID = proProductID
    }
}

/// Whether the user owns Pro. ``unknown`` until the App Store has answered.
public enum PurchaseState: Sendable, Equatable {
    case unknown
    case notPurchased
    /// Ask to Buy, or a payment needing extra action. Not owned yet.
    case pending
    case purchased
}

public enum PurchaseOutcome: Sendable, Equatable {
    case purchased
    case pending
    case alreadyOwned
    /// The user backed out. A decision, not a failure.
    case cancelled
    case failed(BillingError)
}

public enum BillingError: Error, Sendable, Equatable {
    /// In-app purchases are disabled (Screen Time restrictions, a managed device).
    case purchasesNotAllowed
    case networkUnavailable
    /// The product id did not resolve — wrong id, not "Ready to Submit", or wrong storefront.
    case productUnavailable
    /// The App Store returned a transaction whose signature did not verify.
    case verificationFailed
    case unknown(String)
}

/// What the paywall needs to show, already localised by the App Store.
public struct ProProduct: Sendable, Equatable {
    public let productID: String
    public let displayName: String
    public let description: String
    /// Never format or hardcode a price — this one is the App Store's, in the user's currency.
    public let displayPrice: String

    public init(productID: String, displayName: String, description: String, displayPrice: String) {
        self.productID = productID
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
    }
}

/// The product-facing purchase API. No StoreKit type crosses it.
@MainActor
public protocol BillingManager: AnyObject, Observable {
    var purchaseState: PurchaseState { get }
    /// `nil` while loading or when the product is unavailable.
    var proProduct: ProProduct? { get }

    /// Loads the product, reads current ownership and starts listening for transactions that
    /// arrive outside a purchase (Ask to Buy approvals, purchases on another device, refunds).
    /// Call once, at launch.
    func start() async
    /// Re-reads ownership from the device's transaction history. Silent; no sign-in prompt.
    func refreshPurchases() async
    /// The "Restore Purchases" button: syncs with the App Store (may ask the user to sign in),
    /// then re-reads ownership. App Review requires this to exist for non-consumables.
    func restorePurchases() async
    func purchase() async -> PurchaseOutcome
}

extension PurchaseState {
    /// How ads and upsells should treat this state. Pending is not owned.
    public var premiumStatus: PremiumStatus {
        switch self {
        case .unknown: .unknown
        case .purchased: .premium
        case .notPurchased, .pending: .free
        }
    }
}
