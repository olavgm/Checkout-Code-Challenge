//
//  Checkout_Code_ChallengeTests.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import XCTest
import CheckoutFlow
@testable import Checkout_Code_Challenge

final class CheckoutCodeChallengeTests: XCTestCase {

    func testCheckoutFlowConfigurationCreatedFromAPIConfiguration() {
        let apiConfig = APIConfiguration(
            publicKey: "pk_test",
            secretKey: "sk_test",
            baseURL: "https://api.sandbox.checkout.com"
        )
        let config = CheckoutFlowConfiguration(
            publicKey: apiConfig.publicKey,
            secretKey: apiConfig.secretKey,
            baseURL: apiConfig.baseURL,
            paymentAmount: Decimal(string: "10.77")!
        )

        XCTAssertEqual(config.publicKey, "pk_test")
        XCTAssertEqual(config.secretKey, "sk_test")
        XCTAssertEqual(config.baseURL, "https://api.sandbox.checkout.com")
        XCTAssertEqual(config.paymentAmount, Decimal(string: "10.77"))
        XCTAssertEqual(config.paymentCurrency, "GBP")
    }
}
