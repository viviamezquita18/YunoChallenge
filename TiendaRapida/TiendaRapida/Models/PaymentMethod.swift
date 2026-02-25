import Foundation

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case creditCard = "credit_card"
    case debitCard = "debit_card"
    case cash = "cash"
    case bankTransfer = "bank_transfer"
    case nequi = "nequi"
    case yape = "yape"
    case mobileWallet = "mobile_wallet"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .debitCard: return "Debit Card"
        case .cash: return "Cash"
        case .bankTransfer: return "Bank Transfer"
        case .nequi: return "Nequi"
        case .yape: return "Yape"
        case .mobileWallet: return "Mobile Wallet"
        }
    }

    var iconName: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .debitCard: return "creditcard"
        case .cash: return "banknote.fill"
        case .bankTransfer: return "building.columns.fill"
        case .nequi: return "n.circle.fill"
        case .yape: return "y.circle.fill"
        case .mobileWallet: return "iphone.gen3"
        }
    }
}
