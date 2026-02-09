//
//  CardInputViewModel.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation
import Combine

enum PaymentFlowState: Equatable {
    case cardInput
    case threeDSChallenge(URL)
    case result(success: Bool)
}

@MainActor
class CardInputViewModel: ObservableObject {

    // MARK: - Field Focus

    enum Field {
        case cardNumber
        case expiry
        case cvv
    }

    // MARK: - Card Input State

    /// Raw card number digits (no spaces)
    @Published var rawCardNumber = ""

    /// Raw expiry digits (MMYY, no slash)
    @Published var rawExpiry = ""

    /// CVV digits
    @Published var cvv = ""

    // MARK: - Display Text

    @Published var cardNumberText = ""
    @Published var expiryText = ""
    @Published var cvvText = ""

    // MARK: - Focus

    @Published var activeField: Field?

    // MARK: - UI State

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var flowState: PaymentFlowState = .cardInput
    @Published var showFieldErrors = false
    @Published var touchedFields: Set<Field> = []

    // MARK: - Dependencies

    private let apiService: any CheckoutAPIServiceProtocol
    private let cardValidator: any CardValidatorProtocol
    private let paymentConfig: PaymentConfigurationProvider
    private var paymentTask: Task<Void, Never>?

    // MARK: - Init

    init(
        apiService: any CheckoutAPIServiceProtocol,
        cardValidator: any CardValidatorProtocol,
        paymentConfig: PaymentConfigurationProvider = DefaultPaymentConfigurationProvider(
            successURL: "https://example.com/payments/success",
            failureURL: "https://example.com/payments/fail",
            paymentAmount: Decimal(string: "10.77")!,
            paymentCurrency: "GBP"
        )
    ) {
        self.apiService = apiService
        self.cardValidator = cardValidator
        self.paymentConfig = paymentConfig
    }

    // MARK: - Computed Properties

    var detectedScheme: CardScheme {
        cardValidator.detectScheme(from: rawCardNumber)
    }

    var formattedCardNumber: String {
        cardValidator.formatCardNumber(rawCardNumber, scheme: detectedScheme)
    }

    var formattedExpiry: String {
        cardValidator.formatExpiryDate(rawExpiry)
    }

    var isFormValid: Bool {
        guard !rawCardNumber.isEmpty else { return false }
        guard cardValidator.isValidLuhn(rawCardNumber) else { return false }
        guard detectedScheme.validLengths.contains(rawCardNumber.count) else { return false }

        guard rawExpiry.count == 4 else { return false }
        let month = Int(rawExpiry.prefix(2)) ?? 0
        let year = Int(rawExpiry.suffix(2)) ?? 0
        guard cardValidator.isValidExpiry(month: month, year: year) else { return false }

        guard cardValidator.isValidCVV(cvv, scheme: detectedScheme) else { return false }

        return true
    }

    var successURL: String { paymentConfig.successURL }
    var failureURL: String { paymentConfig.failureURL }

    var formattedAmount: String {
        "£\(paymentConfig.paymentAmount)"
    }

    // MARK: - Field Validation Errors

    var cardNumberError: String? {
        guard showFieldErrors || touchedFields.contains(.cardNumber) else { return nil }

        if rawCardNumber.isEmpty {
            return NSLocalizedString("Card number is required", bundle: .module, comment: "")
        }
        if !cardValidator.isValidLuhn(rawCardNumber) {
            return NSLocalizedString("Invalid card number", bundle: .module, comment: "")
        }
        if !detectedScheme.validLengths.contains(rawCardNumber.count) {
            return NSLocalizedString("Incomplete card number", bundle: .module, comment: "")
        }
        return nil
    }

    var expiryError: String? {
        guard showFieldErrors || touchedFields.contains(.expiry) else { return nil }
        if rawExpiry.isEmpty { return NSLocalizedString("Expiry date is required", bundle: .module, comment: "") }
        if rawExpiry.count < 4 { return NSLocalizedString("Incomplete expiry date", bundle: .module, comment: "") }
        let month = Int(rawExpiry.prefix(2)) ?? 0
        let year = Int(rawExpiry.suffix(2)) ?? 0
        if month < 1 || month > 12 {
            return NSLocalizedString("Invalid expiry date", bundle: .module, comment: "")
        }
        if !cardValidator.isValidExpiry(month: month, year: year) {
            return NSLocalizedString("Card has expired", bundle: .module, comment: "")
        }
        return nil
    }

    var cvvError: String? {
        guard showFieldErrors || touchedFields.contains(.cvv) else { return nil }
        if cvv.isEmpty { return NSLocalizedString("CVV is required", bundle: .module, comment: "") }
        if !cardValidator.isValidCVV(cvv, scheme: detectedScheme) {
            return NSLocalizedString("Invalid CVV", bundle: .module, comment: "")
        }
        return nil
    }

    func fieldDidBlur(_ field: Field) {
        touchedFields.insert(field)
    }

    // MARK: - Input Handlers

    /// Primary handler for card number input. Filters non-digits, clamps to max length,
    /// updates `rawCardNumber` and `cardNumberText`, and advances focus when complete.
    func handleCardNumberInput(_ newValue: String) {
        let digits = newValue.filter(\.isNumber)
        let scheme = cardValidator.detectScheme(from: digits)

        guard digits.count <= scheme.maxDigits else {
            cardNumberText = formattedCardNumber
            return
        }

        rawCardNumber = String(digits.prefix(scheme.maxDigits))
        let formatted = formattedCardNumber
        if cardNumberText != formatted {
            cardNumberText = formatted
        }
        if digits.count == scheme.maxDigits {
            activeField = .expiry
        }
    }

    /// Primary handler for expiry input. Filters non-digits, clamps to 4 digits (MMYY),
    /// updates `rawExpiry` and `expiryText`, and advances focus when complete.
    func handleExpiryInput(_ newValue: String) {
        let digits = newValue.filter(\.isNumber)

        guard digits.count <= 4 else {
            expiryText = formattedExpiry
            return
        }

        rawExpiry = String(digits.prefix(4))
        let formatted = formattedExpiry
        if expiryText != formatted {
            expiryText = formatted
        }
        if digits.count == 4 {
            activeField = .cvv
        }
    }

    /// Primary handler for CVV input. Filters non-digits, clamps to the scheme's CVV length,
    /// updates `cvv` and `cvvText`.
    func handleCVVInput(_ newValue: String) {
        let digits = newValue.filter(\.isNumber)
        let maxLength = detectedScheme.cvvLength

        guard digits.count <= maxLength else {
            cvvText = cvv
            return
        }

        cvv = String(digits.prefix(maxLength))
        if cvvText != cvv {
            cvvText = cvv
        }
    }

    // MARK: - Payment Flow

    /// Validates the form and kicks off the payment flow.
    /// Returns the underlying `Task` for testing purposes, or `nil` if validation failed.
    @discardableResult
    func processPayment() -> Task<Void, Never>? {
        showFieldErrors = true
        guard isFormValid else {
            let fieldError = cardNumberError ?? expiryError ?? cvvError
            errorMessage = fieldError ?? NSLocalizedString("Please check your card details", bundle: .module, comment: "")
            return nil
        }

        paymentTask?.cancel()
        let task = Task { await performPayment() }
        paymentTask = task
        return task
    }

    private func performPayment() async {
        isLoading = true
        errorMessage = nil

        do {
            // Part 1: Tokenize card
            let month = Int(rawExpiry.prefix(2))!
            let year = Int("20" + rawExpiry.suffix(2))!

            let tokenRequest = TokenRequest(
                number: rawCardNumber,
                expiryMonth: month,
                expiryYear: year,
                cvv: cvv
            )

            let tokenResponse = try await apiService.tokenize(card: tokenRequest)
            try Task.checkCancellation()

            // Part 2: Request payment with 3DS
            let paymentRequest = PaymentRequest(
                source: PaymentSource(token: tokenResponse.token),
                amount: NSDecimalNumber(decimal: paymentConfig.paymentAmount * 100).intValue,
                currency: paymentConfig.paymentCurrency,
                threeDS: ThreeDSConfig(enabled: true),
                successURL: paymentConfig.successURL,
                failureURL: paymentConfig.failureURL
            )

            let paymentResponse = try await apiService.requestPayment(paymentRequest)
            try Task.checkCancellation()

            guard paymentResponse.isPending, let redirectURL = paymentResponse.redirectURL else {
                throw PaymentError.threeDSRedirectMissing
            }

            isLoading = false
            flowState = .threeDSChallenge(redirectURL)
        } catch is CancellationError {
            // Task was cancelled (e.g. user reset mid-payment) — silently stop
            isLoading = false
        } catch {
            isLoading = false
            if let paymentError = error as? PaymentError {
                errorMessage = [paymentError.errorDescription, paymentError.recoverySuggestion]
                    .compactMap { $0 }
                    .joined(separator: "\n")
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    func handleThreeDSResult(success: Bool) {
        flowState = .result(success: success)
    }

    func reset() {
        paymentTask?.cancel()
        paymentTask = nil
        rawCardNumber = ""
        rawExpiry = ""
        cvv = ""
        cardNumberText = ""
        expiryText = ""
        cvvText = ""
        activeField = nil
        isLoading = false
        errorMessage = nil
        showFieldErrors = false
        touchedFields = []
        flowState = .cardInput
    }

    deinit {
        paymentTask?.cancel()
    }
}
