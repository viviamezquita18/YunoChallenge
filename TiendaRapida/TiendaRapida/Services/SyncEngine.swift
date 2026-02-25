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

    /// Window (in seconds) for client-side duplicate detection
    private let duplicateWindowSeconds: TimeInterval = 120

    /// Last duplicate warning message for the UI
    var duplicateWarning: String?

    init(connectivity: ConnectivityManager = .shared) {
        self.connectivity = connectivity

        connectivity.onConnectivityRestored = { [weak self] in
            Task { @MainActor in
                self?.syncPendingTransactions()
            }
        }
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Duplicate Detection

    /// Check if a similar transaction was created within the last 2 minutes.
    /// Returns the duplicate if found, nil otherwise.
    /// Uses in-memory filtering to avoid SwiftData #Predicate concurrency warnings.
    private func findDuplicate(amount: Double, currency: Currency, paymentMethod: PaymentMethod, customerName: String) -> Transaction? {
        guard let modelContext else { return nil }
        let cutoff = Date().addingTimeInterval(-duplicateWindowSeconds)

        var descriptor = FetchDescriptor<Transaction>()
        descriptor.fetchLimit = 50

        guard var recent = try? modelContext.fetch(descriptor) else { return nil }
        recent.sort { $0.createdAt > $1.createdAt }

        return recent.first { tx in
            tx.amount == amount
            && tx.currency == currency
            && tx.paymentMethod == paymentMethod
            && tx.customerName == customerName
            && tx.createdAt >= cutoff
        }
    }

    /// Attempts to queue a transaction. Returns `true` if queued, `false` if blocked as duplicate.
    @discardableResult
    func queueTransaction(_ transaction: Transaction) -> Bool {
        guard let modelContext else { return false }

        // Client-side duplicate detection (2-minute window)
        if let dup = findDuplicate(
            amount: transaction.amount,
            currency: transaction.currency,
            paymentMethod: transaction.paymentMethod,
            customerName: transaction.customerName
        ) {
            let ago = Int(Date().timeIntervalSince(dup.createdAt))
            duplicateWarning = "A matching transaction for \(transaction.currency.format(transaction.amount)) was created \(ago)s ago. Duplicate blocked."
            return false
        }

        duplicateWarning = nil
        modelContext.insert(transaction)

        // Transition pending → queued (ready for processor)
        transaction.status = .queued
        try? modelContext.save()

        if connectivity.isEffectivelyOnline {
            syncPendingTransactions()
        }
        return true
    }

    /// Force-queue a transaction even if it looks like a duplicate (user confirmed).
    func forceQueueTransaction(_ transaction: Transaction) {
        guard let modelContext else { return }
        duplicateWarning = nil
        modelContext.insert(transaction)
        transaction.status = .queued
        try? modelContext.save()

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
        transaction.nextRetryAt = nil
        try? modelContext?.save()

        if connectivity.isEffectivelyOnline {
            syncPendingTransactions()
        }
    }

    /// Sync all queued transactions
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

            let descriptor = FetchDescriptor<Transaction>()

            guard var allTransactions = try? modelContext.fetch(descriptor) else {
                return
            }

            allTransactions.sort { $0.createdAt < $1.createdAt }
            let pendingTransactions = allTransactions.filter { $0.status == .queued }

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
                    // Re-queue for automatic retry and compute next retry time
                    transaction.status = .queued
                    transaction.idempotencyKey = UUID().uuidString
                    let nextDelay = baseBackoffDelay * pow(2.0, Double(transaction.retryCount - 1))
                    transaction.nextRetryAt = Date().addingTimeInterval(nextDelay)
                    await paymentService.clearKey(transaction.idempotencyKey)
                } else {
                    // Max retries reached — compute a hypothetical next time for display
                    let nextDelay = baseBackoffDelay * pow(2.0, Double(transaction.retryCount - 1))
                    transaction.nextRetryAt = Date().addingTimeInterval(nextDelay)
                }
            } else {
                transaction.nextRetryAt = nil
            }

            if result.status == .approved {
                syncedCount += 1
            }

            try? modelContext?.save()
        } catch {
            transaction.status = .failed
            transaction.errorMessage = "Processing error: \(error.localizedDescription)"
            transaction.retryCount += 1
            let nextDelay = baseBackoffDelay * pow(2.0, Double(transaction.retryCount - 1))
            transaction.nextRetryAt = Date().addingTimeInterval(nextDelay)
            try? modelContext?.save()
        }
    }

    // MARK: - Seed Data

    /// Pre-seeds 16 sample transactions on first launch, including duplicate pairs.
    func seedSampleDataIfNeeded() {
        guard let modelContext else { return }

        let countDescriptor = FetchDescriptor<Transaction>()
        let count = (try? modelContext.fetchCount(countDescriptor)) ?? 0
        guard count == 0 else { return }

        let samples: [(Double, Currency, PaymentMethod, String, String, TransactionStatus, Date)] = [
            (125.50, .gtq, .cash, "Maria Lopez", "Groceries - rice & beans", .approved, Date().addingTimeInterval(-86400 * 3)),
            (45_000, .cop, .nequi, "Carlos Hernandez", "Phone accessories", .approved, Date().addingTimeInterval(-86400 * 2.5)),
            (89.90, .pen, .yape, "Ana Torres", "School supplies", .approved, Date().addingTimeInterval(-86400 * 2)),
            (320.00, .gtq, .creditCard, "Roberto Mendez", "Electronics - USB cables", .declined, Date().addingTimeInterval(-86400 * 1.8)),
            (15_500, .cop, .debitCard, "Laura Garcia", "Cleaning products", .approved, Date().addingTimeInterval(-86400 * 1.5)),
            (55.00, .pen, .cash, "Diego Ramirez", "Snacks & beverages", .approved, Date().addingTimeInterval(-86400 * 1.2)),
            (210.75, .gtq, .bankTransfer, "Patricia Flores", "Medicine - pharmacy", .failed, Date().addingTimeInterval(-86400)),
            (78_200, .cop, .nequi, "Fernando Diaz", "Clothing - t-shirts", .approved, Date().addingTimeInterval(-43200)),
            (42.30, .pen, .yape, "Sofia Vargas", "Bread & pastries", .approved, Date().addingTimeInterval(-21600)),
            (175.00, .usd, .creditCard, "Miguel Santos", "Hardware tools", .queued, Date().addingTimeInterval(-7200)),
            (38_900, .cop, .mobileWallet, "Isabella Cruz", "Cosmetics", .pending, Date().addingTimeInterval(-3600)),
            (95.00, .gtq, .cash, "Andres Morales", "Fresh produce", .pending, Date().addingTimeInterval(-1800)),
            // Duplicate pair: two identical Nequi payments within 30s (cashier double-tap scenario)
            (25_000, .cop, .nequi, "Camila Restrepo", "Water bottles", .approved, Date().addingTimeInterval(-60)),
            (25_000, .cop, .nequi, "Camila Restrepo", "Water bottles", .queued, Date().addingTimeInterval(-30)),
            // Duplicate pair: same Yape cash-out seconds apart
            (150.00, .pen, .yape, "Jorge Quispe", "Bus ticket refund", .approved, Date().addingTimeInterval(-45)),
            (150.00, .pen, .yape, "Jorge Quispe", "Bus ticket refund", .pending, Date().addingTimeInterval(-10)),
        ]

        for (amount, currency, method, name, desc, status, date) in samples {
            let tx = Transaction(
                amount: amount,
                currency: currency,
                paymentMethod: method,
                customerName: name,
                itemDescription: desc
            )
            tx.status = status
            tx.createdAt = date
            if status == .approved || status == .declined || status == .failed {
                tx.processedAt = date.addingTimeInterval(Double.random(in: 1...5))
            }
            if status == .declined {
                tx.errorMessage = "Insufficient funds"
            }
            if status == .failed {
                tx.errorMessage = "Gateway unavailable"
                tx.retryCount = 1
                tx.nextRetryAt = Date().addingTimeInterval(2)
            }
            modelContext.insert(tx)
        }

        try? modelContext.save()
    }
}
