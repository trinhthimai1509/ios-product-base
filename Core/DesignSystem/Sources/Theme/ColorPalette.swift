import SwiftUI

/// The colour roles every Base component draws with.
///
/// Mirrors the Material 3 role names used by the Android Product Base so one brand spec can
/// feed both platforms. A product supplies its own palettes through ``ProductBaseTheme``; it
/// must never edit this file to look like itself.
public struct ColorPalette: Sendable, Equatable {
    public var primary: Color
    public var onPrimary: Color
    public var primaryContainer: Color
    public var onPrimaryContainer: Color
    public var secondary: Color
    public var onSecondary: Color
    public var secondaryContainer: Color
    public var onSecondaryContainer: Color
    public var tertiary: Color
    public var onTertiary: Color
    public var tertiaryContainer: Color
    public var onTertiaryContainer: Color
    public var error: Color
    public var onError: Color
    public var errorContainer: Color
    public var onErrorContainer: Color
    public var background: Color
    public var onBackground: Color
    public var surface: Color
    public var onSurface: Color
    public var surfaceVariant: Color
    public var onSurfaceVariant: Color
    public var outline: Color

    public init(
        primary: Color, onPrimary: Color, primaryContainer: Color, onPrimaryContainer: Color,
        secondary: Color, onSecondary: Color, secondaryContainer: Color, onSecondaryContainer: Color,
        tertiary: Color, onTertiary: Color, tertiaryContainer: Color, onTertiaryContainer: Color,
        error: Color, onError: Color, errorContainer: Color, onErrorContainer: Color,
        background: Color, onBackground: Color, surface: Color, onSurface: Color,
        surfaceVariant: Color, onSurfaceVariant: Color, outline: Color
    ) {
        self.primary = primary
        self.onPrimary = onPrimary
        self.primaryContainer = primaryContainer
        self.onPrimaryContainer = onPrimaryContainer
        self.secondary = secondary
        self.onSecondary = onSecondary
        self.secondaryContainer = secondaryContainer
        self.onSecondaryContainer = onSecondaryContainer
        self.tertiary = tertiary
        self.onTertiary = onTertiary
        self.tertiaryContainer = tertiaryContainer
        self.onTertiaryContainer = onTertiaryContainer
        self.error = error
        self.onError = onError
        self.errorContainer = errorContainer
        self.onErrorContainer = onErrorContainer
        self.background = background
        self.onBackground = onBackground
        self.surface = surface
        self.onSurface = onSurface
        self.surfaceVariant = surfaceVariant
        self.onSurfaceVariant = onSurfaceVariant
        self.outline = outline
    }
}

extension Color {
    /// `Color(hex: 0x4C5BD4)` — opaque sRGB from a 24-bit literal.
    public init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// A deliberately neutral fallback palette — the same values as the Android Base.
private enum Tone {
    static let indigo40 = Color(hex: 0x4C5BD4)
    static let indigo80 = Color(hex: 0xB9C0FF)
    static let indigo90 = Color(hex: 0xE0E3FF)
    static let indigo20 = Color(hex: 0x1B2379)
    static let indigo10 = Color(hex: 0x0B1155)

    static let slate40 = Color(hex: 0x5C5D72)
    static let slate80 = Color(hex: 0xC5C4DD)
    static let slate90 = Color(hex: 0xE2E0F9)
    static let slate20 = Color(hex: 0x2E2F42)

    static let teal40 = Color(hex: 0x0F6E63)
    static let teal80 = Color(hex: 0x7BD8CB)
    static let teal90 = Color(hex: 0x9FF2E4)
    static let teal20 = Color(hex: 0x003731)

    static let red40 = Color(hex: 0xBA1A1A)
    static let red80 = Color(hex: 0xFFB4AB)
    static let red90 = Color(hex: 0xFFDAD6)
    static let red20 = Color(hex: 0x690005)

    static let neutral10 = Color(hex: 0x1B1B1F)
    static let neutral20 = Color(hex: 0x303034)
    static let neutral90 = Color(hex: 0xE4E1E6)
    static let neutral95 = Color(hex: 0xF3F0F4)
    static let neutral99 = Color(hex: 0xFFFBFF)
}

extension ColorPalette {
    /// Default light palette, used when a product supplies none.
    public static let productBaseLight = ColorPalette(
        primary: Tone.indigo40, onPrimary: .white,
        primaryContainer: Tone.indigo90, onPrimaryContainer: Tone.indigo10,
        secondary: Tone.slate40, onSecondary: .white,
        secondaryContainer: Tone.slate90, onSecondaryContainer: Tone.slate20,
        tertiary: Tone.teal40, onTertiary: .white,
        tertiaryContainer: Tone.teal90, onTertiaryContainer: Tone.teal20,
        error: Tone.red40, onError: .white,
        errorContainer: Tone.red90, onErrorContainer: Tone.red20,
        background: Tone.neutral99, onBackground: Tone.neutral10,
        surface: Tone.neutral99, onSurface: Tone.neutral10,
        surfaceVariant: Tone.neutral95, onSurfaceVariant: Tone.neutral20,
        outline: Tone.slate40
    )

    /// Default dark palette, used when a product supplies none.
    public static let productBaseDark = ColorPalette(
        primary: Tone.indigo80, onPrimary: Tone.indigo20,
        primaryContainer: Tone.indigo20, onPrimaryContainer: Tone.indigo90,
        secondary: Tone.slate80, onSecondary: Tone.slate20,
        secondaryContainer: Tone.slate20, onSecondaryContainer: Tone.slate90,
        tertiary: Tone.teal80, onTertiary: Tone.teal20,
        tertiaryContainer: Tone.teal20, onTertiaryContainer: Tone.teal90,
        error: Tone.red80, onError: Tone.red20,
        errorContainer: Tone.red20, onErrorContainer: Tone.red90,
        background: Tone.neutral10, onBackground: Tone.neutral90,
        surface: Tone.neutral10, onSurface: Tone.neutral90,
        surfaceVariant: Tone.neutral20, onSurfaceVariant: Tone.neutral90,
        outline: Tone.slate80
    )
}
