import ProductBaseCommon
import SwiftUI

/// Everything a product can brand. Pass one to ``SwiftUI/View/productBaseTheme(_:themeMode:)``.
///
/// Every property has a neutral default, so `ProductBaseTheme()` is a working theme; branding is
/// overriding values, never editing Base source. See THEMING.md.
public struct ProductBaseTheme: Sendable {
    public var lightColors: ColorPalette
    public var darkColors: ColorPalette
    public var lightSemanticColors: SemanticColors
    public var darkSemanticColors: SemanticColors
    public var spacing: Spacing
    public var radii: CornerRadii
    public var typography: Typography

    public init(
        lightColors: ColorPalette = .productBaseLight,
        darkColors: ColorPalette = .productBaseDark,
        lightSemanticColors: SemanticColors = .productBaseLight,
        darkSemanticColors: SemanticColors = .productBaseDark,
        spacing: Spacing = Spacing(),
        radii: CornerRadii = CornerRadii(),
        typography: Typography = Typography()
    ) {
        self.lightColors = lightColors
        self.darkColors = darkColors
        self.lightSemanticColors = lightSemanticColors
        self.darkSemanticColors = darkSemanticColors
        self.spacing = spacing
        self.radii = radii
        self.typography = typography
    }

    /// The theme resolved for one colour scheme — what components actually read.
    public func resolved(for colorScheme: ColorScheme) -> AppTheme {
        let isDark = colorScheme == .dark
        return AppTheme(
            colors: isDark ? darkColors : lightColors,
            semanticColors: isDark ? darkSemanticColors : lightSemanticColors,
            spacing: spacing,
            radii: radii,
            typography: typography
        )
    }
}

/// The current theme, resolved for the current light/dark appearance.
///
/// Read it with `@Environment(\.appTheme) private var theme`.
public struct AppTheme: Sendable {
    public let colors: ColorPalette
    public let semanticColors: SemanticColors
    public let spacing: Spacing
    public let radii: CornerRadii
    public let typography: Typography
}

extension EnvironmentValues {
    @Entry public var appTheme: AppTheme = ProductBaseTheme().resolved(for: .light)
}

extension ThemeMode {
    /// `nil` for ``ThemeMode/system``, which is what `preferredColorScheme` takes to mean
    /// "follow the device".
    public var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}

private struct ProductBaseThemeModifier: ViewModifier {
    let theme: ProductBaseTheme
    let themeMode: ThemeMode

    @Environment(\.colorScheme) private var systemColorScheme

    func body(content: Content) -> some View {
        let scheme = themeMode.colorScheme ?? systemColorScheme
        let resolved = theme.resolved(for: scheme)
        content
            .environment(\.appTheme, resolved)
            .tint(resolved.colors.primary)
            .preferredColorScheme(themeMode.colorScheme)
    }
}

extension View {
    /// Applies the Base theme to this hierarchy. Call it once, at the root of each window.
    ///
    /// ```swift
    /// RootView()
    ///     .productBaseTheme(ProductBaseTheme(lightColors: .brandLight), themeMode: prefs.themeMode)
    /// ```
    public func productBaseTheme(
        _ theme: ProductBaseTheme = ProductBaseTheme(),
        themeMode: ThemeMode = .system
    ) -> some View {
        modifier(ProductBaseThemeModifier(theme: theme, themeMode: themeMode))
    }
}
