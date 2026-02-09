//
//  MockURLSession.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import Foundation
@testable import CheckoutFlow

class MockURLSession: URLSessionProtocol {
    var result: Result<(Data, URLResponse), Error> = .success((Data(), HTTPURLResponse()))
    var requestHandler: ((URLRequest) throws -> (Data, URLResponse))?
    private(set) var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        if let handler = requestHandler {
            return try handler(request)
        }
        return try result.get()
    }
}
