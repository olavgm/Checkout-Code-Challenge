//
//  CheckoutAPIServiceProtocol.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

protocol CheckoutAPIServiceProtocol {
    func tokenize(card: TokenRequest) async throws -> TokenResponse
    func requestPayment(_ request: PaymentRequest) async throws -> PaymentResponse
}
