//
//  CheckoutAPIService.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

struct CheckoutAPIService: CheckoutAPIServiceProtocol {
    private let networkClient: NetworkClientProtocol
    private let configuration: APIConfiguration

    init(
        networkClient: NetworkClientProtocol = NetworkClient(),
        configuration: APIConfiguration
    ) {
        self.networkClient = networkClient
        self.configuration = configuration
    }

    func tokenize(card: TokenRequest) async throws -> TokenResponse {
        var request = makeRequest(path: "/tokens", authKey: configuration.publicKey)
        request.httpBody = try JSONEncoder().encode(card)

        do {
            return try await networkClient.perform(request: request)
        } catch let error as NetworkError {
            throw mapTokenizationError(error)
        }
    }

    func requestPayment(_ paymentRequest: PaymentRequest) async throws -> PaymentResponse {
        var request = makeRequest(path: "/payments", authKey: configuration.secretKey)
        request.httpBody = try JSONEncoder().encode(paymentRequest)

        do {
            return try await networkClient.perform(request: request)
        } catch let error as NetworkError {
            throw mapPaymentError(error)
        }
    }

    // MARK: - Private Helpers

    private func makeRequest(path: String, authKey: String) -> URLRequest {
        let url = URL(string: "\(configuration.baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(authKey, forHTTPHeaderField: "Authorization")
        return request
    }

    private func mapTokenizationError(_ error: NetworkError) -> PaymentError {
        switch error {
        case .httpError(let statusCode, let data):
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                let message = apiError.errorCodes?.joined(separator: ", ") ?? "Unknown error"
                return .tokenizationFailed(message)
            }
            return .tokenizationFailed("HTTP \(statusCode)")
        case .invalidResponse:
            return .invalidResponse
        }
    }

    private func mapPaymentError(_ error: NetworkError) -> PaymentError {
        switch error {
        case .httpError(let statusCode, let data):
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                let message = apiError.errorCodes?.joined(separator: ", ") ?? "Unknown error"
                return .paymentFailed(message)
            }
            return .paymentFailed("HTTP \(statusCode)")
        case .invalidResponse:
            return .invalidResponse
        }
    }
}
