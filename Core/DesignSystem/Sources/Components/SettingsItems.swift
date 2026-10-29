import SwiftUI

/// A single row in a settings-style list.
///
/// - Parameter action: `nil` for a read-only row (a version number, for example), which then
///   exposes no button trait to VoiceOver.
public struct SettingsItem<Trailing: View>: View {
    private let title: String
    private let subtitle: String?
    private let action: (() -> Void)?
    private let trailing: Trailing

    @Environment(\.appTheme) private var theme

    public init(
        _ title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.trailing = trailing()
    }

    public var body: some View {
        if let action {
            Button(action: action) { row }
                .buttonStyle(.plain)
        } else {
            row.accessibilityElement(children: .combine)
        }
    }

    private var row: some View {
        HStack(spacing: theme.spacing.md) {
            SettingsItemText(title: title, subtitle: subtitle)
            trailing
        }
        .frame(minHeight: theme.spacing.minTouchTarget)
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
        .contentShape(Rectangle())
    }
}

extension SettingsItem where Trailing == EmptyView {
    public init(_ title: String, subtitle: String? = nil, action: (() -> Void)? = nil) {
        self.init(title, subtitle: subtitle, action: action, trailing: { EmptyView() })
    }
}

/// A settings row that toggles a boolean. The whole row is the toggle target, so VoiceOver
/// announces one control instead of two.
public struct SwitchSettingsItem: View {
    private let title: String
    private let subtitle: String?
    @Binding private var isOn: Bool

    @Environment(\.appTheme) private var theme

    public init(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    public var body: some View {
        Toggle(isOn: $isOn) {
            SettingsItemText(title: title, subtitle: subtitle)
        }
        .frame(minHeight: theme.spacing.minTouchTarget)
        .padding(.horizontal, theme.spacing.md)
        .padding(.vertical, theme.spacing.sm)
    }
}

private struct SettingsItemText: View {
    let title: String
    let subtitle: String?

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurface)
            if let subtitle {
                Text(subtitle)
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.colors.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
