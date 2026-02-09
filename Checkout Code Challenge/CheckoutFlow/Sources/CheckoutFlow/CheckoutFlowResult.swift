//
//  CheckoutFlowResult.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

/// The outcome of the payment flow, reported to the host application.
public enum CheckoutFlowResult: Equatable {
    case success
    case failure
}
