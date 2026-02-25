import Foundation
import SwiftData

enum TransactionStatus: String, Codable, CaseIterable, Identifiable {
    case queued = "queued"
    case processing = "processing"
    case approved = "approved"
    case declined = "declined"
    case failed = "failed"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .queued: return "Queued"
        case .processing: return "Processing"
        case .approved: return "Approved"
        case .declined: return "Declined"
        case .failed: return "Failed"
        }
    }

    var iconName: String {
        switch self {
        case .queued: return "clock.fill"
        case .processing: return "arrow.triangle.2.circlepath"
        case .approved: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    var color: String {
        switch self {
        case .queued: return "orange"
        case .processing: return "blue"
        case .approved: return "green"
        case .declined: return "red"
        case .failed: return "purple"
        }
    }

    var isPending: Bool {
        self == .queued || self == .processing
    }

    var canRetry: Bool {
        self == .failed
    }
}

@Model
final class Transaction {
    var id: UUID
    var amount: Double
    var currencyRaw: String
    var paymentMethodRaw: String
    var statusRaw: String
    var customerName: String
    var itemDescription: String
    var createdAt: Date
    var processedAt: Date?
    var retryCount: Int
    var idempotencyKey: String
    var errorMessage: String?

    var currency: Currency {
        get { Currency(rawValue: currencyRaw) ?? .usd }
        set { currencyRaw = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .cash }
        set { paymentMethodRaw = newValue.rawValue }
    }

    var status: TransactionStatus {
        get { TransactionStatus(rawValue: statusRaw) ?? .queued }
        set { statusRaw = newValue.rawValue }
    }

    var formattedAmount: String {
        currency.format(amount)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var formattedProcessedDate: String? {
        guard let processedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: processedAt)
    }

    init(
        amount: Double,
        currency: Currency,
        paymentMethod: PaymentMethod,
        customerName: String,
        itemDescription: String
    ) {
        self.id = UUID()
        self.amount = amount
        self.currencyRaw = currency.rawValue
        self.paymentMethodRaw = paymentMethod.rawValue
        self.statusRaw = TransactionStatus.queued.rawValue
        self.customerName = customerName
        self.itemDescription = itemDescription
        self.createdAt = Date()
        self.processedAt = nil
        self.retryCount = 0
        self.idempotencyKey = UUID().uuidString
        self.errorMessage = nil
    }
}
