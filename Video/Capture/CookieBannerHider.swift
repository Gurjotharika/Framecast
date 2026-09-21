import Foundation
import UniformTypeIdentifiers
import WebKit

enum CookieBannerHider {
    static func hide(in webView: WKWebView) async {
        _ = try? await webView.evaluateJavaScript(script)
    }

    private static let script = """
    (function() {
      const selectors = [
        '#onetrust-banner-sdk',
        '#onetrust-consent-sdk',
        '.onetrust-pc-dark-filter',
        '#CybotCookiebotDialog',
        '#CybotCookiebotDialogBodyUnderlay',
        '.cc-window',
        '.cc-overlay',
        '#cookie-banner',
        '.cookie-banner',
        '[id*="cookie-banner" i]',
        '[class*="cookie-banner" i]',
        '[id*="CookieBanner"]',
        '[class*="CookieBanner"]',
        '.qc-cmp2-container',
        '.qc-cmp2-summary-buttons',
        '#sp_message_container_0',
        'div[id^="sp_message_container"]',
        '.osano-cm-window',
        '.osano-cm-dialog',
        '#tarteaucitronRoot',
        '.js-cookie-consent',
        '.cookieConsent',
        '#cookieConsent',
        'div[role="dialog"][aria-label*="cookie" i]',
        'div[role="dialog"][aria-label*="consent" i]'
      ];
      const hide = (node) => {
        if (!(node instanceof HTMLElement)) return;
        node.style.setProperty('display', 'none', 'important');
        node.setAttribute('aria-hidden', 'true');
      };
      selectors.forEach((selector) => {
        try {
          document.querySelectorAll(selector).forEach(hide);
        } catch (error) {}
      });
    })();
    """
}

enum MovieImport {
    static let dropTypes: [UTType] = [.fileURL, .movie, .mpeg4Movie, .quickTimeMovie]

    static func isMovie(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        if ["mp4", "mov", "m4v"].contains(ext) {
            return true
        }
        guard let type = UTType(filenameExtension: ext) else { return false }
        return type.conforms(to: .movie)
            || type.conforms(to: .mpeg4Movie)
            || type.conforms(to: .quickTimeMovie)
    }
}
