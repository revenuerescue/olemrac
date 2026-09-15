import WebKit
import UniformTypeIdentifiers

/// Serves the files in the bundled `web/` folder at olemrac://app/<path>.
final class AppSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "olemrac"
    static let indexURL = URL(string: "olemrac://app/index.html")!

    func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
        guard let url = task.request.url else { return }
        var path = url.path.isEmpty || url.path == "/" ? "/index.html" : url.path
        if path.hasSuffix("/") { path += "index.html" }
        let rel = String(path.dropFirst())                       // "icons/icon-192.png"
        let base = Bundle.main.resourceURL!.appendingPathComponent("web")
        let file = base.appendingPathComponent(rel)
        guard let data = try? Data(contentsOf: file) else {
            task.didReceive(HTTPURLResponse(url: url, statusCode: 404, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "text/plain"])!)
            task.didReceive("Not found: \(rel)".data(using: .utf8)!)
            task.didFinish()
            return
        }
        let type = UTType(filenameExtension: file.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
        let headers = ["Content-Type": type, "Content-Length": String(data.count), "Cache-Control": "no-cache"]
        task.didReceive(HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!)
        task.didReceive(data)
        task.didFinish()
    }

    func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}
