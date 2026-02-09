//
//  CardValidatorProtocol.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

protocol CardValidatorProtocol {
    func detectScheme(from number: String) -> CardScheme
    func isValidLuhn(_ number: String) -> Bool
    func isValidExpiry(month: Int, year: Int) -> Bool
    func isValidCVV(_ cvv: String, scheme: CardScheme) -> Bool
    func formatCardNumber(_ number: String, scheme: CardScheme) -> String
    func formatExpiryDate(_ input: String) -> String
}
