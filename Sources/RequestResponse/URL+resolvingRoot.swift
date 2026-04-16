import Foundation

/// Resolves a discovery root string (often protocol-relative, e.g. `//host:443/tpan1/.../webclient/`)
/// into an absolute URL suitable as a `RequestBuilder.baseURL`.
public extension URL {
    /// Resolves `root` into an absolute URL using the receiver as a reference.
    ///
    /// - **Protocol-relative** (`//host:port/path/`): prepends `self.scheme` (defaulting to `https`) plus `":"`.
    /// - **Absolute** (`http(s)://...`): parsed as-is.
    /// - **Path-only** (`/tpan1/...`): resolved relative to `self` via `URL(string:relativeTo:)`.
    ///
    /// The result is normalized as a directory base (trailing `/`) so it concatenates cleanly with `RequestBuilder` URL rules.
    func resolvingRoot(_ root: String) throws -> URL {
        let trimmed = root.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw URLError(.badURL)
        }

        let resolved: URL
        if trimmed.hasPrefix("//") {
            let scheme = (self.scheme ?? "https") + ":"
            guard let url = URL(string: scheme + trimmed) else {
                throw URLError(.badURL)
            }
            resolved = url
        } else if trimmed.hasPrefix("/") {
            guard let url = URL(string: trimmed, relativeTo: self)?.absoluteURL else {
                throw URLError(.badURL)
            }
            resolved = url
        } else if let url = URL(string: trimmed), url.scheme != nil {
            resolved = url
        } else {
            throw URLError(.badURL)
        }

        return resolved.normalizedDirectoryBase()
    }

    /// Same as `resolvingRoot(_:)` but returns `nil` instead of throwing.
    func resolvingRootIfPresent(_ root: String?) -> URL? {
        guard let root else { return nil }
        let trimmed = root.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return try? resolvingRoot(trimmed)
    }

    /// Returns a URL normalized as a directory base with a trailing `/`.
    ///
    /// URLs with query or fragment are returned unchanged.
    func normalizedDirectoryBase() -> URL {
        let value = absoluteString
        guard !value.hasSuffix("/") else { return self }
        if value.contains("?") || value.contains("#") {
            return self
        }
        return URL(string: value + "/") ?? self
    }
}
