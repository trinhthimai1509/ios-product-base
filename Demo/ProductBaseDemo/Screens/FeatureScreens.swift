import ProductBaseOnboarding
import ProductBasePremium
import ProductBaseSettings
import SwiftUI

enum DemoOnboarding {
    static var pages: [OnboardingPage] { [
        OnboardingPage(title: "Welcome", description: "This is the iOS Product Base capability catalog.") {
            Image(systemName: "square.stack.3d.up.fill").resizable().scaledToFit().foregroundStyle(.tint)
        },
        OnboardingPage(title: "Pick what you need", description: "Every module is optional. Products link only what they use.") {
            Image(systemName: "puzzlepiece.extension.fill").resizable().scaledToFit().foregroundStyle(.tint)
        },
        OnboardingPage(title: "Ship faster", description: "Theme, settings, paywall and ads are ready on day one.") {
            Image(systemName: "paperplane.fill").resizable().scaledToFit().foregroundStyle(.tint)
        },
    ] }
}

/// Settings assembled from capability-driven rows: the premium and privacy rows appear only when
/// the capability says they apply, and empty sections disappear on their own.
struct DemoSettingsScreen: View {
    let container: AppContainer

    var body: some View {
        let prefs = container.preferences
        let ads = container.ads
        SettingsScreen(
            title: "Settings",
            sections: [
                SettingsSection("Display", rows: [
                    .themePicker(themeMode: prefs.themeMode, onChange: prefs.setThemeMode),
                ]),
                SettingsSection("Notifications", rows: [
                    .toggle(
                        title: "Reminders", subtitle: "The app's own switch, independent of iOS permission",
                        isOn: prefs.notificationsEnabled, onChange: prefs.setNotificationsEnabled
                    ),
                    .openSystemSettings(title: "Open iOS Settings"),
                ]),
                SettingsSection("Privacy", rows: ads.privacyOptionsRequired ? [
                    .action(title: "Privacy options", systemImage: "hand.raised") {
                        Task { _ = await ads.showPrivacyOptions() }
                    },
                ] : []),
                SettingsSection("About", rows: [
                    .share(title: "Share this app", text: "Try Product Base!", systemImage: "square.and.arrow.up"),
                    .link(title: "Source code", url: URL(string: "https://github.com/trinhthimai1509/ios-product-base")!, systemImage: "chevron.left.forwardslash.chevron.right"),
                    .action(title: "Rate this app", systemImage: "star") { _ = container.review.requestReview() },
                    .info(title: "Version", value: Bundle.main.versionDescription),
                ]),
            ]
        )
    }
}

struct DemoPremiumScreen: View {
    @State private var viewModel: PremiumViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: PremiumViewModel(billingManager: container.billing))
    }

    var body: some View {
        PremiumScreen(
            content: PremiumContent(
                title: "Go Pro",
                subtitle: "One purchase, yours forever.",
                benefits: ["No ads, ever", "Support independent development", "Every future Pro feature"],
                footnote: "Uses the local StoreKit configuration file in the demo — no real charge."
            ),
            viewModel: viewModel
        )
        .navigationTitle("Premium")
        .navigationBarTitleDisplayMode(.inline)
    }
}
