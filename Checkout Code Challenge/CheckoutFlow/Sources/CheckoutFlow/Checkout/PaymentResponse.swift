//
//  PaymentResponse.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

struct PaymentLink: Decodable, Sendable {
    let href: String
}

struct PaymentLinks: Decodable, Sendable {
    let redirect: PaymentLink?
}

struct PaymentResponse: Decodable, Sendable {
    let id: String?
    let status: String
    let links: PaymentLinks?

    enum CodingKeys: String, CodingKey {
        case id, status
        case links = "_links"
    }

    var redirectURL: URL? {
        guard let href = links?.redirect?.href else { return nil }
        return URL(string: href)
    }

    var isPending: Bool {
        status.lowercased() == "pending"
    }
}
