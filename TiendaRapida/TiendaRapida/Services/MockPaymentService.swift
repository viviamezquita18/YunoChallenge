import Foundation

/// Simulates a payment gateway with configurable latency and outcomes.
/// Outcomes: 70% approved, 20% declined, 10% failed (network/server error).
actor MockPaymentService {
    static let shared = MockPaymentService()

    /// Minimum simulated network delay in seconds
    var minDelay: TimeInterval = 0.5

    /// Maximum simulated network delay in seconds
    var maxDelay: TimeInterval = 2.0

    struct PaymentResult {
        let status: TransactionStatus
        let message: String?
    }

    /// Process a payment transaction with simulated delay and random outcome.
    /// Uses the idempotency key to ensure duplicate requests return the same result.
    func processPayment(
        amount: Double,
        currency: String,
        paymentMethod: String,
        idempotencyKey: String
    ) async throws -> PaymentResult {
        // Check for duplicate using idempotency key
        if let cached = processedKeys[idempotencyKey] {
            return cached
        }

        // Simulate network latency
        let delay = Double.random(in: minDelay...maxDelay)
        try await Task.sleep(for: .seconds(delay))

        // Determine outcome: 70% approved, 20% declined, 10% failed
        let roll = Double.random(in: 0..<1)
        let result: PaymentResult

        if roll < 0.70 {
            result = PaymentResult(status: .approved, message: "Payment approved successfully")
        } else if roll < 0.90 {
            let declineReasons = [
                "Insufficient funds",
                "Card expired",
                "Transaction limit exceeded",
                "Card blocked by issuer"
            ]
            result = PaymentResult(
                status: .declined,
                message: declineReasons.randomElement()!
            )
        } else {
            let failReasons = [
                "Network timeout",
                "Gateway unavailable",
                "Internal server error"
            ]
            result = PaymentResult(
                status: .failed,
                message: failReasons.randomElement()!
            )
        }

        // Cache result for idempotency
        processedKeys[idempotencyKey] = result

        return result
    }

    /// Cached results keyed by idempotency key for duplicate detection
    private var processedKeys: [String: PaymentResult] = [:]

    /// Clear cached results (for testing)
    func clearCache() {
        processedKeys.removeAll()
    }

    /// Clear a specific idempotency key (for retry with new key)
    func clearKey(_ key: String) {
        processedKeys.removeValue(forKey: key)
    }
}
