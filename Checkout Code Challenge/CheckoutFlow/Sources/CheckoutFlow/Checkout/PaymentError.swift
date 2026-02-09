//
//  PaymentError.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

enum PaymentError: LocalizedError, Equatable {
    case invalidCard(String)
    case tokenizationFailed(String)
    case paymentFailed(String)
    case invalidResponse
    case threeDSRedirectMissing

    var errorDescription: String? {
        switch self {
        case .invalidCard(let reason):
            return String(format: NSLocalizedString("Invalid card: %@", bundle: .module, comment: ""), reason)
        case .tokenizationFailed(let reason):
            return String(format: NSLocalizedString("Tokenization failed: %@", bundle: .module, comment: ""), reason)
        case .paymentFailed(let reason):
            return String(format: NSLocalizedString("Payment failed: %@", bundle: .module, comment: ""), reason)
        case .invalidResponse:
            return NSLocalizedString("Invalid server response", bundle: .module, comment: "")
        case .threeDSRedirectMissing:
            return NSLocalizedString("3DS redirect URL not found in response", bundle: .module, comment: "")
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidCard:
            return NSLocalizedString("Check your card details and try again.", bundle: .module, comment: "")
        case .tokenizationFailed:
            return NSLocalizedString("Verify your card number and expiry date, then try again.", bundle: .module, comment: "")
        case .paymentFailed:
            return NSLocalizedString("Please try again or use a different card.", bundle: .module, comment: "")
        case .invalidResponse:
            return NSLocalizedString("Please try again later.", bundle: .module, comment: "")
        case .threeDSRedirectMissing:
            return NSLocalizedString("Please try again or contact support.", bundle: .module, comment: "")
        }
    }
}
