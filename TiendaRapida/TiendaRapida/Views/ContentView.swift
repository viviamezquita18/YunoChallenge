import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var syncEngine = SyncEngine()
    @State private var connectivity = ConnectivityManager.shared
    @State private var listViewModel: TransactionListViewModel?

    var body: some View {
        Group {
            if let listViewModel {
                TransactionListView(
                    viewModel: listViewModel,
                    syncEngine: syncEngine,
                    connectivity: connectivity
                )
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            syncEngine.configure(modelContext: modelContext)
            syncEngine.seedSampleDataIfNeeded()
            listViewModel = TransactionListViewModel(syncEngine: syncEngine)
            // Attempt to sync any transactions queued from a previous session
            syncEngine.syncPendingTransactions()
        }
    }
}
