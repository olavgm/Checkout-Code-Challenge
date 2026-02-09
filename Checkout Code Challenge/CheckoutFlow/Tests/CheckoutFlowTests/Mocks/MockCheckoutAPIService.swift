//
//  MockCheckoutAPIService.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation
@testable import CheckoutFlow

class MockCheckoutAPIService: CheckoutAPIServiceProtocol {
    var tokenizeResult: Result<TokenResponse, Error> = .success(
        TokenResponse(type: "card", token: "tok_test_123", expiresOn: nil, scheme: "Visa")
    )
    var paymentResult: Result<PaymentResponse, Error> = .success(
        PaymentResponse(
            id: "pay_test_123",
            status: "Pending",
            links: PaymentLinks(
                redirect: PaymentLink(href: "https://api.checkout.com/3ds/pay_test")
            )
        )
    )

    var tokenizeCallCount = 0
    var paymentCallCount = 0
    var lastTokenRequest: TokenRequest?
    var lastPaymentRequest: PaymentRequest?

    func tokenize(card: TokenRequest) async throws -> TokenResponse {
        tokenizeCallCount += 1
        lastTokenRequest = card
        return try tokenizeResult.get()
    }

    func requestPayment(_ request: PaymentRequest) async throws -> PaymentResponse {
        paymentCallCount += 1
        lastPaymentRequest = request
        return try paymentResult.get()
    }
}
