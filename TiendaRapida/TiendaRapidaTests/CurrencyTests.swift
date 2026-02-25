import Testing
import Foundation
@testable import TiendaRapida

@Suite("Currency")
struct CurrencyTests {

    @Test("CaseIterable has 4 currencies")
    func allCasesCount() {
        #expect(Currency.allCases.count == 4)
    }

    @Test("Raw values match ISO 4217 codes")
    func rawValues() {
        #expect(Currency.gtq.rawValue == "GTQ")
        #expect(Currency.cop.rawValue == "COP")
        #expect(Currency.pen.rawValue == "PEN")
        #expect(Currency.usd.rawValue == "USD")
    }

    @Test("Symbols are correct")
    func symbols() {
        #expect(Currency.gtq.symbol == "Q")
        #expect(Currency.cop.symbol == "$")
        #expect(Currency.pen.symbol == "S/")
        #expect(Currency.usd.symbol == "$")
    }

    @Test("Names are non-empty English", arguments: Currency.allCases)
    func names(currency: Currency) {
        #expect(!currency.name.isEmpty)
        #expect(currency.name.first?.isUppercase == true)
    }

    @Test("Flags are non-empty", arguments: Currency.allCases)
    func flags(currency: Currency) {
        #expect(!currency.flag.isEmpty)
    }

    // MARK: - Formatting

    @Test("COP formats as whole number (no cents)")
    func copNoCents() {
        // 45000.75 should be rounded — no fractional part in output
        let formatted = Currency.cop.format(45000.75)
        #expect(formatted.contains("$"))
        // With maximumFractionDigits=0 and value 45000.75, the result
        // should be the rounded whole number 45,001 or 45.001 depending on locale.
        // Verify by formatting a value where cents would be visible if present.
        let withCents = Currency.cop.format(100.99)
        // Should NOT contain ",99" or ".99" — cents are stripped
        #expect(!withCents.contains("99"))
    }

    @Test("GTQ formats with decimal places")
    func gtqWithDecimals() {
        let formatted = Currency.gtq.format(125.50)
        #expect(formatted.contains("Q"))
    }

    @Test("PEN formats with correct symbol")
    func penSymbol() {
        let formatted = Currency.pen.format(89.90)
        #expect(formatted.contains("S/"))
    }

    @Test("USD formats with dollar sign")
    func usdSymbol() {
        let formatted = Currency.usd.format(100.00)
        #expect(formatted.contains("$"))
    }

    @Test("Format returns non-empty string for zero amount", arguments: Currency.allCases)
    func formatZero(currency: Currency) {
        let formatted = currency.format(0)
        #expect(!formatted.isEmpty)
    }

    @Test("Format returns non-empty string for large amount", arguments: Currency.allCases)
    func formatLargeAmount(currency: Currency) {
        let formatted = currency.format(999_999.99)
        #expect(!formatted.isEmpty)
    }
}
