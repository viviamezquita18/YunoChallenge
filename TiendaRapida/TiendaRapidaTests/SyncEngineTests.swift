import Testing
import Foundation
import SwiftData
@testable import TiendaRapida

@Suite("SyncEngine", .serialized)
@MainActor
struct SyncEngineTests {

    // Helper: create an in-memory SwiftData container + context
    private func makeContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Transaction.self, configurations: config)
        return ModelContext(container)
    }

    // MARK: - Queue Transaction

    @Test("queueTransaction transitions pending to queued")
    func queueTransitionsPendingToQueued() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        let tx = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "Test", itemDescription: "Item")
        #expect(tx.status == .pending)

        let queued = engine.queueTransaction(tx)
        #expect(queued == true)
        #expect(tx.status == .queued)
    }

    @Test("queueTransaction persists transaction to SwiftData")
    func queuePersistsTransaction() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        let tx = Transaction(amount: 250, currency: .cop, paymentMethod: .nequi, customerName: "Ana", itemDescription: "Groceries")
        engine.queueTransaction(tx)

        let descriptor = FetchDescriptor<Transaction>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.customerName == "Ana")
        #expect(fetched.first?.amount == 250)
    }

    // MARK: - Duplicate Detection

    @Test("Duplicate within 2 minutes is blocked")
    func duplicateBlocked() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        let tx1 = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "Maria", itemDescription: "Rice")
        let queued1 = engine.queueTransaction(tx1)
        #expect(queued1 == true)

        // Same amount, currency, method, customer — should be blocked
        let tx2 = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "Maria", itemDescription: "Rice")
        let queued2 = engine.queueTransaction(tx2)
        #expect(queued2 == false)
        #expect(engine.duplicateWarning != nil)
    }

    @Test("Different amount is not a duplicate")
    func differentAmountNotDuplicate() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        let tx1 = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "Maria", itemDescription: "Rice")
        engine.queueTransaction(tx1)

        let tx2 = Transaction(amount: 200, currency: .gtq, paymentMethod: .cash, customerName: "Maria", itemDescription: "Beans")
        let queued2 = engine.queueTransaction(tx2)
        #expect(queued2 == true)
    }

    @Test("Different customer is not a duplicate")
    func differentCustomerNotDuplicate() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        let tx1 = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "Maria", itemDescription: "Rice")
        engine.queueTransaction(tx1)

        let tx2 = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "Carlos", itemDescription: "Rice")
        let queued2 = engine.queueTransaction(tx2)
        #expect(queued2 == true)
    }

    @Test("Different currency is not a duplicate")
    func differentCurrencyNotDuplicate() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        let tx1 = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "Maria", itemDescription: "Rice")
        engine.queueTransaction(tx1)

        let tx2 = Transaction(amount: 100, currency: .cop, paymentMethod: .cash, customerName: "Maria", itemDescription: "Rice")
        let queued2 = engine.queueTransaction(tx2)
        #expect(queued2 == true)
    }

    @Test("Different payment method is not a duplicate")
    func differentPaymentMethodNotDuplicate() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        let tx1 = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "Maria", itemDescription: "Rice")
        engine.queueTransaction(tx1)

        let tx2 = Transaction(amount: 100, currency: .gtq, paymentMethod: .nequi, customerName: "Maria", itemDescription: "Rice")
        let queued2 = engine.queueTransaction(tx2)
        #expect(queued2 == true)
    }

    @Test("forceQueueTransaction bypasses duplicate detection")
    func forceQueueBypassesDuplicateCheck() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        let tx1 = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "Maria", itemDescription: "Rice")
        engine.queueTransaction(tx1)

        let tx2 = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "Maria", itemDescription: "Rice")
        engine.forceQueueTransaction(tx2)

        let descriptor = FetchDescriptor<Transaction>()
        let all = try context.fetch(descriptor)
        #expect(all.count == 2)
    }

    // MARK: - Retry

    @Test("retryTransaction resets failed to queued")
    func retryResetsStatus() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        let tx = Transaction(amount: 50, currency: .pen, paymentMethod: .yape, customerName: "Luis", itemDescription: "Ticket")
        context.insert(tx)
        tx.status = .failed
        tx.errorMessage = "Network timeout"
        tx.nextRetryAt = Date()
        let oldKey = tx.idempotencyKey

        engine.retryTransaction(tx)

        #expect(tx.status == .queued)
        #expect(tx.errorMessage == nil)
        #expect(tx.nextRetryAt == nil)
        #expect(tx.idempotencyKey != oldKey)
    }

    @Test("retryTransaction ignores non-failed transactions")
    func retryIgnoresNonFailed() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        let tx = Transaction(amount: 50, currency: .pen, paymentMethod: .yape, customerName: "Luis", itemDescription: "Ticket")
        context.insert(tx)
        tx.status = .approved

        engine.retryTransaction(tx)
        #expect(tx.status == .approved) // unchanged
    }

    // MARK: - Seed Data

    @Test("seedSampleDataIfNeeded inserts 16 transactions on empty DB")
    func seedDataInsertsOnEmpty() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        engine.seedSampleDataIfNeeded()

        let descriptor = FetchDescriptor<Transaction>()
        let all = try context.fetch(descriptor)
        #expect(all.count == 16)
    }

    @Test("seedSampleDataIfNeeded does not duplicate on second call")
    func seedDataIdempotent() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        engine.seedSampleDataIfNeeded()
        engine.seedSampleDataIfNeeded()

        let descriptor = FetchDescriptor<Transaction>()
        let all = try context.fetch(descriptor)
        #expect(all.count == 16)
    }

    @Test("Seed data includes Nequi and Yape payment methods")
    func seedDataIncludesNequiYape() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        engine.seedSampleDataIfNeeded()

        let descriptor = FetchDescriptor<Transaction>()
        let all = try context.fetch(descriptor)
        let methods = Set(all.map(\.paymentMethod))
        #expect(methods.contains(.nequi))
        #expect(methods.contains(.yape))
    }

    @Test("Seed data includes duplicate pairs")
    func seedDataHasDuplicates() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        engine.seedSampleDataIfNeeded()

        let descriptor = FetchDescriptor<Transaction>()
        let all = try context.fetch(descriptor)
        let camilas = all.filter { $0.customerName == "Camila Restrepo" }
        #expect(camilas.count == 2)
        #expect(camilas[0].amount == camilas[1].amount)

        let jorges = all.filter { $0.customerName == "Jorge Quispe" }
        #expect(jorges.count == 2)
    }

    @Test("Seed data contains all status types")
    func seedDataHasAllStatuses() throws {
        let context = try makeContext()
        let engine = SyncEngine()
        engine.configure(modelContext: context)

        engine.seedSampleDataIfNeeded()

        let descriptor = FetchDescriptor<Transaction>()
        let all = try context.fetch(descriptor)
        let statuses = Set(all.map(\.status))
        #expect(statuses.contains(.pending))
        #expect(statuses.contains(.queued))
        #expect(statuses.contains(.approved))
        #expect(statuses.contains(.declined))
        #expect(statuses.contains(.failed))
    }
}
