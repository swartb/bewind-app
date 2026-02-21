import SwiftUI

struct ContentView: View {
    /// Shared cookie jar – created here so both the Portal tab and the Dashboard
    /// have access to the same authenticated session cookies.
    @StateObject private var cookieJar = CookieJar()

    var body: some View {
        TabView {
            WebViewTab()
                .environmentObject(cookieJar)
                .tabItem {
                    Label("Portal", systemImage: "globe")
                }

            DashboardView()
                .environmentObject(cookieJar)
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar")
                }
        }
    }
}

#Preview {
    ContentView()
}
