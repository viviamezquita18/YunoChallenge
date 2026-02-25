import Testing
import Foundation
@testable import TiendaRapida

@Suite("TransactionFilter & TransactionSort")
struct TransactionFilterTests {

    // MARK: - Filter

    @Test("Filter has 7 cases including pending")
    func filterCasesCount() {
        #expect(TransactionFilter.allCases.count == 7)
    }

    @Test("All filter returns nil status")
    func allFilterReturnsNilStatus() {
        #expect(TransactionFilter.all.status == nil)
    }

    @Test("Pending filter maps to .pending status")
    func pendingFilterMapsCorrectly() {
        #expect(TransactionFilter.pending.status == .pending)
    }

    @Test("Each non-all filter maps to its matching status")
    func filtersMapToCorrectStatus() {
        #expect(TransactionFilter.queued.status == .queued)
        #expect(TransactionFilter.processing.status == .processing)
        #expect(TransactionFilter.approved.status == .approved)
        #expect(TransactionFilter.declined.status == .declined)
        #expect(TransactionFilter.failed.status == .failed)
    }

    // MARK: - Sort

    @Test("Sort has 4 cases")
    func sortCasesCount() {
        #expect(TransactionSort.allCases.count == 4)
    }

    @Test("Sort raw values are human-readable", arguments: TransactionSort.allCases)
    func sortRawValues(sort: TransactionSort) {
        #expect(!sort.rawValue.isEmpty)
        #expect(sort.rawValue.count > 5)
    }

    // MARK: - TransactionListViewModel filtering

    @Test("filteredAndSorted returns all when filter is .all")
    @MainActor
    func filterAllReturnsEverything() {
        let engine = SyncEngine()
        let vm = TransactionListViewModel(syncEngine: engine)
        vm.selectedFilter = .all

        let transactions = [
            makeTransaction(status: .approved),
            makeTransaction(status: .failed),
            makeTransaction(status: .pending),
        ]
        let result = vm.filteredAndSorted(transactions)
        #expect(result.count == 3)
    }

    @Test("filteredAndSorted filters by status correctly")
    @MainActor
    func filterByStatus() {
        let engine = SyncEngine()
        let vm = TransactionListViewModel(syncEngine: engine)
        vm.selectedFilter = .approved

        let transactions = [
            makeTransaction(status: .approved),
            makeTransaction(status: .approved),
            makeTransaction(status: .failed),
            makeTransaction(status: .pending),
        ]
        let result = vm.filteredAndSorted(transactions)
        #expect(result.count == 2)
        #expect(result.allSatisfy { $0.status == .approved })
    }

    @Test("filteredAndSorted filters by search text (customer name)")
    @MainActor
    func filterBySearch() {
        let engine = SyncEngine()
        let vm = TransactionListViewModel(syncEngine: engine)
        vm.searchText = "maria"

        let transactions = [
            makeTransaction(name: "Maria Lopez", status: .approved),
            makeTransaction(name: "Carlos Diaz", status: .approved),
        ]
        let result = vm.filteredAndSorted(transactions)
        #expect(result.count == 1)
        #expect(result.first?.customerName == "Maria Lopez")
    }

    @Test("filteredAndSorted sorts by amount high to low")
    @MainActor
    func sortByAmountDesc() {
        let engine = SyncEngine()
        let vm = TransactionListViewModel(syncEngine: engine)
        vm.selectedSort = .amountHighToLow

        let transactions = [
            makeTransaction(amount: 50, status: .approved),
            makeTransaction(amount: 200, status: .approved),
            makeTransaction(amount: 100, status: .approved),
        ]
        let result = vm.filteredAndSorted(transactions)
        #expect(result[0].amount == 200)
        #expect(result[1].amount == 100)
        #expect(result[2].amount == 50)
    }

    @Test("filteredAndSorted sorts by amount low to high")
    @MainActor
    func sortByAmountAsc() {
        let engine = SyncEngine()
        let vm = TransactionListViewModel(syncEngine: engine)
        vm.selectedSort = .amountLowToHigh

        let transactions = [
            makeTransaction(amount: 50, status: .approved),
            makeTransaction(amount: 200, status: .approved),
            makeTransaction(amount: 100, status: .approved),
        ]
        let result = vm.filteredAndSorted(transactions)
        #expect(result[0].amount == 50)
        #expect(result[1].amount == 100)
        #expect(result[2].amount == 200)
    }

    @Test("statusCounts returns correct counts for each status")
    @MainActor
    func statusCounts() {
        let engine = SyncEngine()
        let vm = TransactionListViewModel(syncEngine: engine)

        let transactions = [
            makeTransaction(status: .approved),
            makeTransaction(status: .approved),
            makeTransaction(status: .failed),
            makeTransaction(status: .pending),
            makeTransaction(status: .queued),
        ]
        let counts = vm.statusCounts(transactions)
        #expect(counts[.approved] == 2)
        #expect(counts[.failed] == 1)
        #expect(counts[.pending] == 1)
        #expect(counts[.queued] == 1)
        #expect(counts[.processing] == 0)
        #expect(counts[.declined] == 0)
    }

    // MARK: - Helpers

    private func makeTransaction(
        amount: Double = 100,
        name: String = "Test",
        status: TransactionStatus
    ) -> Transaction {
        let tx = Transaction(amount: amount, currency: .gtq, paymentMethod: .cash, customerName: name, itemDescription: "Item")
        tx.status = status
        return tx
    }
}
