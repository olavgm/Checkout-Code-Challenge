//
//  CardSchemeTests.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import XCTest
@testable import CheckoutFlow

final class CardSchemeTests: XCTestCase {

    // MARK: - Scheme Properties

    func testVisaValidLengths() {
        XCTAssertTrue(CardScheme.visa.validLengths.contains(16))
        XCTAssertTrue(CardScheme.visa.validLengths.contains(13))
        XCTAssertTrue(CardScheme.visa.validLengths.contains(19))
    }

    func testAmexValidLengths() {
        XCTAssertEqual(CardScheme.amex.validLengths, [15])
    }

    func testMastercardValidLengths() {
        XCTAssertEqual(CardScheme.mastercard.validLengths, [16])
    }

    func testVisaCVVLength() {
        XCTAssertEqual(CardScheme.visa.cvvLength, 3)
    }

    func testAmexCVVLength() {
        XCTAssertEqual(CardScheme.amex.cvvLength, 4)
    }

    func testAmexFormatPattern() {
        XCTAssertEqual(CardScheme.amex.formatPattern, [4, 6, 5])
    }

    func testVisaFormatPattern() {
        XCTAssertEqual(CardScheme.visa.formatPattern, [4, 4, 4, 4, 3])
    }

    func testAmexMaxDigits() {
        XCTAssertEqual(CardScheme.amex.maxDigits, 15)
    }

    func testVisaMaxDigits() {
        XCTAssertEqual(CardScheme.visa.maxDigits, 19)
    }

    func testMastercardMaxDigits() {
        XCTAssertEqual(CardScheme.mastercard.maxDigits, 16)
    }
}
