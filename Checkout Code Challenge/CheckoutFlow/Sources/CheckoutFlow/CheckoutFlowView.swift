//
//  CheckoutFlowView.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import SwiftUI

/// The main entry point for the Checkout payment flow.
///
/// Presents card entry UI, handles tokenization, payment requests, and 3D Secure challenges.
/// Reports the final outcome via the `onResult` callback so the host application can notify the user.
public struct CheckoutFlowView: View {
    private let onResult: (CheckoutFlowResult) -> Void
    @StateObject private var viewModel: CardInputViewModel

    public init(
        configuration: CheckoutFlowConfiguration,
        onResult: @escaping (CheckoutFlowResult) -> Void
    ) {
        self.onResult = onResult

        let apiConfig = APIConfiguration(
            publicKey: configuration.publicKey,
            secretKey: configuration.secretKey,
            baseURL: configuration.baseURL
        )
        let paymentConfig = DefaultPaymentConfigurationProvider(
            successURL: configuration.successURL,
            failureURL: configuration.failureURL,
            paymentAmount: configuration.paymentAmount,
            paymentCurrency: configuration.paymentCurrency
        )

        _viewModel = StateObject(
            wrappedValue: CardInputViewModel(
                apiService: CheckoutAPIService(configuration: apiConfig),
                cardValidator: CardValidator(),
                paymentConfig: paymentConfig
            )
        )
    }

    public var body: some View {
        NavigationView {
            Group {
                switch viewModel.flowState {
                case .cardInput:
                    CardInputView(viewModel: viewModel)
                        .transition(.move(edge: .leading))

                case .threeDSChallenge(let url):
                    ThreeDSWebView(
                        url: url,
                        successURL: viewModel.successURL,
                        failureURL: viewModel.failureURL,
                        onComplete: { success in
                            withAnimation {
                                viewModel.handleThreeDSResult(success: success)
                            }
                        }
                    )
                    .navigationTitle(Text("3D Secure Verification", bundle: .module))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(NSLocalizedString("Cancel", bundle: .module, comment: "Cancel 3DS verification")) {
                                withAnimation {
                                    viewModel.handleThreeDSResult(success: false)
                                }
                            }
                        }
                    }
                    .transition(.move(edge: .trailing))

                case .result:
                    Color.clear
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.flowState)
        }
        .navigationViewStyle(.stack)
        .onChange(of: viewModel.flowState) { newState in
            if case .result(let success) = newState {
                onResult(success ? .success : .failure)
                viewModel.reset()
            }
        }
    }
}
