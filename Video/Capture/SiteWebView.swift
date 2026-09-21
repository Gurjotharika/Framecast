import SwiftUI
import WebKit

struct SiteWebView: NSViewRepresentable {
    var session: CaptureSession
    var url: URL?
    var loadToken: Int
    var hideCookieBanners: Bool
    var viewportWidth: Int
    var viewportHeight: Int
    var onStarted: () -> Void
    var onFinished: (URL?) -> Void
    var onFailed: (Error) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            hideCookieBanners: hideCookieBanners,
            onStarted: onStarted,
            onFinished: onFinished,
            onFailed: onFailed
        )
    }

    func makeNSView(context: Context) -> RecordWebHost {
        let host = RecordWebHost(
            viewport: CGSize(width: viewportWidth, height: viewportHeight)
        )
        host.webView.navigationDelegate = context.coordinator
        host.webView.allowsBackForwardNavigationGestures = true
        host.webView.customUserAgent = desktopSafariUserAgent
        session.attach(host.webView)
        return host
    }

    func updateNSView(_ host: RecordWebHost, context: Context) {
        host.viewport = CGSize(width: viewportWidth, height: viewportHeight)
        session.attach(host.webView)
        context.coordinator.onStarted = onStarted
        context.coordinator.onFinished = onFinished
        context.coordinator.onFailed = onFailed

        if hideCookieBanners != context.coordinator.hideCookieBanners {
            context.coordinator.hideCookieBanners = hideCookieBanners
            if hideCookieBanners, host.webView.url != nil {
                Task { await CookieBannerHider.hide(in: host.webView) }
            }
        }

        guard let url else { return }
        guard context.coordinator.lastLoadToken != loadToken else { return }
        context.coordinator.lastLoadToken = loadToken
        host.webView.load(URLRequest(url: url))
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: RecordWebHost, context: Context) -> CGSize? {
        CGSize(width: viewportWidth, height: viewportHeight)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var hideCookieBanners: Bool
        var onStarted: () -> Void
        var onFinished: (URL?) -> Void
        var onFailed: (Error) -> Void
        var lastLoadToken = 0

        init(
            hideCookieBanners: Bool,
            onStarted: @escaping () -> Void,
            onFinished: @escaping (URL?) -> Void,
            onFailed: @escaping (Error) -> Void
        ) {
            self.hideCookieBanners = hideCookieBanners
            self.onStarted = onStarted
            self.onFinished = onFinished
            self.onFailed = onFailed
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            Task { @MainActor in
                onStarted()
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let url = webView.url
            let hideBanners = hideCookieBanners
            Task { @MainActor in
                onFinished(url)
                guard hideBanners else { return }
                await CookieBannerHider.hide(in: webView)
                try? await Task.sleep(for: .milliseconds(800))
                await CookieBannerHider.hide(in: webView)
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                onFailed(error)
            }
        }

        func webView(
            _ webView: WKWebView,
            didFailProvisionalNavigation navigation: WKNavigation!,
            withError error: Error
        ) {
            Task { @MainActor in
                onFailed(error)
            }
        }
    }
}

final class RecordWebHost: NSView {
    let webView: WKWebView
    var viewport: CGSize {
        didSet {
            guard oldValue != viewport else { return }
            invalidateIntrinsicContentSize()
            needsLayout = true
        }
    }

    init(viewport: CGSize) {
        self.viewport = viewport
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.preferredContentMode = .desktop
        webView = WKWebView(frame: CGRect(origin: .zero, size: viewport), configuration: configuration)
        super.init(frame: CGRect(origin: .zero, size: viewport))
        wantsLayer = true
        addSubview(webView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize { viewport }

    override func layout() {
        super.layout()
        webView.frame = CGRect(origin: .zero, size: viewport)
    }
}

private let desktopSafariUserAgent =
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"

#Preview("SiteWebView") {
    let session = CaptureSession()
    return SiteWebView(
        session: session,
        url: URL(string: "https://www.apple.com"),
        loadToken: 1,
        hideCookieBanners: false,
        viewportWidth: 1440,
        viewportHeight: 900,
        onStarted: {},
        onFinished: { _ in },
        onFailed: { _ in }
    )
    .frame(width: 800, height: 500)
}
