import Foundation

enum Currency: String, Codable, CaseIterable, Identifiable {
    case gtq = "GTQ"  // Guatemala Quetzal
    case cop = "COP"  // Colombian Peso
    case pen = "PEN"  // Peruvian Sol
    case usd = "USD"  // US Dollar

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .gtq: return "Q"
        case .cop: return "$"
        case .pen: return "S/"
        case .usd: return "$"
        }
    }

    var name: String {
        switch self {
        case .gtq: return "Guatemalan Quetzal"
        case .cop: return "Colombian Peso"
        case .pen: return "Peruvian Sol"
        case .usd: return "US Dollar"
        }
    }

    var flag: String {
        switch self {
        case .gtq: return "🇬🇹"
        case .cop: return "🇨🇴"
        case .pen: return "🇵🇪"
        case .usd: return "🇺🇸"
        }
    }

    func format(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = symbol
        formatter.maximumFractionDigits = (self == .cop) ? 0 : 2
        return formatter.string(from: NSNumber(value: amount)) ?? "\(symbol)\(amount)"
    }
}
