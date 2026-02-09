//
//  PaymentConfigurationProvider.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

protocol PaymentConfigurationProvider {
    var successURL: String { get }
    var failureURL: String { get }
    var paymentAmount: Decimal { get }
    var paymentCurrency: String { get }
}

struct DefaultPaymentConfigurationProvider: PaymentConfigurationProvider {
    let successURL: String
    let failureURL: String
    let paymentAmount: Decimal
    let paymentCurrency: String
}
