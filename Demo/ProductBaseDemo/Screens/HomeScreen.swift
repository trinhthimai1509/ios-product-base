import ProductBaseAds
import ProductBaseDesignSystem
import SwiftUI

/// The capability catalog's index. A verification shell — never a product.
struct HomeScreen: View {
    let container: AppContainer

    @Environment(\.appTheme) private var theme

    var body: some View {
        AppScaffold {
            List {
                Section("Design system") {
                    NavigationLink("Component catalog") { CatalogScreen() }
                }
                Section("Features") {
                    NavigationLink("Settings") { DemoSettingsScreen(container: container) }
                    NavigationLink("Premium paywall") { DemoPremiumScreen(container: container) }
                    Button("Replay onboarding") { container.preferences.setOnboardingCompleted(false) }
                }
                Section("Capabilities") {
                    NavigationLink("Ads & review") { MonetisationScreen(container: container) }
                    NavigationLink("Network") { NetworkScreen(container: container) }
                    NavigationLink("Database") { DataScreen() }
                    NavigationLink("Notifications & telemetry") { InfraScreen(container: container) }
                }
            }
            .scrollContentBackground(.hidden)
        } bottomBar: {
            AppBannerAd(adsController: container.ads)
        }
        .navigationTitle("Product Base")
    }
}
