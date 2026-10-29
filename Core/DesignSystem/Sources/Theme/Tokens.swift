import SwiftUI

/// Colours with a meaning the palette does not define a role for.
///
/// Kept to the two that recur in almost every app. A colour belongs here only when several
/// unrelated screens need the same meaning, not when one screen wants a hue.
public struct SemanticColors: Sendable, Equatable {
    public var success: Color
    public var onSuccess: Color
    public var warning: Color
    public var onWarning: Color

    public init(success: Color, onSuccess: Color, warning: Color, onWarning: Color) {
        self.success = success
        self.onSuccess = onSuccess
        self.warning = warning
        self.onWarning = onWarning
    }

    public static let productBaseLight = SemanticColors(
        success: Color(hex: 0x1B6C3A), onSuccess: .white,
        warning: Color(hex: 0x8A5300), onWarning: .white
    )

    public static let productBaseDark = SemanticColors(
        success: Color(hex: 0x8FDBA6), onSuccess: Color(hex: 0x00391A),
        warning: Color(hex: 0xFFB95C), onWarning: Color(hex: 0x472A00)
    )
}

/// Spacing scale, so components and screens do not scatter magic numbers.
public struct Spacing: Sendable, Equatable {
    public var xs: CGFloat
    public var sm: CGFloat
    public var md: CGFloat
    public var lg: CGFloat
    public var xl: CGFloat
    public var xxl: CGFloat

    /// Apple's minimum accessible hit target (Human Interface Guidelines).
    public let minTouchTarget: CGFloat = 44

    public init(
        xs: CGFloat = 4, sm: CGFloat = 8, md: CGFloat = 16,
        lg: CGFloat = 24, xl: CGFloat = 32, xxl: CGFloat = 48
    ) {
        self.xs = xs
        self.sm = sm
        self.md = md
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
    }
}

/// Corner radii. Slightly softer than the system defaults; overridable per product.
public struct CornerRadii: Sendable, Equatable {
    public var extraSmall: CGFloat
    public var small: CGFloat
    public var medium: CGFloat
    public var large: CGFloat
    public var extraLarge: CGFloat

    public init(
        extraSmall: CGFloat = 6, small: CGFloat = 10, medium: CGFloat = 14,
        large: CGFloat = 20, extraLarge: CGFloat = 28
    ) {
        self.extraSmall = extraSmall
        self.small = small
        self.medium = medium
        self.large = large
        self.extraLarge = extraLarge
    }
}

/// The fonts Base components use. Defaults are Dynamic Type text styles; a product with a brand
/// typeface passes `Font.custom(_:size:relativeTo:)` values so Dynamic Type keeps working.
public struct Typography: Sendable {
    public var largeTitle: Font
    public var title: Font
    public var headline: Font
    public var body: Font
    public var callout: Font
    public var caption: Font
    public var label: Font

    public init(
        largeTitle: Font = .largeTitle.bold(),
        title: Font = .title2.weight(.semibold),
        headline: Font = .headline,
        body: Font = .body,
        callout: Font = .callout,
        caption: Font = .caption,
        label: Font = .caption.weight(.semibold)
    ) {
        self.largeTitle = largeTitle
        self.title = title
        self.headline = headline
        self.body = body
        self.callout = callout
        self.caption = caption
        self.label = label
    }
}
