//
//  APIErrorResponse.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation

struct APIErrorResponse: Decodable, Sendable {
    let requestId: String?
    let errorType: String?
    let errorCodes: [String]?

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case errorType = "error_type"
        case errorCodes = "error_codes"
    }
}
