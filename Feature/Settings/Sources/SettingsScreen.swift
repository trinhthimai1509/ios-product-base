import ProductBaseCommon
import ProductBaseDesignSystem
import SwiftUI

/// A group of rows under an optional header. Sections with no rows are not rendered, so a
/// capability-driven list needs no filtering.
public struct SettingsSection {
    public let title: String?
    public let footer: String?
    public let rows: [SettingsRow]

    public init(_ title: String? = nil, footer: String? = nil, rows: [SettingsRow]) {
        self.title = title
        self.footer = footer
        self.rows = rows
    }
}

/// One row. The product owns every value and every callback; the screen holds no state.
public enum SettingsRow {
    case action(title: String, subtitle: String? = nil, systemImage: String? = nil, action: @MainActor () -> Void)
    case toggle(title: String, subtitle: String? = nil, isOn: Bool, isEnabled: Bool = true, onChange: @MainActor (Bool) -> Void)
    case info(title: String, value: String)
    /// Labels itself with the Base's strings (see ``SettingsLabels``).
    case themePicker(themeMode: ThemeMode, onChange: @MainActor (ThemeMode) -> Void)
    /// Opens the URL in the browser — or, for `mailto:` and app links, the handling app.
    case link(title: String, url: URL, systemImage: String? = nil)
    /// Presents the system share sheet with `text`.
    case share(title: String, text: String, systemImage: String? = nil)
    /// Opens this app's page in the Settings app — where notification and privacy permissions
    /// are changed once denied.
    case openSystemSettings(title: String)
}

/// The Base-owned labels of ``SettingsRow/themePicker(themeMode:onChange:)``.
public struct SettingsLabels: Sendable {
    public var theme: String
    public var light: String
    public var dark: String
    public var system: String

    public init(theme: String, light: String, dark: String, system: String) {
        self.theme = theme
        self.light = light
        self.dark = dark
        self.system = system
    }

    public static var standard: SettingsLabels {
        SettingsLabels(
            theme: String(localized: "settings.theme", bundle: .module),
            light: String(localized: "settings.theme.light", bundle: .module),
            dark: String(localized: "settings.theme.dark", bundle: .module),
            system: String(localized: "settings.theme.system", bundle: .module)
        )
    }
}

/// A settings screen assembled from rows the product supplies. Put it in a `NavigationStack`.
///
/// ```swift
/// SettingsScreen(title: "Settings", sections: [
///     SettingsSection("Appearance", rows: [.themePicker(themeMode: prefs.themeMode, onChange: prefs.setThemeMode)]),
///     SettingsSection("About", rows: [.info(title: "Version", value: Bundle.main.versionString)]),
/// ])
/// ```
public struct SettingsScreen: View {
    private let title: String
    private let sections: [SettingsSection]
    private let labels: SettingsLabels

    @Environment(\.openURL) private var openURL

    public init(title: String, sections: [SettingsSection], labels: SettingsLabels = .standard) {
        self.title = title
        self.sections = sections
        self.labels = labels
    }

    public var body: some View {
        List {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                if !section.rows.isEmpty {
                    Section {
                        ForEach(Array(section.rows.enumerated()), id: \.offset) { _, row in
                            rowView(row)
                        }
                    } header: {
                        if let title = section.title { Text(title) }
                    } footer: {
                        if let footer = section.footer { Text(footer) }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
    }

    @ViewBuilder
    private func rowView(_ row: SettingsRow) -> some View {
        switch row {
        case let .action(title, subtitle, systemImage, action):
            Button(action: action) {
                RowLabel(title: title, subtitle: subtitle, systemImage: systemImage)
            }
            .foregroundStyle(.primary)

        case let .toggle(title, subtitle, isOn, isEnabled, onChange):
            Toggle(isOn: Binding(get: { isOn }, set: onChange)) {
                RowLabel(title: title, subtitle: subtitle, systemImage: nil)
            }
            .disabled(!isEnabled)

        case let .info(title, value):
            LabeledContent(title, value: value)

        case let .themePicker(themeMode, onChange):
            Picker(labels.theme, selection: Binding(get: { themeMode }, set: onChange)) {
                Text(labels.system).tag(ThemeMode.system)
                Text(labels.light).tag(ThemeMode.light)
                Text(labels.dark).tag(ThemeMode.dark)
            }

        case let .link(title, url, systemImage):
            Link(destination: url) {
                RowLabel(title: title, subtitle: nil, systemImage: systemImage)
            }
            .foregroundStyle(.primary)

        case let .share(title, text, systemImage):
            ShareLink(item: text) {
                RowLabel(title: title, subtitle: nil, systemImage: systemImage)
            }
            .foregroundStyle(.primary)

        case let .openSystemSettings(title):
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                RowLabel(title: title, subtitle: nil, systemImage: nil)
            }
            .foregroundStyle(.primary)
        }
    }
}

private struct RowLabel: View {
    let title: String
    let subtitle: String?
    let systemImage: String?

    var body: some View {
        HStack(spacing: 12) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)
                    .frame(width: 24)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

extension Bundle {
    /// `"1.4.0 (212)"` — `CFBundleShortVersionString` and `CFBundleVersion`, for an "About" row.
    public var versionDescription: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }
}
