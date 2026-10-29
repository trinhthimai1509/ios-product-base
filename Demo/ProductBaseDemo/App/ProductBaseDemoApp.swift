import ProductBaseDesignSystem
import ProductBaseOnboarding
import SwiftUI

@main
struct ProductBaseDemoApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .productBaseTheme(themeMode: container.preferences.themeMode)
                .modelContainer(container.modelContainer)
        }
    }
}

private struct RootView: View {
    let container: AppContainer

    @State private var onboarding: OnboardingViewModel

    init(container: AppContainer) {
        self.container = container
        _onboarding = State(initialValue: OnboardingViewModel(preferences: container.preferences))
    }

    var body: some View {
        Group {
            if onboarding.isCompleted {
                NavigationStack {
                    HomeScreen(container: container)
                }
            } else {
                OnboardingScreen(pages: DemoOnboarding.pages, viewModel: onboarding)
                    .transition(.opacity)
            }
        }
        .animation(.default, value: onboarding.isCompleted)
        .task {
            await container.billing.start()
            await container.ads.initialize()
        }
    }
}
