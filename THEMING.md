# Theming

**A product brands itself by passing values, never by editing `ProductBaseDesignSystem`.**

## The one entry point

```swift
extension ProductBaseTheme {
    static let tracker = ProductBaseTheme(
        lightColors: .trackerLight,
        darkColors: .trackerDark,
        spacing: Spacing(md: 20),
        radii: CornerRadii(medium: 12),
        typography: Typography(
            largeTitle: .custom("Inter-Bold", size: 34, relativeTo: .largeTitle),
            body: .custom("Inter-Regular", size: 17, relativeTo: .body)
        )
    )
}

RootView()
    .productBaseTheme(.tracker, themeMode: preferences.themeMode)
```

Apply it once, at the root of each window. It sets the resolved `AppTheme` in the environment,
the global `tint`, and `preferredColorScheme` from the user's `ThemeMode`.

## Colours

`ColorPalette` uses the Material 3 role names, so the brand spec that produced the Android
`ColorScheme` produces this too:

```swift
extension ColorPalette {
    static let trackerLight: ColorPalette = {
        var palette = ColorPalette.productBaseLight
        palette.primary = Color(hex: 0x00658F)
        palette.primaryContainer = Color(hex: 0xC7E7FF)
        palette.onPrimaryContainer = Color(hex: 0x001E2E)
        return palette
    }()
}
```

Start from the Base palette and override roles — unspecified roles keep neutral defaults.

## Reading the theme in product views

```swift
@Environment(\.appTheme) private var theme

Text("Streak").font(theme.typography.headline).foregroundStyle(theme.colors.primary)
    .padding(theme.spacing.md)
```

## Typography

Always pass `Font.custom(_:size:relativeTo:)` so Dynamic Type keeps working. Never fixed sizes.

## What you cannot change (on purpose)

- `Spacing.minTouchTarget` is 44 pt — Apple's accessibility minimum.
- Components' structure. If one doesn't fit, build your own in the product (class **A**).
