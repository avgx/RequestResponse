import Foundation

/// Builds resolved URLs and `URLRequest` values from a ``Request`` and client context (base URL, body encoding, default headers).
public struct RequestBuilder: Sendable {
    public let baseURL: URL
    
    /// Values from `URLSessionConfiguration.httpAdditionalHeaders`, used for default Content-Type / Accept checks.
    public let sessionDefaultHeaders: [String: String]?

    private let encodeBody: @Sendable (any Encodable & Sendable) async throws -> Data?

    /// Full control over how request bodies are encoded (JSON, custom binary, empty, etc.).
    public init(
        baseURL: URL,
        sessionDefaultHeaders: [String: String]? = nil,
        encodeBody: @escaping @Sendable (any Encodable & Sendable) async throws -> Data?
    ) {
        self.baseURL = baseURL
        self.sessionDefaultHeaders = sessionDefaultHeaders
        self.encodeBody = encodeBody
    }

    /// JSON-friendly encoding: `Data` and `String` pass through; other values are JSON-encoded. The encoder is not stored on the builder; it is captured by the closure.
    public static func json(
        baseURL: URL,
        encoder: JSONEncoder,
        sessionDefaultHeaders: [String: String]? = nil
    ) -> RequestBuilder {
        RequestBuilder(baseURL: baseURL, sessionDefaultHeaders: sessionDefaultHeaders) { value in
            if let data = value as? Data { return data }
            if let string = value as? String { return string.data(using: .utf8) }
            return try await Task.detached {
                try encoder.encode(value)
            }.value
        }
    }

    public func url<T>(for request: Request<T>) throws -> URL {
        let baseFix = baseURL.absoluteString.hasSuffix("/")
            ? baseURL.absoluteString
            : baseURL.absoluteString + "/"
        let pathFix = request.path.hasPrefix("/")
            ? String(request.path.dropFirst())
            : request.path
        let resultUrl = URL(string: baseFix + pathFix)

        guard let url = resultUrl, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw URLError(.badURL)
        }
        if let query = request.query, !query.isEmpty {
            components.queryItems = query.map(URLQueryItem.init)
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }
        return url
    }

    public func urlRequest<T>(for request: Request<T>) async throws -> URLRequest {
        let url = try url(for: request)
        var urlRequest = URLRequest(url: url)
        urlRequest.allHTTPHeaderFields = request.headers
        urlRequest.httpMethod = request.method.rawValue
        if let body = request.body {
            urlRequest.httpBody = try await encodeBody(body)
            if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil,
               sessionDefaultHeaders?["Content-Type"] == nil {
                urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        if urlRequest.value(forHTTPHeaderField: "Accept") == nil,
           sessionDefaultHeaders?["Accept"] == nil {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        }
        return urlRequest
    }
}
