//
//  NetworkClientTests.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import XCTest
@testable import CheckoutFlow

final class NetworkClientTests: XCTestCase {
    private var mockSession: MockURLSession!
    private var networkClient: NetworkClient!

    private let dummyURL = URL(string: "https://api.sandbox.checkout.com/tokens")!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        networkClient = NetworkClient(session: mockSession)
    }

    override func tearDown() {
        networkClient = nil
        mockSession = nil
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: dummyURL, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }

    private func makeRequest() -> URLRequest {
        var request = URLRequest(url: dummyURL)
        request.httpMethod = "POST"
        return request
    }

    // MARK: - Success

    func testPerformDecodesSuccessfulResponse() async throws {
        let data = try JSONEncoder().encode(
            CodableTokenResponse(type: "card", token: "tok_123", expiresOn: nil, scheme: "Visa")
        )
        mockSession.result = .success((data, makeResponse(statusCode: 200)))

        let result: TokenResponse = try await networkClient.perform(request: makeRequest())
        XCTAssertEqual(result.token, "tok_123")
        XCTAssertEqual(result.type, "card")
    }

    // MARK: - HTTP Error

    func testPerformThrowsHTTPErrorForNon2xxStatus() async {
        let errorBody = Data("""
        {"request_id": "req_123", "error_type": "request_invalid", "error_codes": ["card_number_invalid"]}
        """.utf8)
        mockSession.result = .success((errorBody, makeResponse(statusCode: 422)))

        do {
            let _: TokenResponse = try await networkClient.perform(request: makeRequest())
            XCTFail("Expected NetworkError.httpError")
        } catch let error as NetworkError {
            if case .httpError(let statusCode, let data) = error {
                XCTAssertEqual(statusCode, 422)
                let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
                XCTAssertEqual(apiError?.errorCodes, ["card_number_invalid"])
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Invalid Response

    func testPerformThrowsInvalidResponseForNonHTTPResponse() async {
        mockSession.result = .success((Data(), URLResponse()))

        do {
            let _: TokenResponse = try await networkClient.perform(request: makeRequest())
            XCTFail("Expected NetworkError.invalidResponse")
        } catch let error as NetworkError {
            if case .invalidResponse = error {
                // Expected
            } else {
                XCTFail("Expected invalidResponse, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Malformed Response

    func testPerformThrowsDecodingErrorForMalformedJSON() async {
        mockSession.result = .success((Data("not json".utf8), makeResponse(statusCode: 200)))

        do {
            let _: TokenResponse = try await networkClient.perform(request: makeRequest())
            XCTFail("Expected decoding error")
        } catch is DecodingError {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Server Error

    func testPerformThrowsHTTPErrorFor500() async {
        mockSession.result = .success((Data(), makeResponse(statusCode: 500)))

        do {
            let _: TokenResponse = try await networkClient.perform(request: makeRequest())
            XCTFail("Expected NetworkError.httpError")
        } catch let error as NetworkError {
            if case .httpError(let statusCode, _) = error {
                XCTAssertEqual(statusCode, 500)
            } else {
                XCTFail("Expected httpError, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Network Failure

    func testPerformThrowsWhenSessionFails() async {
        mockSession.result = .failure(URLError(.notConnectedToInternet))

        do {
            let _: TokenResponse = try await networkClient.perform(request: makeRequest())
            XCTFail("Expected URLError")
        } catch is URLError {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

// Helper for encoding TokenResponse-like data (since TokenResponse is Decodable only)
private struct CodableTokenResponse: Encodable {
    let type: String
    let token: String
    let expiresOn: String?
    let scheme: String?

    enum CodingKeys: String, CodingKey {
        case type, token, scheme
        case expiresOn = "expires_on"
    }
}
