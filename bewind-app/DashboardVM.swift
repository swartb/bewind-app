import Foundation

// MARK: - DashboardVM

/// ViewModel that drives the Dashboard UI.
///
/// Call `refresh(using:)` to fetch live data from the Smart FMS portal.
/// The ViewModel populates `accounts` and `reservations` using `FMSParser`,
/// or falls back to placeholder mock data while the first load is in progress.
@MainActor
final class DashboardVM: ObservableObject {

    // MARK: - Published state

    @Published private(set) var accounts: [Account] = Self.mockAccounts
    @Published private(set) var reservations: [Reservation] = Self.mockReservations
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Endpoints

    private let rekeningenURL    = URL(string: "https://mijnsmartfms.nl/default.asp?p=FINANB_REKENINGEN")!
    private let reserveringenURL = URL(string: "https://mijnsmartfms.nl/default.asp?p=FINANB_RESERVERINGEN")!

    // MARK: - Refresh

    /// Fetches fresh data from both portal endpoints concurrently and updates the published properties.
    ///
    /// - Parameter cookieJar: The shared `CookieJar` that carries the authenticated session cookies.
    func refresh(using cookieJar: CookieJar) {
        guard !isLoading else { return }
        Task {
            isLoading = true
            errorMessage = nil
            do {
                async let rekeningenHTML    = fetchHTML(from: rekeningenURL,    cookieJar: cookieJar)
                async let reserveringenHTML = fetchHTML(from: reserveringenURL, cookieJar: cookieJar)
                let (aHTML, rHTML) = try await (rekeningenHTML, reserveringenHTML)

                let parsedAccounts      = FMSParser.parseAccounts(from: aHTML)
                let parsedReservations  = FMSParser.parseReservations(from: rHTML)

                // Only replace mock data if the parser found real rows.
                if !parsedAccounts.isEmpty     { accounts      = parsedAccounts }
                if !parsedReservations.isEmpty { reservations  = parsedReservations }
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    // MARK: - Private helpers

    private func fetchHTML(from url: URL, cookieJar: CookieJar) async throws -> String {
        var request = URLRequest(url: url)
        cookieJar.apply(to: &request)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeRawData)
        }
        return html
    }

    // MARK: - Mock / placeholder data

    private static let mockAccounts: [Account] = [
        Account(name: "Betaalrekening", balance: 12_345.67, currency: "EUR"),
        Account(name: "Spaarrekening",  balance:  5_000.00, currency: "EUR"),
    ]

    private static let mockReservations: [Reservation] = [
        Reservation(description: "Belastingdienst",  amount: 2_500.00, date: Date()),
        Reservation(description: "KvK Jaarrekening", amount:    75.00, date: Date()),
    ]
}
