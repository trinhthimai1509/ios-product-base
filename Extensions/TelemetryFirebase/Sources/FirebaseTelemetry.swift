import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics
import Foundation
import ProductBaseCommon
import ProductBaseTelemetry

/// What ``FirebaseTelemetry/bootstrap(bundle:logger:)`` hands back: the two contracts, bound to
/// Firebase or to no-ops.
public struct TelemetryBindings: Sendable {
    public let analytics: any ProductBaseTelemetry.Analytics
    public let crashReporter: any CrashReporter
    /// `false` when `GoogleService-Info.plist` was missing and the no-ops were bound.
    public let isFirebaseConfigured: Bool
}

/// Product code never calls Firebase; it calls ``Analytics`` and ``CrashReporter``. This is where
/// they meet.
public enum FirebaseTelemetry {
    /// Configures Firebase and returns the bindings. Call once, at launch, before anything logs.
    ///
    /// Without `GoogleService-Info.plist` in `bundle`, Firebase is not configured and the no-op
    /// implementations are returned instead of crashing — so a fresh clone builds and runs. Keep
    /// the plist out of version control.
    @MainActor
    public static func bootstrap(bundle: Bundle = .main, logger: any Logger) -> TelemetryBindings {
        guard let path = bundle.path(forResource: "GoogleService-Info", ofType: "plist"),
            let options = FirebaseOptions(contentsOfFile: path)
        else {
            logger.info(tag, "GoogleService-Info.plist not found; telemetry is a no-op")
            return TelemetryBindings(
                analytics: NoOpAnalytics(), crashReporter: NoOpCrashReporter(), isFirebaseConfigured: false
            )
        }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure(options: options)
        }
        return TelemetryBindings(
            analytics: FirebaseAnalyticsClient(), crashReporter: CrashlyticsReporter(), isFirebaseConfigured: true
        )
    }

    private static let tag = "Telemetry"
}

struct FirebaseAnalyticsClient: ProductBaseTelemetry.Analytics {
    func logScreenView(_ screenName: String) {
        FirebaseAnalytics.Analytics.logEvent(AnalyticsEventScreenView, parameters: [AnalyticsParameterScreenName: screenName])
    }

    func logEvent(_ event: AnalyticsEvent) {
        FirebaseAnalytics.Analytics.logEvent(
            event.name,
            parameters: event.parameters.isEmpty ? nil : event.parameters.mapValues { $0.rawValue }
        )
    }
}

struct CrashlyticsReporter: CrashReporter {
    func recordNonFatal(_ error: any Error) {
        Crashlytics.crashlytics().record(error: error)
    }

    func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }

    func setCustomKey(_ key: String, value: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }
}
