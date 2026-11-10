import SwiftUI
import WebKit
import StandLockCore

/// WebKit supplies native MathML layout for the bank's LaTeX source. The document has
/// no scripts or network resources, and its local data store is discarded with the view.
struct LatexMathView: NSViewRepresentable {
    let prompt: String
    @Environment(\.colorScheme) private var colorScheme

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.underPageBackgroundColor = .clear
        return view
    }

    func updateNSView(_ view: WKWebView, context: Context) {
        let dark = colorScheme == .dark
        guard context.coordinator.prompt != prompt || context.coordinator.dark != dark else { return }
        context.coordinator.prompt = prompt
        context.coordinator.dark = dark
        view.loadHTMLString(MathPromptDocument(prompt).html(dark: dark), baseURL: nil)
    }

    @MainActor final class Coordinator: NSObject, WKNavigationDelegate {
        var prompt: String?
        var dark: Bool?

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            navigationAction.request.url?.absoluteString == "about:blank" ? .allow : .cancel
        }
    }
}
