//
//  CardValidator.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

struct CardValidator: CardValidatorProtocol {

    func detectScheme(from number: String) -> CardScheme {
        let digits = String(number.filter(\.isNumber))
        guard !digits.isEmpty else { return .unknown }

        // Amex: starts with 34 or 37
        if digits.hasPrefix("34") || digits.hasPrefix("37") { return .amex }

        // Visa: starts with 4
        if digits.hasPrefix("4") { return .visa }

        // Mastercard: starts with 51-55 or 2221-2720
        if digits.count >= 2 {
            let first2 = Int(digits.prefix(2)) ?? 0
            if (51...55).contains(first2) { return .mastercard }
        }
        if digits.count >= 4 {
            let first4 = Int(digits.prefix(4)) ?? 0
            if (2221...2720).contains(first4) { return .mastercard }
        }

        return .unknown
    }

    func isValidLuhn(_ number: String) -> Bool {
        let digits = number.filter(\.isNumber)
        guard digits.count >= 13, digits.count <= 19 else { return false }

        var sum = 0
        let reversed = digits.reversed().compactMap { Int(String($0)) }

        for (index, digit) in reversed.enumerated() {
            if index % 2 == 1 {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
        }

        return sum % 10 == 0
    }

    func isValidExpiry(month: Int, year: Int) -> Bool {
        guard (1...12).contains(month) else { return false }

        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        // Support for both 2-digit and 4-digit year input
        let fullYear = year < 100 ? 2000 + year : year

        if fullYear > currentYear { return true }
        if fullYear == currentYear && month >= currentMonth { return true }
        return false
    }

    func isValidCVV(_ cvv: String, scheme: CardScheme) -> Bool {
        let digits = cvv.filter(\.isNumber)
        return digits.count == scheme.cvvLength
    }

    func formatCardNumber(_ number: String, scheme: CardScheme) -> String {
        let digits = number.filter(\.isNumber)
        let trimmed = String(digits.prefix(scheme.maxDigits))

        let pattern = scheme.formatPattern
        var result = ""
        var index = trimmed.startIndex

        for (groupIndex, groupSize) in pattern.enumerated() {
            guard index < trimmed.endIndex else { break }
            let end = trimmed.index(index, offsetBy: groupSize, limitedBy: trimmed.endIndex) ?? trimmed.endIndex
            if groupIndex > 0 && !result.isEmpty { result += " " }
            result += String(trimmed[index..<end])
            index = end
        }

        return result
    }

    func formatExpiryDate(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        let trimmed = String(digits.prefix(4))

        if trimmed.count <= 2 {
            return trimmed
        }

        let month = String(trimmed.prefix(2))
        let year = String(trimmed.dropFirst(2))
        return "\(month)/\(year)"
    }
}
