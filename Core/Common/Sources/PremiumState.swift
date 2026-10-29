import Observation

/// Whether the user has paid to remove ads — including the honest answer "not known yet".
///
/// This exists for one reason: it lets the Ads extension hide ads for a paying user **without
/// depending on `ProductBaseBilling`**. Without the seam, every ad-supported free app would link
/// StoreKit purchase code it never uses.
///
/// It is not an entitlement framework and must not grow into one. If a product needs tiers,
/// trials or per-feature entitlements, that belongs to the product.
///
/// Implementations are `@Observable`, so SwiftUI views and computed properties that read
/// ``status`` update when it changes.
///
/// Bindings:
/// - app with no purchases: ``AlwaysFreePremiumState`` (``PremiumState/alwaysFree``)
/// - app with a Pro purchase: `StoreKitBillingManager` from `ProductBaseBilling`
@MainActor
public protocol PremiumState: AnyObject, Observable {
    var status: PremiumStatus { get }
}

/// Three states, not a boolean, because "we have not asked the App Store yet" is neither yes nor
/// no.
///
/// A boolean forces that third case to be guessed, and the only safe guess at start-up — false —
/// means a paying user can see an ad flash in the first second of a cold start. Callers must
/// treat ``unknown`` as "do not yet show anything a paying user would not see".
public enum PremiumStatus: Sendable, Equatable {
    /// Ownership has not been established yet. Temporary; suppress paid-tier-visible behaviour.
    case unknown
    /// The user has paid.
    case premium
    /// The user has not paid, and free-tier behaviour — advertising, upsells — is appropriate.
    case free
}

/// For apps that sell nothing. ``PremiumStatus/free`` immediately, because an app with no
/// purchases has no unresolved ownership.
@MainActor
@Observable
public final class AlwaysFreePremiumState: PremiumState {
    public let status: PremiumStatus = .free

    public init() {}
}

extension PremiumState where Self == AlwaysFreePremiumState {
    public static var alwaysFree: AlwaysFreePremiumState { AlwaysFreePremiumState() }
}
