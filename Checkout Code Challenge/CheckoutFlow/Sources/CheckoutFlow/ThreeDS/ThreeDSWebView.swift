//
//  ThreeDSWebView.swift
//  Checkout Code Challenge
//
//  Created by Olav Gausaker on 9/2/26.
//

import SwiftUI
import WebKit

struct ThreeDSWebView: UIViewRepresentable {
    let url: URL
    let successURL: String
    let failureURL: String
    let onComplete: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed; initial load handled in makeUIView
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: ThreeDSWebView

        init(parent: ThreeDSWebView) {
            self.parent = parent
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url?.absoluteString else {
                decisionHandler(.allow)
                return
            }

            if url.hasPrefix(parent.successURL) {
                decisionHandler(.cancel)
                parent.onComplete(true)
                return
            }

            if url.hasPrefix(parent.failureURL) {
                decisionHandler(.cancel)
                parent.onComplete(false)
                return
            }

            decisionHandler(.allow)
        }

        func webView(
            _ webView: WKWebView,
            didFail navigation: WKNavigation!,
            withError error: Error
        ) {
            // Navigation failure is treated as payment failure
            parent.onComplete(false)
        }
    }
}
