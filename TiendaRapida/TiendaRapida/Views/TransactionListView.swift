import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Query(sort: \Transaction.createdAt, order: .reverse) private var allTransactions: [Transaction]
    @Bindable var viewModel: TransactionListViewModel
    let syncEngine: SyncEngine
    let connectivity: ConnectivityManager

    @State private var showingNewTransaction = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ConnectivityBannerView(connectivity: connectivity)

                // Stats bar
                statsBar

                // Filter chips
                filterBar

                // Transaction list
                if viewModel.filteredAndSorted(allTransactions).isEmpty {
                    emptyState
                } else {
                    transactionList
                }
            }
            .navigationTitle("Tienda Rapida")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Toggle("Simulate Offline", isOn: Bindable(connectivity).isSimulatingOffline)

                        Divider()

                        Button {
                            viewModel.syncNow()
                        } label: {
                            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .disabled(!connectivity.isEffectivelyOnline)

                        Divider()

                        Picker("Sort By", selection: $viewModel.selectedSort) {
                            ForEach(TransactionSort.allCases) { sort in
                                Text(sort.rawValue).tag(sort)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search transactions")
            .sheet(isPresented: $showingNewTransaction) {
                TransactionFormView(
                    viewModel: TransactionFormViewModel(
                        syncEngine: syncEngine,
                        connectivity: connectivity
                    )
                )
            }
        }
    }

    // MARK: - Stats Bar

    private var statsBar: some View {
        let counts = viewModel.statusCounts(allTransactions)
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                statBadge(
                    title: "Total",
                    count: allTransactions.count,
                    color: .primary
                )
                statBadge(
                    title: "Queued",
                    count: counts[.queued] ?? 0,
                    color: .orange
                )
                statBadge(
                    title: "Processing",
                    count: counts[.processing] ?? 0,
                    color: .blue
                )
                statBadge(
                    title: "Approved",
                    count: counts[.approved] ?? 0,
                    color: .green
                )
                statBadge(
                    title: "Declined",
                    count: counts[.declined] ?? 0,
                    color: .red
                )
                statBadge(
                    title: "Failed",
                    count: counts[.failed] ?? 0,
                    color: .purple
                )

                if syncEngine.isSyncing {
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.mini)
                        Text("Syncing...")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func statBadge(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 50)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TransactionFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.subheadline)
                            .fontWeight(viewModel.selectedFilter == filter ? .semibold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                viewModel.selectedFilter == filter
                                    ? Color.accentColor.opacity(0.15)
                                    : Color(.tertiarySystemFill)
                            )
                            .foregroundStyle(
                                viewModel.selectedFilter == filter
                                    ? Color.accentColor
                                    : .secondary
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        List {
            ForEach(viewModel.filteredAndSorted(allTransactions)) { transaction in
                TransactionRowView(transaction: transaction) {
                    viewModel.retryTransaction(transaction)
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.syncNow()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: viewModel.selectedFilter == .all ? "tray" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            if viewModel.selectedFilter == .all && allTransactions.isEmpty {
                Text("No Transactions Yet")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Tap + to create your first transaction.\nIt will be queued even if you're offline.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No \(viewModel.selectedFilter.rawValue) Transactions")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Try a different filter or create a new transaction.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
