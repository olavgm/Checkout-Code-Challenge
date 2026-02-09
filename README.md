# Checkout-Code-Challenge

Checkout Code Challenge Feb 2026

An iOS app that implements a complete 3D Secure payment flow using the Checkout.com API. Built with SwiftUI, targeting iOS 15+.

## Payment Flow

1. **Card Input** — Enter card number, expiry, and CVV with real-time validation and formatting
2. **3DS Challenge** — Complete 3D Secure verification in a WebView
3. **Payment Result** — See the payment outcome (success or failure)

## Architecture

MVVM with protocol-based dependency injection. No third-party dependencies.

The payment flow is encapsulated in a **local SPM module** (`CheckoutFlow`). The host app only injects API secrets and listens for the final result.

```
Host App                          CheckoutFlow Module
─────────                         ───────────────────
APIConfiguration (Info.plist)  →  CheckoutFlowConfiguration  →  CheckoutFlowView
PaymentResultView              ←  CheckoutFlowResult            ├── CardInputView → CardInputViewModel → CheckoutAPIService
                                                                ├── ThreeDSWebView
                                                                └── NetworkClient
```

- **Views** are purely declarative with no business logic — display text and focus state are owned by the ViewModel
- **ViewModels** manage state via `@Published` properties and `async/await`
- **Services** are behind protocols, enabling mock injection for testing
- **NetworkClient** provides a generic `perform<T: Decodable>(request:)` method used by all API calls
- **APIConfiguration** reads keys from `Info.plist`, populated at build time via xcconfig files

### Key Design Decisions

| Decision                          | Rationale                                                          |
| --------------------------------- | ------------------------------------------------------------------ |
| Local SPM module                  | Encapsulates payment logic; clear public API boundary              |
| No third-party dependencies       | URLSession covers the scope; avoids dependency management overhead |
| Protocol-based DI                 | Mock injection in tests without any DI framework                   |
| `ObservableObject` + `@Published` | Supports iOS 15+ while providing reactive SwiftUI integration      |
| `PaymentFlowState` enum           | Makes navigation explicit and prevents invalid states              |
| xcconfig-based API keys           | Separates sandbox/production config; no keys in Swift source       |

## Project Structure

```
Checkout Code Challenge/
├── Checkout Code Challenge/                # Host app
│   ├── App/
│   │   ├── CheckoutCodeChallengeApp.swift  # Entry point
│   │   └── ContentView.swift              # Injects config, listens for result
│   ├── Features/
│   │   └── PaymentResult/
│   │       └── PaymentResultView.swift    # Success/failure screen
│   ├── Configuration/
│   │   ├── APIConfiguration.swift         # Reads API keys from Info.plist
│   │   └── Checkout-template.xcconfig     # Template for API keys
│   └── Resources/
│       ├── Assets.xcassets/               # App icon
│       └── Localizable.xcstrings          # String catalog (English)
├── Checkout Code ChallengeTests/
│   └── CheckoutCodeChallengeTests.swift   # App-level test
└── CheckoutFlow/                          # Local SPM package
    ├── Package.swift
    ├── Sources/CheckoutFlow/
    │   ├── CheckoutFlowConfiguration.swift    # Public: config struct
    │   ├── CheckoutFlowResult.swift           # Public: success/failure enum
    │   ├── CheckoutFlowView.swift             # Public: entry-point view
    │   ├── CardEntry/
    │   │   ├── CardInputView.swift            # Card input form
    │   │   ├── CardInputViewModel.swift       # Card input state and logic
    │   │   ├── CardScheme.swift               # Card scheme detection
    │   │   ├── CardValidator.swift            # Luhn, expiry, CVV, formatting
    │   │   └── CardValidatorProtocol.swift
    │   ├── Checkout/
    │   │   ├── PaymentConfigurationProvider.swift
    │   │   ├── PaymentRequest.swift / PaymentResponse.swift
    │   │   ├── TokenRequest.swift / TokenResponse.swift
    │   │   ├── PaymentError.swift
    │   │   └── APIErrorResponse.swift
    │   ├── Services/
    │   │   ├── CheckoutAPIService.swift
    │   │   ├── CheckoutAPIServiceProtocol.swift
    │   │   └── APIConfiguration.swift
    │   ├── Networking/
    │   │   └── NetworkClient.swift
    │   ├── ThreeDS/
    │   │   └── ThreeDSWebView.swift
    │   └── Resources/
    │       └── CardLogos.xcassets/             # Visa, Mastercard, Amex logos
    └── Tests/CheckoutFlowTests/
        ├── CardInputViewModelTests.swift
        ├── CardSchemeTests.swift
        ├── CardValidatorTests.swift
        ├── CheckoutAPIServiceTests.swift
        ├── NetworkClientTests.swift
        ├── PaymentModelTests.swift
        └── Mocks/
```

## Card Validation

- **Scheme detection** from the first digits (Visa, Mastercard, Amex)
- **Card logo** displayed as soon as the scheme is identified
- **Luhn algorithm** for card number checksum validation
- **Auto-formatting** by scheme (4-4-4-4 for Visa/MC, 4-6-5 for Amex)
- **Expiry formatting** with auto-inserted `/` separator
- **CVV length** enforced per scheme (3 for Visa/MC, 4 for Amex)
- **Input limiting** to the max digits for each scheme
- **Inline error messages** per field on blur (leaving a field) and on submission
- **Invalid date detection** — distinguishes between impossible dates (e.g. month 16) and expired cards

## How to Run

1. Open `Checkout Code Challenge.xcodeproj` in Xcode
2. Copy `Configuration/Checkout-template.xcconfig` to `Checkout-Sandbox.xcconfig` and fill in your Checkout.com sandbox keys
3. Select a simulator or device (iOS 15+)
4. Build and run (Cmd+R)

### Test Cards

| Scenario           | Card Number         | Expiry | CVV |
| ------------------ | ------------------- | ------ | --- |
| Success (3DS pass) | 4242 4242 4242 4242 | 06/30  | 100 |
| Failure (3DS fail) | 4243 7542 7170 0719 | 06/30  | 100 |

## Testing

Run the full test suite (112 tests) via Xcode (Cmd+U) or from the command line:

```bash
xcodebuild test \
  -project "Checkout Code Challenge/Checkout Code Challenge.xcodeproj" \
  -scheme "Checkout Code Challenge (Sandbox)" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

All tests use mock services (`MockCheckoutAPIService`, `MockCardValidator`, `MockURLSession`) to isolate business logic from network calls.

### Module Tests (111 tests — in `CheckoutFlow/Tests/`)

| Test File                 | Coverage                                                                         |
| ------------------------- | -------------------------------------------------------------------------------- |
| `CardValidatorTests`      | Luhn algorithm, expiry validation, CVV rules, number/expiry formatting           |
| `CardInputViewModelTests` | Payment flow, input handling, form validation, API failure handling, state reset |
| `PaymentModelTests`       | JSON encoding/decoding for all API models                                        |
| `NetworkClientTests`      | HTTP success/error handling, JSON decoding, malformed responses                  |
| `CheckoutAPIServiceTests` | Tokenize and payment request/response, error mapping                             |
| `CardSchemeTests`         | Card scheme detection from card number prefixes                                  |

### App Tests (1 test — in `Checkout Code ChallengeTests/`)

| Test File                      | Coverage                                                    |
| ------------------------------ | ----------------------------------------------------------- |
| `CheckoutCodeChallengeTests`   | Verifies `CheckoutFlowConfiguration` creation from API keys |

## Accessibility

- All input fields have `accessibilityLabel` and `accessibilityHint`
- Error messages use combined accessible element labels
- Pay button hint reflects form validity
- Result icons are decorative (`accessibilityHidden`)

## Localization

Both the host app and the CheckoutFlow module have their own String Catalog (`Localizable.xcstrings`) with English as the base language. The module uses `bundle: .module` for all `NSLocalizedString` calls and `Text` views so translations resolve from the package's own bundle. To add a new language, add translations to each `Localizable.xcstrings` in Xcode's String Catalog editor. Non-view strings use `NSLocalizedString` for iOS 15 compatibility.

## Linting

A SwiftLint build phase runs automatically if SwiftLint is installed. Lint issues appear as warnings only. Configuration is in `.swiftlint.yml`.

## CheckoutFlow Module

The `CheckoutFlow` local SPM package exposes three public types:

- **`CheckoutFlowConfiguration`** — Accepts API keys, base URL, payment amount/currency, and 3DS redirect URLs
- **`CheckoutFlowResult`** — `.success` or `.failure`
- **`CheckoutFlowView`** — SwiftUI view that runs the entire payment flow and reports the result via a callback

Everything else inside the module (networking, validation, API models, 3DS handling) is `internal`.

```swift
// Host app usage
import CheckoutFlow

CheckoutFlowView(configuration: config) { result in
    // result is .success or .failure
}
```

## Assumptions

- **Amount**: Defaults to GBP 10.77, configurable via `CheckoutFlowConfiguration(paymentAmount:)` using `Decimal` for precision
- **API keys**: Provided via xcconfig files, read through `Info.plist` at runtime. In production, the secret key should never be in the client app
- **3DS redirect URLs**: Placeholder URLs (`https://example.com/payments/success` and `/fail`), overridable in `CheckoutFlowConfiguration`
- **iOS version**: 15+ for broad device compatibility
