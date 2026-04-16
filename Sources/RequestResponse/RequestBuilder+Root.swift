import Foundation

extension RequestBuilder {

    /// Builds a ``RequestBuilder`` whose ``baseURL`` is the resolved discovery root (e.g. `//host:443/tpan1/…/webclient/`).
    ///
    /// - Parameters:
    ///   - discoveryServerRoot: String from your server method (protocol-relative or absolute).
    ///   - schemeReference: Your known base (e.g. `https://axxonnet.com`) — its **scheme** is applied for `//…` inputs; for path-only inputs it is the relative base.
    ///   - encoder: Same as ``RequestBuilder/init(baseURL:encoder:sessionDefaultHeaders:)``.
    ///   - sessionDefaultHeaders: Same as ``RequestBuilder/init(baseURL:encoder:sessionDefaultHeaders:)``.
    public static func withResolvedRoot(
        discoveryRoot: String,
        schemeReference: URL,
        encoder: JSONEncoder,
        sessionDefaultHeaders: [String: String]? = nil
    ) throws -> RequestBuilder {
        let base = try RootURL.resolve(discoveryRoot, schemeReference: schemeReference)
        return RequestBuilder(baseURL: base, encoder: encoder, sessionDefaultHeaders: sessionDefaultHeaders)
    }
}
