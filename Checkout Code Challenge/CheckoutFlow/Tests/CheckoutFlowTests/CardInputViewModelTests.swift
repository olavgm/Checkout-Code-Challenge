//
//  CardInputViewModelTests.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import XCTest
@testable import CheckoutFlow

@MainActor
final class CardInputViewModelTests: XCTestCase {
    private var mockAPI: MockCheckoutAPIService!
    private var mockValidator: MockCardValidator!
    private var cardInputViewModel: CardInputViewModel!

    override func setUp() {
        super.setUp()
        mockAPI = MockCheckoutAPIService()
        mockValidator = MockCardValidator()
        cardInputViewModel = CardInputViewModel(apiService: mockAPI, cardValidator: mockValidator)
    }

    override func tearDown() {
        cardInputViewModel = nil
        mockAPI = nil
        mockValidator = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertEqual(cardInputViewModel.rawCardNumber, "")
        XCTAssertEqual(cardInputViewModel.rawExpiry, "")
        XCTAssertEqual(cardInputViewModel.cvv, "")
        XCTAssertEqual(cardInputViewModel.cardNumberText, "")
        XCTAssertEqual(cardInputViewModel.expiryText, "")
        XCTAssertEqual(cardInputViewModel.cvvText, "")
        XCTAssertNil(cardInputViewModel.activeField)
        XCTAssertFalse(cardInputViewModel.isLoading)
        XCTAssertNil(cardInputViewModel.errorMessage)
        XCTAssertEqual(cardInputViewModel.flowState, .cardInput)
    }

    // MARK: - Card Number Input

    func testHandleCardNumberInputSetsRawDigits() {
        cardInputViewModel.handleCardNumberInput("4242 4242 4242 4242")
        XCTAssertEqual(cardInputViewModel.rawCardNumber, "4242424242424242")
    }

    func testHandleCardNumberInputStripsNonDigits() {
        cardInputViewModel.handleCardNumberInput("4242-abcd-4242")
        XCTAssertEqual(cardInputViewModel.rawCardNumber, "42424242")
    }

    func testHandleCardNumberInputRejectsOverMaxDigits() {
        cardInputViewModel.handleCardNumberInput("4242424242424242424")
        XCTAssertEqual(cardInputViewModel.rawCardNumber.count, 19)
        // Adding more digits is rejected — raw value stays the same
        cardInputViewModel.handleCardNumberInput("42424242424242424242")
        XCTAssertEqual(cardInputViewModel.rawCardNumber.count, 19)
    }

    func testHandleCardNumberInputSetsDisplayText() {
        cardInputViewModel.handleCardNumberInput("4242424242424242")
        XCTAssertEqual(cardInputViewModel.cardNumberText, cardInputViewModel.formattedCardNumber)
    }

    func testHandleCardNumberInputAdvancesFocusWhenComplete() {
        // Visa maxDigits = 19
        cardInputViewModel.handleCardNumberInput("4242424242424242424")
        XCTAssertEqual(cardInputViewModel.activeField, .expiry)
    }

    func testHandleCardNumberInputDoesNotAdvanceFocusWhenIncomplete() {
        cardInputViewModel.handleCardNumberInput("424242")
        XCTAssertNil(cardInputViewModel.activeField)
    }

    func testHandleCardNumberInputRevertsDisplayOnOverflow() {
        cardInputViewModel.handleCardNumberInput("4242424242424242")
        let previousText = cardInputViewModel.cardNumberText
        // Now exceed max digits — should revert display text
        cardInputViewModel.handleCardNumberInput("42424242424242424242424242")
        XCTAssertEqual(cardInputViewModel.cardNumberText, previousText)
    }

    // MARK: - Expiry Input

    func testHandleExpiryInputSetsRawDigits() {
        cardInputViewModel.handleExpiryInput("06/30")
        XCTAssertEqual(cardInputViewModel.rawExpiry, "0630")
    }

    func testHandleExpiryInputRejectsOverMaxDigits() {
        cardInputViewModel.handleExpiryInput("0630")
        XCTAssertEqual(cardInputViewModel.rawExpiry, "0630")
        // Adding more digits is rejected — raw value stays the same
        cardInputViewModel.handleExpiryInput("063099")
        XCTAssertEqual(cardInputViewModel.rawExpiry, "0630")
    }

    func testHandleExpiryInputSetsDisplayText() {
        cardInputViewModel.handleExpiryInput("0630")
        XCTAssertEqual(cardInputViewModel.expiryText, cardInputViewModel.formattedExpiry)
    }

    func testHandleExpiryInputAdvancesFocusWhenComplete() {
        cardInputViewModel.handleExpiryInput("0630")
        XCTAssertEqual(cardInputViewModel.activeField, .cvv)
    }

    func testHandleExpiryInputDoesNotAdvanceFocusWhenIncomplete() {
        cardInputViewModel.handleExpiryInput("06")
        XCTAssertNil(cardInputViewModel.activeField)
    }

    // MARK: - CVV Input

    func testHandleCVVInputSetsDigits() {
        cardInputViewModel.handleCVVInput("100")
        XCTAssertEqual(cardInputViewModel.cvv, "100")
    }

    func testHandleCVVInputStripsNonDigits() {
        cardInputViewModel.handleCVVInput("1a2b3c")
        XCTAssertEqual(cardInputViewModel.cvv, "123")
    }

    func testHandleCVVInputRejectsOverMaxLength() {
        // Default mock scheme is .visa (cvvLength = 3)
        cardInputViewModel.handleCVVInput("123")
        XCTAssertEqual(cardInputViewModel.cvv, "123")
        // Adding more digits is rejected — raw value stays the same
        cardInputViewModel.handleCVVInput("12345")
        XCTAssertEqual(cardInputViewModel.cvv, "123")
    }

    func testHandleCVVInputSetsDisplayText() {
        cardInputViewModel.handleCVVInput("100")
        XCTAssertEqual(cardInputViewModel.cvvText, "100")
    }

    // MARK: - Scheme Detection

    func testDetectedSchemeUsesValidator() {
        mockValidator.detectSchemeResult = .amex
        XCTAssertEqual(cardInputViewModel.detectedScheme, .amex)
    }

    // MARK: - Form Validation

    func testFormValidWithAllFieldsCorrect() {
        setupValidCard()
        XCTAssertTrue(cardInputViewModel.isFormValid)
    }

    func testFormInvalidWithEmptyFields() {
        XCTAssertFalse(cardInputViewModel.isFormValid)
    }

    func testFormInvalidWithBadLuhn() {
        mockValidator.isValidLuhnResult = false
        cardInputViewModel.handleCardNumberInput("4242424242424243")
        cardInputViewModel.handleExpiryInput("0630")
        cardInputViewModel.handleCVVInput("100")
        XCTAssertFalse(cardInputViewModel.isFormValid)
    }

    func testFormInvalidWithBadExpiry() {
        mockValidator.isValidExpiryResult = false
        cardInputViewModel.handleCardNumberInput("4242424242424242")
        cardInputViewModel.handleExpiryInput("0120")
        cardInputViewModel.handleCVVInput("100")
        XCTAssertFalse(cardInputViewModel.isFormValid)
    }

    func testFormInvalidWithBadCVV() {
        mockValidator.isValidCVVResult = false
        cardInputViewModel.handleCardNumberInput("4242424242424242")
        cardInputViewModel.handleExpiryInput("0630")
        cardInputViewModel.handleCVVInput("10")
        XCTAssertFalse(cardInputViewModel.isFormValid)
    }

    // MARK: - Process Payment Success

    func testProcessPaymentSuccess() async {
        setupValidCard()

        await cardInputViewModel.processPayment()?.value

        XCTAssertFalse(cardInputViewModel.isLoading)
        XCTAssertNil(cardInputViewModel.errorMessage)
        XCTAssertEqual(mockAPI.tokenizeCallCount, 1)
        XCTAssertEqual(mockAPI.paymentCallCount, 1)

        if case .threeDSChallenge(let url) = cardInputViewModel.flowState {
            XCTAssertEqual(url.absoluteString, "https://api.checkout.com/3ds/pay_test")
        } else {
            XCTFail("Expected threeDSChallenge state, got \(cardInputViewModel.flowState)")
        }
    }

    func testProcessPaymentSendsCorrectTokenRequest() async {
        setupValidCard()

        await cardInputViewModel.processPayment()?.value

        XCTAssertEqual(mockAPI.lastTokenRequest?.number, "4242424242424242")
        XCTAssertEqual(mockAPI.lastTokenRequest?.expiryMonth, 6)
        XCTAssertEqual(mockAPI.lastTokenRequest?.expiryYear, 2030)
        XCTAssertEqual(mockAPI.lastTokenRequest?.cvv, "100")
    }

    func testProcessPaymentSendsCorrectPaymentRequest() async {
        setupValidCard()

        await cardInputViewModel.processPayment()?.value

        XCTAssertEqual(mockAPI.lastPaymentRequest?.source.token, "tok_test_123")
        XCTAssertEqual(mockAPI.lastPaymentRequest?.amount, 1077)
        XCTAssertEqual(mockAPI.lastPaymentRequest?.currency, "GBP")
        XCTAssertTrue(mockAPI.lastPaymentRequest?.threeDS.enabled ?? false)
        XCTAssertEqual(mockAPI.lastPaymentRequest?.successURL, cardInputViewModel.successURL)
        XCTAssertEqual(mockAPI.lastPaymentRequest?.failureURL, cardInputViewModel.failureURL)
    }

    // MARK: - Process Payment Failures

    func testProcessPaymentTokenizationFailure() async {
        setupValidCard()
        mockAPI.tokenizeResult = .failure(PaymentError.tokenizationFailed("card_number_invalid"))

        await cardInputViewModel.processPayment()?.value

        XCTAssertFalse(cardInputViewModel.isLoading)
        XCTAssertNotNil(cardInputViewModel.errorMessage)
        XCTAssertEqual(cardInputViewModel.flowState, .cardInput)
        XCTAssertEqual(mockAPI.paymentCallCount, 0)
    }

    func testProcessPaymentPaymentFailure() async {
        setupValidCard()
        mockAPI.paymentResult = .failure(PaymentError.paymentFailed("insufficient_funds"))

        await cardInputViewModel.processPayment()?.value

        XCTAssertFalse(cardInputViewModel.isLoading)
        XCTAssertNotNil(cardInputViewModel.errorMessage)
        XCTAssertEqual(cardInputViewModel.flowState, .cardInput)
    }

    func testProcessPaymentMissingRedirectURL() async {
        setupValidCard()
        mockAPI.paymentResult = .success(
            PaymentResponse(id: "pay_test", status: "Pending", links: nil)
        )

        await cardInputViewModel.processPayment()?.value

        XCTAssertFalse(cardInputViewModel.isLoading)
        XCTAssertNotNil(cardInputViewModel.errorMessage)
        XCTAssertEqual(cardInputViewModel.flowState, .cardInput)
    }

    func testProcessPaymentNonPendingStatus() async {
        setupValidCard()
        mockAPI.paymentResult = .success(
            PaymentResponse(
                id: "pay_test",
                status: "Declined",
                links: PaymentLinks(
                    redirect: PaymentLink(href: "https://api.checkout.com/3ds/test")
                )
            )
        )

        await cardInputViewModel.processPayment()?.value

        XCTAssertNotNil(cardInputViewModel.errorMessage)
        XCTAssertEqual(cardInputViewModel.flowState, .cardInput)
    }

    func testProcessPaymentInvalidFormDoesNotCallAPI() async {
        await cardInputViewModel.processPayment()?.value

        XCTAssertEqual(mockAPI.tokenizeCallCount, 0)
        XCTAssertEqual(mockAPI.paymentCallCount, 0)
        XCTAssertNotNil(cardInputViewModel.errorMessage)
    }

    // MARK: - 3DS Result Handling

    func testHandleThreeDSSuccess() {
        cardInputViewModel.handleThreeDSResult(success: true)
        XCTAssertEqual(cardInputViewModel.flowState, .result(success: true))
    }

    func testHandleThreeDSFailure() {
        cardInputViewModel.handleThreeDSResult(success: false)
        XCTAssertEqual(cardInputViewModel.flowState, .result(success: false))
    }

    // MARK: - Reset

    func testResetClearsAllState() async {
        setupValidCard()
        await cardInputViewModel.processPayment()?.value

        cardInputViewModel.reset()

        XCTAssertEqual(cardInputViewModel.rawCardNumber, "")
        XCTAssertEqual(cardInputViewModel.rawExpiry, "")
        XCTAssertEqual(cardInputViewModel.cvv, "")
        XCTAssertEqual(cardInputViewModel.cardNumberText, "")
        XCTAssertEqual(cardInputViewModel.expiryText, "")
        XCTAssertEqual(cardInputViewModel.cvvText, "")
        XCTAssertNil(cardInputViewModel.activeField)
        XCTAssertTrue(cardInputViewModel.touchedFields.isEmpty)
        XCTAssertFalse(cardInputViewModel.isLoading)
        XCTAssertNil(cardInputViewModel.errorMessage)
        XCTAssertEqual(cardInputViewModel.flowState, .cardInput)
    }

    // MARK: - Field Blur Validation

    func testFieldErrorHiddenBeforeBlur() {
        cardInputViewModel.handleCardNumberInput("42")
        XCTAssertNil(cardInputViewModel.cardNumberError)
    }

    func testFieldErrorShownAfterBlur() {
        cardInputViewModel.handleCardNumberInput("42")
        cardInputViewModel.fieldDidBlur(.cardNumber)
        XCTAssertNotNil(cardInputViewModel.cardNumberError)
    }

    func testExpiryErrorShownAfterBlur() {
        cardInputViewModel.handleExpiryInput("01")
        cardInputViewModel.fieldDidBlur(.expiry)
        XCTAssertNotNil(cardInputViewModel.expiryError)
    }

    func testCvvErrorShownAfterBlur() {
        mockValidator.isValidCVVResult = false
        cardInputViewModel.handleCVVInput("1")
        cardInputViewModel.fieldDidBlur(.cvv)
        XCTAssertNotNil(cardInputViewModel.cvvError)
    }

    func testNoErrorAfterBlurWithValidField() {
        setupValidCard()
        cardInputViewModel.fieldDidBlur(.cardNumber)
        XCTAssertNil(cardInputViewModel.cardNumberError)
    }

    // MARK: - Formatted Amount

    func testFormattedAmount() {
        XCTAssertEqual(cardInputViewModel.formattedAmount, "£10.77")
    }

    // MARK: - Helpers

    private func setupValidCard() {
        cardInputViewModel.handleCardNumberInput("4242424242424242")
        cardInputViewModel.handleExpiryInput("0630")
        cardInputViewModel.handleCVVInput("100")
    }
}
