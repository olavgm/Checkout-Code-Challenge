//
//  CardInputView.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import SwiftUI

struct CardInputView: View {
    @ObservedObject var viewModel: CardInputViewModel

    // Focus management
    @FocusState private var focusedField: CardInputViewModel.Field?
    @State private var previousField: CardInputViewModel.Field?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                cardNumberField

                HStack(alignment: .top, spacing: 16) {
                    expiryField
                    cvvField
                }

                errorMessageView

                payButton

                Spacer()
            }
            .padding()
        }
        .navigationTitle(Text("Payment", bundle: .module))
        .onChange(of: viewModel.activeField) { newValue in
            focusedField = newValue
        }
        .onChange(of: focusedField) { newValue in
            if let previous = previousField, previous != newValue {
                viewModel.fieldDidBlur(previous)
            }
            previousField = newValue
        }
    }

    // MARK: - Card number

    private var cardNumberField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Card number", bundle: .module)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                TextField("4242 4242 4242 4242", text: $viewModel.cardNumberText)
                    .keyboardType(.numberPad)
                    .textContentType(.creditCardNumber)
                    .font(.title3.monospaced())
                    .focused($focusedField, equals: .cardNumber)
                    .onChange(of: viewModel.cardNumberText) { newValue in
                        viewModel.handleCardNumberInput(newValue)
                    }
                    .accessibilityLabel(Text("Card number", bundle: .module))
                    .accessibilityHint(Text("Enter your 15 or 16 digit card number", bundle: .module))

                if let logoName = viewModel.detectedScheme.logoImageName {
                    Image(logoName, bundle: .module)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 25)
                        .fixedSize()
                }
            }
            .frame(height: 56)
            .padding(.horizontal)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .animation(.easeInOut(duration: 0.2), value: viewModel.detectedScheme.logoImageName)

            if let error = viewModel.cardNumberError {
                fieldErrorLabel(error)
            }
        }
    }

    // MARK: - Expiry date

    private var expiryField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Expiry date", bundle: .module)
                .font(.caption)
                .foregroundColor(.secondary)

            TextField("MM/YY", text: $viewModel.expiryText)
                .keyboardType(.numberPad)
                .font(.title3.monospaced())
                .focused($focusedField, equals: .expiry)
                .onChange(of: viewModel.expiryText) { newValue in
                    viewModel.handleExpiryInput(newValue)
                }
                .frame(height: 56)
                .padding(.horizontal)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel(Text("Expiry date", bundle: .module))
                .accessibilityHint(Text("Enter month and year, for example 06 30", bundle: .module))

            if let error = viewModel.expiryError {
                fieldErrorLabel(error)
            }
        }
    }

    // MARK: - CVV

    private var cvvField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CVV", bundle: .module)
                .font(.caption)
                .foregroundColor(.secondary)

            SecureField("123", text: $viewModel.cvvText)
                .keyboardType(.numberPad)
                .font(.title3.monospaced())
                .focused($focusedField, equals: .cvv)
                .onChange(of: viewModel.cvvText) { newValue in
                    viewModel.handleCVVInput(newValue)
                }
                .frame(height: 56)
                .padding(.horizontal)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityLabel(Text("CVV security code", bundle: .module))
                .accessibilityHint(Text("Enter your 3 or 4 digit security code", bundle: .module))

            if let error = viewModel.cvvError {
                fieldErrorLabel(error)
            }
        }
    }

    // MARK: - Field Error Label

    private func fieldErrorLabel(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundColor(.red)
            .accessibilityLabel(Text("Error: \(message)", bundle: .module))
    }

    // MARK: - Error Message

    @ViewBuilder
    private var errorMessageView: some View {
        if let error = viewModel.errorMessage, !viewModel.showFieldErrors || isAPIError(error) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(error)
                    .font(.callout)
                    .foregroundColor(.red)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("Error: \(error)", bundle: .module))
        }
    }

    private func isAPIError(_ error: String) -> Bool {
        error.contains("Tokenization") || error.contains("Payment") ||
        error.contains("HTTP") || error.contains("server") ||
        error.contains("3DS") || error.contains("redirect")
    }

    // MARK: - Pay Button

    private var payButton: some View {
        Button {
            viewModel.processPayment()
        } label: {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Pay \(viewModel.formattedAmount)", bundle: .module)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(viewModel.isFormValid && !viewModel.isLoading ? Color.blue : Color.gray)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(viewModel.isLoading)
        .accessibilityLabel(Text("Pay \(viewModel.formattedAmount)", bundle: .module))
        .accessibilityHint(viewModel.isFormValid
            ? Text("Double tap to process payment", bundle: .module)
            : Text("Complete all card details first", bundle: .module))
    }
}
