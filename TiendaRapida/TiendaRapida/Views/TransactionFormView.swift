import SwiftUI

struct TransactionFormView: View {
    @Bindable var viewModel: TransactionFormViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Offline indicator
                if viewModel.isOffline {
                    Section {
                        HStack {
                            Image(systemName: "wifi.slash")
                                .foregroundStyle(.orange)
                            Text("You're offline. Transaction will be queued and synced when connectivity returns.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Amount section
                Section("Payment Details") {
                    HStack {
                        Text(viewModel.selectedCurrency.symbol)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        TextField("Amount", text: $viewModel.amount)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }

                    Picker("Currency", selection: $viewModel.selectedCurrency) {
                        ForEach(Currency.allCases) { currency in
                            HStack {
                                Text(currency.flag)
                                Text(currency.rawValue)
                                Text("- \(currency.name)")
                                    .foregroundStyle(.secondary)
                            }
                            .tag(currency)
                        }
                    }

                    Picker("Payment Method", selection: $viewModel.selectedPaymentMethod) {
                        ForEach(PaymentMethod.allCases) { method in
                            Label(method.displayName, systemImage: method.iconName)
                                .tag(method)
                        }
                    }
                }

                // Customer section
                Section("Customer Information") {
                    TextField("Customer Name", text: $viewModel.customerName)
                        .textContentType(.name)
                        .autocapitalization(.words)

                    TextField("Item Description", text: $viewModel.itemDescription)
                }

                // Submit button
                Section {
                    Button(action: {
                        viewModel.submitTransaction()
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isOffline {
                                Image(systemName: "clock.fill")
                                Text("Queue Payment")
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Submit Payment")
                            }
                            Spacer()
                        }
                        .font(.headline)
                        .padding(.vertical, 4)
                    }
                    .disabled(!viewModel.isFormValid)
                    .listRowBackground(
                        viewModel.isFormValid
                            ? (viewModel.isOffline ? Color.orange : Color.accentColor)
                            : Color.gray.opacity(0.3)
                    )
                    .foregroundStyle(.white)
                }
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Transaction Queued", isPresented: $viewModel.showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                if viewModel.isOffline {
                    Text("Your transaction has been saved locally and will be processed when connectivity is restored.")
                } else {
                    Text("Your transaction has been submitted for processing.")
                }
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}
