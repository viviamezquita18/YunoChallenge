import Foundation
import Observation

@Observable
@MainActor
final class TransactionFormViewModel {
    var amount: String = ""
    var customerName: String = ""
    var itemDescription: String = ""
    var selectedCurrency: Currency = .gtq
    var selectedPaymentMethod: PaymentMethod = .cash

    var showingSuccess: Bool = false
    var showingError: Bool = false
    var errorMessage: String = ""

    private let syncEngine: SyncEngine
    private let connectivity: ConnectivityManager

    var isOffline: Bool {
        !connectivity.isEffectivelyOnline
    }

    var isFormValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        return !customerName.trimmingCharacters(in: .whitespaces).isEmpty
            && !itemDescription.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(syncEngine: SyncEngine, connectivity: ConnectivityManager = .shared) {
        self.syncEngine = syncEngine
        self.connectivity = connectivity
    }

    func submitTransaction() {
        guard isFormValid else {
            errorMessage = "Please fill in all fields with valid values."
            showingError = true
            return
        }

        guard let amountValue = Double(amount) else { return }

        let transaction = Transaction(
            amount: amountValue,
            currency: selectedCurrency,
            paymentMethod: selectedPaymentMethod,
            customerName: customerName.trimmingCharacters(in: .whitespaces),
            itemDescription: itemDescription.trimmingCharacters(in: .whitespaces)
        )

        syncEngine.queueTransaction(transaction)
        showingSuccess = true
        resetForm()
    }

    func resetForm() {
        amount = ""
        customerName = ""
        itemDescription = ""
        selectedCurrency = .gtq
        selectedPaymentMethod = .cash
    }
}
