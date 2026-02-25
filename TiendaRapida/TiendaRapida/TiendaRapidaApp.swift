import SwiftUI
import SwiftData

@main
struct TiendaRapidaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Transaction.self)
    }
}
