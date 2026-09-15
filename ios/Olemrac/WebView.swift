import SwiftUI
import WebKit
import UniformTypeIdentifiers

/// Hosts the bundled Olemrac web app. The page is served from a custom scheme
/// (olemrac://app/…) rather than file:// so IndexedDB and localStorage get a
/// stable origin and persist between launches.
struct WebView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(AppSchemeHandler(), forURLScheme: AppSchemeHandler.scheme)
        config.allowsInlineMediaPlayback = true
        config.websiteDataStore = .default()   // persistent: keeps the ledger between launches
        config.userContentController.add(context.coordinator, name: "olemrac")

        let web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = context.coordinator
        web.uiDelegate = context.coordinator
        web.scrollView.contentInsetAdjustmentBehavior = .never
        web.isOpaque = false
        web.backgroundColor = .clear
        web.allowsBackForwardNavigationGestures = false
        #if DEBUG
        if #available(iOS 16.4, *) { web.isInspectable = true }
        #endif
        context.coordinator.web = web
        web.load(URLRequest(url: AppSchemeHandler.indexURL))
        return web
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        weak var web: WKWebView?

        // Messages from the page: { type: "share", filename, data } for CSV export.
        func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
            switch type {
            case "share":
                guard let name = body["filename"] as? String, let data = body["data"] as? String else { return }
                shareFile(named: name, contents: data)
            case "haptic":
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            default:
                break
            }
        }

        private func shareFile(named name: String, contents: String) {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
            try? contents.data(using: .utf8)?.write(to: url)
            let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let pop = sheet.popoverPresentationController, let v = web { pop.sourceView = v; pop.sourceRect = CGRect(x: v.bounds.midX, y: v.bounds.maxY - 40, width: 1, height: 1) }
            topController()?.present(sheet, animated: true)
        }

        // External links (e.g. a PDF receipt opened in a new tab) go to Safari.
        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = action.request.url, url.scheme != AppSchemeHandler.scheme, url.scheme != "blob", url.scheme != "about", url.scheme != "data" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = action.request.url { UIApplication.shared.open(url) }
            return nil
        }

        // JS confirm()/alert() need a host to show them.
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
            topController()?.present(a, animated: true)
        }
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            topController()?.present(a, animated: true)
        }

        private func topController() -> UIViewController? {
            let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            var top = scene?.keyWindow?.rootViewController
            while let p = top?.presentedViewController { top = p }
            return top
        }
    }
}
