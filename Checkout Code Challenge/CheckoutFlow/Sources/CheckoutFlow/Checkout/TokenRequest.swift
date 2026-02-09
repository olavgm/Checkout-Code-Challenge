//
//  TokenRequest.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

struct TokenRequest: Encodable, Sendable {
    let type: String = "card"
    let number: String
    let expiryMonth: Int
    let expiryYear: Int
    let cvv: String

    enum CodingKeys: String, CodingKey {
        case type, number, cvv
        case expiryMonth = "expiry_month"
        case expiryYear = "expiry_year"
    }
}
