import SwiftUI

// MARK: - Data Models

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
    /// Shared cookie jar injected from ContentView – used to make authenticated requests.
    @EnvironmentObject private var cookieJar: CookieJar

    /// ViewModel that owns the accounts / reservations state and the refresh logic.
    @StateObject private var viewModel = DashboardVM()

    var body: some View {
        NavigationView {
            List {
                // MARK: Accounts section
                Section(header: Text("Rekeningen")) {
                    ForEach(viewModel.accounts) { account in
                        AccountRow(account: account)
                    }
                }

                // MARK: Reservations section
                Section(header: Text("Reserveringen")) {
                    ForEach(viewModel.reservations) { reservation in
                        ReservationRow(reservation: reservation)
                    }
                }

                // MARK: Error section
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                    } else {
                        Button {
                            viewModel.refresh(using: cookieJar)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
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
