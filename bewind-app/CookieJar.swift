import Foundation
import WebKit

// MARK: - CookieJar

/// Manages HTTP cookies captured from the `WKWebView` portal tab and makes them
/// available to other parts of the app (e.g. the Dashboard) for authenticated requests.
///
/// The cookies originate from the `WKWebView`'s default data store and are harvested
/// after every successful navigation via `WKNavigationDelegate.webView(_:didFinish:)`.
final class CookieJar: ObservableObject {

    /// The most recently captured set of cookies from the Smart FMS portal.
    @Published private(set) var cookies: [HTTPCookie] = []

    // MARK: - Update

    /// Replaces the stored cookies with a fresh snapshot from the WKWebView cookie store.
    /// This is called on the background queue that `getAllCookies` delivers on,
    /// so the publish is dispatched back to the main actor.
    func update(cookies newCookies: [HTTPCookie]) {
        DispatchQueue.main.async {
            self.cookies = newCookies
        }
    }

    // MARK: - Applying cookies to URLRequests

    /// Injects the stored cookies as HTTP header fields into a `URLRequest`.
    /// Use this to make authenticated API / page-scrape calls from the Dashboard.
    ///
    /// Example usage:
    /// ```swift
    /// var request = URLRequest(url: somePortalURL)
    /// cookieJar.apply(to: &request)
    /// let (data, _) = try await URLSession.shared.data(for: request)
    /// ```
    func apply(to request: inout URLRequest) {
        let headers = HTTPCookie.requestHeaderFields(with: cookies)
        for (field, value) in headers {
            request.addValue(value, forHTTPHeaderField: field)
        }
    }

    // MARK: - Future development

    // TODO: Persist cookies to the Keychain between app launches for seamless session restoration.

    // TODO: Implement portal data fetching + SwiftSoup parsing, for example:
    // func fetchPortalHTML(from url: URL) async throws -> String {
    //     var request = URLRequest(url: url)
    //     apply(to: &request)
    //     let (data, _) = try await URLSession.shared.data(for: request)
    //     return String(data: data, encoding: .utf8) ?? ""
    // }
    //
    // func parseAccounts(from html: String) throws -> [Account] {
    //     // Use SwiftSoup to locate the accounts table and extract rows:
    //     // let doc  = try SwiftSoup.parse(html)
    //     // let rows = try doc.select("table.rekeningen tr")
    //     // return try rows.map { row in ... }
    //     return []
    // }
}
