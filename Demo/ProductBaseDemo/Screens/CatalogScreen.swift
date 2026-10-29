import ProductBaseDesignSystem
import SwiftUI

/// Renders every component in `ProductBaseDesignSystem` in one place. If a component cannot be
/// shown here without awkwardness, its API is wrong.
struct CatalogScreen: View {
    @State private var dialogVisible = false
    @State private var switchOn = true
    @State private var loading = false

    @Environment(\.appTheme) private var theme

    var body: some View {
        AppScaffold {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader("Buttons")
                    HStack(spacing: theme.spacing.sm) {
                        PrimaryButton("Primary") { dialogVisible = true }
                        SecondaryButton("Secondary") { dialogVisible = true }
                    }
                    .padding(.horizontal, theme.spacing.md)
                    HStack(spacing: theme.spacing.sm) {
                        PrimaryButton("Disabled") {}.disabled(true)
                        PrimaryButton("Loading", isLoading: loading) { loading.toggle() }
                    }
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.top, theme.spacing.sm)

                    SectionHeader("Containers")
                    AppCard(action: { dialogVisible = true }) {
                        Text("A tappable card").font(theme.typography.headline)
                        Text("Cards group related content on a surface colour.")
                            .font(theme.typography.callout)
                    }
                    .padding(.horizontal, theme.spacing.md)
                    HStack {
                        PremiumBadge("PRO")
                        Text("Premium badge").font(theme.typography.callout)
                    }
                    .padding(theme.spacing.md)

                    SectionHeader("States")
                    stateBox { LoadingState(description: "Loading sample content") }
                    stateBox {
                        EmptyState(
                            title: "Nothing here yet", description: "Items you add appear here.",
                            actionTitle: "Add one", action: { dialogVisible = true }
                        )
                    }
                    stateBox {
                        ErrorState(
                            title: "Couldn't load", description: "Check your connection and try again.",
                            retryTitle: "Retry", retry: { dialogVisible = true }
                        )
                    }

                    SectionHeader("List items")
                    SettingsItem("A settings item", subtitle: "With a subtitle") { dialogVisible = true }
                    SettingsItem("Read-only item") { Text("1.0").foregroundStyle(theme.colors.onSurfaceVariant) }
                    SwitchSettingsItem("A switch item", subtitle: "The whole row toggles", isOn: $switchOn)
                }
                .padding(.bottom, theme.spacing.xl)
            }
        }
        .navigationTitle("Catalog")
        .toolbar { PremiumBadge("PRO") }
        .appDialog(
            isPresented: $dialogVisible, title: "A dialog",
            message: "Dialogs take already-localised strings.",
            confirmTitle: "OK", dismissTitle: "Cancel", onConfirm: {}
        )
    }

    private func stateBox(@ViewBuilder _ content: () -> some View) -> some View {
        content()
            .frame(height: 200)
            .background(theme.colors.surfaceVariant.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.medium))
            .padding(.horizontal, theme.spacing.md)
            .padding(.bottom, theme.spacing.sm)
    }
}
