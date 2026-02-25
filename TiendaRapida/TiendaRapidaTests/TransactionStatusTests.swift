import Testing
import Foundation
@testable import TiendaRapida

@Suite("TransactionStatus")
struct TransactionStatusTests {

    // MARK: - Raw Values

    @Test("All status raw values are correct")
    func rawValues() {
        #expect(TransactionStatus.pending.rawValue == "pending")
        #expect(TransactionStatus.queued.rawValue == "queued")
        #expect(TransactionStatus.processing.rawValue == "processing")
        #expect(TransactionStatus.approved.rawValue == "approved")
        #expect(TransactionStatus.declined.rawValue == "declined")
        #expect(TransactionStatus.failed.rawValue == "failed")
    }

    @Test("CaseIterable has 6 cases")
    func allCasesCount() {
        #expect(TransactionStatus.allCases.count == 6)
    }

    // MARK: - Display Names

    @Test("Display names are capitalized English", arguments: TransactionStatus.allCases)
    func displayNames(status: TransactionStatus) {
        #expect(!status.displayName.isEmpty)
        #expect(status.displayName.first?.isUppercase == true)
    }

    // MARK: - Icon Names

    @Test("All statuses have non-empty SF Symbol icon names", arguments: TransactionStatus.allCases)
    func iconNames(status: TransactionStatus) {
        #expect(!status.iconName.isEmpty)
    }

    // MARK: - Colors

    @Test("All statuses have non-empty color names", arguments: TransactionStatus.allCases)
    func colorNames(status: TransactionStatus) {
        #expect(!status.color.isEmpty)
    }

    @Test("Each status has a unique color")
    func uniqueColors() {
        let colors = TransactionStatus.allCases.map(\.color)
        #expect(Set(colors).count == colors.count)
    }

    // MARK: - isWaiting

    @Test("Pending is waiting")
    func pendingIsWaiting() {
        #expect(TransactionStatus.pending.isWaiting == true)
    }

    @Test("Queued is waiting")
    func queuedIsWaiting() {
        #expect(TransactionStatus.queued.isWaiting == true)
    }

    @Test("Processing is waiting")
    func processingIsWaiting() {
        #expect(TransactionStatus.processing.isWaiting == true)
    }

    @Test("Approved is not waiting")
    func approvedIsNotWaiting() {
        #expect(TransactionStatus.approved.isWaiting == false)
    }

    @Test("Declined is not waiting")
    func declinedIsNotWaiting() {
        #expect(TransactionStatus.declined.isWaiting == false)
    }

    @Test("Failed is not waiting")
    func failedIsNotWaiting() {
        #expect(TransactionStatus.failed.isWaiting == false)
    }

    // MARK: - canRetry

    @Test("Only failed status can retry")
    func onlyFailedCanRetry() {
        for status in TransactionStatus.allCases {
            if status == .failed {
                #expect(status.canRetry == true)
            } else {
                #expect(status.canRetry == false)
            }
        }
    }
}
