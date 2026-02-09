//
//  CardValidatorTests.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import XCTest
@testable import CheckoutFlow

final class CardValidatorTests: XCTestCase {
    private var cardValidator: CardValidator!

    override func setUp() {
        super.setUp()
        cardValidator = CardValidator()
    }

    override func tearDown() {
        cardValidator = nil
        super.tearDown()
    }

    // MARK: - Scheme Detection

    func testDetectSchemeVisa() {
        XCTAssertEqual(cardValidator.detectScheme(from: "4242424242424242"), .visa)
    }

    func testDetectSchemeVisaPartial() {
        XCTAssertEqual(cardValidator.detectScheme(from: "4"), .visa)
    }

    func testDetectSchemeMastercard51() {
        XCTAssertEqual(cardValidator.detectScheme(from: "5155555555554444"), .mastercard)
    }

    func testDetectSchemeMastercard55() {
        XCTAssertEqual(cardValidator.detectScheme(from: "5555555555554444"), .mastercard)
    }

    func testDetectSchemeMastercard2221() {
        XCTAssertEqual(cardValidator.detectScheme(from: "2221000000000000"), .mastercard)
    }

    func testDetectSchemeMastercard2720() {
        XCTAssertEqual(cardValidator.detectScheme(from: "2720000000000000"), .mastercard)
    }

    func testDetectSchemeAmex34() {
        XCTAssertEqual(cardValidator.detectScheme(from: "340000000000000"), .amex)
    }

    func testDetectSchemeAmex37() {
        XCTAssertEqual(cardValidator.detectScheme(from: "378282246310005"), .amex)
    }

    func testDetectSchemeUnknown() {
        XCTAssertEqual(cardValidator.detectScheme(from: "9999999999999999"), .unknown)
    }

    func testDetectSchemeEmpty() {
        XCTAssertEqual(cardValidator.detectScheme(from: ""), .unknown)
    }

    // MARK: - Luhn Validation

    func testValidVisaNumber() {
        XCTAssertTrue(cardValidator.isValidLuhn("4242424242424242"))
    }

    func testValidAmexNumber() {
        XCTAssertTrue(cardValidator.isValidLuhn("378282246310005"))
    }

    func testValidMastercardNumber() {
        XCTAssertTrue(cardValidator.isValidLuhn("5555555555554444"))
    }

    func testInvalidLuhnNumber() {
        XCTAssertFalse(cardValidator.isValidLuhn("4242424242424243"))
    }

    func testTooShortNumber() {
        XCTAssertFalse(cardValidator.isValidLuhn("424242"))
    }

    func testEmptyNumber() {
        XCTAssertFalse(cardValidator.isValidLuhn(""))
    }

    func testFailureTestCardNumber() {
        XCTAssertTrue(cardValidator.isValidLuhn("4243754271700719"))
    }

    // MARK: - Expiry Validation

    func testValidFutureExpiry() {
        XCTAssertTrue(cardValidator.isValidExpiry(month: 6, year: 2030))
    }

    func testValidFutureExpiryTwoDigitYear() {
        XCTAssertTrue(cardValidator.isValidExpiry(month: 6, year: 30))
    }

    func testExpiredDate() {
        XCTAssertFalse(cardValidator.isValidExpiry(month: 1, year: 2020))
    }

    func testInvalidMonth0() {
        XCTAssertFalse(cardValidator.isValidExpiry(month: 0, year: 2030))
    }

    func testInvalidMonth13() {
        XCTAssertFalse(cardValidator.isValidExpiry(month: 13, year: 2030))
    }

    func testCurrentMonthIsValid() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        XCTAssertTrue(cardValidator.isValidExpiry(month: currentMonth, year: currentYear))
    }

    // MARK: - CVV Validation

    func testValid3DigitCVVForVisa() {
        XCTAssertTrue(cardValidator.isValidCVV("123", scheme: .visa))
    }

    func testValid4DigitCVVForAmex() {
        XCTAssertTrue(cardValidator.isValidCVV("1234", scheme: .amex))
    }

    func testInvalidCVVTooShort() {
        XCTAssertFalse(cardValidator.isValidCVV("12", scheme: .visa))
    }

    func testInvalidCVVTooLongForVisa() {
        XCTAssertFalse(cardValidator.isValidCVV("1234", scheme: .visa))
    }

    func testInvalidCVVTooShortForAmex() {
        XCTAssertFalse(cardValidator.isValidCVV("123", scheme: .amex))
    }

    // MARK: - Card Number Formatting

    func testFormat16DigitVisaNumber() {
        let result = cardValidator.formatCardNumber("4242424242424242", scheme: .visa)
        XCTAssertEqual(result, "4242 4242 4242 4242")
    }

    func testFormat15DigitAmexNumber() {
        let result = cardValidator.formatCardNumber("378282246310005", scheme: .amex)
        XCTAssertEqual(result, "3782 822463 10005")
    }

    func testFormatPartialNumber() {
        let result = cardValidator.formatCardNumber("424242", scheme: .visa)
        XCTAssertEqual(result, "4242 42")
    }

    func testFormatEmptyNumber() {
        let result = cardValidator.formatCardNumber("", scheme: .unknown)
        XCTAssertEqual(result, "")
    }

    func testFormatStripsNonDigits() {
        let result = cardValidator.formatCardNumber("4242 4242", scheme: .visa)
        XCTAssertEqual(result, "4242 4242")
    }

    func testFormatTruncatesToMaxDigits() {
        let result = cardValidator.formatCardNumber("42424242424242429999999", scheme: .visa)
        XCTAssertEqual(result, "4242 4242 4242 4242 999")
    }

    func testFormatAmexTruncatesTo15Digits() {
        let result = cardValidator.formatCardNumber("3782822463100051234", scheme: .amex)
        XCTAssertEqual(result, "3782 822463 10005")
    }

    // MARK: - Expiry Formatting

    func testFormatExpiryFullDigits() {
        XCTAssertEqual(cardValidator.formatExpiryDate("0630"), "06/30")
    }

    func testFormatExpiryPartialMonth() {
        XCTAssertEqual(cardValidator.formatExpiryDate("06"), "06")
    }

    func testFormatExpiryMonthAndPartialYear() {
        XCTAssertEqual(cardValidator.formatExpiryDate("063"), "06/3")
    }

    func testFormatExpiryTruncatesExcessDigits() {
        XCTAssertEqual(cardValidator.formatExpiryDate("06301"), "06/30")
    }

    func testFormatExpiryEmpty() {
        XCTAssertEqual(cardValidator.formatExpiryDate(""), "")
    }

    func testFormatExpiryStripsNonDigits() {
        XCTAssertEqual(cardValidator.formatExpiryDate("06/30"), "06/30")
    }
}
