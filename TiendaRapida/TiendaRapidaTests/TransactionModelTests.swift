import Testing
import Foundation
import SwiftData
@testable import TiendaRapida

@Suite("Transaction Model")
struct TransactionModelTests {

    // MARK: - Initialization

    @Test("New transaction starts with pending status")
    func initialStatusIsPending() {
        let tx = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "Test", itemDescription: "Item")
        #expect(tx.status == .pending)
        #expect(tx.statusRaw == "pending")
    }

    @Test("New transaction has zero retry count")
    func initialRetryCountIsZero() {
        let tx = Transaction(amount: 50, currency: .cop, paymentMethod: .nequi, customerName: "Ana", itemDescription: "Desc")
        #expect(tx.retryCount == 0)
    }

    @Test("New transaction has no processedAt date")
    func initialProcessedAtIsNil() {
        let tx = Transaction(amount: 50, currency: .pen, paymentMethod: .yape, customerName: "Luis", itemDescription: "Desc")
        #expect(tx.processedAt == nil)
    }

    @Test("New transaction has no error message")
    func initialErrorMessageIsNil() {
        let tx = Transaction(amount: 50, currency: .usd, paymentMethod: .creditCard, customerName: "Bob", itemDescription: "Desc")
        #expect(tx.errorMessage == nil)
    }

    @Test("New transaction has no nextRetryAt")
    func initialNextRetryAtIsNil() {
        let tx = Transaction(amount: 50, currency: .gtq, paymentMethod: .cash, customerName: "Test", itemDescription: "Item")
        #expect(tx.nextRetryAt == nil)
    }

    @Test("New transaction generates unique UUID")
    func uniqueIds() {
        let tx1 = Transaction(amount: 10, currency: .gtq, paymentMethod: .cash, customerName: "A", itemDescription: "X")
        let tx2 = Transaction(amount: 10, currency: .gtq, paymentMethod: .cash, customerName: "A", itemDescription: "X")
        #expect(tx1.id != tx2.id)
    }

    @Test("New transaction generates unique idempotency key")
    func uniqueIdempotencyKeys() {
        let tx1 = Transaction(amount: 10, currency: .gtq, paymentMethod: .cash, customerName: "A", itemDescription: "X")
        let tx2 = Transaction(amount: 10, currency: .gtq, paymentMethod: .cash, customerName: "A", itemDescription: "X")
        #expect(tx1.idempotencyKey != tx2.idempotencyKey)
    }

    // MARK: - Computed Properties

    @Test("Currency computed property reads and writes raw value")
    func currencyComputedProperty() {
        let tx = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "T", itemDescription: "I")
        #expect(tx.currency == .gtq)
        #expect(tx.currencyRaw == "GTQ")
        tx.currency = .cop
        #expect(tx.currencyRaw == "COP")
    }

    @Test("PaymentMethod computed property reads and writes raw value")
    func paymentMethodComputedProperty() {
        let tx = Transaction(amount: 100, currency: .gtq, paymentMethod: .nequi, customerName: "T", itemDescription: "I")
        #expect(tx.paymentMethod == .nequi)
        #expect(tx.paymentMethodRaw == "nequi")
        tx.paymentMethod = .yape
        #expect(tx.paymentMethodRaw == "yape")
    }

    @Test("Status computed property reads and writes raw value")
    func statusComputedProperty() {
        let tx = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "T", itemDescription: "I")
        tx.status = .approved
        #expect(tx.statusRaw == "approved")
        tx.statusRaw = "failed"
        #expect(tx.status == .failed)
    }

    @Test("formattedProcessedDate returns nil when not processed")
    func formattedProcessedDateNilWhenUnprocessed() {
        let tx = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "T", itemDescription: "I")
        #expect(tx.formattedProcessedDate == nil)
    }

    @Test("formattedProcessedDate returns string when processed")
    func formattedProcessedDateReturnsValue() {
        let tx = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "T", itemDescription: "I")
        tx.processedAt = Date()
        #expect(tx.formattedProcessedDate != nil)
    }

    // MARK: - Next Retry Formatting

    @Test("formattedNextRetry returns nil when status is not failed")
    func nextRetryNilWhenNotFailed() {
        let tx = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "T", itemDescription: "I")
        tx.status = .approved
        tx.nextRetryAt = Date().addingTimeInterval(30)
        #expect(tx.formattedNextRetry == nil)
    }

    @Test("formattedNextRetry returns nil when nextRetryAt is nil")
    func nextRetryNilWhenDateNil() {
        let tx = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "T", itemDescription: "I")
        tx.status = .failed
        tx.nextRetryAt = nil
        #expect(tx.formattedNextRetry == nil)
    }

    @Test("formattedNextRetry shows seconds when under 60s")
    func nextRetryShowsSeconds() {
        let tx = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "T", itemDescription: "I")
        tx.status = .failed
        tx.nextRetryAt = Date().addingTimeInterval(30)
        let result = tx.formattedNextRetry
        #expect(result != nil)
        #expect(result!.contains("Next retry in"))
        #expect(result!.contains("s"))
        #expect(!result!.contains("m"))
    }

    @Test("formattedNextRetry shows minutes when over 60s")
    func nextRetryShowsMinutes() {
        let tx = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "T", itemDescription: "I")
        tx.status = .failed
        tx.nextRetryAt = Date().addingTimeInterval(90)
        let result = tx.formattedNextRetry
        #expect(result != nil)
        #expect(result!.contains("m"))
    }

    @Test("formattedNextRetry shows 'Retry imminent' when past due")
    func nextRetryImminentWhenPastDue() {
        let tx = Transaction(amount: 100, currency: .gtq, paymentMethod: .cash, customerName: "T", itemDescription: "I")
        tx.status = .failed
        tx.nextRetryAt = Date().addingTimeInterval(-5)
        #expect(tx.formattedNextRetry == "Retry imminent")
    }
}
