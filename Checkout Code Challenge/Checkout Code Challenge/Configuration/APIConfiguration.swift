//
//  APIConfiguration.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

/// Configuration for the Checkout.com API.
///
/// Reads `CheckoutPublicKey`, `CheckoutSecretKey`, and `CheckoutBaseURL` from the app's
/// `Info.plist`, which are populated at build time from the active xcconfig file:
/// - **Debug** → `Checkout-Sandbox.xcconfig` (gitignored)
/// - **Release** → `Checkout-Production.xcconfig` (gitignored)
///
/// Both xcconfig files are gitignored. Copy `Checkout-template.xcconfig` and rename it
/// to get started. See the template file for instructions.
///
/// - Important: In production, the secret key should never be embedded in the client app.
///   It should only be used from a secure backend server. This is just for this Code
///   Challenge scenario.
struct APIConfiguration {
    let publicKey: String
    let secretKey: String
    let baseURL: String

    init(
        publicKey: String? = nil,
        secretKey: String? = nil,
        baseURL: String? = nil
    ) {
        let info = Bundle.main.infoDictionary
        self.publicKey = publicKey ?? info?["CheckoutPublicKey"] as? String ?? ""
        self.secretKey = secretKey ?? info?["CheckoutSecretKey"] as? String ?? ""
        self.baseURL = baseURL ?? info?["CheckoutBaseURL"] as? String ?? ""
    }
}
