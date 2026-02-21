import Foundation

// MARK: - FMSParser

/// Parses financial data (accounts and reservations) from Smart FMS portal HTML pages.
struct FMSParser {

    // MARK: - Account Parsing

    /// Parses account information from the `FINANB_REKENINGEN` page HTML.
    ///
    /// The parser walks every `<tr>` that contains at least two `<td>` cells
    /// and treats the first cell as the account name and the second as the
    /// balance (Dutch currency format, e.g. "1.234,56").
    static func parseAccounts(from html: String) -> [Account] {
        var accounts: [Account] = []

        // Match rows that contain at least 2 <td> cells (name + balance).
        let rowPattern = #"<tr[^>]*>\s*(?:<td[^>]*>(.*?)</td>\s*){2,}"#
        guard let rowRegex = try? NSRegularExpression(
            pattern: rowPattern,
            options: [.dotMatchesLineSeparators, .caseInsensitive]
        ) else { return accounts }

        let cellPattern = #"<td[^>]*>(.*?)</td>"#
        guard let cellRegex = try? NSRegularExpression(
            pattern: cellPattern,
            options: [.dotMatchesLineSeparators, .caseInsensitive]
        ) else { return accounts }

        let nsHTML = html as NSString
        let rowMatches = rowRegex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        for rowMatch in rowMatches {
            let rowString = nsHTML.substring(with: rowMatch.range)
            let nsRow = rowString as NSString
            let cellMatches = cellRegex.matches(in: rowString, range: NSRange(location: 0, length: nsRow.length))
            guard cellMatches.count >= 2 else { continue }

            let name = nsRow.substring(with: cellMatches[0].range(at: 1)).strippingHTML()
            let rawBalance = nsRow.substring(with: cellMatches[1].range(at: 1)).strippingHTML()

            guard !name.isEmpty, let balance = rawBalance.parseDutchCurrency() else { continue }
            accounts.append(Account(name: name, balance: balance, currency: "EUR"))
        }

        return accounts
    }

    // MARK: - Reservation Parsing

    /// Parses reservation details from the `FINANB_RESERVERINGEN` page HTML.
    ///
    /// The parser expects rows with at least three cells: description, amount, date.
    /// Dates are expected in `dd-MM-yyyy` format as used by Smart FMS.
    static func parseReservations(from html: String) -> [Reservation] {
        var reservations: [Reservation] = []

        // Match rows that contain at least 3 <td> cells (description + amount + date).
        let rowPattern = #"<tr[^>]*>\s*(?:<td[^>]*>(.*?)</td>\s*){3,}"#
        guard let rowRegex = try? NSRegularExpression(
            pattern: rowPattern,
            options: [.dotMatchesLineSeparators, .caseInsensitive]
        ) else { return reservations }

        let cellPattern = #"<td[^>]*>(.*?)</td>"#
        guard let cellRegex = try? NSRegularExpression(
            pattern: cellPattern,
            options: [.dotMatchesLineSeparators, .caseInsensitive]
        ) else { return reservations }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy"
        dateFormatter.locale = Locale(identifier: "nl_NL")

        let nsHTML = html as NSString
        let rowMatches = rowRegex.matches(in: html, range: NSRange(location: 0, length: nsHTML.length))

        for rowMatch in rowMatches {
            let rowString = nsHTML.substring(with: rowMatch.range)
            let nsRow = rowString as NSString
            let cellMatches = cellRegex.matches(in: rowString, range: NSRange(location: 0, length: nsRow.length))
            guard cellMatches.count >= 3 else { continue }

            let desc     = nsRow.substring(with: cellMatches[0].range(at: 1)).strippingHTML()
            let rawAmt   = nsRow.substring(with: cellMatches[1].range(at: 1)).strippingHTML()
            let rawDate  = nsRow.substring(with: cellMatches[2].range(at: 1)).strippingHTML()

            guard !desc.isEmpty,
                  let amount = rawAmt.parseDutchCurrency(),
                  let date   = dateFormatter.date(from: rawDate) else { continue }

            reservations.append(Reservation(description: desc, amount: amount, date: date))
        }

        return reservations
    }
}

// MARK: - String helpers

private extension String {

    /// Returns the string with HTML tags removed and whitespace trimmed.
    func strippingHTML() -> String {
        guard let regex = try? NSRegularExpression(pattern: "<[^>]+>", options: []) else {
            return self
        }
        let stripped = regex.stringByReplacingMatches(
            in: self,
            range: NSRange(startIndex..., in: self),
            withTemplate: ""
        )
        return stripped.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Parses a Dutch-formatted currency string (e.g. `"€ 1.234,56"`) to `Double`.
    func parseDutchCurrency() -> Double? {
        var s = self
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // Dutch format uses `.` as thousands separator and `,` as decimal separator.
        s = s.replacingOccurrences(of: ".", with: "")
        s = s.replacingOccurrences(of: ",", with: ".")
        return Double(s)
    }
}
