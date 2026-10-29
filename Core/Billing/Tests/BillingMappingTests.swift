import Foundation
import StoreKit
import Testing

@testable import ProductBaseBilling

struct BillingMappingTests {
    @Test func pendingIsNotPremium() {
        #expect(PurchaseState.unknown.premiumStatus == .unknown)
        #expect(PurchaseState.pending.premiumStatus == .free)
        #expect(PurchaseState.notPurchased.premiumStatus == .free)
        #expect(PurchaseState.purchased.premiumStatus == .premium)
    }

    @Test func userCancelIsNotAFailure() {
        #expect(BillingErrorMapping.outcome(for: StoreKitError.userCancelled) == .cancelled)
    }

    @Test func networkErrorsMapToNetworkUnavailable() {
        #expect(
            BillingErrorMapping.billingError(for: StoreKitError.networkError(URLError(.notConnectedToInternet)))
                == .networkUnavailable
        )
        #expect(BillingErrorMapping.billingError(for: URLError(.timedOut)) == .networkUnavailable)
    }

    @Test func purchaseNotAllowedIsReported() {
        #expect(
            BillingErrorMapping.billingError(for: Product.PurchaseError.purchaseNotAllowed)
                == .purchasesNotAllowed
        )
    }
}
