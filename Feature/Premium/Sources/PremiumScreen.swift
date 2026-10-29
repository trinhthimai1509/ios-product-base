import ProductBaseBilling
import ProductBaseDesignSystem
import SwiftUI

/// The Base-owned wording of the paywall's buttons and messages. Copy ``standard`` and change a
/// field to override one.
public struct PremiumLabels: Sendable {
    public var buy: @Sendable (_ price: String) -> String
    public var restore: String
    public var owned: String
    public var priceLoading: String
    public var ok: String
    public var message: @Sendable (PremiumMessage) -> String

    public init(
        buy: @escaping @Sendable (String) -> String,
        restore: String,
        owned: String,
        priceLoading: String,
        ok: String,
        message: @escaping @Sendable (PremiumMessage) -> String
    ) {
        self.buy = buy
        self.restore = restore
        self.owned = owned
        self.priceLoading = priceLoading
        self.ok = ok
        self.message = message
    }

    public static var standard: PremiumLabels {
        PremiumLabels(
            buy: { price in String(localized: "premium.buy \(price)", bundle: .module) },
            restore: String(localized: "premium.restore", bundle: .module),
            owned: String(localized: "premium.owned", bundle: .module),
            priceLoading: String(localized: "premium.priceLoading", bundle: .module),
            ok: String(localized: "premium.ok", bundle: .module),
            message: { message in
                switch message {
                case .purchaseCompleted: String(localized: "premium.message.completed", bundle: .module)
                case .purchasePending: String(localized: "premium.message.pending", bundle: .module)
                case .alreadyOwned: String(localized: "premium.message.alreadyOwned", bundle: .module)
                case .nothingToRestore: String(localized: "premium.message.nothingToRestore", bundle: .module)
                case .couldNotCheck: String(localized: "premium.message.couldNotCheck", bundle: .module)
                case .failed: String(localized: "premium.message.failed", bundle: .module)
                }
            }
        )
    }
}

/// A paywall: benefits, the App Store price, purchase and restore, and the owned state.
public struct PremiumScreen: View {
    private let content: PremiumContent
    private let viewModel: PremiumViewModel
    private let labels: PremiumLabels

    @Environment(\.appTheme) private var theme

    public init(content: PremiumContent, viewModel: PremiumViewModel, labels: PremiumLabels = .standard) {
        self.content = content
        self.viewModel = viewModel
        self.labels = labels
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.spacing.lg) {
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text(content.title)
                        .font(theme.typography.largeTitle)
                        .foregroundStyle(theme.colors.onBackground)
                    Text(content.subtitle)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.onSurfaceVariant)
                }

                AppCard {
                    ForEach(content.benefits, id: \.self) { benefit in
                        Label {
                            Text(benefit).font(theme.typography.body)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.semanticColors.success)
                        }
                        .padding(.vertical, theme.spacing.xs)
                    }
                }

                actions

                if let footnote = content.footnote {
                    Text(footnote)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.onSurfaceVariant)
                }
            }
            .padding(theme.spacing.lg)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .alert(
            viewModel.message.map(labels.message) ?? "",
            isPresented: Binding(
                get: { viewModel.message != nil },
                set: { if !$0 { viewModel.dismissMessage() } }
            )
        ) {
            Button(labels.ok, role: .cancel) { viewModel.dismissMessage() }
        }
    }

    @ViewBuilder
    private var actions: some View {
        VStack(spacing: theme.spacing.sm) {
            if viewModel.purchaseState == .purchased {
                Label(labels.owned, systemImage: "checkmark.seal.fill")
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.semanticColors.success)
                    .frame(maxWidth: .infinity, minHeight: theme.spacing.minTouchTarget)
            } else {
                PrimaryButton(
                    viewModel.product.map { labels.buy($0.displayPrice) } ?? labels.priceLoading,
                    isLoading: viewModel.isWorking
                ) {
                    Task { await viewModel.purchase() }
                }
                .frame(maxWidth: .infinity)
                .disabled(viewModel.product == nil || viewModel.purchaseState == .pending)

                Button(labels.restore) {
                    Task { await viewModel.restore() }
                }
                .font(theme.typography.callout)
                .frame(minHeight: theme.spacing.minTouchTarget)
                .disabled(viewModel.isWorking)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
