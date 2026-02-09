//
//  CardScheme.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

enum CardScheme: Equatable, Sendable {
    case visa
    case mastercard
    case amex
    case unknown

    var validLengths: Set<Int> {
        switch self {
        case .amex: return [15]
        case .visa: return [13, 16, 19]
        case .mastercard: return [16]
        case .unknown: return Set(13...19)
        }
    }

    var cvvLength: Int {
        switch self {
        case .amex: return 4
        default: return 3
        }
    }

    var maxDigits: Int {
        switch self {
        case .amex: return 15
        case .visa: return 19
        case .mastercard: return 16
        case .unknown: return 19
        }
    }

    var formatPattern: [Int] {
        switch self {
        case .amex: return [4, 6, 5]
        default: return [4, 4, 4, 4, 3]
        }
    }

    var logoImageName: String? {
        switch self {
        case .visa: return "visa_logo"
        case .mastercard: return "mastercard_logo"
        case .amex: return "amex_logo"
        case .unknown: return nil
        }
    }
}
