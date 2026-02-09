//
//  CheckoutFlowConfiguration.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

/// Configuration for the Checkout Flow module.
///
/// The host application must provide API credentials and payment parameters.
public struct CheckoutFlowConfiguration {
    public let publicKey: String
    public let secretKey: String
    public let baseURL: String
    public let paymentAmount: Decimal
    public let paymentCurrency: String
    public let successURL: String
    public let failureURL: String

    public init(
        publicKey: String,
        secretKey: String,
        baseURL: String,
        paymentAmount: Decimal,
        paymentCurrency: String = "GBP",
        successURL: String = "https://example.com/payments/success",
        failureURL: String = "https://example.com/payments/fail"
    ) {
        self.publicKey = publicKey
        self.secretKey = secretKey
        self.baseURL = baseURL
        self.paymentAmount = paymentAmount
        self.paymentCurrency = paymentCurrency
        self.successURL = successURL
        self.failureURL = failureURL
    }
}
