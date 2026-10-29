import GoogleMobileAds
import SwiftUI

/// An anchored adaptive banner. Renders **nothing at all** — no reserved space — while ads are
/// unavailable (premium, no consent, disabled), so it can be placed unconditionally.
///
/// ```swift
/// AppScaffold { content } bottomBar: { AppBannerAd(adsController: ads) }
/// ```
public struct AppBannerAd: View {
    private let adsController: any AdsController

    public init(adsController: any AdsController) {
        self.adsController = adsController
    }

    public var body: some View {
        if adsController.adsAvailable {
            let adSize = currentOrientationAnchoredAdaptiveBanner(width: Self.availableWidth)
            BannerRepresentable(adUnitID: adsController.bannerAdUnitID, adSize: adSize)
                .frame(width: adSize.size.width, height: adSize.size.height)
                .frame(maxWidth: .infinity)
        }
    }

    /// The window's width. The banner is sized once from it rather than from a GeometryReader,
    /// whose first pass reports zero and leaves the creative laid out for the wrong size.
    @MainActor
    private static var availableWidth: CGFloat {
        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        guard let window else { return 320 }
        return window.bounds.inset(by: window.safeAreaInsets).width
    }
}

private struct BannerRepresentable: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        guard !isAdSizeEqualToSize(size1: banner.adSize, size2: adSize) else { return }
        banner.adSize = adSize
        banner.load(Request())
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: BannerView, context: Context) -> CGSize? {
        adSize.size
    }
}
