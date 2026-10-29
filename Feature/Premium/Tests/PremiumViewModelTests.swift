import Observation
import ProductBaseBilling
import Testing

@testable import ProductBasePremium

@MainActor
@Observable
final class FakeBillingManager: BillingManager {
    var purchaseState: PurchaseState = .notPurchased
    var proProduct: ProProduct? = ProProduct(
        productID: "pro", displayName: "Pro", description: "", displayPrice: "$2.99"
    )
    var nextOutcome: PurchaseOutcome = .purchased
    var stateAfterRestore: PurchaseState = .notPurchased
    private(set) var purchaseCalls = 0

    func start() async {}
    func refreshPurchases() async {}

    func restorePurchases() async {
        purchaseState = stateAfterRestore
    }

    func purchase() async -> PurchaseOutcome {
        purchaseCalls += 1
        if nextOutcome == .purchased { purchaseState = .purchased }
        return nextOutcome
    }
}

@MainActor
struct PremiumViewModelTests {
    @Test func successfulPurchaseSaysThankYou() async {
        let billing = FakeBillingManager()
        let viewModel = PremiumViewModel(billingManager: billing)

        await viewModel.purchase()

        #expect(viewModel.message == .purchaseCompleted)
        #expect(viewModel.purchaseState == .purchased)
        #expect(!viewModel.isWorking)
    }

    @Test func cancelShowsNothing() async {
        let billing = FakeBillingManager()
        billing.nextOutcome = .cancelled
        let viewModel = PremiumViewModel(billingManager: billing)

        await viewModel.purchase()

        #expect(viewModel.message == nil)
    }

    @Test func restoreThatCouldNotAskIsNotNothingToRestore() async {
        let billing = FakeBillingManager()
        billing.stateAfterRestore = .unknown
        let viewModel = PremiumViewModel(billingManager: billing)

        await viewModel.restore()

        #expect(viewModel.message == .couldNotCheck)
    }

    @Test(arguments: [
        (PurchaseState.purchased, PremiumMessage.purchaseCompleted),
        (.pending, .purchasePending),
        (.notPurchased, .nothingToRestore),
        (.unknown, .couldNotCheck),
    ])
    func restoreMessages(state: PurchaseState, expected: PremiumMessage) {
        #expect(PremiumMessages.restoreMessage(for: state) == expected)
    }

    @Test func failureCarriesTheError() {
        #expect(PremiumMessages.message(for: .failed(.networkUnavailable)) == .failed(.networkUnavailable))
    }
}
