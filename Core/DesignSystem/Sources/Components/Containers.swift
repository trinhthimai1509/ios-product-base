import SwiftUI

/// A grouped surface. Tappable when `action` is supplied, in which case it is one accessibility
/// element announced as a button.
public struct AppCard<Content: View>: View {
    private let action: (() -> Void)?
    private let content: Content

    @Environment(\.appTheme) private var theme

    public init(action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }

    public var body: some View {
        if let action {
            Button(action: action) { card }
                .buttonStyle(.plain)
        } else {
            card
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(theme.spacing.md)
        .foregroundStyle(theme.colors.onSurface)
        .background(
            RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous)
                .fill(theme.colors.surfaceVariant)
        )
        .contentShape(RoundedRectangle(cornerRadius: theme.radii.large, style: .continuous))
    }
}

/// A screen's background and, optionally, something pinned to the bottom — a banner ad, a
/// primary action. Put it inside a `NavigationStack`; the title belongs to `.navigationTitle`.
public struct AppScaffold<Content: View, BottomBar: View>: View {
    private let content: Content
    private let bottomBar: BottomBar

    @Environment(\.appTheme) private var theme

    public init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder bottomBar: () -> BottomBar
    ) {
        self.content = content()
        self.bottomBar = bottomBar()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.colors.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
    }
}

extension AppScaffold where BottomBar == EmptyView {
    public init(@ViewBuilder content: () -> Content) {
        self.init(content: content, bottomBar: { EmptyView() })
    }
}

/// A heading above a group of rows or cards.
public struct SectionHeader: View {
    private let title: String

    @Environment(\.appTheme) private var theme

    public init(_ title: String) {
        self.title = title
    }

    public var body: some View {
        Text(title)
            .font(theme.typography.label)
            .textCase(.uppercase)
            .foregroundStyle(theme.colors.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, theme.spacing.md)
            .padding(.top, theme.spacing.lg)
            .padding(.bottom, theme.spacing.xs)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Marks a feature as part of a paid tier.
///
/// Purely visual — it knows nothing about entitlement. The caller decides when to show it, using
/// `PremiumState`, so this component stays usable in apps with no billing at all.
public struct PremiumBadge: View {
    private let text: String

    @Environment(\.appTheme) private var theme

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(theme.typography.label)
            .foregroundStyle(theme.colors.onTertiaryContainer)
            .padding(.horizontal, theme.spacing.sm)
            .padding(.vertical, theme.spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.small, style: .continuous)
                    .fill(theme.colors.tertiaryContainer)
            )
    }
}
