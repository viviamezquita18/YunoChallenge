import SwiftUI

struct TransactionRowView: View {
    let transaction: Transaction
    var onRetry: (() -> Void)?

    private var statusColor: Color {
        switch transaction.status {
        case .pending: return .gray
        case .queued: return .orange
        case .processing: return .blue
        case .approved: return .green
        case .declined: return .red
        case .failed: return .purple
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: customer + amount
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.customerName)
                        .font(.headline)
                    Text(transaction.itemDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(transaction.formattedAmount)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            // Bottom row: status + payment method + date
            HStack(spacing: 12) {
                // Status badge
                HStack(spacing: 4) {
                    if transaction.status == .processing {
                        ProgressView()
                            .controlSize(.mini)
                    } else {
                        Image(systemName: transaction.status.iconName)
                            .font(.caption)
                    }
                    Text(transaction.status.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.15))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())

                // Payment method
                HStack(spacing: 4) {
                    Image(systemName: transaction.paymentMethod.iconName)
                        .font(.caption)
                    Text(transaction.paymentMethod.displayName)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                Spacer()

                // Date
                Text(transaction.formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Error message + retry
            if let errorMessage = transaction.errorMessage,
               (transaction.status == .failed || transaction.status == .declined) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text(errorMessage)
                        .font(.caption)

                    Spacer()

                    if transaction.status.canRetry, let onRetry {
                        Button(action: onRetry) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption)
                                Text("Retry")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.mini)
                        .tint(.purple)
                    }
                }
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }

            // Retry count + next retry time
            if transaction.retryCount > 0 {
                HStack(spacing: 8) {
                    Text("Retry attempt: \(transaction.retryCount)/\(3)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if let nextRetryText = transaction.formattedNextRetry {
                        HStack(spacing: 3) {
                            Image(systemName: "timer")
                                .font(.caption2)
                            Text(nextRetryText)
                                .font(.caption2)
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
