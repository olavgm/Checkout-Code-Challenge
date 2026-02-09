//
//  TokenResponse.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

struct TokenResponse: Decodable, Sendable {
    let type: String
    let token: String
    let expiresOn: String?
    let scheme: String?

    enum CodingKeys: String, CodingKey {
        case type, token, scheme
        case expiresOn = "expires_on"
    }
}
