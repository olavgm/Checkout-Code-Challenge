//
//  PaymentModelTests.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import XCTest
@testable import CheckoutFlow

final class PaymentModelTests: XCTestCase {

    // MARK: - TokenRequest Encoding

    func testTokenRequestEncoding() throws {
        let request = TokenRequest(
            number: "4242424242424242",
            expiryMonth: 6,
            expiryYear: 2030,
            cvv: "100"
        )

        let data = try JSONEncoder().encode(request)
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        let json = try XCTUnwrap(jsonObject as? [String: Any])

        XCTAssertEqual(json["type"] as? String, "card")
        XCTAssertEqual(json["number"] as? String, "4242424242424242")
        XCTAssertEqual(json["expiry_month"] as? Int, 6)
        XCTAssertEqual(json["expiry_year"] as? Int, 2030)
        XCTAssertEqual(json["cvv"] as? String, "100")
    }

    // MARK: - TokenResponse Decoding

    func testTokenResponseDecoding() throws {
        let json = """
        {
            "type": "card",
            "token": "tok_ubfj2q76miwundwlk72vxt2i7q",
            "expires_on": "2030-01-01T00:00:00Z",
            "scheme": "Visa"
        }
        """
        let data = Data(json.utf8)

        let response = try JSONDecoder().decode(TokenResponse.self, from: data)

        XCTAssertEqual(response.type, "card")
        XCTAssertEqual(response.token, "tok_ubfj2q76miwundwlk72vxt2i7q")
        XCTAssertEqual(response.scheme, "Visa")
        XCTAssertNotNil(response.expiresOn)
    }

    func testTokenResponseDecodingMinimalFields() throws {
        let json = """
        {
            "type": "card",
            "token": "tok_test_123"
        }
        """
        let data = Data(json.utf8)

        let response = try JSONDecoder().decode(TokenResponse.self, from: data)

        XCTAssertEqual(response.token, "tok_test_123")
        XCTAssertNil(response.expiresOn)
        XCTAssertNil(response.scheme)
    }

    // MARK: - PaymentRequest Encoding

    func testPaymentRequestEncoding() throws {
        let request = PaymentRequest(
            source: PaymentSource(token: "tok_test_123"),
            amount: 6540,
            currency: "GBP",
            threeDS: ThreeDSConfig(enabled: true),
            successURL: "https://example.com/payments/success",
            failureURL: "https://example.com/payments/fail"
        )

        let data = try JSONEncoder().encode(request)
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        let json = try XCTUnwrap(jsonObject as? [String: Any])

        // Verify source
        let source = try XCTUnwrap(json["source"] as? [String: Any])
        XCTAssertEqual(source["type"] as? String, "token")
        XCTAssertEqual(source["token"] as? String, "tok_test_123")

        // Verify top-level fields
        XCTAssertEqual(json["amount"] as? Int, 6540)
        XCTAssertEqual(json["currency"] as? String, "GBP")
        XCTAssertEqual(json["success_url"] as? String, "https://example.com/payments/success")
        XCTAssertEqual(json["failure_url"] as? String, "https://example.com/payments/fail")

        // Verify 3ds key name (must be "3ds", not "threeDS")
        let threeDS = try XCTUnwrap(json["3ds"] as? [String: Any])
        XCTAssertEqual(threeDS["enabled"] as? Bool, true)
    }

    // MARK: - PaymentResponse Decoding

    func testPaymentResponseDecodingWith3DSRedirect() throws {
        let json = """
        {
            "id": "pay_mbabizu24mvu3mela5njyhpit4",
            "status": "Pending",
            "_links": {
                "redirect": {
                    "href": "https://api.checkout.com/3ds/pay_mbabizu24mvu3mela5njyhpit4"
                }
            }
        }
        """
        let data = Data(json.utf8)

        let response = try JSONDecoder().decode(PaymentResponse.self, from: data)

        XCTAssertEqual(response.id, "pay_mbabizu24mvu3mela5njyhpit4")
        XCTAssertEqual(response.status, "Pending")
        XCTAssertTrue(response.isPending)
        XCTAssertNotNil(response.redirectURL)
        XCTAssertEqual(
            response.redirectURL?.absoluteString,
            "https://api.checkout.com/3ds/pay_mbabizu24mvu3mela5njyhpit4"
        )
    }

    func testPaymentResponsePendingCheck() throws {
        let json = """
        { "status": "Pending", "_links": {} }
        """
        let data = Data(json.utf8)

        let response = try JSONDecoder().decode(PaymentResponse.self, from: data)
        XCTAssertTrue(response.isPending)
    }

    func testPaymentResponseNonPendingStatus() throws {
        let json = """
        { "status": "Declined", "_links": {} }
        """
        let data = Data(json.utf8)

        let response = try JSONDecoder().decode(PaymentResponse.self, from: data)
        XCTAssertFalse(response.isPending)
    }

    func testPaymentResponseNoRedirectURL() throws {
        let json = """
        { "status": "Pending", "_links": {} }
        """
        let data = Data(json.utf8)

        let response = try JSONDecoder().decode(PaymentResponse.self, from: data)
        XCTAssertNil(response.redirectURL)
    }

    // MARK: - APIErrorResponse Decoding

    func testAPIErrorResponseDecoding() throws {
        let json = """
        {
            "request_id": "req_123",
            "error_type": "request_invalid",
            "error_codes": ["card_number_invalid", "cvv_invalid"]
        }
        """
        let data = Data(json.utf8)

        let error = try JSONDecoder().decode(APIErrorResponse.self, from: data)

        XCTAssertEqual(error.requestId, "req_123")
        XCTAssertEqual(error.errorType, "request_invalid")
        XCTAssertEqual(error.errorCodes?.count, 2)
        XCTAssertEqual(error.errorCodes?.first, "card_number_invalid")
    }
}
