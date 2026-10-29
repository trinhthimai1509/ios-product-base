import ProductBaseDesignSystem
import SwiftUI

/// One onboarding page. The product supplies all content, already localised.
public struct OnboardingPage {
    public let title: String
    public let description: String
    public let illustration: AnyView?

    public init(title: String, description: String) {
        self.title = title
        self.description = description
        self.illustration = nil
    }

    public init(title: String, description: String, @ViewBuilder illustration: () -> some View) {
        self.title = title
        self.description = description
        self.illustration = AnyView(illustration())
    }
}

/// The Base-owned button labels. Defaults come from this module's string catalog (English and
/// Vietnamese); pass your own to change wording or add languages.
public struct OnboardingLabels: Sendable {
    public var skip: String
    public var next: String
    public var finish: String
    public var pageIndicator: @Sendable (_ page: Int, _ count: Int) -> String

    public init(
        skip: String,
        next: String,
        finish: String,
        pageIndicator: @escaping @Sendable (_ page: Int, _ count: Int) -> String
    ) {
        self.skip = skip
        self.next = next
        self.finish = finish
        self.pageIndicator = pageIndicator
    }

    /// The Base's own wording, in the user's language. Copy and change one field to override it.
    public static var standard: OnboardingLabels {
        OnboardingLabels(
            skip: String(localized: "onboarding.skip", bundle: .module),
            next: String(localized: "onboarding.next", bundle: .module),
            finish: String(localized: "onboarding.finish", bundle: .module),
            pageIndicator: { page, count in
                String(localized: "onboarding.pageIndicator \(page) \(count)", bundle: .module)
            }
        )
    }
}

/// A paged introduction with Skip, Next and Get Started.
///
/// Stateless: it renders `pageIndex` and reports intent. Navigate away on
/// ``OnboardingViewModel/isCompleted``, not on a button press.
public struct OnboardingScreen: View {
    private let pages: [OnboardingPage]
    private let pageIndex: Int
    private let labels: OnboardingLabels
    private let onNext: @MainActor () -> Void
    private let onSkip: @MainActor () -> Void
    private let onFinish: @MainActor () -> Void
    private let onPageChanged: @MainActor (Int) -> Void

    @Environment(\.appTheme) private var theme

    public init(
        pages: [OnboardingPage],
        pageIndex: Int,
        labels: OnboardingLabels = .standard,
        onNext: @escaping @MainActor () -> Void,
        onSkip: @escaping @MainActor () -> Void,
        onFinish: @escaping @MainActor () -> Void,
        onPageChanged: @escaping @MainActor (Int) -> Void
    ) {
        self.pages = pages
        self.pageIndex = pageIndex
        self.labels = labels
        self.onNext = onNext
        self.onSkip = onSkip
        self.onFinish = onFinish
        self.onPageChanged = onPageChanged
    }

    /// Wires the screen to an ``OnboardingViewModel``.
    public init(pages: [OnboardingPage], viewModel: OnboardingViewModel, labels: OnboardingLabels = .standard) {
        self.init(
            pages: pages,
            pageIndex: viewModel.pageIndex,
            labels: labels,
            onNext: { viewModel.next(pageCount: pages.count) },
            onSkip: viewModel.skip,
            onFinish: viewModel.finish,
            onPageChanged: viewModel.goToPage
        )
    }

    private var isLastPage: Bool { pageIndex >= pages.count - 1 }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if !isLastPage {
                    Button(labels.skip, action: onSkip)
                        .font(theme.typography.headline)
                        .frame(minHeight: theme.spacing.minTouchTarget)
                }
            }
            .padding(.horizontal, theme.spacing.md)
            .frame(minHeight: theme.spacing.minTouchTarget)

            TabView(selection: Binding(get: { pageIndex }, set: onPageChanged)) {
                ForEach(pages.indices, id: \.self) { index in
                    PageView(page: pages[index])
                        .tag(index)
                        .accessibilityElement(children: .combine)
                        .accessibilityHint(labels.pageIndicator(index + 1, pages.count))
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.snappy, value: pageIndex)

            PageDots(count: pages.count, current: pageIndex)
                .padding(.vertical, theme.spacing.md)
                .accessibilityHidden(true)

            PrimaryButton(isLastPage ? labels.finish : labels.next, action: isLastPage ? onFinish : onNext)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, theme.spacing.lg)
                .padding(.bottom, theme.spacing.lg)
        }
        .background(theme.colors.background.ignoresSafeArea())
    }
}

private struct PageView: View {
    let page: OnboardingPage

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(spacing: theme.spacing.md) {
            Spacer(minLength: 0)
            if let illustration = page.illustration {
                illustration
                    .frame(maxHeight: 280)
                    .padding(.bottom, theme.spacing.lg)
            }
            Text(page.title)
                .font(theme.typography.largeTitle)
                .foregroundStyle(theme.colors.onBackground)
            Text(page.description)
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.onSurfaceVariant)
            Spacer(minLength: 0)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, theme.spacing.xl)
    }
}

private struct PageDots: View {
    let count: Int
    let current: Int

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: theme.spacing.sm) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? theme.colors.primary : theme.colors.outline.opacity(0.4))
                    .frame(width: index == current ? 24 : 8, height: 8)
            }
        }
        .animation(.snappy, value: current)
    }
}
