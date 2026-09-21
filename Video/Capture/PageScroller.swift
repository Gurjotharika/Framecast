import Foundation
import WebKit

struct PageScrollMetrics {
    var scrollY: Double
    var viewport: Double
    var height: Double

    var maxScroll: Double {
        max(0, height - viewport)
    }
}

enum PageScroller {
    static func metrics(in webView: WKWebView) async throws -> PageScrollMetrics {
        let script = """
        (function() {
          const root = document.scrollingElement || document.documentElement;
          const body = document.body;
          return {
            scrollY: root.scrollTop || 0,
            viewport: window.innerHeight || 0,
            height: Math.max(root.scrollHeight || 0, body ? body.scrollHeight : 0)
          };
        })()
        """

        let result = try await webView.evaluateJavaScript(script)
        guard let dict = result as? [String: Any] else {
            throw VideoCaptureError.pageMetrics
        }

        return PageScrollMetrics(
            scrollY: number(dict["scrollY"]),
            viewport: number(dict["viewport"]),
            height: number(dict["height"])
        )
    }

    static func scroll(to y: Double, in webView: WKWebView) async {
        let value = max(0, y)
        _ = try? await webView.evaluateJavaScript(
            "document.scrollingElement.scrollTop = \(value);"
        )
    }

    private static func number(_ value: Any?) -> Double {
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        return value as? Double ?? 0
    }
}
