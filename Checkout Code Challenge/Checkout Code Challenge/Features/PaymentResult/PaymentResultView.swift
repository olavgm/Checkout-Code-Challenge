//
//  PaymentResultView.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import SwiftUI

struct PaymentResultView: View {
    let success: Bool
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            resultIcon
            resultTitle
            resultMessage
            Spacer()
            dismissButton
        }
        .padding(32)
    }

    // MARK: - Result Icon

    private var resultIcon: some View {
        Image(systemName: success ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.system(size: 80))
            .foregroundColor(success ? .green : .red)
            .accessibilityHidden(true)
    }

    // MARK: - Title

    private var resultTitle: some View {
        Text(success
            ? NSLocalizedString("Payment Completed", comment: "Title shown after successful payment")
            : NSLocalizedString("Payment Failed", comment: "Title shown after failed payment")
        )
            .font(.title)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
    }

    // MARK: - Message

    private var resultMessage: some View {
        Text(
            success
            ? NSLocalizedString("Your payment was processed successfully.", comment: "Success message after payment")
            : NSLocalizedString("Your payment could not be processed. Please try again.", comment: "Failure message after payment")
        )
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Dismiss Button

    private var dismissButton: some View {
        Button(action: onDismiss) {
            Text(success
                ? NSLocalizedString("Done", comment: "Button title after successful payment")
                : NSLocalizedString("Try Again", comment: "Button title after failed payment")
            )
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .background(success ? Color.green : Color.blue)
        .foregroundColor(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel(success
            ? NSLocalizedString("Done", comment: "Accessibility label for done button")
            : NSLocalizedString("Try again", comment: "Accessibility label for retry button")
        )
        .accessibilityHint(NSLocalizedString("Returns to the card input screen", comment: "Accessibility hint for dismiss button"))
    }
}
