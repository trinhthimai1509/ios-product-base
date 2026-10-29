import SwiftUI

/// A screen that is still loading.
///
/// - Parameter description: announced by VoiceOver. Required, because "loading" is information a
///   sighted user gets from the spinner and a VoiceOver user would otherwise lose.
public struct LoadingState: View {
    private let description: String

    public init(description: String) {
        self.description = description
    }

    public var body: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(description)
    }
}

/// Shown when a screen has loaded successfully but has nothing to display.
public struct EmptyState: View {
    private let title: String
    private let description: String?
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(
        title: String,
        description: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        MessageState(title: title, description: description, actionTitle: actionTitle, action: action)
    }
}

/// Shown when a screen failed.
///
/// - Parameter description: a message the product has already mapped to something a user can act
///   on. Never pass a raw error description.
public struct ErrorState: View {
    private let title: String
    private let description: String?
    private let retryTitle: String?
    private let retry: (() -> Void)?

    public init(
        title: String,
        description: String? = nil,
        retryTitle: String? = nil,
        retry: (() -> Void)? = nil
    ) {
        self.title = title
        self.description = description
        self.retryTitle = retryTitle
        self.retry = retry
    }

    public var body: some View {
        MessageState(title: title, description: description, actionTitle: retryTitle, action: retry)
    }
}

private struct MessageState: View {
    let title: String
    let description: String?
    let actionTitle: String?
    let action: (() -> Void)?

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.sm) {
            Text(title)
                .font(theme.typography.headline)
                .foregroundStyle(theme.colors.onSurface)
            if let description {
                Text(description)
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.colors.onSurfaceVariant)
            }
            if let actionTitle, let action {
                PrimaryButton(actionTitle, action: action)
                    .padding(.top, theme.spacing.sm)
            }
        }
        .multilineTextAlignment(.center)
        .padding(theme.spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
