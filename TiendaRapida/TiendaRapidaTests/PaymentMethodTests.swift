import Testing
import Foundation
@testable import TiendaRapida

@Suite("PaymentMethod")
struct PaymentMethodTests {

    @Test("CaseIterable has 7 payment methods including Nequi and Yape")
    func allCasesCount() {
        #expect(PaymentMethod.allCases.count == 7)
    }

    @Test("Nequi exists with correct raw value")
    func nequiRawValue() {
        #expect(PaymentMethod.nequi.rawValue == "nequi")
    }

    @Test("Yape exists with correct raw value")
    func yapeRawValue() {
        #expect(PaymentMethod.yape.rawValue == "yape")
    }

    @Test("All payment methods have non-empty display names", arguments: PaymentMethod.allCases)
    func displayNames(method: PaymentMethod) {
        #expect(!method.displayName.isEmpty)
    }

    @Test("Nequi display name")
    func nequiDisplayName() {
        #expect(PaymentMethod.nequi.displayName == "Nequi")
    }

    @Test("Yape display name")
    func yapeDisplayName() {
        #expect(PaymentMethod.yape.displayName == "Yape")
    }

    @Test("All payment methods have non-empty SF Symbol icon names", arguments: PaymentMethod.allCases)
    func iconNames(method: PaymentMethod) {
        #expect(!method.iconName.isEmpty)
    }

    @Test("All raw values are unique")
    func uniqueRawValues() {
        let raws = PaymentMethod.allCases.map(\.rawValue)
        #expect(Set(raws).count == raws.count)
    }

    @Test("Identifiable id matches raw value", arguments: PaymentMethod.allCases)
    func identifiableId(method: PaymentMethod) {
        #expect(method.id == method.rawValue)
    }
}
