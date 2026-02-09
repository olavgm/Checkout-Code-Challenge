//
//  CheckoutAPIServiceTests.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import XCTest
@testable import CheckoutFlow

final class CheckoutAPIServiceTests: XCTestCase {
    private var mockSession: MockURLSession!
    private var checkoutAPIService: CheckoutAPIService!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        let networkClient = NetworkClient(session: mockSession)
        let apiConfig = APIConfiguration(
            publicKey: "pk_test",
            secretKey: "sk_test",
            baseURL: "https://api.sandbox.checkout.com"
        )
        checkoutAPIService = CheckoutAPIService(networkClient: networkClient, configuration: apiConfig)
    }

    override func tearDown() {
        checkoutAPIService = nil
        mockSession = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeResponse(url: URL, statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    // MARK: - Tokenize

    func testTokenizeSendsCorrectRequest() async throws {
        let responseJSON = Data("""
        {"type": "card", "token": "tok_test_456", "expires_on": "2026-03-01T00:00:00Z", "scheme": "Visa"}
        """.utf8)

        mockSession.requestHandler = { request in
            let response = self.makeResponse(url: request.url!, statusCode: 201)
            return (responseJSON, response)
        }

        let tokenRequest = TokenRequest(number: "4242424242424242", expiryMonth: 6, expiryYear: 2030, cvv: "100")
        let result = try await checkoutAPIService.tokenize(card: tokenRequest)

        XCTAssertEqual(result.token, "tok_test_456")
        XCTAssertEqual(result.scheme, "Visa")
        XCTAssertEqual(mockSession.lastRequest?.url?.absoluteString, "https://api.sandbox.checkout.com/tokens")
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization"), "pk_test")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Content-Type"), "application/json")
    }

    func testTokenizeDecodesResponse() async throws {
        let responseJSON = Data("""
        {"type": "card", "token": "tok_abc", "scheme": "Mastercard"}
        """.utf8)

        mockSession.requestHandler = { request in
            let response = self.makeResponse(url: request.url!, statusCode: 200)
            return (responseJSON, response)
        }

        let tokenRequest = TokenRequest(number: "5500000000000004", expiryMonth: 12, expiryYear: 2028, cvv: "123")
        let result = try await checkoutAPIService.tokenize(card: tokenRequest)

        XCTAssertEqual(result.token, "tok_abc")
        XCTAssertEqual(result.type, "card")
        XCTAssertEqual(result.scheme, "Mastercard")
    }

    func testTokenizeThrowsTokenizationFailedOnHTTPError() async {
        let errorJSON = Data("""
        {"request_id": "req_123", "error_type": "request_invalid", "error_codes": ["card_number_invalid"]}
        """.utf8)

        mockSession.requestHandler = { request in
            let response = self.makeResponse(url: request.url!, statusCode: 422)
            return (errorJSON, response)
        }

        let tokenRequest = TokenRequest(number: "1234", expiryMonth: 1, expiryYear: 2020, cvv: "000")

        do {
            _ = try await checkoutAPIService.tokenize(card: tokenRequest)
            XCTFail("Expected PaymentError.tokenizationFailed")
        } catch let error as PaymentError {
            if case .tokenizationFailed(let message) = error {
                XCTAssertTrue(message.contains("card_number_invalid"))
            } else {
                XCTFail("Expected tokenizationFailed, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Request Payment

    func testRequestPaymentSendsCorrectRequest() async throws {
        let responseJSON = Data("""
        {"id": "pay_123", "status": "Pending", "_links": {"redirect": {"href": "https://3ds.checkout.com/redirect"}}}
        """.utf8)

        mockSession.requestHandler = { request in
            let response = self.makeResponse(url: request.url!, statusCode: 202)
            return (responseJSON, response)
        }

        let paymentRequest = PaymentRequest(
            source: PaymentSource(token: "tok_test"),
            amount: 1077,
            currency: "GBP",
            threeDS: ThreeDSConfig(enabled: true),
            successURL: "https://example.com/success",
            failureURL: "https://example.com/fail"
        )

        let result = try await checkoutAPIService.requestPayment(paymentRequest)

        XCTAssertEqual(result.id, "pay_123")
        XCTAssertEqual(result.status, "Pending")
        XCTAssertTrue(result.isPending)
        XCTAssertNotNil(result.redirectURL)
        XCTAssertEqual(mockSession.lastRequest?.url?.absoluteString, "https://api.sandbox.checkout.com/payments")
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
        XCTAssertEqual(mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization"), "sk_test")
    }

    func testRequestPaymentThrowsPaymentFailedOnHTTPError() async {
        let errorJSON = Data("""
        {"request_id": "req_456", "error_type": "processing_error", "error_codes": ["insufficient_funds"]}
        """.utf8)

        mockSession.requestHandler = { request in
            let response = self.makeResponse(url: request.url!, statusCode: 422)
            return (errorJSON, response)
        }

        let paymentRequest = PaymentRequest(
            source: PaymentSource(token: "tok_test"),
            amount: 1077,
            currency: "GBP",
            threeDS: ThreeDSConfig(enabled: true),
            successURL: "https://example.com/success",
            failureURL: "https://example.com/fail"
        )

        do {
            _ = try await checkoutAPIService.requestPayment(paymentRequest)
            XCTFail("Expected PaymentError.paymentFailed")
        } catch let error as PaymentError {
            if case .paymentFailed(let message) = error {
                XCTAssertTrue(message.contains("insufficient_funds"))
            } else {
                XCTFail("Expected paymentFailed, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
