//
//  PaymentRequest.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

struct PaymentSource: Encodable, Sendable {
    let type: String = "token"
    let token: String
}

struct ThreeDSConfig: Encodable, Sendable {
    let enabled: Bool
}

struct PaymentRequest: Encodable, Sendable {
    let source: PaymentSource
    let amount: Int // In cents -> Int 10 is £0.10
    let currency: String
    let threeDS: ThreeDSConfig
    let successURL: String
    let failureURL: String

    enum CodingKeys: String, CodingKey {
        case source, amount, currency
        case threeDS = "3ds"
        case successURL = "success_url"
        case failureURL = "failure_url"
    }
}
