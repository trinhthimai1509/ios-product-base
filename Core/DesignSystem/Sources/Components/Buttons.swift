import SwiftUI

/// The main call to action on a screen. Use at most one per screen.
///
/// - Parameter title: already-resolved, localised text. Base components never hold a string key.
public struct PrimaryButton: View {
    private let title: String
    private let isLoading: Bool
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    public init(_ title: String, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                }
            }
        }
        .buttonStyle(FilledButtonStyle(isEnabled: isEnabled))
        .disabled(isLoading)
        .accessibilityValue(isLoading ? Text(verbatim: "…") : Text(verbatim: ""))
    }
}

/// An alternative action next to — or instead of — a ``PrimaryButton``.
public struct SecondaryButton: View {
    private let title: String
    private let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(title, action: action)
            .buttonStyle(OutlinedButtonStyle(isEnabled: isEnabled))
    }
}

private struct FilledButtonStyle: ButtonStyle {
    let isEnabled: Bool

    @Environment(\.appTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.typography.headline)
            .foregroundStyle(isEnabled ? theme.colors.onPrimary : theme.colors.onSurface.opacity(0.38))
            .tint(theme.colors.onPrimary)
            .padding(.horizontal, theme.spacing.lg)
            .frame(minHeight: theme.spacing.minTouchTarget + 4)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                    .fill(isEnabled ? theme.colors.primary : theme.colors.onSurface.opacity(0.12))
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

private struct OutlinedButtonStyle: ButtonStyle {
    let isEnabled: Bool

    @Environment(\.appTheme) private var theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.typography.headline)
            .foregroundStyle(isEnabled ? theme.colors.primary : theme.colors.onSurface.opacity(0.38))
            .padding(.horizontal, theme.spacing.lg)
            .frame(minHeight: theme.spacing.minTouchTarget + 4)
            .background(
                RoundedRectangle(cornerRadius: theme.radii.medium, style: .continuous)
                    .strokeBorder(
                        isEnabled ? theme.colors.outline : theme.colors.onSurface.opacity(0.12),
                        lineWidth: 1
                    )
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}
