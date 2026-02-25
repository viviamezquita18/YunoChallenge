import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class SyncEngine {
    private let connectivity: ConnectivityManager
    private let paymentService = MockPaymentService.shared
    private var modelContext: ModelContext?

    private(set) var isSyncing: Bool = false
    private(set) var syncedCount: Int = 0
    private(set) var lastSyncDate: Date?

    /// Maximum retry attempts before giving up
    let maxRetries = 3

    /// Base delay for exponential backoff (seconds)
    let baseBackoffDelay: TimeInterval = 1.0

    init(connectivity: ConnectivityManager = .shared) {
        self.connectivity = connectivity

        // Register for connectivity restored events
        connectivity.onConnectivityRestored = { [weak self] in
            Task { @MainActor in
                self?.syncPendingTransactions()
            }
        }
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Queue a new transaction — persists immediately via SwiftData
    func queueTransaction(_ transaction: Transaction) {
        guard let modelContext else { return }
        modelContext.insert(transaction)
        try? modelContext.save()

        // If online, start syncing immediately
        if connectivity.isEffectivelyOnline {
            syncPendingTransactions()
        }
    }

    /// Retry a specific failed transaction with a new idempotency key
    func retryTransaction(_ transaction: Transaction) {
        guard transaction.status == .failed else { return }
        transaction.status = .queued
        transaction.idempotencyKey = UUID().uuidString
        transaction.errorMessage = nil
        try? modelContext?.save()

        if connectivity.isEffectivelyOnline {
            syncPendingTransactions()
        }
    }

    /// Sync all pending (queued) transactions
    func syncPendingTransactions() {
        guard !isSyncing else { return }
        guard connectivity.isEffectivelyOnline else { return }
        guard let modelContext else { return }

        isSyncing = true

        Task {
            defer {
                isSyncing = false
                lastSyncDate = Date()
            }

            let pendingDescriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate<Transaction> { tx in
                    tx.statusRaw == "queued"
                },
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )

            guard let pendingTransactions = try? modelContext.fetch(pendingDescriptor) else {
                return
            }

            for transaction in pendingTransactions {
                guard connectivity.isEffectivelyOnline else { break }

                await processTransaction(transaction)
            }
        }
    }

    private func processTransaction(_ transaction: Transaction) async {
        transaction.status = .processing
        try? modelContext?.save()

        // Exponential backoff delay for retries
        if transaction.retryCount > 0 {
            let delay = baseBackoffDelay * pow(2.0, Double(transaction.retryCount - 1))
            let jitter = Double.random(in: 0...0.5)
            try? await Task.sleep(for: .seconds(delay + jitter))
        }

        do {
            let result = try await paymentService.processPayment(
                amount: transaction.amount,
                currency: transaction.currencyRaw,
                paymentMethod: transaction.paymentMethodRaw,
                idempotencyKey: transaction.idempotencyKey
            )

            transaction.status = result.status
            transaction.processedAt = Date()
            transaction.errorMessage = result.message

            if result.status == .failed {
                transaction.retryCount += 1
                if transaction.retryCount < maxRetries {
                    // Re-queue for automatic retry
                    transaction.status = .queued
                    transaction.idempotencyKey = UUID().uuidString
                    // Clear cached key so retry gets a fresh outcome
                    await paymentService.clearKey(transaction.idempotencyKey)
                }
            }

            if result.status == .approved {
                syncedCount += 1
            }

            try? modelContext?.save()
        } catch {
            transaction.status = .failed
            transaction.errorMessage = "Processing error: \(error.localizedDescription)"
            transaction.retryCount += 1
            try? modelContext?.save()
        }
    }
}
