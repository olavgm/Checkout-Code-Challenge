//
//  MockCardValidator.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation
@testable import CheckoutFlow

class MockCardValidator: CardValidatorProtocol {
    var isValidLuhnResult = true
    var isValidExpiryResult = true
    var isValidCVVResult = true
    var detectSchemeResult: CardScheme = .visa

    var isValidLuhnCallCount = 0

    func detectScheme(from number: String) -> CardScheme {
        detectSchemeResult
    }

    func isValidLuhn(_ number: String) -> Bool {
        isValidLuhnCallCount += 1
        return isValidLuhnResult
    }

    func isValidExpiry(month: Int, year: Int) -> Bool {
        isValidExpiryResult
    }

    func isValidCVV(_ cvv: String, scheme: CardScheme) -> Bool {
        isValidCVVResult
    }

    func formatCardNumber(_ number: String, scheme: CardScheme) -> String {
        CardValidator().formatCardNumber(number, scheme: scheme)
    }

    func formatExpiryDate(_ input: String) -> String {
        CardValidator().formatExpiryDate(input)
    }
}
