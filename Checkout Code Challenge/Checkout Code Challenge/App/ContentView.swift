//
//  ContentView.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import SwiftUI
import CheckoutFlow

struct ContentView: View {
    private let configuration: CheckoutFlowConfiguration
    @State private var paymentResult: CheckoutFlowResult?

    init() {
        let apiConfig = APIConfiguration()
        self.configuration = CheckoutFlowConfiguration(
            publicKey: apiConfig.publicKey,
            secretKey: apiConfig.secretKey,
            baseURL: apiConfig.baseURL,
            paymentAmount: Decimal(string: "10.77")!
        )
    }

    var body: some View {
        if let result = paymentResult {
            PaymentResultView(success: result == .success) {
                withAnimation {
                    paymentResult = nil
                }
            }
            .transition(.move(edge: .trailing))
        } else {
            CheckoutFlowView(configuration: configuration) { result in
                withAnimation {
                    paymentResult = result
                }
            }
            .transition(.move(edge: .leading))
        }
    }
}

#Preview {
    ContentView()
}
