import SwiftUI
import WebKit

// MARK: - WebView

/// A SwiftUI wrapper around `WKWebView` for loading the Smart FMS portal.
/// Uses the default (shared) data store so cookies are persisted across sessions.
struct WebView: UIViewRepresentable {
    let url: URL
    let cookieJar: CookieJar

    func makeUIView(context: Context) -> WKWebView {
        // Use the default data store so the cookie store is shared with URLSession.shared
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        // Load the portal URL on first creation
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No incremental updates needed; the WebView manages its own navigation
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(cookieJar: cookieJar)
    }

    // MARK: Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        let cookieJar: CookieJar

        init(cookieJar: CookieJar) {
            self.cookieJar = cookieJar
        }

        /// After each successful navigation, inject CSS to hide unnecessary portal UI elements
        /// (e.g. banners and cookie notices), then harvest cookies into the shared CookieJar
        /// so the Dashboard can reuse the authenticated session.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            injectCleanupCSS(into: webView)
            webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
                self.cookieJar.update(cookies: cookies)
            }
        }

        // MARK: - CSS injection

        private func injectCleanupCSS(into webView: WKWebView) {
            let css = "header, .banner, #cookie-notice, .cookie-bar { display: none !important; }"
            let js = """
            (function() {
                var style = document.createElement('style');
                style.textContent = '\(css)';
                document.head.appendChild(style);
            })();
            """
            webView.evaluateJavaScript(js) { _, error in
                if let error {
                    print("[WebView] CSS injection error: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - WebViewTab

/// The tab that wraps the WebView and receives the shared `CookieJar` from the environment.
struct WebViewTab: View {
    @EnvironmentObject private var cookieJar: CookieJar

    /// Starting URL for the Smart FMS portal – financial accounts overview.
    private let portalURL = URL(string: "https://mijnsmartfms.nl/default.asp?p=FINANB_REKENINGEN")!

    var body: some View {
        WebView(url: portalURL, cookieJar: cookieJar)
            .ignoresSafeArea(edges: .bottom)
    }
}
