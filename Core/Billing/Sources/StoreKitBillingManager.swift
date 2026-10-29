import Foundation
import Observation
import ProductBaseCommon
import StoreKit

/// ``BillingManager`` on StoreKit 2, which is also the app's ``PremiumState``.
///
/// The App Store is the only source of ownership: nothing is cached, and there is no receipt
/// validation server. A product that needs server-side entitlement checks builds that itself.
@MainActor
@Observable
public final class StoreKitBillingManager: BillingManager, PremiumState {
    public private(set) var purchaseState: PurchaseState = .unknown
    public private(set) var proProduct: ProProduct?

    public var status: PremiumStatus { purchaseState.premiumStatus }

    @ObservationIgnored private let config: BillingConfig
    @ObservationIgnored private let logger: any Logger
    @ObservationIgnored private var product: Product?
    // Only written on the main actor; read in deinit, after which nothing else can touch it.
    @ObservationIgnored nonisolated(unsafe) private var updatesTask: Task<Void, Never>?

    public init(config: BillingConfig, logger: any Logger) {
        self.config = config
        self.logger = logger
    }

    deinit {
        updatesTask?.cancel()
    }

    public func start() async {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        await loadProduct()
        await refreshPurchases()
    }

    public func refreshPurchases() async {
        var found: PurchaseState = .notPurchased
        for await entitlement in Transaction.currentEntitlements {
            guard case let .verified(transaction) = entitlement,
                transaction.productID == config.proProductID
            else { continue }
            found = transaction.revocationDate == nil ? .purchased : .notPurchased
        }
        // Keep "pending" from an Ask to Buy request until the App Store resolves it.
        if !(found == .notPurchased && purchaseState == .pending) {
            purchaseState = found
        }
    }

    public func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            logger.warning(tag, "AppStore.sync failed", error: error)
        }
        await refreshPurchases()
    }

    public func purchase() async -> PurchaseOutcome {
        if purchaseState == .purchased { return .alreadyOwned }
        if product == nil { await loadProduct() }
        guard let product else { return .failed(.productUnavailable) }

        do {
            switch try await product.purchase() {
            case let .success(verification):
                guard case let .verified(transaction) = verification else {
                    return .failed(.verificationFailed)
                }
                await transaction.finish()
                purchaseState = .purchased
                return .purchased
            case .pending:
                purchaseState = .pending
                return .pending
            case .userCancelled:
                return .cancelled
            @unknown default:
                return .failed(.unknown("Unrecognised purchase result"))
            }
        } catch {
            logger.warning(tag, "Purchase failed", error: error)
            return BillingErrorMapping.outcome(for: error)
        }
    }

    private func loadProduct() async {
        do {
            product = try await Product.products(for: [config.proProductID]).first
            proProduct = product.map {
                ProProduct(
                    productID: $0.id, displayName: $0.displayName,
                    description: $0.description, displayPrice: $0.displayPrice
                )
            }
            if product == nil {
                logger.warning(tag, "Product \(config.proProductID) not found")
            }
        } catch {
            logger.warning(tag, "Could not load products", error: error)
        }
    }

    private func handle(_ update: VerificationResult<Transaction>) async {
        guard case let .verified(transaction) = update else {
            logger.warning(tag, "Ignoring unverified transaction update")
            return
        }
        if transaction.productID == config.proProductID {
            purchaseState = transaction.revocationDate == nil ? .purchased : .notPurchased
        }
        await transaction.finish()
    }

    private let tag = "Billing"
}

/// Maps StoreKit's errors to ``BillingError`` — pure, so it is testable without the App Store.
enum BillingErrorMapping {
    static func outcome(for error: any Error) -> PurchaseOutcome {
        if let storeKitError = error as? StoreKitError, case .userCancelled = storeKitError {
            return .cancelled
        }
        return .failed(billingError(for: error))
    }

    static func billingError(for error: any Error) -> BillingError {
        if let storeKitError = error as? StoreKitError {
            switch storeKitError {
            case .networkError: return .networkUnavailable
            case .notAvailableInStorefront: return .productUnavailable
            case .notEntitled: return .purchasesNotAllowed
            case .unsupported: return .purchasesNotAllowed
            default: return .unknown(String(describing: storeKitError))
            }
        }
        if let purchaseError = error as? Product.PurchaseError {
            switch purchaseError {
            case .purchaseNotAllowed: return .purchasesNotAllowed
            case .productUnavailable: return .productUnavailable
            default: return .unknown(String(describing: purchaseError))
            }
        }
        if error is URLError { return .networkUnavailable }
        return .unknown(String(describing: error))
    }
}
