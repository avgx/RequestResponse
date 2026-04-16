import Foundation

/// Resolves a server root string returned by discovery APIs (often protocol-relative, e.g. `//host:443/tpan1/…/webclient/`)
/// into an absolute URL suitable as ``RequestBuilder/baseURL``.
///
/// Typical flow: you keep a canonical base (`https://example.org`), receive `//example.org:443/tpan1/12_1_bmyolk/webclient/`,
/// resolve with ``resolve(_:schemeReference:)``, then build ``Request`` paths relative to that root (e.g. `path: "api/foo"`).
public enum RootURL {

    /// Resolves `discovery` into an absolute URL.
    ///
    /// - **Protocol-relative** (`//host:port/path/`): prepends `schemeReference.scheme` (defaulting to `https`) plus `":"`, so `//…` becomes `https://…`.
    /// - **Absolute** (`http(s)://…`): parsed as-is (then normalized).
    /// - **Path-only** (`/tpan1/…`): resolved against `schemeReference` (same host/scheme/port as the reference URL, path replaced/merged via `URL` relative resolution).
    ///
    /// The result is normalized as a directory base (trailing `/`) so it concatenates cleanly with ``RequestBuilder`` URL rules.
    public static func resolve(_ discovery: String, schemeReference: URL) throws -> URL {
        let trimmed = discovery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw URLError(.badURL)
        }

        let resolved: URL
        if trimmed.hasPrefix("//") {
            let scheme = (schemeReference.scheme ?? "https") + ":"
            guard let url = URL(string: scheme + trimmed) else {
                throw URLError(.badURL)
            }
            resolved = url
        } else if trimmed.hasPrefix("/") {
            guard let url = URL(string: trimmed, relativeTo: schemeReference)?.absoluteURL else {
                throw URLError(.badURL)
            }
            resolved = url
        } else if let url = URL(string: trimmed), url.scheme != nil {
            resolved = url
        } else {
            throw URLError(.badURL)
        }

        return normalizeDirectoryBase(resolved)
    }

    /// Same as ``resolve(_:schemeReference:)`` but returns `nil` instead of throwing.
    public static func resolveIfPresent(_ discovery: String?, schemeReference: URL) -> URL? {
        guard let discovery, !discovery.isEmpty else { return nil }
        return try? resolve(discovery, schemeReference: schemeReference)
    }

    private static func normalizeDirectoryBase(_ url: URL) -> URL {
        let s = url.absoluteString
        guard !s.hasSuffix("/") else { return url }
        if s.contains("?") || s.contains("#") {
            return url
        }
        return URL(string: s + "/") ?? url
    }
}
