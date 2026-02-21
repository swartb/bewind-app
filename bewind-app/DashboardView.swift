import SwiftUI

// MARK: - Mock Data Models
// TODO: Replace with real models populated by SwiftSoup parsing of the Smart FMS portal HTML.

struct Account: Identifiable {
    let id = UUID()
    let name: String
    let balance: Double
    let currency: String
}

struct Reservation: Identifiable {
    let id = UUID()
    let description: String
    let amount: Double
    let date: Date
}

// MARK: - DashboardView

struct DashboardView: View {
    /// Shared cookie jar injected from ContentView – use to make authenticated requests.
    @EnvironmentObject private var cookieJar: CookieJar

    // Mock accounts – replace with data fetched and parsed from the portal
    @State private var accounts: [Account] = [
        Account(name: "Betaalrekening", balance: 12_345.67, currency: "EUR"),
        Account(name: "Spaarrekening",  balance:  5_000.00, currency: "EUR"),
    ]

    // Mock reservations – replace with data fetched and parsed from the portal
    @State private var reservations: [Reservation] = [
        Reservation(description: "Belastingdienst",  amount: 2_500.00, date: Date()),
        Reservation(description: "KvK Jaarrekening", amount:    75.00, date: Date()),
    ]

    var body: some View {
        NavigationView {
            List {
                // MARK: Accounts section
                Section(header: Text("Rekeningen")) {
                    ForEach(accounts) { account in
                        AccountRow(account: account)
                    }
                }

                // MARK: Reservations section
                Section(header: Text("Reserveringen")) {
                    ForEach(reservations) { reservation in
                        ReservationRow(reservation: reservation)
                    }
                }
            }
            .navigationTitle("Dashboard")
            // TODO: Add a refresh action that fetches portal HTML via CookieJar,
            //       parses it with SwiftSoup, and updates `accounts` and `reservations`.
        }
    }
}

// MARK: - AccountRow

struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack {
            Text(account.name)
                .font(.headline)
            Spacer()
            Text(account.balance, format: .currency(code: account.currency))
                .font(.subheadline)
        }
    }
}

// MARK: - ReservationRow

struct ReservationRow: View {
    let reservation: Reservation

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(reservation.description)
                    .font(.headline)
                Text(reservation.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(reservation.amount, format: .currency(code: "EUR"))
                .font(.subheadline)
        }
    }
}

#Preview {
    DashboardView()
}
