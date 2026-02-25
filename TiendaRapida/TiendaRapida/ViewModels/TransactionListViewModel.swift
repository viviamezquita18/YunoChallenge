import Foundation
import SwiftData
import Observation

enum TransactionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pending = "Pending"
    case queued = "Queued"
    case processing = "Processing"
    case approved = "Approved"
    case declined = "Declined"
    case failed = "Failed"

    var id: String { rawValue }

    var status: TransactionStatus? {
        switch self {
        case .all: return nil
        case .pending: return .pending
        case .queued: return .queued
        case .processing: return .processing
        case .approved: return .approved
        case .declined: return .declined
        case .failed: return .failed
        }
    }
}

enum TransactionSort: String, CaseIterable, Identifiable {
    case newestFirst = "Newest First"
    case oldestFirst = "Oldest First"
    case amountHighToLow = "Amount: High to Low"
    case amountLowToHigh = "Amount: Low to High"

    var id: String { rawValue }
}

@Observable
@MainActor
final class TransactionListViewModel {
    var selectedFilter: TransactionFilter = .all
    var selectedSort: TransactionSort = .newestFirst
    var searchText: String = ""

    private let syncEngine: SyncEngine

    init(syncEngine: SyncEngine) {
        self.syncEngine = syncEngine
    }

    func retryTransaction(_ transaction: Transaction) {
        syncEngine.retryTransaction(transaction)
    }

    func syncNow() {
        syncEngine.syncPendingTransactions()
    }

    func filteredAndSorted(_ transactions: [Transaction]) -> [Transaction] {
        var result = transactions

        // Apply status filter
        if let status = selectedFilter.status {
            result = result.filter { $0.status == status }
        }

        // Apply search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.customerName.lowercased().contains(query)
                || $0.itemDescription.lowercased().contains(query)
                || $0.id.uuidString.lowercased().contains(query)
            }
        }

        // Apply sort
        switch selectedSort {
        case .newestFirst:
            result.sort { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            result.sort { $0.createdAt < $1.createdAt }
        case .amountHighToLow:
            result.sort { $0.amount > $1.amount }
        case .amountLowToHigh:
            result.sort { $0.amount < $1.amount }
        }

        return result
    }

    func statusCounts(_ transactions: [Transaction]) -> [TransactionStatus: Int] {
        var counts: [TransactionStatus: Int] = [:]
        for status in TransactionStatus.allCases {
            counts[status] = transactions.filter { $0.status == status }.count
        }
        return counts
    }
}
