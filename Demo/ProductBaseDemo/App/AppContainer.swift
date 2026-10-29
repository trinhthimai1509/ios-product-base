import Foundation
import Observation
import ProductBaseAds
import ProductBaseBilling
import ProductBaseCommon
import ProductBaseDatabase
import ProductBaseNetwork
import ProductBaseNotification
import ProductBasePreferences
import ProductBaseReview
import ProductBaseTelemetry
import ProductBaseTelemetryFirebase
import SwiftData

/// The composition root: every Base capability, built once and wired together.
///
/// This is the file a product writes — the iOS counterpart of the Android demo's Hilt modules.
/// There is no DI framework; construction order is the dependency graph.
@MainActor
final class AppContainer {
    let logger: any Logger
    let preferences: UserDefaultsAppPreferences
    let billing: StoreKitBillingManager
    let ads: GoogleAdsController
    let review: any AppReviewManager
    let telemetry: TelemetryBindings
    let httpClient: HTTPClient
    let networkMonitor: any NetworkMonitor
    let notificationPermission: any NotificationPermission
    let reminders: any ReminderScheduler
    let modelContainer: ModelContainer

    init() {
        #if DEBUG
            let logger: any Logger = OSLogLogger(subsystem: "dev.sautao.productbase.demo")
            let isRelease = false
        #else
            let logger: any Logger = NoOpLogger()
            let isRelease = true
        #endif
        self.logger = logger

        telemetry = FirebaseTelemetry.bootstrap(logger: logger)
        preferences = UserDefaultsAppPreferences()

        // Including ProductBaseBilling *is* the decision that premium means "owns Pro".
        billing = StoreKitBillingManager(
            config: BillingConfig(proProductID: "dev.sautao.productbase.demo.pro"),
            logger: logger
        )

        var adsConfig = AdsConfig.testAds(interstitialPolicy: InterstitialPolicy(minInterval: .seconds(30)))
        adsConfig.isReleaseBuild = isRelease
        ads = GoogleAdsController(config: adsConfig, premiumState: billing, logger: logger)

        review = StoreKitReviewManager(logger: logger)

        httpClient = HTTPClient(
            config: NetworkConfig(
                baseURL: URL(string: "https://jsonplaceholder.typicode.com/")!,
                enableHTTPLogging: !isRelease
            ),
            logger: logger
        )
        networkMonitor = PathNetworkMonitor()

        notificationPermission = UserNotificationPermission(logger: logger)
        reminders = UserNotificationReminderScheduler()

        do {
            modelContainer = try PersistentStore.makeContainer(
                schema: Schema([DemoNote.self]),
                location: .applicationSupport(name: "demo"),
                logger: logger
            )
        } catch {
            // A product decides what to show here. Never delete the store to "recover".
            fatalError("Could not open the demo store: \(error)")
        }
    }
}

@Model
final class DemoNote {
    var text: String
    var createdAt: Date

    init(text: String, createdAt: Date = .now) {
        self.text = text
        self.createdAt = createdAt
    }
}
